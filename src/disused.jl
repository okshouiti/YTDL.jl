# --------------------------------------------------------------------
# ------------------------------  MAIN  ------------------------------
# --------------------------------------------------------------------
function ytdl_native(url, dir, codec_ext, thumbnail, infotxt)
    (acodec, vcodec, aext, vext) = codec_ext
    meta = info(url)
    tags = audiotag(meta)
    infotxt && infofile(meta, dir)
    thumbnail && thumb(url, meta.title, dir)
    audiocmd = `youtube-dl -f "$acodec" $url -o -`
    if isnothing(vcodec)
        ffmpegcmd = `ffmpeg -i pipe:0 -codec copy $tags "$(joinpath(dir, meta.title)).$aext"`
        run(pipeline(audiocmd, ffmpegcmd))
    else
        temp = joinpath(dir, "ytdltemp."*aext)
        ffmpegcmd = `ffmpeg -i pipe:0 -codec copy $tags $temp`
        run(pipeline(audiocmd, ffmpegcmd))
        videocmd = `youtube-dl -f "$vcodec" $url -o -`
        muxcmd = `ffmpeg -i pipe:0 -i $temp -codec copy "$(joinpath(dir, meta.title)).$vext"`
        run(pipeline(videocmd, muxcmd))
        rm(temp)
    end
    @info("YTDL - Downloaded File",
        title = meta.title,
        extension = ifelse(isnothing(vcodec), aext, vext),
        location = dir,
        thumbnail = true,
        infotxt = infotxt
    )
    return nothing
end



# --------------------------------------------------------------------
# ------------------------------  META  ------------------------------
# --------------------------------------------------------------------
const SELECTORS = (
    title = "#eow-title",
    user = ".yt-user-info",
    date = ".watch-time-text"
)

function info(url)
    HTTP.setuseragent!(nothing)
    dom = parsehtml(String(HTTP.get(url).body)).root
    nodes = NamedTuple()
    for (sym,sel) ∈ pairs(SELECTORS)
        str = nodeText(first(eachmatch(Selector(sel), dom)))
        pair = (; zip((sym,), (str,))...)
        nodes = merge(nodes, pair)
    end
    title = filter(x -> x ∉ UNSAFE_CHARS, strip(nodes.title))
    date = filter(isdigit, nodes.date)
    desc = let
        node = first(eachmatch(Selector("#eow-description"), dom))
        text = ""
        for elm ∈ node.children
            if elm isa HTMLElement{:br}
                text *= "\r\n"
            else
                text *= nodeText(elm)
            end
        end
        text
    end
    return (title=title, user=nodes.user, date=date, desc=desc)
end

function audiotag(meta)
    fields = (
        title="title",
        user="author",
        date="year",
        desc="comment"
    )
    tags = String[]
    for (sym, text) ∈ pairs(meta)
        push!(tags, "-metadata")
        push!(tags, fields[sym] * "=" * text)
    end
    return Cmd(tags)
end

function infofile(meta, dir)
    file = joinpath(dir, meta.title)*".txt"
    texts = ""
    for (index, txt) ∈ pairs(meta)
        texts *= string(String(index), "\n", txt, "\n\n")
    end
    try
        open(file, "w") do io
            write(io, texts)
        end
    catch
        @warn "Cannot write infomation to $file"
    end
    return nothing
end



# --------------------------------------------------------------------
# ------------------------------  DEPS  ------------------------------
# --------------------------------------------------------------------
function install()
    if Sys.iswindows()
        dir = let
            old = pwd()
            cd(dirname(YTDL_DIR))
            if !isdir("deps")
                mkdir("deps")
            end
            cd(old)
            joinpath(dirname(YTDL_DIR), "deps")
        end
        ver = let
            url = "https://github.com/ytdl-org/youtube-dl/releases"
            dom = parsehtml(String(HTTP.get(url).body)).root
            latest = first(eachmatch(Selector(".release-header"), dom))
            v = nodeText(first(eachmatch(Selector("a"), latest)))
            v[end-9:end]
        end
        dest = joinpath(dir, "youtube-dl.exe")
        url = "https://github.com/ytdl-org/youtube-dl/releases/download"
        HTTP.open("GET", joinpath(url, ver, "youtube-dl.exe")) do stream
            open(dest, "w") do io
                write(io, stream)
            end
        end
    else
        println("aaa")
    end
    return nothing
end