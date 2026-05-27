using AnnotatedTests
using Aqua
using JET
using Test

@testset "AnnotatedTests" begin
    @annotated_test "simple pass" 1 + 1 == 2 "should not appear"

    @testset "expression parsing" begin
        parts = AnnotatedTests._binary_parts(:(1 + 1 == 3))
        @test parts == (Symbol("=="), :(1 + 1), 3)

        @test AnnotatedTests._binary_parts(:(isready())) === nothing
    end

    @testset "default feedback" begin
        ctx = AnnotationContext("comparison", :(1 == 2), Symbol("=="), :1, :2, 1, 2, false)
        msg = default_feedback(ctx)
        @test occursin("comparison failed", msg)
        @test occursin("Observed left value: 1", msg)
        @test occursin("Observed right value: 2", msg)

        nonbinary = AnnotationContext("condition", :(false), nothing,
                                      nothing, nothing, nothing, nothing, false)
        @test default_feedback(nonbinary) == "The condition evaluated to false."
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
end

@testset "Aqua" begin
    Aqua.test_all(AnnotatedTests)
end

@testset "JET" begin
    report = JET.report_package(AnnotatedTests; target_modules=(AnnotatedTests,))
    @test isempty(JET.get_reports(report))
end
