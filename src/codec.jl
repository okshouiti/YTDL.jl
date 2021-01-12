#=export A_CODEC,
    V_CODEC,
    CODECS_EACH_RES,
    isaudio,
    name,
    bitrate,
    resolution,
    fps,
    sellect_format,
    sellect_ext=#

const A_CODEC = Dict(
    251 => ("opus", 160),
    250 => ("opus", 70),
    249 => ("opus", 50),
    140 => ("aac", 128),
    139 => ("aac", 48)
)
const V_CODEC = Dict(
    # VP9
    272 => (4320, "vp9", "60HDR"),
    337 => (2160, "vp9", "60HDR"),
    315 => (2160, "vp9", "60"),
    313 => (2160, "vp9", "30"),
    336 => (1440, "vp9", "60HDR"),
    308 => (1440, "vp9", "60"),
    271 => (1440, "vp9", "30"),
    335 => (1080, "vp9", "60HDR"),
    303 => (1080, "vp9", "60"),
    248 => (1080, "vp9", "30"),
    334 => (720, "vp9", "60HDR"),
    302 => (720, "vp9", "60"),
    247 => (720, "vp9", "30"),
    333 => (480, "vp9", "60HDR"),
    244 => (480, "vp9", "30"),
    332 => (360, "vp9", "60HDR"),
    243 => (360, "vp9", "30"),
    331 => (240, "vp9", "60HDR"),
    242 => (240, "vp9", "30"),
    330 => (144, "vp9", "60HDR"),
    278 => (144, "vp9", "30"),
    # AV1
    571 => (4320, "av1", "60"), # higher bitrate than 402
    402 => (4320, "av1", "60"),
    401 => (2160, "av1", "60"),
    400 => (1440, "av1", "60"),
    399 => (1080, "av1", "60"),
    398 => (720, "av1", "60"),
    397 => (480, "av1", "30"),
    396 => (360, "av1", "30"),
    395 => (240, "av1", "30"),
    394 => (144, "av1", "30"),
    # AVC (H.264)
    299 => (1080, "avc", "60"),
    137 => (1080, "avc", "30"),
    298 => (720, "avc", "60"),
    136 => (720, "avc", "30"),
    135 => (480, "avc", "30"),
    134 => (360, "avc", "30"),
    133 => (240, "avc", "30"),
    160 => (144, "avc", "30"),
)
const CODECS_EACH_RES = Dict(
    4320 => (272, 571, 402),
    2160 => (337, 315, 401, 313),
    1440 => (336, 308, 400, 271),
    1080 => (335, 303, 399, 299, 248, 137),
    720  => (334, 302, 398, 298, 247, 136),
    480  => (333, 244, 397, 135),
    360  => (332, 243, 396, 134),
    240  => (331, 242, 395, 133),
    144  => (330, 278, 394, 160)
)



# Codec Utils
isaudio(c) = haskey(A_CODEC, c)

name(c) = isaudio(c) ? A_CODEC[c][begin] : V_CODEC[c][2]

bitrate(c) = A_CODEC[c][end]

resolution(c) = V_CODEC[c][begin]

fps(c) = V_CODEC[c][end]




# ====================================================
# ===================    Codec    ====================
# ====================================================
# codec sellection for native extracted codecs
function sellect_format(codecs_dict::AbstractDict, opts)
    sellect_format(keys(codecs_dict), opts)
end

# codec sellection (compatatible with backend mode)
function sellect_format(cs, opts)
    p = get(opts, :preset, "bestaudio") |>
        x -> replace(x, '-'=>'_')
    if p == "bestaudio"
        a = preset_a_best(cs)
        v = nothing
    elseif p == "best"
        a = preset_a_best(cs)
        v = preset_limited_best(cs)
    else
        a,v = try_preset_func(p, cs)
    end
    return (a=a, v=v)
end

# call user-defined preset function
function try_preset_func(preset, cs)
    f = Symbol(preset)
    if isdefined(@__MODULE__, f)
        Expr(:call, f, cs) |> eval
    else
        return error("""

            Preset function 【$(preset)】 is not defined.
            Call the predefined function below instead.
                best      : best_audio + best_video
                bestaudio : best_audio
            Or, define your preset following the rules:
                - Define in  ~/.julia/config/ytdl.jl
                - Return integer tuple (audio_id, video_id)
                - Have valid name
                    can include a-z, 0-9 and "_"
                    not starts with numbers
                    in lowercase
        """)
    end
end





# ====================================================
# =================    Extension    ==================
# ====================================================

# sellect audio ext
sellect_ext(a) = a=="aac" ? "m4a" : "opus"

# extension for audio codec
function sellect_ext(a_id, v_id::Nothing)
    a = name(a_id)
    ext = sellect_ext(a)
    temp = sellect_temp(a)
    (a=ext, v=nothing, atemp=temp, vtemp=nothing)
end

# extension for audio and video codec
function sellect_ext(a_id, v_id)
    a = name(a_id)
    v = name(v_id)
    aext = sellect_ext(a)
    if a=="aac" && (v=="av1" || v=="avc")
        vext = "mp4"
    elseif a=="opus" && v=="vp9"
        vext = "webm"
    else
        vext = "mkv"
    end
    atemp = sellect_temp(a)
    vtemp = sellect_temp(v)
    (a=aext, v=vext, atemp=atemp, vtemp=atemp)
end



# 
function sellect_temp(c)
    if c=="opus" || c=="vp9"
        "webm"
    elseif c=="aac" || c=="av1" || c=="avc"
        "mp4"
    end
end
