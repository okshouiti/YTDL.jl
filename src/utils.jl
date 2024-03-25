# ====================================================
# =============    Keyword Arguments    ==============
# ====================================================

# Embed thumbnail option
function isembedthumb(opts)
    bool = get(opts, :embed_thumbnail, true)
    bool isa Bool ? bool : error("embed_thumbnail must be Bool")
end



# ====================================================
# ====================    File    ====================
# ====================================================

const UNSAFE_CHARS = Dict(
    '/' => '／',
    '\\' => '＼',
    '?' => '？',
    '<' => '＜',
    '>' => '＞',
    ':' => '：',
    '*' => '＊',
    '|' => '｜',
    '"' => '”'
)

function safename(str, opts)
    mode = get(opts, :unsafe_chars, :delete)
    m = Symbol(mode)
    if m === :delete
        filter(x -> x ∉ keys(UNSAFE_CHARS), str)
    elseif m === :replace
        io = IOBuffer(str)
        out = IOBuffer()
        while !eof(io)
            c = read(io, Char)
            if haskey(UNSAFE_CHARS, c)
                write(out, UNSAFE_CHARS[c])
            else
                write(out, c)
            end
        end
        String(take!(out))
    else
        filter(x -> x ∉ keys(UNSAFE_CHARS), str)
    end
end



# ====================================================
# ====================    HTTP    ====================
# ====================================================

# return dict of queries
queries(url) = url |> HTTP.URI |> HTTP.queryparams

overwrite_useragent!(opts) = get(opts, :useragent, nothing) |> HTTP.setuseragent!

function print_global_useragent()
    url = "https://httpbin.org/user-agent"
    response = HTTP.get(url).body |> String
    println(response)
    return nothing
end



# ====================================================
# ===================    Print    ====================
# ====================================================

function available_codecs(url; color=true)
    HTTP.setuseragent!(nothing)
    v_id = queries(url)["v"]
    metadata = extract_info(v_id)
    if isnothing(metadata)
        return @error("""

            Failed to extract video info.
            Use `youtube-dl -F $url` instead!
        """)
    end
    codecs = metadata.codecs |> keys

    matrix_audio = reshape(AbstractString[], 0, 3)
    matrix_video = reshape(AbstractString[], 0, 4)
    #df_a = DataFrame(ID=Int[], Codec=String[], Bitrate=Int[])
    #df_v = DataFrame(ID=Int[], Resolution=Int[], FPS=String[], Codec=String[])
    for c ∈ codecs
        if isaudio(c)
            matrix_audio = vcat(matrix_audio, [c name(c) bitrate(c)])
        else
            matrix_video = vcat(matrix_video, [c resolution(c) fps(c) name(c)])
        end
    end
    # sorting table
    # TODO:
    #sort!(df_a, [order(:Codec, rev=true), order(:Bitrate, rev=true)])
    #sort!(df_v, [order(:Resolution, rev=true), order(:FPS, rev=true), order(:Codec, rev=true)])
    header_a = (
        ["ID", "Codec", "Bitrate"],
        ["", "", "[Kbps]"],
    )
    header_v = (
        ["ID", "Resolution", "Framerate", "Codec"],
        ["", "[pixels]", "[fps]", ""],
    )
    fmt = []
    if color
        push!(fmt, :header_crayon => crayon"green bold")
        #push!(fmt, :border_crayon => crayon"yellow")
        #push!(fmt, :highlighters => (hl_lt(2), hl_gt(4)))
    end

    @show 
    pretty_table(matrix_audio; header=header_a, title="  Audio Codecs")
    pretty_table(matrix_video; header=header_v, title="  Video Codecs")
end