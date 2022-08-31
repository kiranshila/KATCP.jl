using KATCP
using Documenter

DocMeta.setdocmeta!(KATCP, :DocTestSetup, :(using KATCP); recursive=true)

makedocs(;
    modules=[KATCP],
    authors="Kiran Shila <me@kiranshila.com> and contributors",
    repo="https://github.com/kiranshila/KATCP.jl/blob/{commit}{path}#{line}",
    sitename="KATCP.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://kiranshila.github.io/KATCP.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/kiranshila/KATCP.jl",
    devbranch="main",
)
