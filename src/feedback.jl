_show_expr(ex) = sprint(show, ex)

function _term_lines(ctx::AnnotationContext)
    isempty(ctx.terms) && return ""

    parts = String[]
    for name in keys(ctx.terms)
        push!(parts, string("\n", titlecase(String(name)), ": ", repr(getfield(ctx.terms, name))))
    end
    return join(parts)
end

"""
    default_feedback(ctx::AnnotationContext)

Default human-readable feedback message for a failed annotated test.

This function is used when `@annotated_test` is called without an explicit
feedback handler. It reports the test name, expression, observed and expected
values for supported binary comparisons, and operator-specific terms such as
`difference` when available.

# Example

```julia
@annotated_test "sorted output" student_sort([3, 1, 2]) == [1, 2, 3]
```

Example output:

```text
Test: sorted output
Expression: :(student_sort([3, 1, 2]) == [1, 2, 3])
Observed: [3, 1, 2]
Expected: [1, 2, 3]
Operator: ==
```
"""
function default_feedback(ctx::AnnotationContext)
    header = string("Test: ", ctx.name, "\nExpression: ", _show_expr(ctx.expr))
    if ctx.op === :throws
        return string(header,
                      "\nExpected exception: ", repr(ctx.expected_exception),
                      "\nThrown exception: ", repr(ctx.thrown),
                      "\nThrown type: ", ctx.thrown_type,
                      "\nMessage: ", ctx.message)
    end

    if ctx.op === nothing
        return header * "\nThe condition evaluated to false."
    end

    return string(header,
                  "\nObserved: ", repr(ctx.observed),
                  "\nExpected: ", repr(ctx.expected),
                  "\nOperator: ", ctx.op,
                  _term_lines(ctx))
end

"""
    compare_feedback(; message=nothing, observed_label="Observed", expected_label="Expected")

Create a feedback handler for ordinary comparisons. The returned handler prints
the original expression, observed value, expected value, and any operator terms.

# Examples

```julia
@annotated_test "computed value" student_answer() == expected compare_feedback()

@annotated_test "computed value" student_answer() == expected \\
    compare_feedback(message="Check the formula used to compute this value.")

@annotated_test "computed value" student_answer() == expected \\
    compare_feedback(observed_label="Returned", expected_label="Target")
```

Example output:

```text
Expression: :(student_answer() == expected)
Returned: 17
Target: 42
Check the formula used to compute this value.
```
"""
function compare_feedback(; message=nothing,
                            observed_label::AbstractString="Observed",
                            expected_label::AbstractString="Expected")
    return ctx -> begin
        base = string("Expression: ", _show_expr(ctx.expr),
                      "\n", observed_label, ": ", repr(ctx.observed),
                      "\n", expected_label, ": ", repr(ctx.expected),
                      _term_lines(ctx))
        message === nothing ? base : string(base, "\n", message)
    end
end

"""
    type_feedback([expected])

Create feedback for type checks. If `expected` is omitted and the annotated
expression uses `isa`, the right-hand side of the comparison is shown.

# Examples

```julia
@annotated_test "returns integers" student_values() isa Vector{Int} type_feedback()

@annotated_test "returns vector" student_values() isa AbstractVector \\
    type_feedback(Vector{Int})
```

Example output:

```text
Expected type: Vector{Int64}
Observed type: Vector{Float64}
Observed value: [1.0, 2.0, 3.0]
```
"""
function type_feedback(expected=nothing)
    return ctx -> begin
        expected_type = expected === nothing ? ctx.expected : expected
        string("Expected type: ", expected_type,
               "\nObserved type: ", typeof(ctx.observed),
               "\nObserved value: ", repr(ctx.observed))
    end
end

"""
    length_feedback([expected])

Create feedback that includes observed and expected lengths when they are
available.

# Examples

```julia
@annotated_test "preserves length" student_values() == expected_values length_feedback()

@annotated_test "returns three values" student_values() == expected_values \\
    length_feedback(3)
```

Example output:

```text
Observed length: 2
Expected length: 3
Observed value: [1, 2]
Expected value: [1, 2, 3]
```
"""
function length_feedback(expected=nothing)
    return ctx -> begin
        observed_len = _maybe_length(ctx.observed)
        expected_len = expected === nothing ? _maybe_length(ctx.expected) : expected
        string("Observed length: ", observed_len,
               "\nExpected length: ", expected_len,
               "\nObserved value: ", repr(ctx.observed),
               "\nExpected value: ", repr(ctx.expected))
    end
end

"""
    unordered_feedback()

Create feedback for collection comparisons where order might be the issue.

# Example

```julia
@annotated_test "same values" student_values() == [1, 2, 3] unordered_feedback()
```

Example output:

```text
The values match, but the order is different.
Observed: [1, 3, 2]
Expected: [1, 2, 3]
```
"""
function unordered_feedback()
    return ctx -> begin
        same_items = _same_items_unordered(ctx.observed, ctx.expected)
        prefix = same_items === true ?
            "The values match, but the order is different." :
            "The values do not match as an unordered collection."

        string(prefix,
               "\nObserved: ", repr(ctx.observed),
               "\nExpected: ", repr(ctx.expected))
    end
end

function _maybe_length(x)
    try
        return length(x)
    catch
        return "unknown"
    end
end

function _counts(xs)
    counts = Dict{Any,Int}()
    for x in xs
        counts[x] = get(counts, x, 0) + 1
    end
    return counts
end

function _same_items_unordered(lhs, rhs)
    try
        return _counts(lhs) == _counts(rhs)
    catch
        return nothing
    end
end

_feedback_message(handler, ctx::AnnotationContext) = string(handler(ctx))
_feedback_message(handler::AbstractString, ctx::AnnotationContext) = String(handler)
_feedback_message(handler::Function, ctx::AnnotationContext) = string(handler(ctx))
