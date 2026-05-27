This package is a small extension of the `Test` stdlib package with very similar functionality. 

It creates a macro called `@annotated_test` that takes the form `@annotated_test name test on_error` where name allows us to name each test, the test is a boolean expression to be evaluated, and the on_error returns a configurable response in order to provide a test framework that provides more meaningful, human readable, understandable output. A use case might be to provide test output to students who are trying to develop their own code as part of an assignment. The current test output says what is wrong, but doesn't explain why. It would be good for a teacher to be able to have automated tests that give the students clearer feedback. 

Conceptually, we do things like

     @annotated_test "same values" f(x) == y explain(using LHS and RHS of ==)

A possible output might look like

```
Annotated Test Failed: "sorted output"
Expression: sort(student_answer) == expected
Observed:   [1, 3, 2]
Expected:   [1, 2, 3]

Feedback:
Your output contains the right values, but they are not sorted. Check the order in which you append elements.
```

Some features:

+ Support strings, functions, and callable structs for on_error.
+ Work with binary relational operators: ==, !=, <, <=, >, >=, ≈, where there is a well-defined LHS and RHS.
+ Allow additional relational operators to be registered, with optional derived terms such as `difference`.
+ Avoid double evaluation. A test like pop!(xs) == 3 must not evaluate pop!(xs) twice.
+ Distinguish test failure from test error. If evaluating the expression throws, that should remain an ordinary Test.Error, possibly with extra annotation.
+ Keep output CI-friendly. Student feedback should not break compatibility with Pkg.test.

The package should remain small, clean, and easy to use. It is intentionally a
thin layer over `Test`, and `Test` should remain a runtime dependency so
annotated checks behave like ordinary Julia tests. Avoid adding a separate test
runner, grading engine, report format, or assignment-management workflow until
there is a clear need.

## Example use

```
using Test
using AnnotatedTests

@testset "Assignment 1" begin
    @annotated_test "question 1: sorted result" student_q1(x) == [1,2,3] explain_sorting
    @annotated_test "question 2: type" student_q2() isa Vector{Int} "Your function should return a Vector{Int}."
    @annotated_broken "extension task" student_q3() == expected "Optional extension."
end
```

## Challenges

1. Maintain macro hygiene
2. Careful parse of test expressions to allow use in the explanation without double evaluation
3. Keep operator extension simple: users can register relations and terms, but AnnotatedTests should not become a symbolic expression system
