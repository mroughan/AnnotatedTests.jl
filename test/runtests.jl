using AnnotatedTests
using Aqua
using Test

@testset "AnnotatedTests" begin
    @annotated_test "simple pass" 1 + 1 == 2 "should not appear"
    @atest "short alias pass" 2 + 2 == 4 "should not appear"

    @testset "expression parsing" begin
        parts = AnnotatedTests._binary_parts(:(1 + 1 == 3))
        @test parts == (Symbol("=="), :(1 + 1), 3)

        @test AnnotatedTests._binary_parts(:(isready())) === nothing
    end

    @testset "context aliases and default feedback" begin
        ctx = AnnotationContext("comparison", :(1 == 2), Symbol("=="), :1, :2, 1, 2, false,
                                (difference=1,))
        @test ctx.observed == ctx.lhs == ctx.LHS == 1
        @test ctx.expected == ctx.rhs == ctx.RHS == 2
        @test ctx.difference == 1

        msg = default_feedback(ctx)
        @test occursin("Test: comparison", msg)
        @test occursin("Expression: :(1 == 2)", msg)
        @test occursin("Observed: 1", msg)
        @test occursin("Expected: 2", msg)
        @test occursin("Difference: 1", msg)

        nonbinary = AnnotationContext("condition", :(false), nothing,
                                      nothing, nothing, nothing, nothing, false)
        @test occursin("The condition evaluated to false.", default_feedback(nonbinary))
    end

    @testset "handler forms" begin
        ctx = AnnotationContext("handler", :(1 > 2), Symbol(">"), :1, :2, 1, 2, false)
        @test AnnotatedTests._feedback_message("Use a true condition.", ctx) == "Use a true condition."

        struct PrefixFeedback
            prefix::String
        end
        (handler::PrefixFeedback)(ctx) = "$(handler.prefix): $(ctx.name)"

        callable_calls = Ref(0)
        handler = PrefixFeedback("Hint")
        msg = AnnotatedTests._feedback_message(ctx -> begin
            callable_calls[] += 1
            handler(ctx)
        end, ctx)
        @test msg == "Hint: handler"
        @test callable_calls[] == 1
    end

    @testset "feedback helpers" begin
        ctx = AnnotationContext("values", :([1, 3, 2] == [1, 2, 3]), Symbol("=="),
                                :([1, 3, 2]), :([1, 2, 3]),
                                [1, 3, 2], [1, 2, 3], false)

        @test occursin("Observed: [1, 3, 2]", compare_feedback()(ctx))
        @test occursin("Try again.", compare_feedback(message="Try again.")(ctx))
        @test occursin("Observed length: 3", length_feedback()(ctx))
        @test occursin("order is different", unordered_feedback()(ctx))

        type_ctx = AnnotationContext("type", :(student() isa Vector{Int}), :isa,
                                     :(student()), :(Vector{Int}), [1, 2], Vector{Int}, false)
        @test occursin("Observed type: Vector{Int64}", type_feedback()(type_ctx))
    end

    @testset "throws" begin
        @annotated_test_throws "domain error" DomainError sqrt(-1)
        @atest_throws "short alias domain error" DomainError sqrt(-1)
        @annotated_test_throws "tuple of errors" (ArgumentError, DomainError) sqrt(-1)
        @annotated_test_throws "message regex" r"Domain" sqrt(-1)
        @annotated_test_throws "message string" "Domain" sqrt(-1)

        err = ErrorException("bad input")
        @test AnnotatedTests._exception_matches(ErrorException, err)
        @test AnnotatedTests._exception_matches((ArgumentError, ErrorException), err)
        @test AnnotatedTests._exception_matches(r"bad", err)
        @test AnnotatedTests._exception_matches("input", err)
        @test AnnotatedTests._exception_matches(ErrorException("bad input"), err)
        @test !AnnotatedTests._exception_matches(ArgumentError, err)
        @test !AnnotatedTests._exception_matches(ErrorException, nothing)

        ctx = AnnotationContext("throws", :(parse(Int, "x")), :throws,
                                nothing, :(ArgumentError), err, ArgumentError, false,
                                AnnotatedTests._throws_terms(ArgumentError, err))
        msg = default_feedback(ctx)
        @test occursin("Expected exception", msg)
        @test occursin("Thrown exception", msg)
        @test ctx.thrown === err
        @test ctx.expected_exception === ArgumentError
    end

    @testset "broken and skip keywords" begin
        calls = Ref(0)
        should_not_run() = (calls[] += 1; error("should not run"))

        @annotated_test "broken keyword" should_not_run() broken=true
        @annotated_test "skip keyword" should_not_run() skip=true
        @atest "short alias broken keyword" should_not_run() broken=true
        @annotated_test_throws "throws broken keyword" ErrorException should_not_run() broken=true
        @annotated_test_throws "throws skip keyword" ErrorException should_not_run() skip=true

        @test calls[] == 0

        flag = true
        @annotated_test "conditional normal" flag == true broken=false skip=false
    end

    @testset "Test-style keyword arguments" begin
        @annotated_test "approx atol" π ≈ 3.14 atol=0.01
        @atest "approx atol with handler" π ≈ 3.14 "pi should be close" atol=0.01
        @annotated_test "isapprox atol" isapprox(π, 3.14) atol=0.01

        tol = 0.01
        @annotated_test "approx variable atol" π ≈ 3.14 atol=tol
        @annotated_test "approx with explicit control keywords" π ≈ 3.14 atol=tol broken=false skip=false
    end

    @testset "operator terms" begin
        @test AnnotatedTests._operator_terms(Symbol("≈"), 1.0, 1.25).difference == 0.25
        @test AnnotatedTests._operator_terms(Symbol("≈"), [1.0, 2.0], [1.0, 2.5]).difference == 0.5
        @test AnnotatedTests._operator_terms(Symbol("≈"), "left", "right") == (;)
        @test AnnotatedTests._operator_terms(Symbol("=="), 1, 1) == (;)
        @test AnnotatedTests._operator_terms(:not_registered, 1, 2) == (;)

        register_annotated_operator!(:badterms; terms=(lhs, rhs) -> "not a NamedTuple")
        @test_throws ArgumentError AnnotatedTests._operator_terms(:badterms, 1, 2)

        within10(x, y) = abs(x - y) <= 10
        register_annotated_operator!(:within10; terms=(lhs, rhs) -> (difference=abs(lhs - rhs),))
        @test AnnotatedTests._binary_parts(:(within10(1, 20))) == (:within10, 1, 20)
        @test AnnotatedTests._operator_terms(:within10, 1, 20).difference == 19
        @annotated_test "custom operator pass" within10(10, 12) "should not appear"

        relapprox(x, y; rtol=0.05) = abs(x - y) / max(abs(y), eps()) <= rtol
        register_annotated_operator!(:relapprox; terms=(lhs, rhs) -> (
            relative_difference=abs(lhs - rhs) / max(abs(rhs), eps()),
        ))
        @test AnnotatedTests._binary_parts(:(relapprox(99, 100; rtol=0.02))) == (:relapprox, 99, 100)
        @test AnnotatedTests._operator_terms(:relapprox, 99, 100).relative_difference == 0.01
        @atest "relative operator pass" relapprox(99, 100; rtol=0.02) "should not appear"

        @test AnnotatedTests._binary_parts(:not_an_expr) === nothing
        @test AnnotatedTests._binary_parts(:(1 + 2 + 3)) === nothing
        @test AnnotatedTests._binary_parts(:(unknown_relation(1, 2))) === nothing
        @test AnnotatedTests._binary_parts(:(within10(1, 2, 3))) === nothing
    end

    @testset "single evaluation" begin
        xs = [3]
        @annotated_test "pop once" pop!(xs) == 3 "pop! should run once"
        @test isempty(xs)

        calls = Ref(0)
        is_ready() = (calls[] += 1; false)
        @test !is_ready()
        @test calls[] == 1
    end

    @annotated_testset "wrapper" begin
        @annotated_test "less-than" 1 < 2 "ok"
    end

    @annotated_test "known issue" 1 == 2 "This is expected to fail for now." broken=true

    wrapper_name = "wrapper variable name"
    observed = Ref(false)
    @annotated_testset wrapper_name begin
        observed[] = true
        @test observed[]
    end
end

@testset "Aqua" begin
    Aqua.test_all(AnnotatedTests)
end
