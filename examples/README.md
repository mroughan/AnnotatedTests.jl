# Examples

This directory contains two versions of the same small sorting-assignment
example.

## Passing Example

Run this when you want to confirm the package and examples are working:

```bash
julia --project=. examples/sorting_assignment_passing.jl
```

This example should finish with all tests passing.

## Deliberately Failing Example

Run this when you want to inspect the annotated failure output:

```bash
julia --project=. examples/sorting_assignment_deliberate_failures.jl
```

This example is expected to fail. The failures are intentional and demonstrate
the feedback messages that a student might see.
