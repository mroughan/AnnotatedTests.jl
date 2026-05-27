using Documenter
using AnnotatedTests

makedocs(
    sitename = "AnnotatedTests.jl",
    modules = [AnnotatedTests],
    format = Documenter.HTML(disable_git = true, edit_link = nothing, repolink = nothing),
    pages = ["Home" => "index.md"],
    remotes = nothing,
)
