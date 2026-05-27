using AnnotatedTests

mysort(xs) = xs # deliberately wrong

explain_sort(ctx) = """
The expected sorted result was $(ctx.rhs), but your function returned $(ctx.lhs).
Check that you are returning elements in increasing order.
"""

@annotated_testset "Sorting assignment" begin
    @annotated_test "sorts three integers" mysort([3, 1, 2]) == [1, 2, 3] explain_sort

    @annotated_test "preserves length" length(mysort([3, 1, 2])) == 3 ctx ->
        "Sorting should reorder the input without dropping or adding values."
end
