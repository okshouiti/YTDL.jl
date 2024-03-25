module YTDL

using Dates
using HTTP, Gumbo, Cascadia, JSON3
using Underscores, PrettyTables

export ytdl, available_codecs, extract_info


const VIDEO_PREFIX = "https://www.youtube.com/watch?v="

include("types.jl")
include("codec.jl")
include("deps.jl")
include("meta.jl")
include("extractor.jl")
include("downloader.jl")
include("presets.jl")
include("utils.jl")
include("youtube-dl.jl")

const USER_JL = joinpath(homedir(), ".julia", "config", "ytdl.jl")
if isfile(USER_JL)
    include(USER_JL)
end



"""
    ytdl(url; kwargs...)

| keyword         | Default     | Type               |
|:----------------|:------------|:-------------------|
| backend_options | see below   | Collection{String} |
| chunk_size      | 10          | Int                |
| dir             | homedir()   | String             |
| embed_thumbnail | true        | Bool               |
| enable_backend  | false       | Bool               |
| ffmpeg_path     | "ffmpeg"    | String             |
| preset          | "bestaudio" | String             |
| queue_size      | 512         | Int                |
| usemkv          | false       | Bool               |
| usemp4          | false       | Bool               |
| use_tempfile    | true        | Bool               |

"""
function ytdl(url::AbstractString; kwargs...)
    # global immutable options (named tuple)
    if haskey(kwargs, :dir)
        opts = kwargs.data
    else
        d = get(ENV, "YTDL_DIR", homedir())
        opts = merge((; dir=d), kwargs)
    end
    isdir(opts.dir) || return error("$(opts.dir) does not exist.")
    overwrite_useragent!(opts)
    v_id = queries(url)["v"]
    ytdl_body(v_id, opts)
    return nothing
end



# download setting each video
function ytdl_body(v_id, opts)
    opts = Dict{Symbol,Any}(pairs(opts))   # make keyword arguments mutable
    info = extract_info(v_id)
    # -----  Backend-Mode -----
    if isempty(info.codecs)
        if get(opts, :enable_backend, false)
            return youtube_dl(v_id, opts)
        else
            println("""
                This video type (cipherd video source URL) is not yet available,
                but you can download it using youtube-dl backend-mode.
                Add option `enable_backend=true` and call `ytdl` again!
            """)
            return nothing
        end
    end
    path = joinpath(opts[:dir], safename(info.title, opts))
    # -----  Thumbnail -----
    @async get_thumbnail(v_id, path)
    # -----  Codec and Extension -----
    c = sellect_format(info.codecs, opts)
    ext = sellect_ext(c.a, c.v, opts)
    if !isembeddable(ext)
        fmt = isnothing(ext.v) ? ext.a : ext.v
        @warn("$fmt doesn't support embedding thumbnail.")
        opts[:embed_thumbnail] = false
    end
    # ----- instance of AV -----
    audio = Audio(info.codecs[c.a], ext)
    video = isnothing(c.v) ? nothing : Video(info.codecs[c.v], ext)
    ffcmd = info2ffcmd(info, v_id, opts)
    downloader(audio, video, v_id, path, ffcmd, opts)
end



end # module
