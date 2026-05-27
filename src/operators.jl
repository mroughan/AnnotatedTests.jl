struct AnnotatedOperator{F}
    terms::F
end

_no_terms(lhs, rhs) = (;)

const _ANNOTATED_OPERATORS = Dict{Symbol,AnnotatedOperator}()

"""
    register_annotated_operator!(op::Symbol; terms=(lhs, rhs) -> (;))

Register an operator or binary relation that `@annotated_test` should treat as a
comparison. The optional `terms` function receives the evaluated left and right
values and must return a `NamedTuple`.

Those terms become available in feedback handlers as `ctx.terms` and as direct
properties. For example, a term named `difference` can be read as
`ctx.difference`.

# Example

```julia
relapprox(x, y; rtol=0.05) = abs(x - y) / max(abs(y), eps()) <= rtol

register_annotated_operator!(:relapprox; terms=(lhs, rhs) -> (
    relative_difference = abs(lhs - rhs) / max(abs(rhs), eps()),
))
```
"""
function register_annotated_operator!(op::Symbol; terms=_no_terms)
    _ANNOTATED_OPERATORS[op] = AnnotatedOperator(terms)
    return op
end

function _register_default_operators!()
    for op in Symbol.(("==", "!=", "<", "<=", ">", ">=", "===", "!==", "∈", "in", "isa"))
        register_annotated_operator!(op)
    end
    register_annotated_operator!(Symbol("≈"); terms=_approx_terms)
    return nothing
end

function _difference(lhs, rhs)
    try
        return abs(lhs - rhs)
    catch
    end

    try
        return maximum(abs.(lhs .- rhs))
    catch
    end

    return nothing
end

function _approx_terms(lhs, rhs)
    diff = _difference(lhs, rhs)
    return diff === nothing ? (;) : (difference=diff,)
end

function _operator_terms(op::Symbol, lhs, rhs)
    spec = get(_ANNOTATED_OPERATORS, op, nothing)
    spec === nothing && return (;)

    terms = spec.terms(lhs, rhs)
    terms isa NamedTuple || throw(ArgumentError("operator terms must return a NamedTuple"))
    return terms
end

function _binary_parts(ex)
    if ex isa Expr && ex.head == :call && length(ex.args) >= 3
        op = ex.args[1]
        offset = length(ex.args) >= 4 && ex.args[2] isa Expr && ex.args[2].head == :parameters ? 1 : 0
        if op isa Symbol && haskey(_ANNOTATED_OPERATORS, op) && length(ex.args) == 3 + offset
            return (op, ex.args[2 + offset], ex.args[3 + offset])
        end
    end
    return nothing
end

_register_default_operators!()
