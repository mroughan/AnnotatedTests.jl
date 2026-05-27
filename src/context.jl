"""
    AnnotationContext

Structured information made available to feedback handlers when an annotated
test fails.

Fields include the test `name`, the original test expression `expr`, the
detected binary operator `op` when there is one, the unevaluated left and right
expressions, their evaluated values, the final Boolean `value`, and any
operator-specific `terms`.

For non-binary expressions, `op`, `lhs_expr`, `rhs_expr`, `lhs`, and `rhs` are
`nothing`.

Aliases are available for common teaching language:

- `ctx.observed` and `ctx.LHS` are aliases for `ctx.lhs`
- `ctx.expected` and `ctx.RHS` are aliases for `ctx.rhs`
- operator-specific terms such as `ctx.difference` are read from `ctx.terms`
"""
struct AnnotationContext
    name::String
    expr::Any
    op::Union{Symbol,Nothing}
    lhs_expr::Any
    rhs_expr::Any
    lhs::Any
    rhs::Any
    value::Bool
    terms::NamedTuple
end

AnnotationContext(name::String, expr, op, lhs_expr, rhs_expr, lhs, rhs, value::Bool) =
    AnnotationContext(name, expr, op, lhs_expr, rhs_expr, lhs, rhs, value, (;))

function Base.getproperty(ctx::AnnotationContext, name::Symbol)
    if name === :observed || name === :LHS
        return getfield(ctx, :lhs)
    elseif name === :expected || name === :RHS
        return getfield(ctx, :rhs)
    end

    terms = getfield(ctx, :terms)
    if haskey(terms, name)
        return getfield(terms, name)
    end

    return getfield(ctx, name)
end
