module AnnotatedTests

using Test

export @annotated_test,
       @atest,
       @annotated_test_throws,
       @atest_throws,
       @annotated_testset,
       AnnotationContext,
       compare_feedback,
       default_feedback,
       length_feedback,
       register_annotated_operator!,
       type_feedback,
       unordered_feedback

include("context.jl")
include("operators.jl")
include("feedback.jl")
include("macros.jl")

end # module
