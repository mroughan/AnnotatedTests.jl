using AnnotatedTests

# PASSING EXAMPLE
#
# This file is intended to pass. Use it to check that AnnotatedTests is
# installed and that the example test file runs successfully.

mysort(xs) = sort(xs)

explain_sort(ctx) = """
The expected sorted result was $(ctx.expected), but your function returned $(ctx.observed).
Check that you are returning elements in increasing order.
"""

@annotated_testset "Sorting assignment: passing example" begin
    @annotated_test "sorts three integers" mysort([3, 1, 2]) == [1, 2, 3] explain_sort

    @atest "preserves length" mysort([3, 1, 2]) == [1, 2, 3] length_feedback()

    @annotated_test "handles duplicate values" mysort([2, 1, 2]) == [1, 2, 2] unordered_feedback()
end
