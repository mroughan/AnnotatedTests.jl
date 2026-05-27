# AnnotatedTests.jl

`AnnotatedTests.jl` is a small extension of Julia's standard `Test` library for
tests that produce more helpful feedback, especially for teaching.

## Quick start

Install the package from this repository, then use `@annotated_test` anywhere you
would normally use `Test.@test`:

```julia
using Pkg
Pkg.add(url="https://github.com/YOUR-ORG/AnnotatedTests.jl")
```

```julia
using AnnotatedTests

@annotated_test "sorts a vector" mysort([3,1,2]) == [1,2,3] ctx -> begin
    "Your sorting function returned $(ctx.lhs), but the expected answer was $(ctx.rhs)."
end
```

The feedback handler can be a string, a function, or a callable object. When the
expression is a binary comparison, the handler receives the evaluated left and
right values as part of an `AnnotationContext`.

## What it is for

Annotated tests are ordinary Julia tests with clearer failure messages. They are
useful in assignments, workshops, and autograded exercises where the person
reading the result needs a hint about how to improve their answer.

```julia
@annotated_test "returns integers" student_values() isa Vector{Int} \
    "Return a Vector{Int}; check the element type of your result."
```

Supported binary comparisons include `==`, `!=`, `<`, `<=`, `>`, `>=`, `===`,
`!==`, `in`, `∈`, `isa`, and `≈`. Each side of the comparison is evaluated once,
so expressions with side effects are handled safely.

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
