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
