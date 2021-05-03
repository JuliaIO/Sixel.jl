using Sixel
using Documenter

DocMeta.setdocmeta!(Sixel, :DocTestSetup, :(using Sixel); recursive=true)

makedocs(;
    modules=[Sixel],
    authors="Johnny Chen <johnnychen94@hotmail.com>",
    repo="https://github.com/johnnychen94/Sixel.jl/blob/{commit}{path}#{line}",
    sitename="Sixel.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://johnnychen94.github.io/Sixel.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/johnnychen94/Sixel.jl",
)
