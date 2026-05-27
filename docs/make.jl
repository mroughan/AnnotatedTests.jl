using Pkg

Pkg.develop(PackageSpec(path=joinpath(@__DIR__, "..")))
Pkg.instantiate()

using Documenter
using AnnotatedTests

DocMeta.setdocmeta!(AnnotatedTests, :DocTestSetup, :(using AnnotatedTests); recursive=true)

makedocs(
    modules=[AnnotatedTests],
    authors="Matthew Roughan <matthew.roughan@adelaide.edu.au>",
    sitename="AnnotatedTests.jl",
    format=Documenter.HTML(
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://matthew.roughan@adelaide.edu.au.github.io/AnnotatedTests.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md", 
    ],
    remotes=nothing,
    checkdocs=:exports,
)

deploydocs(;
    repo="github.com/mroughan/AnnotatedTests.jl",
)
