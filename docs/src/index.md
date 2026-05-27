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

@annotated_test "sorts a vector" mysort([3, 1, 2]) == [1, 2, 3] ctx ->
    "Expected $(ctx.rhs), got $(ctx.lhs). Check the order of the result."
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
right values for supported binary comparisons.

## Supported Comparisons

AnnotatedTests captures the left and right side of `==`, `!=`, `<`, `<=`, `>`,
`>=`, `===`, `!==`, `in`, `∈`, `isa`, and `≈`. Each side is evaluated once.

For non-binary expressions, the context still records the test name and original
expression, but the binary-expression fields are `nothing`.

## API

```@docs
@annotated_test
@annotated_testset
AnnotationContext
default_feedback
```
