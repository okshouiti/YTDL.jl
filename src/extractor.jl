# ====================================================
# ==================    MetaData    ==================
# ====================================================

"""
    extract_info(v_id)

Extract video information as Dict.
It contains url of source file, title, channel name and more!
"""
extract_info(v_id::AbstractString) = dl_page(v_id) |> extract_json |> ytinfo



function dl_page(v_id::AbstractString)
    HTTP.setuseragent!(nothing)
    HTTP.get(VIDEO_PREFIX * v_id).body |> String
end


function extract_json(htmlstr::AbstractString)
    var_token_idx = findfirst("ytInitial", htmlstr)[end]
    open_idx = findfirst('{', htmlstr[var_token_idx:end])
    close_idx = findfirst("};", htmlstr[var_token_idx:end])[begin]

    return JSON3.read(htmlstr[var_token_idx:end][open_idx:close_idx])
end


function ytinfo(json::JSON3.Object)
    info_entry = json[:videoDetails]
    @debug info_entry

    micro_format = json[:microformat][:playerMicroformatRenderer]
    @debug micro_format

    return (
        title = info_entry[:title],
        author = info_entry[:author],
        author_id = info_entry[:channelId],
        desc_short = info_entry[:shortDescription],
        #keywords = info_entry[:keywords] |> Vector{String},
        view_count = info_entry[:viewCount],
        seconds = info_entry[:lengthSeconds],
        desc = haskey(micro_format, :description) ? micro_format[:description][:simpleText] : "",
        date = micro_format[:publishDate],
        codecs = find_codecs(json)
    )
end



function find_codecs(dict)
    cs = Dict{Int,NamedTuple}()
    if !haskey(dict, :streamingData) ||
            !haskey(dict[:streamingData], :adaptiveFormats) ||
            !haskey(first(dict[:streamingData][:adaptiveFormats]), :url)
        return cs
    end
    for d ∈ dict[:streamingData][:adaptiveFormats]
        ps = Pair{Symbol,Any}[]
        haskey(d, :contentLength) && push!(ps, :length => d[:contentLength])
        push!(ps, :url => d[:url])
        push!(cs, d[:itag] => (; ps...))
    end
    return cs
end