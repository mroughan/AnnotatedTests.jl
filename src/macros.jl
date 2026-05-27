function _record_failure(name::String, ctx::AnnotationContext, message::String)
    fullmsg = "Annotated test failed: " * name * "\n" * message
    println(stderr, fullmsg)
    @test false
    return false
end

function _record_broken()
    @test false broken=true
    return false
end

function _record_skip()
    @test true skip=true
    return false
end

function _record_pass()
    @test true
    return true
end

function _exception_message(err)
    err === nothing && return "nothing was thrown"
    return sprint(showerror, err)
end

function _exception_matches(expected, err)
    expected isa Type && return err isa expected
    expected isa Tuple && return any(item -> _exception_matches(item, err), expected)
    expected isa Regex && return occursin(expected, _exception_message(err))
    expected isa AbstractString && return occursin(expected, _exception_message(err))
    expected isa Exception && return typeof(err) === typeof(expected) &&
                                     _exception_message(err) == _exception_message(expected)
    return expected == err
end

function _throws_terms(expected, thrown)
    return (
        expected_exception = expected,
        thrown = thrown,
        thrown_type = thrown === nothing ? nothing : typeof(thrown),
        message = _exception_message(thrown),
    )
end

function _parse_annotated_args(args)
    on_error = :(default_feedback)
    broken = false
    skip = false
    test_kwargs = []
    seen_handler = false

    for arg in args
        if arg isa Expr && arg.head == :(=) && length(arg.args) == 2
            key, value = arg.args
            if key === :broken
                broken = value
            elseif key === :skip
                skip = value
            elseif key isa Symbol
                push!(test_kwargs, arg)
            else
                throw(ArgumentError("unsupported @annotated_test keyword: $key"))
            end
        elseif seen_handler
            throw(ArgumentError("expected at most one feedback handler"))
        else
            on_error = arg
            seen_handler = true
        end
    end

    return on_error, broken, skip, test_kwargs
end

function _skip_or_broken_expr(broken, skip)
    return quote
        if Bool($(esc(skip)))
            AnnotatedTests._record_skip()
        elseif Bool($(esc(broken)))
            AnnotatedTests._record_broken()
        else
            nothing
        end
    end
end

function _keyword_parameters(test_kwargs)
    isempty(test_kwargs) && return nothing

    kwargs = map(test_kwargs) do kwarg
        Expr(:kw, kwarg.args[1], esc(kwarg.args[2]))
    end
    return Expr(:parameters, kwargs...)
end

function _call_with_kwargs(ex::Expr, test_kwargs)
    ex.head == :call || throw(ArgumentError("test keyword arguments require a function call or binary comparison"))

    parameters = _keyword_parameters(test_kwargs)
    parameters === nothing && return esc(ex)

    return Expr(:call, esc(ex.args[1]), parameters, map(esc, ex.args[2:end])...)
end

function _binary_call(op, test_kwargs)
    parameters = _keyword_parameters(test_kwargs)
    if parameters === nothing
        return Expr(:call, esc(op), :_lhs, :_rhs)
    end
    return Expr(:call, esc(op), parameters, :_lhs, :_rhs)
end

function _annotated_test_expr(name, ex, on_error, broken, skip, test_kwargs)
    parts = _binary_parts(ex)
    name_esc = esc(name)
    handler = esc(on_error)
    precheck = _skip_or_broken_expr(broken, skip)

    if parts === nothing
        return quote
            local _skipped_or_broken = $precheck
            if _skipped_or_broken !== nothing
                _skipped_or_broken
            else
                local _name = String($name_esc)
                local _val = Bool($(_call_with_kwargs(ex, test_kwargs)))
                if _val
                    AnnotatedTests._record_pass()
                else
                    local _ctx = AnnotatedTests.AnnotationContext(_name, $(QuoteNode(ex)), nothing,
                                                                  nothing, nothing, nothing, nothing, _val)
                    local _msg = AnnotatedTests._feedback_message($handler, _ctx)
                    AnnotatedTests._record_failure(_name, _ctx, _msg)
                end
            end
        end
    else
        op, lhs, rhs = parts
        call = _binary_call(op, test_kwargs)
        return quote
            local _skipped_or_broken = $precheck
            if _skipped_or_broken !== nothing
                _skipped_or_broken
            else
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
end

"""
    @annotated_test name expr [on_error] [test_keyword=value...] [broken=condition] [skip=condition]
    @atest name expr [on_error] [test_keyword=value...] [broken=condition] [skip=condition]

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

@atest "within tolerance" estimate() ≈ 10 atol=0.01

@annotated_test "documented issue" current_answer() == expected broken=true
```
"""
macro annotated_test(name, ex, args...)
    on_error, broken, skip, test_kwargs = _parse_annotated_args(args)
    return _annotated_test_expr(name, ex, on_error, broken, skip, test_kwargs)
end

"""
    @atest name expr [on_error] [test_keyword=value...] [broken=condition] [skip=condition]

Short alias for [`@annotated_test`](@ref).
"""
macro atest(name, ex, args...)
    on_error, broken, skip, test_kwargs = _parse_annotated_args(args)
    return _annotated_test_expr(name, ex, on_error, broken, skip, test_kwargs)
end

"""
    @annotated_test_throws name expected_exception expr [on_error] [broken=condition] [skip=condition]
    @atest_throws name expected_exception expr [on_error] [broken=condition] [skip=condition]

Run a test like `Test.@test_throws`, but attach teacher-written feedback when it
fails. The expected exception may be an exception type, tuple of exception
types, exception value, string, or regular expression.

Feedback handlers receive an `AnnotationContext`. For throwing tests,
`ctx.expected` is the expected exception specification, `ctx.observed` is the
thrown exception or `nothing`, and terms include `ctx.thrown`,
`ctx.thrown_type`, `ctx.expected_exception`, and `ctx.message`.

# Example

```julia
@annotated_test_throws "rejects empty input" ArgumentError parse_answer("") \\
    "Empty input should throw an ArgumentError."
```
"""
macro annotated_test_throws(name, expected, ex, args...)
    on_error, broken, skip, test_kwargs = _parse_annotated_args(args)
    isempty(test_kwargs) || throw(ArgumentError("@annotated_test_throws only supports broken= and skip= keywords"))
    name_esc = esc(name)
    expected_esc = esc(expected)
    handler = esc(on_error)
    precheck = _skip_or_broken_expr(broken, skip)

    return quote
        local _skipped_or_broken = $precheck
        if _skipped_or_broken !== nothing
            _skipped_or_broken
        else
            local _name = String($name_esc)
            local _expected = $expected_esc
            local _thrown = nothing

            try
                $(esc(ex))
            catch _err
                _err isa InterruptException && rethrow()
                _thrown = _err
            end

            local _val = AnnotatedTests._exception_matches(_expected, _thrown)
            local _terms = AnnotatedTests._throws_terms(_expected, _thrown)
            local _ctx = AnnotatedTests.AnnotationContext(_name, $(QuoteNode(ex)), :throws,
                                                          nothing, $(QuoteNode(expected)),
                                                          _thrown, _expected, _val, _terms)

            if _val
                AnnotatedTests._record_pass()
            else
                local _msg = AnnotatedTests._feedback_message($handler, _ctx)
                AnnotatedTests._record_failure(_name, _ctx, _msg)
            end
        end
    end
end

"""
    @atest_throws name expected_exception expr [on_error] [broken=condition] [skip=condition]

Short alias for [`@annotated_test_throws`](@ref).
"""
macro atest_throws(name, expected, ex, args...)
    on_error, broken, skip, test_kwargs = _parse_annotated_args(args)
    isempty(test_kwargs) || throw(ArgumentError("@atest_throws only supports broken= and skip= keywords"))
    name_esc = esc(name)
    expected_esc = esc(expected)
    handler = esc(on_error)
    precheck = _skip_or_broken_expr(broken, skip)

    return quote
        local _skipped_or_broken = $precheck
        if _skipped_or_broken !== nothing
            _skipped_or_broken
        else
            local _name = String($name_esc)
            local _expected = $expected_esc
            local _thrown = nothing

            try
                $(esc(ex))
            catch _err
                _err isa InterruptException && rethrow()
                _thrown = _err
            end

            local _val = AnnotatedTests._exception_matches(_expected, _thrown)
            local _terms = AnnotatedTests._throws_terms(_expected, _thrown)
            local _ctx = AnnotatedTests.AnnotationContext(_name, $(QuoteNode(ex)), :throws,
                                                          nothing, $(QuoteNode(expected)),
                                                          _thrown, _expected, _val, _terms)

            if _val
                AnnotatedTests._record_pass()
            else
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
