using StringViews

@enum MessageKind Request Reply Inform

"""
The core message type of KATCP.
"""
struct KatcpMessage{T1,T2,T3}
    kind::MessageKind
    name::T1
    id::Maybe{T2}
    arguments::Vector{T3}
    # Default constructor
    function KatcpMessage(kind::MessageKind, name::T1, id::Some{T2}, arguments::Vector{T3}) where {T1<:AbstractString,T2<:Integer,T3<:AbstractArray{UInt8}}
        new{T1,T2,T3}(kind, name, id, arguments)
    end
    # Fallback ID type for no ID
    function KatcpMessage(kind::MessageKind, name::T1, id::T2, arguments::Vector{T3}) where {T1<:AbstractString,T2<:Nothing,T3<:AbstractArray{UInt8}}
        new{T1,Int64,T3}(kind, name, id, arguments)
    end
end

# fallback constructors for when there isn't enough information to fully type KatcpMessage
KatcpMessage(kind::MessageKind, name::AbstractString, id::Maybe{Integer}) = KatcpMessage(kind, name, id, Vector{UInt8}[])
KatcpMessage(kind::MessageKind, name::AbstractString, id::Integer, arguments::Vector) = KatcpMessage(kind, name, Some(id), arguments)

"""
Parse an incoming vector of bytes (without trailing newline) into a `KatcpMessage`.
"""
function KatcpMessage(bytes::AbstractArray{UInt8})
    ptr, kind = sentinel(bytes)
    ptr, n = name(bytes, ptr)
    ptr, id = maybe_id(bytes, ptr)
    args = arguments(bytes, ptr)

    # Parse ID
    id_parsed = if isempty(id)
        nothing
    else
        Some(Base.parse(Int64, id))
    end

    KatcpMessage(kind, n, id_parsed, args)
end

"""
Serialize a `KatcpMessage` into a vector of bytes (without trailing newline)
"""
function serialize(message::KatcpMessage)
    payload = UInt8[]

    # Kind sentinel
    if message.kind == Inform
        push!(payload, UInt8('#'))
    elseif message.kind == Reply
        push!(payload, UInt8('!'))
    else
        push!(payload, UInt8('?'))
    end

    # Name
    append!(payload, Vector{UInt8}(message.name))

    # Maybe ID
    if !isnothing(message.id)
        push!(payload, UInt8('['))
        append!(payload, Vector{UInt8}(string(something(message.id))))
        push!(payload, UInt8(']'))
    end

    # Arguments
    for argument in message.arguments
        push!(payload, UInt8(' '))
        append!(payload, Vector{UInt8}(argument))
    end

    payload
end

export KatcpMessage