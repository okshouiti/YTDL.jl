# export downloader

# ====================================================
# =================    Downloader    =================
# ====================================================
# export downloader

# download only audio
function downloader(audio, video::Nothing, path, metadata, opts)
    dest = string(path, '.', audio.ext)
    dl_file(audio, dest, metadata, opts)
end

# download audio and video with muxing
function downloader(audio, video::Video, path, metadata, opts)
    a_temp = string(path, "___audiotemp.", audio.temp_ext)
    dest = string(path, '.', video.ext)
    dl_file(audio, a_temp, opts)
    use_temp = get(opts, :use_tempfile, true)
    if use_temp
        v_temp = string(path, "___videotemp.", video.temp_ext)
        dl_file(video, v_temp, opts)
        mux(a_temp, v_temp, dest, metadata, opts)
        rm(v_temp)
    else
        dl_file(video, dest, a_temp, metadata, opts)
    end
    rm(a_temp)
end



# ====================================================
# ==================    Payload    ===================
# ====================================================
# Audio temporary file
function dl_file(audio::Audio, dest, opts)
    ffpath, chunk_size = dl_options(opts)
    io = `$ffpath -i pipe:0 -c copy $dest`
    get_payload(audio, io, chunk_size)
end

# Audio file
function dl_file(audio::Audio, dest, metadata, opts)
    ffpath, chunk_size = dl_options(opts)
    io = `$ffpath -i pipe:0 -c copy $metadata $dest`
    get_payload(audio, io, chunk_size)
end

# Video temporary file
function dl_file(video::Video, dest, opts)
    ffpath, chunk_size = dl_options(opts)
    #qs = get(opts, :queue_size, 10)
    #io = `$ffpath -thread_queue_size $qs -i pipe:0 -c copy $dest`
    #get_payload(video, io, chunk_size)
    get_payload(video, dest, chunk_size)
end

# Video file (muxing video stream and audio temporary file)
function dl_file(video::Video, dest, temp, metadata, opts)
    ffpath, chunk_size = dl_options(opts)
    qs = get(opts, :queue_size, 10)
    io = `$ffpath -thread_queue_size $qs -i pipe:0 -i $temp -c copy $metadata $dest`
    get_payload(video, io, chunk_size)
end

# 
function get_payload(av, io_target, chunk_size)
    open(io_target, "w") do io
        chunk = chunk_size * 1024 * 1024
        start = 0
        stop = chunk - 1
        if iszero(av.length)
            h = HTTP.head(av.url).headers |> Dict
            len = h["Content-Length"]
        else
            len = av.length
        end
        while stop ≤ len
            chunked_payload(av.url, start, stop, io)
            start = stop + 1
            stop += chunk
        end
        chunked_payload(av.url, start, len, io)
    end
end

# youtube doesn't send data using Transfer-Encoding:chunked 
# for accelerating download speed, YTDL.jl use RangeRequest instead
function chunked_payload(url, start, stop, io)
    header = ["Range"=>"bytes=$(start)-$(stop)"]
    HTTP.open("GET", url, header) do stream
        write(io, stream)
    end
end

# set default value to download option
function dl_options(opts)
    ff = get(opts, :ffmpeg_path, "ffmpeg")
    size = get(opts, :chunk_size, 10)
    ff, size
end



# temporary file post processsing
function mux(a, v, dest, metadata, opts)
    ffpath = get(opts, :ffmpeg_path, "ffmpeg")
    run(`$ffpath -i $v -i $a -c copy $metadata $dest`)
end
