abstract type YTDLDeps end
struct YTDLbin <: YTDLDeps end
struct FFMPEGbin <: YTDLDeps end



# test availability of COMMANDS (copied from Franklin.jl)
isexcutable(cmd)::Bool = try success(cmd); catch; false; end

isavailable(::Type{YTDLbin}) = isexcutable(`youtube-dl --help`)

isavailable(::Type{FFMPEGbin}) = isexcutable(`ffmpeg -h`)



function deps()
    yt = try
        `youtube-dl --version` |> readlines |> first
    catch
        "unavailable"
    end
    ff = try
        `ffmpeg -version` |> readlines |> first |> x->split(x," ",limit=4)[3]
    catch
        "unavailable"
    end
    @info("Dependencies' version",
        ytdl = yt,
        ffmpeg = ff
    )
    return nothing
end