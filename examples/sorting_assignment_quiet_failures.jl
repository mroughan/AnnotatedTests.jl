using AnnotatedTests

# QUIET DELIBERATELY FAILING EXAMPLE
#
# This file is expected to fail. It demonstrates student-facing output that
# suppresses Julia's immediate standard failure block for each annotated failure.
# Annotated failures are separated by a blank line. The final test summary still
# reports failures, and the process still exits unsuccessfully.

set_annotated_test_output!(show_standard_failure=false)

mysort(xs) = xs

explain_sort(ctx) = """
The expected sorted result was $(ctx.expected), but your function returned $(ctx.observed).
Check that you are returning elements in increasing order.
"""

@annotated_testset "Sorting assignment: quiet deliberate failures" begin
    @annotated_test "sorts three integers" mysort([3, 1, 2]) == [1, 2, 3] explain_sort

    @atest "preserves sorted output length" mysort([3, 1]) == [1, 2, 3] length_feedback()

    @annotated_test "same values, wrong order" mysort([3, 1, 2]) == [1, 2, 3] unordered_feedback()
end
