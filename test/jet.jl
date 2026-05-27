using AnnotatedTests
using JET
using Test

@testset "JET" begin
    report = JET.report_package(AnnotatedTests; target_modules=(AnnotatedTests,))
    @test isempty(JET.get_reports(report))
end
