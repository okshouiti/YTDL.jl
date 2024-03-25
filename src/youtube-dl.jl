# youtube-dl backend mode for unsupported video
function youtube_dl(v_id, opts)
    @info("Entered youtube-dl MODE")
    if !isavailable(YTDLbin)
        return @error("""

            Command `youtube-dl` is unavailable on your computer.
            Install it and try again!
        """)
    end
    u = "https://wwww.youtube.com/watch?v=" * v_id
    codecs = youtube_dl_available_codecs(u)
    c = sellect_format(codecs, opts)
    ext = sellect_ext(c.a, c.v, opts)
    base = (
        "youtube-dl",
        "-o",
        joinpath(opts[:dir], "%(title)s.%(ext)s"),
        "-f",
        isnothing(c.v) ? c.a : string(c.v, "+", c.a)
    )
    if isnothing(c.v)
        fmt = ("--extract-audio", "--audio-format", ext.a)
    else
        fmt = ("--merge-output-format", ext.v)
    end
    if haskey(opts, :backend_options)
        backend_opts = opts[:backend_options]
    else
        backend_opts = [
            "--no-continue",
            "--no-mtime",
            "-q",
            "--console-title",
            "--add-metadata"
        ]
    end
    t = Sys.get_process_title()
    run(`$base $backend_opts $fmt $u`)
    Sys.set_process_title(t)
    return nothing
end



function youtube_dl_available_codecs(url)
    lines = readlines(`youtube-dl -F $url`)
    Int[
        parse(Int, first(l, 3))
            for l ∈ lines
                if isdigit(l[1]) && isdigit(l[3])
    ]
end
