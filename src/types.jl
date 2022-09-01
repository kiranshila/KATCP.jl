"""The types we can serde with KATCP and implementations of the serde.

parse(::Type{T}, bytes) - create a KATCP type `T` from `bytes`
Vector{UInt8}(val::T) - create a byte vector from KATCP value `val` of KATCP type `T`
"""

using Sockets, Dates

"""Fallback method for parse if we came from a "safe" string"""
parse(t::Type, bytes::Base.CodeUnits) = parse(t, collect(bytes))

##### KATCP Enum Types

@enum RetCode Ok Invalid Fail

function parse(::Type{RetCode}, bytes::Vector{UInt8})
    if bytes == b"ok"
        Ok
    elseif bytes == b"invalid"
        Invalid
    elseif bytes == b"fail"
        Fail
    else
        error("Failed to parse a `RetCode` at input \"$(String(bytes))\"")
    end
end

function Vector{UInt8}(val::RetCode)
    # Exhaustive because enum
    Vector{UInt8}(if val == Ok
        "ok"
    elseif val == Invalid
        "invalid"
    else
        "fail"
    end
    )
end

##### KATCP "Primitive" Types

parse(::Type{Int32}, bytes::Vector{UInt8}) = Base.parse(Int32, String(bytes))
Vector{UInt8}(val::Int32) = Vector{UInt8}(string(val))

parse(::Type{Float32}, bytes::Vector{UInt8}) = Base.parse(Float32, String(bytes))
Vector{UInt8}(val::Float32) = Vector{UInt8}(string(val))

parse(::Type{Bool}, bytes::Vector{UInt8}) = bytes[1] == UInt8('1')
Vector{UInt8}(val::Bool) = [val ? UInt8('1') : UInt8('0')]

parse(::Type{DateTime}, bytes::Vector{UInt8}) = unix2datetime(parse(Float32, bytes))
Vector{UInt8}(val::DateTime) = Vector{UInt8}(string(datetime2unix(val)))

##### KATCP "Complex" Types

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

function Vector{UInt8}(val::KatcpAddress{T}) where {T}
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

export KatcpAddress