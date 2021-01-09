function preset_a_best(codecs)
    list = (251, 250, 249, 140, 139)
    for c ∈ list
        c ∈ codecs && return c
    end
end

function preset_limited_best(codecs; res_limit=4320)
    resolutions = (4320,2160,1440,1080,720,480,360,240,144)
    for r ∈ resolutions
        r > res_limit && continue
        cs_r = CODECS_EACH_RES[r]
        i_end = lastindex(cs_r)
        for i ∈ 1:i_end
            c = cs_r[i]
            if c ∉ codecs
                continue
            elseif (r ≤ 480) || (name(c) != "av1")
                return c
            else
                for j ∈ i+1:i_end
                    c_next = cs_r[j]
                    if c_next ∉ codecs
                        continue
                    elseif fps(c_next) != "30"
                        return c
                    else
                        return c_next
                    end
                end
                return c
            end
        end
    end
end

# 1 accept up to V_144p, default is 9 (up to V_4320p)
#=function preset_limited_best(codecs; limit=9)
    list = (
        V_4320p,
        V_2160p,
        V_1440p,
        V_1080p,
        V_720p,
        V_480p,
        V_360p,
        V_240p,
        V_144p
    )[end-limit+1:end]
    for ctuple ∈ list
        cs = ∩(ctuple, codecs)
        if isempty(cs)
            continue
        elseif length(cs) == 1
            return first(cs)
        elseif (codec(first(cs)) == "av1" &&
            fps(cs[2]) == "30" &&
            resolution(first(cs)) ∉ ("480", "360", "240", "144")
        )
            return cs[2]
        else
            return first(cs)
        end
    end
end=#
