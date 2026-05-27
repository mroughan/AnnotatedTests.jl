# Contributing

Thank you for considering a contribution to AnnotatedTests.jl. The package is
experimental, but its intended shape is deliberately small: a teaching-focused
layer over Julia's standard `Test` library that gives clearer feedback when
tests fail.

## Project Scope

Contributions should preserve the package's core idea:

- Annotated tests should remain ordinary Julia tests that work with `Pkg.test()`
  and `Test.@testset`.
- `Test` should remain the runtime test framework.
- Feedback should stay teacher-written, simple, and human-readable.
- Test expressions should not be evaluated more than once.
- Macro hygiene matters. User expressions should resolve in the caller's scope.
- Custom operators should remain simple binary relations with optional derived
  terms, not a symbolic expression system.

Please avoid adding broad autograder, gradebook, LMS, custom runner, or report
format features without maintainer agreement first.

## Development Setup

Clone the repository and run the ordinary test suite with:

```julia
julia --project=. -e 'using Pkg; Pkg.test()'
```

The package compatibility is Julia 1.10 and later. JET static analysis is kept
separate from the ordinary test target because current JET releases may require
newer Julia compiler internals.

To run the JET check locally on Julia 1.12 or later:

```julia
julia --color=yes -e 'using Pkg; Pkg.activate(; temp=true); Pkg.develop(PackageSpec(path=pwd())); Pkg.add(PackageSpec(name="JET", version="0.11")); include("test/jet.jl")'
```

## Documentation

Build the documentation locally with:

```julia
julia --project=docs docs/make.jl
```

When changing public behavior, update the relevant docstrings, README examples,
and Documenter pages. Keep examples focused on assignments, workshops, and small
reusable feedback patterns.

If a change affects user-facing output, update the examples as well. The
deliberately failing examples are intended to show the current failure format,
including colored annotated headings, blank-line spacing, and the quiet
student-facing mode.

## Tests

Please add or update tests for behavior changes. Useful tests include:

- Macro behavior in caller scope.
- Single evaluation of expressions with side effects.
- Passing, failing, broken, and skipped annotated tests.
- Feedback helpers and custom operator terms.
- Compatibility with Test-style keyword arguments such as `atol`.

Coverage is useful, but behavior matters most. Prefer small tests that document
the intended user-facing behavior.

## Generated Files

Do not commit generated artifacts unless the maintainer explicitly asks for
them. In particular, keep these out of normal commits:

- `Manifest.toml`
- `docs/Manifest.toml`
- `docs/build/`
- `*.cov`
- `lcov.info`

## Pull Requests

Before opening a pull request, please check:

- The ordinary test suite passes.
- Documentation builds if docs or docstrings changed.
- New public behavior is documented.
- The change fits the narrow package scope described above.

If you used AI assistance, please say so briefly in the pull request notes.
