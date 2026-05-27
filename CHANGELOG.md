# Changelog

All notable changes to AnnotatedTests.jl will be documented in this file.

The format follows the spirit of Keep a Changelog, and this project uses
semantic versioning once public releases are tagged.

## Unreleased

- Added annotated test macros, including `@annotated_test`, `@atest`,
  `@annotated_test_throws`, `@atest_throws`, and `@annotated_testset`.
- Added `broken=` and `skip=` keyword support for annotated tests.
- Added forwarding for Test-style trailing keyword arguments such as
  `atol=...` and `rtol=...` in approximate comparisons.
- Added `AnnotationContext` with left/right and observed/expected aliases.
- Added default and reusable feedback helpers for comparisons, types, lengths,
  unordered collections, and expected-vs-observed messages.
- Added support for registering custom binary relations with derived context
  terms such as `difference`.
- Added configurable student-facing failure output with
  `set_annotated_test_output!(show_standard_failure=false)`.
- Styled annotated failure headings in red and separated annotated feedback
  blocks with a blank line.
- Added passing, deliberately failing, and quiet deliberately failing examples.
- Added contributing and AI-agent guidance for future development.
- Added Documenter.jl documentation, Aqua.jl and JET.jl test checks, Codecov
  upload, and GitHub Actions workflows.

## 0.1.0

- Initial public development version.
