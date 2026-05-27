using AnnotatedTests

# DELIBERATELY FAILING EXAMPLE
#
# This file is expected to fail. It demonstrates the feedback a student might
# see when their solution has common mistakes. Annotated failures are separated
# by a blank line to make the output easier to scan.

set_annotated_test_output!(show_standard_failure=true)

mysort(xs) = xs

explain_sort(ctx) = """
The expected sorted result was $(ctx.expected), but your function returned $(ctx.observed).
Check that you are returning elements in increasing order.
"""

@annotated_testset "Sorting assignment: deliberate failures" begin
    @annotated_test "sorts three integers" mysort([3, 1, 2]) == [1, 2, 3] explain_sort

    @atest "preserves sorted output length" mysort([3, 1]) == [1, 2, 3] length_feedback()

    @annotated_test "same values, wrong order" mysort([3, 1, 2]) == [1, 2, 3] unordered_feedback()
end
