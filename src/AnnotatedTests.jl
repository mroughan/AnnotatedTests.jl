module AnnotatedTests

using Test

export @annotated_test, @annotated_testset, AnnotationContext, default_feedback

"""
    AnnotationContext

Structured information made available to feedback handlers when an annotated
test fails.

Fields include the test `name`, the original test expression `expr`, the
detected binary operator `op` when there is one, the unevaluated left and right
expressions, their evaluated values, and the final Boolean `value`.

For non-binary expressions, `op`, `lhs_expr`, `rhs_expr`, `lhs`, and `rhs` are
`nothing`.
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
end

"""
    default_feedback(ctx::AnnotationContext)

Default human-readable feedback message for a failed annotated test.

This function is used when `@annotated_test` is called without an explicit
feedback handler. It reports the observed left and right values for supported
binary comparisons, and a generic message for other false conditions.
"""
function default_feedback(ctx::AnnotationContext)
    if ctx.op === nothing
        return "The condition evaluated to false."
    end
    return string("The comparison failed: ",
                  ctx.lhs_expr, " ", ctx.op, " ", ctx.rhs_expr,
                  "\nObserved left value: ", repr(ctx.lhs),
                  "\nObserved right value: ", repr(ctx.rhs))
end

_feedback_message(handler, ctx::AnnotationContext) = string(handler(ctx))
_feedback_message(handler::AbstractString, ctx::AnnotationContext) = String(handler)
_feedback_message(handler::Function, ctx::AnnotationContext) = string(handler(ctx))

function _record_failure(name::String, ctx::AnnotationContext, message::String)
    fullmsg = "Annotated test failed: " * name * "\n" * message
    @test ctx.value
    println(stderr, fullmsg)
    return false
end

function _record_pass()
    @test true
    return true
end

const _BINARY_OPS = Set{Symbol}(
    Symbol.(("==", "!=", "<", "<=", ">", ">=", "===", "!==", "∈", "in", "isa", "≈"))
)

function _binary_parts(ex)
    if ex isa Expr && ex.head == :call && length(ex.args) == 3
        op = ex.args[1]
        if op isa Symbol && op in _BINARY_OPS
            return (op, ex.args[2], ex.args[3])
        end
    end
    return nothing
end

"""
    @annotated_test name expr [on_error]

Run a test like `Test.@test`, but attach teacher-written feedback when it fails.
The feedback handler may be a string, function, or callable object. Functions
receive an `AnnotationContext`.

The macro evaluates each side of a supported binary comparison exactly once, so
expressions with side effects such as `pop!(xs) == 3` are safe to annotate.

# Examples

```julia
@annotated_test "sorted output" mysort([3, 1, 2]) == [1, 2, 3] ctx ->
    "Expected \$(ctx.rhs), got \$(ctx.lhs). Check the order of the result."

@annotated_test "returns vector" student_answer() isa Vector{Int} \\
    "Return a Vector{Int}, not another collection type."
```
"""
macro annotated_test(name, ex, on_error=:(default_feedback))
    parts = _binary_parts(ex)
    name_esc = esc(name)
    handler = esc(on_error)
    if parts === nothing
        return quote
            local _name = String($name_esc)
            local _val = Bool($(esc(ex)))
            if _val
                AnnotatedTests._record_pass()
            else
                local _ctx = AnnotatedTests.AnnotationContext(_name, $(QuoteNode(ex)), nothing,
                                                              nothing, nothing, nothing, nothing, _val)
                local _msg = AnnotatedTests._feedback_message($handler, _ctx)
                AnnotatedTests._record_failure(_name, _ctx, _msg)
            end
        end
    else
        op, lhs, rhs = parts
        return quote
            local _name = String($name_esc)
            local _lhs = $(esc(lhs))
            local _rhs = $(esc(rhs))
            local _val = Bool($(Expr(:call, op, :_lhs, :_rhs)))
            if _val
                AnnotatedTests._record_pass()
            else
                local _ctx = AnnotatedTests.AnnotationContext(_name, $(QuoteNode(ex)), $(QuoteNode(op)),
                                                              $(QuoteNode(lhs)), $(QuoteNode(rhs)),
                                                              _lhs, _rhs, _val)
                local _msg = AnnotatedTests._feedback_message($handler, _ctx)
                AnnotatedTests._record_failure(_name, _ctx, _msg)
            end
        end
    end
end

"""
    @annotated_testset name begin ... end

A light wrapper over `Test.@testset` for pedagogical test groups.

# Example

```julia
@annotated_testset "Assignment 1" begin
    @annotated_test "question 1" q1() == 42 "Review the formula for q1."
end
```
"""
macro annotated_testset(name, block)
    name_sym = gensym(:name)
    return quote
        local $name_sym = $(esc(name))
        @testset $(Expr(:string, name_sym)) begin
            $(esc(block))
        end
    end
end

end # module
