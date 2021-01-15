# YTDL

`youtube-dl`や`annie`のようなダウンローダをjuliaで書いてみたかったマン



## Installation
```julia
(@v1.5) pkg> add https://github.com/okshouiti/YTDL.jl
```



## Usage
いつもの
```julia
julia> using YTDL
```

### Print available codecs
```julia
julia> available_codecs(url)
  Audio Codecs
┌─────┬───────┬─────────┐
│  ID │ Codec │ Bitrate │
│     │       │  [Kbps] │
├─────┼───────┼─────────┤
│ 251 │  opus │     160 │
│ 140 │   aac │     128 │
└─────┴───────┴─────────┘
  Video Codecs
┌─────┬────────────┬───────────┬───────┐
│  ID │ Resolution │ Framerate │ Codec │
│     │   [pixels] │     [fps] │       │
├─────┼────────────┼───────────┼───────┤
│ 247 │        720 │        30 │   vp9 │
│ 136 │        720 │        30 │   avc │
│ 244 │        480 │        30 │   vp9 │
│ 135 │        480 │        30 │   avc │
│ 243 │        360 │        30 │   vp9 │
│ 134 │        360 │        30 │   avc │
│ 242 │        240 │        30 │   vp9 │
│ 133 │        240 │        30 │   avc │
│ 278 │        144 │        30 │   vp9 │
│ 160 │        144 │        30 │   avc │
└─────┴────────────┴───────────┴───────┘
```

### Download video
```julia
julia> ytdl(url, preset="best")
Download start...
```



## Dependencies
`ffmpeg`と任意で`youtube-dl`が必要なので入れておきましょう。

```bash
# Windows
sudo scoop install ffmpeg

# Ubuntu or Debian
sudo apt install ffmpeg

# Arch
yay -S ffmpeg

# etc...
```
