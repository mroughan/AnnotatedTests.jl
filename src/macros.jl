function _record_failure(name::String, ctx::AnnotationContext, message::String)
    fullmsg = "Annotated test failed: " * name * "\n" * message
    @test ctx.value
    println(stderr, fullmsg)
    return false
end

function _record_broken(name::String, ctx::AnnotationContext, message::String)
    @test_broken ctx.value
    if ctx.value
        println(stderr, "Annotated broken test now passes: " * name * "\n" * message)
    end
    return !ctx.value
end

function _record_pass()
    @test true
    return true
end

function _annotated_test_expr(name, ex, on_error; broken::Bool=false)
    parts = _binary_parts(ex)
    name_esc = esc(name)
    handler = esc(on_error)

    if parts === nothing
        if broken
            return quote
                local _name = String($name_esc)
                local _val = Bool($(esc(ex)))
                local _ctx = AnnotatedTests.AnnotationContext(_name, $(QuoteNode(ex)), nothing,
                                                              nothing, nothing, nothing, nothing, _val)
                local _msg = AnnotatedTests._feedback_message($handler, _ctx)
                AnnotatedTests._record_broken(_name, _ctx, _msg)
            end
        end

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
        call = Expr(:call, esc(op), :_lhs, :_rhs)
        if broken
            return quote
                local _name = String($name_esc)
                local _lhs = $(esc(lhs))
                local _rhs = $(esc(rhs))
                local _val = Bool($call)
                local _terms = AnnotatedTests._operator_terms($(QuoteNode(op)), _lhs, _rhs)
                local _ctx = AnnotatedTests.AnnotationContext(_name, $(QuoteNode(ex)), $(QuoteNode(op)),
                                                              $(QuoteNode(lhs)), $(QuoteNode(rhs)),
                                                              _lhs, _rhs, _val, _terms)
                local _msg = AnnotatedTests._feedback_message($handler, _ctx)
                AnnotatedTests._record_broken(_name, _ctx, _msg)
            end
        end

        return quote
            local _name = String($name_esc)
            local _lhs = $(esc(lhs))
            local _rhs = $(esc(rhs))
            local _val = Bool($call)
            if _val
                AnnotatedTests._record_pass()
            else
                local _terms = AnnotatedTests._operator_terms($(QuoteNode(op)), _lhs, _rhs)
                local _ctx = AnnotatedTests.AnnotationContext(_name, $(QuoteNode(ex)), $(QuoteNode(op)),
                                                              $(QuoteNode(lhs)), $(QuoteNode(rhs)),
                                                              _lhs, _rhs, _val, _terms)
                local _msg = AnnotatedTests._feedback_message($handler, _ctx)
                AnnotatedTests._record_failure(_name, _ctx, _msg)
            end
        end
    end
end

"""
    @annotated_test name expr [on_error]
    @atest name expr [on_error]

Run a test like `Test.@test`, but attach teacher-written feedback when it fails.
The feedback handler may be a string, function, or callable object. Functions
receive an `AnnotationContext`.

The macro evaluates each side of a supported binary comparison exactly once, so
expressions with side effects such as `pop!(xs) == 3` are safe to annotate.

# Examples

```julia
@annotated_test "sorted output" mysort([3, 1, 2]) == [1, 2, 3] \\
    "Return the values in increasing order."

@atest "close enough" estimate() ≈ 10 ctx ->
    "Difference was \$(ctx.difference)."
```
"""
macro annotated_test(name, ex, on_error=:(default_feedback))
    return _annotated_test_expr(name, ex, on_error)
end

"""
    @atest name expr [on_error]

Short alias for [`@annotated_test`](@ref).
"""
macro atest(name, ex, on_error=:(default_feedback))
    return _annotated_test_expr(name, ex, on_error)
end

"""
    @annotated_broken name expr [on_error]

Record an annotated test as broken. This mirrors `Test.@test_broken`: a false
condition is recorded as a broken test, while an unexpectedly true condition is
reported by the test framework.
"""
macro annotated_broken(name, ex, on_error=:(default_feedback))
    return _annotated_test_expr(name, ex, on_error; broken=true)
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
