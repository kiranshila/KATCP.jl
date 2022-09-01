"""The types we can serde with KATCP and implementations of the serde.

parse(::Type{T}, bytes) - create a KATCP type `T` from `bytes`
Vector{UInt8}(val::T) - create a byte vector from KATCP value `val` of KATCP type `T`
"""

using Sockets, Dates

"""Fallback method for parse if we came from a "safe" string"""
parse(t::Type, bytes::Base.CodeUnits) = parse(t, collect(bytes))

##### KATCP Enum Types

@enum RetCode Ok Invalid Fail

##### KATCP "Primitive" Types

parse(::Type{Int32}, bytes::Vector{UInt8}) = Base.parse(Int32, StringView(bytes))
unparse(val::Int32) = Vector{UInt8}(string(val))

parse(::Type{Int64}, bytes::Vector{UInt8}) = Base.parse(Int64, StringView(bytes))
unparse(val::Int64) = Vector{UInt8}(string(val))

parse(::Type{Float32}, bytes::Vector{UInt8}) = Base.parse(Float32, StringView(bytes))
unparse(val::Float32) = Vector{UInt8}(string(val))

parse(::Type{Float64}, bytes::Vector{UInt8}) = Base.parse(Float64, StringView(bytes))
unparse(val::Float64) = Vector{UInt8}(string(val))

parse(::Type{Bool}, bytes::Vector{UInt8}) = bytes[1] == UInt8('1')
unparse(val::Bool) = [val ? UInt8('1') : UInt8('0')]

parse(::Type{DateTime}, bytes::Vector{UInt8}) = unix2datetime(parse(Float64, bytes))
unparse(val::DateTime) = Vector{UInt8}(string(datetime2unix(val)))

##### KATCP "Complex" Types

# There is probably a smarter way to do this with a hashing, 
# but the number of variants is going to be small, so I'm not sure it matters
function parse(::Type{T}, bytes::Vector{UInt8}) where {T<:Enum}
    sv = StringView(bytes)
    for kind in instances(T)
        if sv == lowercase(string(kind))
            return kind
        end
    end
    error("Discrete variant in payload, $sv, doesn't match a variant in $T")
end

unparse(val::Enum) = Vector{UInt8}(lowercase(string(val)))

"""
The IPv4/v6 address type from KATCP
"""
struct KatcpAddress{T<:IPAddr}
    host::T
    port::Union{UInt16,Nothing}
end

function parse(::Type{KatcpAddress}, bytes::Vector{UInt8})
    sv = StringView(bytes)
    ipv6 = match(r"\[(.*)\](?::(\d+))?", sv)
    ipv4 = match(r"([^:]*)(?::(\d+))?", sv)
    ip = isnothing(ipv6) ? ipv4 : ipv6
    kind = isnothing(ipv6) ? IPv4 : IPv6
    @assert !(isnothing(ipv4) && isnothing(ipv6)) "Tried to parse an invalid IP address: $(String(bytes))"
    host = Base.parse(kind, ip[1])
    port = isnothing(ip[2]) ? nothing : Base.parse(UInt16, ip[2])
    KatcpAddress(host, port)
end

function unparse(val::KatcpAddress{T}) where {T}
    payload = UInt8[]
    if T == IPv6
        push!(payload, UInt8('['))
    end
    append!(payload, Vector{UInt8}(string(val.host)))
    if T == IPv6
        push!(payload, UInt8(']'))
    end
    if !isnothing(val.port)
        push!(payload, UInt8(':'))
        append!(payload, Vector{UInt8}(string(val.port)))
    end
    payload
end

##### KATCP String Types
# I'll include a vector of bytes here, because in the "official" implementation these can exist (which breaks the specification).
# The way the katcp-python implementation gets around this is by escaping the bytes exactly as if there were strings (which is ridiculous)

function unescape(s::AbstractString)
    replace(s,
        "\\\\" => '\\',
        "\\_" => ' ',
        "\\0" => '\0',
        "\\n" => '\n',
        "\\r" => '\r',
        "\\e" => '\e',
        "\\t" => '\t',
        "\\@" => "",)
end

function escape(s::AbstractString)
    if s == ""
        "\\@"
    else
        replace(s,
            '\\' => "\\\\",
            ' ' => "\\_",
            '\0' => "\\0",
            '\n' => "\\n",
            '\r' => "\\r",
            '\e' => "\\e",
            '\t' => "\\t",)
    end
end

unescape(b::Vector{UInt8}) = Vector{UInt8}(unescape(StringView(b)))
escape(b::Vector{UInt8}) = Vector{UInt8}(escape(StringView(b)))

parse(::Type{String}, bytes::Vector{UInt8}) = unescape(StringView(bytes))
unparse(val::String) = escape(Vector{UInt8}(val))

parse(::Type{Vector{UInt8}}, bytes::Vector{UInt8}) = unescape(bytes)
unparse(val::Vector{UInt8}) = escape(val)

##### Maybe
# This will only work is the optional value is the last field or fields, otherwise you need to write a parser
parse(::Type{Maybe{T}}, bytes::Vector{UInt8}) where {T} = isempty(bytes) ? nothing : parse(T, bytes)
unparse(::Nothing) = UInt8[]

export KatcpAddress