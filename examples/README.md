# Examples

This directory contains three versions of the same small sorting-assignment
example.

## Passing Example

Run this when you want to confirm the package and examples are working:

```bash
julia --project=. examples/sorting_assignment_passing.jl
```

This example should finish with all tests passing.

## Deliberately Failing Example

Run this when you want to inspect the annotated failure output alongside Julia's
standard test failure details:

```bash
julia --project=. examples/sorting_assignment_deliberate_failures.jl
```

This example is expected to fail. The failures are intentional and demonstrate
the feedback messages that a student might see. Each annotated failure starts
with a red heading and is separated from the next block by a blank line.

## Quiet Deliberately Failing Example

Run this when you want simpler student-facing failure output:

```bash
julia --project=. examples/sorting_assignment_quiet_failures.jl
```

This example is expected to fail. It calls
`set_annotated_test_output!(show_standard_failure=false)`, so each annotated
failure prints the custom feedback without Julia's immediate standard failure
block and stack trace. The final test summary still reports the failures. This
is the best example to inspect the simplified student-facing output.
