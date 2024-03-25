abstract type AV end

struct Audio <: AV
    url::String
    length::Int64
    ext::String
    temp_ext::String
    function Audio(nt, ext)
        # Int32 reach its ceiling at typemax(Int32) == 2 * (2^10)^3 - 1  (≒ 2 GiB)
        # Int64 accepts up to 2^63-1 (≒ 1 EiB)
        len = haskey(nt, :length) ? parse(Int64, nt.length) : 0
        new(nt.url, len, ext.a, ext.atemp)
    end
end

struct Video <: AV
    url::String
    length::Int64
    ext::String
    temp_ext::String
    function Video(nt, ext)
        len = haskey(nt, :length) ? parse(Int64, nt.length) : 0
        new(nt.url, len, ext.v, ext.vtemp)
    end
    Video(t::Nothing, ext) = nothing
end
