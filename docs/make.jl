using Documenter, YTDL

makedocs(;
    modules=[YTDL],
    format=Documenter.HTML(),
    pages=[
        "Home" => "index.md",
    ],
    repo="https://github.com/okshouiti/YTDL.jl/blob/{commit}{path}#L{line}",
    sitename="YTDL.jl",
    authors="okshouiti",
    assets=String[],
)

deploydocs(;
    repo="github.com/okshouiti/YTDL.jl",
)
