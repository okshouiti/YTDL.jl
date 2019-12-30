module YTDL

using HTTP, Gumbo, Cascadia

export ytdl

function ytdl(url::String)
    dom = Gumbo.parsehtml(String(HTTP.get(url).body))
    title = nodeText(Cascadia.eachmatch(sel".watch-title", dom.root)[1])[6:end-5]
    #thumbnail(url, title)
    codeclist = "251/140/webm/bestaudio"
    ytdlCmd = `youtube-dl -f $codeclist $url -o -`
    ffmpegCmd = `ffmpeg -i pipe:0 -codec copy "H:/download/$title.opus"`
    run(pipeline(ytdlCmd, ffmpegCmd));
    println("$title.opus has been saved to H:/download/")
end

# サムネイル取得は試験段階
function thumbnail(url::String, title::String)
    id = url[[findlast("?v=", url)...][end]+1:end]
    thumburl = ["https://i.ytimg.com/vi$fmt/$id/maxresdefault.$ext" for (fmt,ext) in [("", "jpg"), ("_webp", "webp")]]
    dst = ["H:/download/$title.$ext" for ext in ["jpg", "webp"]]
    download.(thumburl, dst)
    println("Thumbnail (jpg & webp) has been saved to H:/download/")
end

end # module
