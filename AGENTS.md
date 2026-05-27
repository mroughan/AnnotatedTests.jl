# Agent Instructions

AnnotatedTests.jl is a small teaching-focused layer over Julia's standard
`Test` library. Future AI agents working in this repository should preserve that
core idea.

## Core Principles

- Keep annotated tests compatible with normal `Pkg.test()` and `Test.@testset`
  workflows.
- Keep `Test` as a runtime dependency; do not replace Julia's test framework.
- Prefer clear, teacher-written feedback over complex reporting machinery.
- Avoid double evaluation of test expressions, especially expressions with side
  effects.
- Preserve macro hygiene. Names and values in user tests must resolve in the
  caller's scope.
- Keep the public API small and stable. Do not add broad autograder, gradebook,
  LMS, or custom test-runner features without explicit maintainer direction.
- Treat custom operators as simple binary relations with optional derived terms;
  do not turn the package into a symbolic expression system.

## Development Expectations

- Add or update tests for behavior changes.
- Run `julia --project=. -e 'using Pkg; Pkg.test()'` after code changes when
  feasible.
- Run `julia --project=docs -e 'include("docs/make.jl")'` after documentation
  or docstring changes when feasible.
- Keep generated artifacts such as `Manifest.toml`, `docs/Manifest.toml`, and
  `docs/build/` out of commits unless the maintainer explicitly asks otherwise.
- Keep documentation examples focused on teaching, assignments, workshops, and
  small reusable feedback patterns.
