# AnnotatedTests.jl

`AnnotatedTests.jl` adds named, annotated tests to Julia's standard testing
workflow. It is intended for teaching contexts where a failing test should give a
student a concrete next step, not only a Boolean failure.

```julia
@annotated_test "absolute value" abs(x) >= 0 ctx -> "The absolute value should never be negative."
```

## Quick Start

```julia
using AnnotatedTests

@annotated_test "sorts a vector" mysort([3, 1, 2]) == [1, 2, 3] \
    "Return the values in increasing order."

@atest "same values" sort(student_values()) == [1, 2, 3] unordered_feedback()
```

Use `@annotated_testset` when you want a pedagogical name for a group of related
checks:

```julia
@annotated_testset "Assignment 1" begin
    @annotated_test "question 1" q1() == 42 "Review the formula for q1."
end
```

The feedback handler may be a string, a function, or a callable object. Function
handlers receive an [`AnnotationContext`](@ref), which includes evaluated left and
right values for supported binary comparisons. The traditional `ctx.lhs` and
`ctx.rhs` names are available alongside teaching-oriented aliases:
`ctx.observed`, `ctx.expected`, `ctx.LHS`, and `ctx.RHS`.

## Supported Comparisons

AnnotatedTests captures the left and right side of `==`, `!=`, `<`, `<=`, `>`,
`>=`, `===`, `!==`, `in`, `∈`, `isa`, and `≈`. Each side is evaluated once.

For non-binary expressions, the context still records the test name and original
expression, but the binary-expression fields are `nothing`.

`≈` also records `ctx.difference` when a difference can be computed.

## Feedback Helpers

```julia
@atest "close answer" estimate() ≈ 10 compare_feedback(message="Check your rounding.")
@atest "close answer with tolerance" estimate() ≈ 10 atol=0.01
@atest "right type" answer() isa Vector{Int} type_feedback()
@atest "right length" answer() == expected length_feedback()
@atest "same items" answer() == expected unordered_feedback()
```

Trailing keyword arguments other than `broken` and `skip` are forwarded to the
tested function or comparison, matching `Test.@test`:

```julia
@annotated_test "pi approximation" π ≈ 3.14 atol=0.01
@annotated_test "pi approximation" isapprox(π, 3.14) atol=0.01
```

## Broken And Skipped Tests

```julia
@annotated_test "stretch goal" advanced_answer() == expected \
    "This check documents the next feature to implement." broken=true

@atest "requires optional data" answer_from_file() == expected skip=!isfile(path)
```

When `broken` or `skip` evaluates to `true`, the test expression is not
evaluated. This mirrors Julia's `Test.@test` behavior.

## Exception Tests

```julia
@annotated_test_throws "rejects empty input" ArgumentError parse_answer("") \
    "Empty input should throw an ArgumentError."

@atest_throws "rejects missing file" SystemError read("missing.txt")
```

The expected exception can be a type, tuple of types, exception value, string, or
regular expression. Feedback handlers receive `ctx.thrown`, `ctx.thrown_type`,
`ctx.expected_exception`, and `ctx.message`.

## Custom Operators

Use [`register_annotated_operator!`](@ref) to add a relation and optional terms:

```julia
relapprox(x, y; rtol=0.05) = abs(x - y) / max(abs(y), eps()) <= rtol

register_annotated_operator!(:relapprox; terms=(lhs, rhs) -> (
    relative_difference = abs(lhs - rhs) / max(abs(rhs), eps()),
))

@atest "relative error" relapprox(student_answer(), 100; rtol=0.02) ctx ->
    "The relative difference was $(ctx.relative_difference); it must be below 2%."
```

## API

```@docs
@annotated_test
@atest
@annotated_test_throws
@atest_throws
@annotated_testset
AnnotationContext
default_feedback
compare_feedback
type_feedback
length_feedback
unordered_feedback
register_annotated_operator!
```
