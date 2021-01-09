#=function deps()
    yt = try
        `youtube-dl --version` |> readlines |> first |> VersionNumber
    catch
        @error "youtube-dl can't be found."
    end
    ff = try
        `ffmpeg -version` |> readlines |> first |> x->split(x," ",limit=4)[3] |> VersionNumber
    catch
        @error "ffmpeg can't be found."
    end
    @info("Dependencies' version",
        ytdl = yt,
        ffmpeg = ff
    )
    return nothing
end=#



abstract type YTDLDeps end
struct YTDLbin <: YTDLDeps end
struct FFMPEGbin <: YTDLDeps end



# 外部バイナリが利用できるか
isexcutable(cmd) = try success(cmd); catch; false; end

isavailable(::Type{YTDLbin}) = isexcutable(`youtube-dl --help`)

isavailable(::Type{FFMPEGbin}) = isexcutable(`ffmpeg -h`)
