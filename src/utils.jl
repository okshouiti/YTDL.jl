# ====================================================
# ==================    Utility    ===================
# ====================================================

# FileSystem Utils
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



# URL Utils
# return dict of queries
queries(url) = url |> HTTP.URI |> HTTP.queryparams



# HTTP Utils
function print_global_useragent()
    url = "https://httpbin.org/user-agent"
    response = HTTP.get(url).body |> String
    println(response)
    return nothing
end



# Print Utils
function available_codecs(url; color=true)
    HTTP.setuseragent!(nothing)
    v_id = queries(url)["v"]
    metadata = get_metadata(v_id)
    if isnothing(metadata)
        return @error("""

            Failed to extract video info.
            Use `youtube-dl -F $url` instead!
        """)
    end
    codecs = metadata.codecs |> keys
    df_a = DataFrame(ID=Int[], Codec=String[], Bitrate=Int[])
    df_v = DataFrame(ID=Int[], Resolution=Int[], FPS=String[], Codec=String[])
    for c ∈ codecs
        if isaudio(c)
            push!(df_a, (c, name(c), bitrate(c)))
        else
            push!(df_v, (c, resolution(c), fps(c), name(c)))
        end
    end
    # sorting table
    sort!(df_a, [order(:Codec, rev=true), order(:Bitrate, rev=true)])
    sort!(df_v, [order(:Resolution, rev=true), order(:FPS, rev=true), order(:Codec, rev=true)])
    header_a = [
        "ID" "Codec" "Bitrate";
        "" "" "[Kbps]"
    ]
    header_v = [
        "ID" "Resolution" "Framerate" "Codec";
        "" "[pixels]" "[fps]" ""
    ]
    fmt = []
    if color
        push!(fmt, :header_crayon => crayon"green bold")
        #push!(fmt, :border_crayon => crayon"yellow")
        #push!(fmt, :highlighters => (hl_lt(2), hl_gt(4)))
    end
    pretty_table(df_a, header_a; title="  Audio Codecs", fmt...)
    pretty_table(df_v, header_v; title="  Video Codecs", fmt...)
end