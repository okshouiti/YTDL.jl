# ====================================================
# =================    Downloader    =================
# ====================================================

function downloader(audio, video, v_id, path, ffcmd, opts)
    embed_thumb = isembedthumb(opts)
    if embed_thumb
        thumb_path = embedthumb_name(path)
        get_embedthumb(v_id, thumb_path)
    end
    downloader_body(audio, video, path, ffcmd, opts)
    embed_thumb && rm(thumb_path*".jpg")
    return nothing
end



# download only audio
function downloader_body(audio, video::Nothing, path, ffcmd, opts)
    dest = string(path, '.', audio.ext)
    if get(opts, :use_tempfile, true)
        temp = string(path, "___audiotemp.", audio.temp_ext)
        dl_temp_audio(audio, temp, opts)
        audio_temp_remux(temp, dest, ffcmd, opts)
        rm(temp)
    else
        dl_audio(audio, dest, path, ffcmd, opts)
    end
end


# download audio and video with muxing
function downloader_body(audio, video::Video, path, ffcmd, opts)
    a_temp = string(path, "___audiotemp.", audio.temp_ext)
    dest = string(path, '.', video.ext)
    dl_temp_audio(audio, a_temp, opts)
    usetemp = get(opts, :use_tempfile, true)
    if usetemp
        v_temp = string(path, "___videotemp.", video.temp_ext)
        complete = dl_temp_video(video, v_temp, opts)
        if complete
            mux(a_temp, v_temp, dest, path, ffcmd, opts)
        end
        rm(v_temp)
    else
        complete = dl_video_with_muxing(video, dest, a_temp, path, ffcmd, opts)
        complete || rm(dest)
    end
    rm(a_temp)
    return nothing
end



function dl_options(opts)
    ff = get(opts, :ffmpeg_path, "ffmpeg")
    size = get(opts, :chunk_size, 1)
    ff, size
end





# ====================================================
# ===================    Audio    ====================
# ====================================================

function dl_temp_audio(audio, dest, opts)
    ffpath, chunk_size = dl_options(opts)
    # io = `$ffpath -i pipe:0 -c copy $dest`
    # get_payload(audio, io, chunk_size)
    get_payload(audio, dest, chunk_size)
end

function dl_audio(audio, dest, path, ffcmd, opts)
    ffpath, chunk_size = dl_options(opts)
    if isembedthumb(opts)
        thumb_path = embedthumb_name(path) * ".jpg"
        # "-disposition:1 attached_pic" = second stream is embeded image
        io = `$ffpath -i pipe:0 -i $thumb_path -map 0 -map 1 -c copy -disposition:v:0 attached_pic $ffcmd $dest`
    else
        io = `$ffpath -i pipe:0 -map 0 -c copy $ffcmd $dest`
    end
    get_payload(audio, io, chunk_size)
end

function audio_temp_remux(tempfile, destfile, ffcmd, opts)
    ffpath, _ = dl_options(opts)
    run(`$ffpath -i $tempfile -c copy $ffcmd $destfile`)
end



# ====================================================
# ===================    Video    ====================
# ====================================================

function dl_temp_video(video, dest, opts)
    ffpath, chunk_size = dl_options(opts)
    get_payload(video, dest, chunk_size)
end

# post processsing
function mux(a, v, dest, path, ffcmd, opts)
    ffpath = get(opts, :ffmpeg_path, "ffmpeg")
    if isembedthumb(opts)
        thumb_path = embedthumb_name(path) * ".jpg"
        run(`$ffpath -i $v -i $a -i $thumb_path -map 0 -map 1 -map 2 -c copy -disposition:v:1 attached_pic $ffcmd $dest`)
    else
        run(`$ffpath -i $v -i $a -map 0 -map 1 -c copy $ffcmd $dest`)
    end
end

function dl_video_with_muxing(video, dest, temp, path, ffcmd, opts)
    ffpath, chunk_size = dl_options(opts)
    qs = get(opts, :queue_size, 512)
    if isembedthumb(opts)
        thumb_path = embedthumb_name(path) * ".jpg"
        io = `$ffpath -thread_queue_size $qs -i pipe:0 -i $temp -i $thumb_path -map 0 -map 1 -map 2 -c copy -disposition:v:1 attached_pic $ffcmd $dest`
    else
        io = `$ffpath -thread_queue_size $qs -i pipe:0 -i $temp -map 0 -map 1 -c copy $ffcmd $dest`
    end
    get_payload(video, io, chunk_size)
end





# ====================================================
# ==================    Payload    ===================
# ====================================================
function get_payload(av, io_target, chunk_size)
    open(io_target, "w") do io
        chunk = chunk_size * 1024 * 1024
        start = 0
        stop = chunk - 1
        len = if iszero(av.length)
            h = try
                resp = HTTP.head(av.url)
                Dict(resp.headers)
            catch e
                printstyled("Target file not found. Status:$(e.status)\n", color=:red)
                return false
            end
            h["Content-Length"]
        else
            av.length
        end
        @info string("Filesize: ", len)
        while stop ≤ len
            chunked_payload(av.url, start, stop, io)
            start = stop + 1
            stop += chunk
        end
        chunked_payload(av.url, start, len, io)
        return true
    end
end

# youtube doesn't send data using Transfer-Encoding:chunked 
# for dl speed, YTDL.jl uses RangeRequest instead
function chunked_payload(url, start, stop, io)
    header = ["Range"=>"bytes=$start-$stop"]
    HTTP.open("GET", url, header) do stream
        write(io, stream)
    end
    @info string(Dates.now(), " ", "Downloaded ", stop, " bytes")
end