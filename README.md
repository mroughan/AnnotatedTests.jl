# AnnotatedTests.jl

[![Docs](https://img.shields.io/badge/docs-dev-blue.svg)](https://mroughan.github.io/AnnotatedTests.jl/dev)
[![CI](https://github.com/mroughan/AnnotatedTests.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/mroughan/AnnotatedTests.jl/actions/workflows/CI.yml)
[![Codecov](https://codecov.io/gh/mroughan/AnnotatedTests.jl/branch/main/graph/badge.svg?token=MK532CLS72)](https://codecov.io/gh/mroughan/AnnotatedTests.jl)
[![Aqua QA](https://img.shields.io/badge/qa-Aqua.jl-4c8eda.svg)](https://github.com/JuliaTesting/Aqua.jl)
[![JET](https://img.shields.io/badge/static%20analysis-JET.jl-9558b2.svg)](https://github.com/aviatesk/JET.jl)

**AnnotatedTests** is a small extension of Julia's standard `Test`
  library to build tests with more helpful feedback, especially for
  teaching.

> AnnotatedTests.jl is experimental. The package is usable, but the public API
> may change before a stable 1.0 release.

## Quick start

Install the package with Julia's package manager, then use `@annotated_test`
anywhere you would normally use `Test.@test`. For frequent classroom tests,
`@atest` is a short alias.

```julia
using Pkg
Pkg.add("AnnotatedTests")
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

## Simpler student-facing output

By default, a failing annotated test prints a red, bold annotated-failure heading
followed by the custom feedback, then records an ordinary Julia `@test false`,
including Julia's standard failure details. Feedback blocks are separated by a
blank line to make multiple failures easier to scan.

For student-facing runs, you can suppress Julia's immediate standard failure
block while still counting the result as a failed test:

```julia
set_annotated_test_output!(show_standard_failure=false)
```

`Pkg.test()` will still fail when annotated tests fail; this option only reduces
the extra diagnostic text printed for each annotated failure.

The option is global for the current Julia session. If you only want it for one
test file or one block, save and restore the previous value:

```julia
old = set_annotated_test_output!(show_standard_failure=false)
try
    @atest "sorts values" student_sort([3, 1, 2]) == [1, 2, 3] \
        "Return the values in increasing order."
finally
    set_annotated_test_output!(show_standard_failure=old)
end
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

See [`examples/README.md`](examples/README.md) for three small teaching-oriented
examples: one that passes, one with deliberate failures for inspecting standard
annotated feedback, and one with deliberate failures using simpler
student-facing output. The quiet deliberate-failure example is useful for
checking the red annotated headings and blank-line spacing.

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

The ordinary test suite includes Aqua.jl and is intended to run on Julia 1.10
and later. JET.jl static analysis is run as a separate GitHub Actions job on
Julia 1.12, so JET's compiler-version requirements do not set the minimum Julia
version for package users. GitHub Actions are also configured to build the
documentation and upload coverage reports to Codecov.

## AI use disclosure

This package was developed with assistance from OpenAI Codex, an AI coding
assistant based on GPT-5. Code design decisions were human mediated, and the
resulting code was manually reviewed.

## Notes

The package compatibility is set to Julia 1.10 and later. Development tooling
may use newer Julia versions where individual tools require them.
