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
@atest "close answer" estimate() ≈ 10 expected_feedback("Check your rounding.")
@atest "right type" answer() isa Vector{Int} type_feedback()
@atest "right length" answer() == expected length_feedback()
@atest "same items" answer() == expected unordered_feedback()
```

## Broken Tests

```julia
@annotated_broken "stretch goal" advanced_answer() == expected \
    "This check documents the next feature to implement."
```

## Custom Operators

Use [`register_annotated_operator!`](@ref) to add a relation and optional terms:

```julia
within10(x, y) = abs(x - y) <= 10

register_annotated_operator!(:within10; terms=(lhs, rhs) -> (
    difference = abs(lhs - rhs),
))

@atest "within tolerance" within10(student_answer(), 100) ctx ->
    "The difference was $(ctx.difference); it must be at most 10."
```

## API

```@docs
@annotated_test
@atest
@annotated_broken
@annotated_testset
AnnotationContext
default_feedback
compare_feedback
expected_feedback
type_feedback
length_feedback
unordered_feedback
register_annotated_operator!
```
