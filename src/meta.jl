"""
    get_thumbnail(video_id, path)

Save thumbnail image to path. Path must not include extension name (e.g. `"/home/user/filename"`).

| id            | resolution  |
|:--------------|:------------|
| default       | 120x90      |
| mqdefault     | 320x180     |
| hqdefault     | 480x360     |
| sddefault     | 640x480     |
| maxresdefault | 1280x720    |

!!! note
    Some resolutions are different from original one.
    They have black border on Top-Bottom or Left-Right.
"""
function get_thumbnail(v_id, path)
    res = (
        "maxresdefault",
        "sddefault",
        "hqdefault",
        "mqdefault",
        "default"
    )
    for r ∈ res
        u = "https://img.youtube.com/vi/$(v_id)/$(r).jpg"
        try
            HTTP.head(u)
        catch e
            if e.status == 404
                continue
            else
                @warn("Couldn't get thumbnail.", status = e.status)
                break
            end
        end
        HTTP.open(:GET, u) do stream
            open("$path.jpg", "w") do io
                write(io, stream)
            end
        end
        break
    end
end
# http://img.youtube.com
# http://i.ytimg.com
# http://i3.ytimg.com
# WEBP_URL_PATTERN   /vi_webp/OAOP2JUvxYw/maxresdefault.webp

# download valid format thumbnail for embed
get_embedthumb(v_id, path) = get_thumbnail(v_id, path)

embedthumb_name(path) = path * "_embed"





# ====================================================
# ==================    MetaData    ==================
# ====================================================

function get_metadata(v_id)
    response = get_player_response(v_id)
    j = LazyJSON.value(response)
    haskey(j, "streamingData") || return nothing
    haskey(j["streamingData"], "adaptiveFormats") || return nothing
    cs = Dict{Int,NamedTuple}()
    for d ∈ j["streamingData"]["adaptiveFormats"]
        ps = Pair{Symbol,Any}[]
        if haskey(d, "contentLength")
            push!(ps, :length => d["contentLength"])
        end
        if haskey(d, "url")
            push!(ps, :url => d["url"])
        #=elseif haskey(d, "signatureCipher")
            push!(ps, :cipher => d["signatureCipher"])=#
        else
            return nothing
        end
        push!(cs, d["itag"] => (; ps...))
    end
    return (
        title = j["videoDetails"]["title"],
        owner = j["videoDetails"]["author"],
        owner_id = j["videoDetails"]["channelId"],
        description = j["videoDetails"]["shortDescription"],
        length = j["videoDetails"]["lengthSeconds"],
        date = j["microformat"]["playerMicroformatRenderer"]["publishDate"],
        codecs = cs
    )
end



function get_player_response(v_id)
    u = "https://www.youtube.com/get_video_info?video_id=" * v_id
    msg = HTTP.get(u).body |> String
    response = split(msg, '&') |>
        x -> filter(y->startswith(y, "player_response"), x) |>
        first |>
        x -> split(x, '=', limit=2) |>
        last
    unescape_uri(response)
end

# unescape URI encoded character
#   (forked from HTTP.URIs.unescapeuri)
function unescape_uri(str)
    io = IOBuffer(str)
    out = IOBuffer()
    while !eof(io)
        c = read(io, Char)
        c == '&' && break
        if c == '%'
            c1 = read(io, Char)
            c2 = read(io, Char)
            c_decoded = parse(UInt8, string(c1, c2); base=16)
            write(out, c_decoded)
        # spaces have been replaced with '+'
        elseif c == '+'
            write(out, ' ')
        else
            write(out, c)
        end
    end
    String(take!(out))
end

#=function extract_json()
    TODO
end=#





# ====================================================
# ===================    Cipher    ===================
# ====================================================

function iscipher(codecs_dict)
    keys(codecs_dict) |>
        first |>
        x -> codecs_dict[x].url |>
        isempty
end

# decipher(url) = TODO





# ====================================================
# =============    MetaData for FFMPEG    ============
# ====================================================

# convert metadata to FFMPEG format
function info2ffcmd(info, v_id, opts)
    date = format_date(info.date, opts)
    usecrlf = get(opts, :use_crlf, false)
    desc = usecrlf ? replace(info.description, '\n'=>"\r\n") : info.desc
    d = Dict(
        "title" => info.title,
        "comment" => desc,
        "date" => date,
        "artist" => info.author,
        "publisher" => "https://www.youtube.com/channel/" * info.author_id,
        "purl" => VIDEO_PREFIX * v_id
        #"encoding_tool" => ""
    )
    cmd_arr = String[]
    for (k,v) ∈ d
        push!(cmd_arr, "-metadata:g", string(k, "=", v))
    end
    return cmd_arr
end



function format_date(date, opts)
    # youtube default delimiter
    default = '-'
    haskey(opts, :date_format) || return date
    fmt = opts[:date_format] 
    if haskey(fmt, :delim)
        replace(date, default=>fmt[:delim])
    elseif haskey(fmt, :custom)
        # TODO
        # user defined format
        #=ud = fmt[:custom]
        year, month, day = split(date, default)
        if occursin("yyyy", ud)
            date = replace(date, "yyyy"=>year)
        elseif occursin("yy", ud)
            date = replace(date, "yy"=>year)
        elseif occursin("y", ud)
            date = replace(date, "yyyy"=>year)
        end=#
        return date
    else
        date
    end
end