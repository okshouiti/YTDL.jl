module YTDL

using HTTP, LazyJSON, PrettyTables, DataFrames
export ytdl, available_codecs



abstract type AV end

struct Audio <: AV
	url::String
	length::Int64
    ext::String
    temp_ext::String
    function Audio(nt, ext)
        # Int32 reach its ceiling at 2^31-1 (≒ 256 MiB)
        # Int64 accepts up to 2^63-1 (≒ 1 EiB)
        len = haskey(nt, :length) ? parse(Int64, nt.length) : 0
        new(nt.url, len, ext.a, ext.atemp)
    end
end

struct Video <: AV
	url::String
	length::Int64
    ext::String
    temp_ext::String
    function Video(nt, ext)
        len = haskey(nt, :length) ? parse(Int64, nt.length) : 0
        new(nt.url, len, ext.v, ext.vtemp)
    end
    Video(t::Nothing, ext) = nothing
end



include("codec.jl")
include("deps.jl")
include("meta.jl")
include("downloader.jl")
include("presets.jl")
include("utils.jl")
include("youtube-dl.jl")

const USER_JL = joinpath(homedir(), ".julia", "config", "ytdl.jl")
if isfile(USER_JL)
    include(USER_JL)
end



# global setting
function ytdl(url::AbstractString; kwargs...)
    d = get(ENV, "YTDL_DIR", homedir())
    #opts = haskey(kwargs, :dir) ? kwargs.data : merge((;dir=d), kwargs)
    opts = get(kwargs, :dir, merge((;dir=d), kwargs))
    isdir(opts.dir) || return error("$(opts.dir) does not exist.")
    get(opts, :useragent, nothing) |> HTTP.setuseragent!
    v_id = queries(url)["v"]
    ytdl_body(v_id, opts)
    return nothing
end

# download setting each video
function ytdl_body(v_id, opts)
    info = get_metadata(v_id)
    if isnothing(info)
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
    path = joinpath(opts.dir, safename(info.title, opts))
    @async get_thumbnail(v_id, path)
    c = sellect_format(info.codecs, opts)
    ext = sellect_ext(c.a, c.v)
	downloader(
		Audio(info.codecs[c.a], ext),
        Video(get(info.codecs, c.v, nothing), ext),
        path,
        info2cmd(info, v_id, opts),
        opts
    )
end



end # module
