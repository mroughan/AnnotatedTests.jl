# AnnotatedTests.jl

[![CI](https://github.com/YOUR-ORG/AnnotatedTests.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/YOUR-ORG/AnnotatedTests.jl/actions/workflows/CI.yml)
[![Documentation](https://img.shields.io/badge/docs-Documenter.jl-blue.svg)](docs/build/index.html)
[![Codecov](https://codecov.io/gh/YOUR-ORG/AnnotatedTests.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/YOUR-ORG/AnnotatedTests.jl)
[![Aqua QA](https://img.shields.io/badge/qa-Aqua.jl-4c8eda.svg)](https://github.com/JuliaTesting/Aqua.jl)
[![JET](https://img.shields.io/badge/static%20analysis-JET.jl-9558b2.svg)](https://github.com/aviatesk/JET.jl)

`AnnotatedTests.jl` is a small extension of Julia's standard `Test` library for
tests that produce more helpful feedback, especially for teaching.

## Quick start

Install the package from this repository, then use `@annotated_test` anywhere you
would normally use `Test.@test`. For frequent classroom tests, `@atest` is a
short alias.

```julia
using Pkg
Pkg.add(url="https://github.com/YOUR-ORG/AnnotatedTests.jl")
```

```julia
using AnnotatedTests

@annotated_test "sorts a vector" mysort([3, 1, 2]) == [1, 2, 3] \
    "Return the values in increasing order."

@atest "keeps all values" sort(student_values()) == [1, 2, 3] unordered_feedback()
```

The feedback handler can be a string, a function, or a callable object. Strings
are the easiest way to add a hint. Functions receive an `AnnotationContext` when
you need richer feedback.

## What it is for

Annotated tests are ordinary Julia tests with clearer failure messages. They are
useful in assignments, workshops, and autograded exercises where the person
reading the result needs a hint about how to improve their answer.

```julia
@annotated_test "returns integers" student_values() isa Vector{Int} \
    type_feedback(Vector{Int})
```

Supported binary comparisons include `==`, `!=`, `<`, `<=`, `>`, `>=`, `===`,
`!==`, `in`, `∈`, `isa`, and `≈`. Each side of the comparison is evaluated once,
so expressions with side effects are handled safely.

For binary comparisons, `ctx.lhs` and `ctx.rhs` are available as the traditional
left- and right-hand sides. The aliases `ctx.observed`, `ctx.expected`,
`ctx.LHS`, and `ctx.RHS` are also provided for feedback text.

## Feedback helpers

The package includes small helper constructors for common teaching messages:

```julia
@atest "close answer" estimate() ≈ 10 expected_feedback("Check your rounding.")
@atest "right type" answer() isa Vector{Int} type_feedback()
@atest "right length" answer() == expected length_feedback()
@atest "same items" answer() == expected unordered_feedback()
```

`≈` records a `difference` term when it can be computed:

```julia
@atest "close enough" estimate() ≈ 10 ctx ->
    "The difference was $(ctx.difference)."
```

## Broken annotated tests

Use `@annotated_broken` for known issues or stretch checks. It mirrors
`Test.@test_broken`: a currently failing condition is recorded as broken, while
an unexpectedly passing condition is reported by the test framework.

```julia
@annotated_broken "stretch goal" advanced_answer() == expected \
    "This check documents the next feature to implement."
```

## Custom comparison operators

Additional binary operators can be registered with optional derived terms:

```julia
within10(x, y) = abs(x - y) <= 10

register_annotated_operator!(:within10; terms=(lhs, rhs) -> (
    difference = abs(lhs - rhs),
))

@atest "within tolerance" within10(student_answer(), 100) ctx ->
    "The difference was $(ctx.difference); it must be at most 10."
```

## Examples

See [`examples/sorting_assignment.jl`](examples/sorting_assignment.jl) for a
small teaching-oriented example.

## Running tests

```julia
julia --project=. -e 'using Pkg; Pkg.test()'
```

## Documentation

Build the documentation locally with:

```julia
julia --project=docs docs/make.jl
```

## Quality checks

The test suite includes Aqua.jl and JET.jl checks. GitHub Actions are configured
to run the package tests, build the documentation, and upload coverage reports to
Codecov.

## AI use disclosure

Some documentation, test, and continuous-integration improvements in this
repository were prepared with assistance from OpenAI's Codex. Changes should be
reviewed and maintained by the package authors, and generated text should be
edited whenever it does not match the intended teaching style or package
behavior.
