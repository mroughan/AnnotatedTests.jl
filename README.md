# AnnotatedTests.jl

[![CI](https://github.com/mroughan/AnnotatedTests.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/mroughan/AnnotatedTests.jl/actions/workflows/CI.yml)
[![Documentation](https://github.com/mroughan/AnnotatedTests.jl/actions/workflows/Documentation.yml/badge.svg)](https://github.com/mroughan/AnnotatedTests.jl/actions/workflows/Documentation.yml)
[![Codecov](https://codecov.io/gh/mroughan/AnnotatedTests.jl/branch/main/graph/badge.svg?token=MK532CLS72)](https://codecov.io/gh/mroughan/AnnotatedTests.jl)
[![Aqua QA](https://img.shields.io/badge/qa-Aqua.jl-4c8eda.svg)](https://github.com/JuliaTesting/Aqua.jl)
[![JET](https://img.shields.io/badge/static%20analysis-JET.jl-9558b2.svg)](https://github.com/aviatesk/JET.jl)

`AnnotatedTests.jl` is a small extension of Julia's standard `Test` library for
tests that produce more helpful feedback, especially for teaching.

> AnnotatedTests.jl is experimental. The package is usable, but the public API
> may change before a stable 1.0 release.

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

## Scope

AnnotatedTests.jl is intentionally a narrow layer over Julia's standard `Test`
library. It aims to make test failures more understandable by attaching names,
feedback, and simple comparison context.

It is not intended to be an autograder, learning-management-system integration,
gradebook, separate test runner, or reporting framework. Features should stay
small enough that annotated tests remain ordinary Julia tests.

## Feedback helpers

The package includes small helper constructors for common teaching messages:

```julia
@atest "close answer" estimate() ≈ 10 compare_feedback(message="Check your rounding.")
@atest "close answer with tolerance" estimate() ≈ 10 atol=0.01
@atest "right type" answer() isa Vector{Int} type_feedback()
@atest "right length" answer() == expected length_feedback()
@atest "same items" answer() == expected unordered_feedback()
```

As with `Test.@test`, trailing keyword arguments other than `broken` and `skip`
are passed to the tested function or comparison. This makes approximate tests
easy to migrate:

```julia
@annotated_test "pi approximation" π ≈ 3.14 atol=0.01
@annotated_test "pi approximation" isapprox(π, 3.14) atol=0.01
```

`≈` records a `difference` term when it can be computed:

```julia
@atest "close enough" estimate() ≈ 10 ctx ->
    "The difference was $(ctx.difference)."
```

## Broken and skipped annotated tests

Use `broken=` and `skip=` for known issues, stretch checks, or tests that should
not run in the current environment. These keywords mirror `Test.@test`: when the
condition is true, the test expression is not evaluated and the result is
recorded as broken/skipped by Julia's test framework.

```julia
@annotated_test "stretch goal" advanced_answer() == expected \
    "This check documents the next feature to implement." broken=true

@atest "requires optional data" answer_from_file() == expected skip=!isfile(path)
```

## Annotated exception tests

Use `@annotated_test_throws` when the expected behavior is an exception:

```julia
@annotated_test_throws "rejects empty input" ArgumentError parse_answer("") \
    "Empty input should throw an ArgumentError."

@atest_throws "rejects missing file" SystemError read("missing.txt")
```

The expected exception can be a type, tuple of types, exception value, string, or
regular expression. Feedback handlers receive the thrown exception as
`ctx.observed` or `ctx.thrown`, and the expected exception specification as
`ctx.expected` or `ctx.expected_exception`.

## Custom comparison operators

Additional binary operators can be registered with optional derived terms:

```julia
relapprox(x, y; rtol=0.05) = abs(x - y) / max(abs(y), eps()) <= rtol

register_annotated_operator!(:relapprox; terms=(lhs, rhs) -> (
    relative_difference = abs(lhs - rhs) / max(abs(rhs), eps()),
))

@atest "relative error" relapprox(student_answer(), 100; rtol=0.02) ctx ->
    "The relative difference was $(ctx.relative_difference); it must be below 2%."
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
