using AnnotatedTests
using Aqua
using JET
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
        @test occursin("Try again.", expected_feedback("Try again.")(ctx))
        @test occursin("Observed length: 3", length_feedback()(ctx))
        @test occursin("order is different", unordered_feedback()(ctx))

        type_ctx = AnnotationContext("type", :(student() isa Vector{Int}), :isa,
                                     :(student()), :(Vector{Int}), [1, 2], Vector{Int}, false)
        @test occursin("Observed type: Vector{Int64}", type_feedback()(type_ctx))
    end

    @testset "operator terms" begin
        @test AnnotatedTests._operator_terms(Symbol("≈"), 1.0, 1.25).difference == 0.25

        within10(x, y) = abs(x - y) <= 10
        register_annotated_operator!(:within10; terms=(lhs, rhs) -> (difference=abs(lhs - rhs),))
        @test AnnotatedTests._binary_parts(:(within10(1, 20))) == (:within10, 1, 20)
        @test AnnotatedTests._operator_terms(:within10, 1, 20).difference == 19
        @annotated_test "custom operator pass" within10(10, 12) "should not appear"
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

    @annotated_broken "known issue" 1 == 2 "This is expected to fail for now."

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

@testset "JET" begin
    report = JET.report_package(AnnotatedTests; target_modules=(AnnotatedTests,))
    @test isempty(JET.get_reports(report))
end
