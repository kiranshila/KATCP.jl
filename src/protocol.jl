using StringViews

@enum MessageKind Request Reply Inform

"""
The core message type of KATCP.
"""
struct RawMessage{T1,T2,T3}
    kind::MessageKind
    name::T1
    id::Maybe{T2}
    arguments::Vector{T3}
    # Default constructor
    function RawMessage(kind::MessageKind, name::T1, id::T2, argument::Vector{T3}) where {T1<:AbstractString,T2<:Integer,T3<:AbstractArray{UInt8}}
        new{T1,T2,T3}(kind, name, id, argument)
    end
    # Fallback ID type for no ID
    function RawMessage(kind::MessageKind, name::T1, id::T2, argument::Vector{T3}) where {T1<:AbstractString,T2<:Nothing,T3<:AbstractArray{UInt8}}
        new{T1,Int64,T3}(kind, name, id, argument)
    end
end

# fallback constructors for when there isn't enough information to fully type RawMessage
RawMessage(kind::MessageKind, name::AbstractString, id::Maybe{Integer}) = RawMessage(kind, name, id, Vector{UInt8}[])

"""
Parse an incoming vector of bytes (without trailing newline) into a `RawMessage`.
"""
function RawMessage(bytes::AbstractArray{UInt8})
    ptr, kind = sentinel(bytes)
    ptr, n = name(bytes, ptr)
    ptr, id = maybe_id(bytes, ptr)
    args = arguments(bytes, ptr)

    # Parse ID
    id_parsed = if isempty(id)
        nothing
    else
        Base.parse(Int64, id)
    end

    RawMessage(kind, n, id_parsed, args)
end

"""
Serialize a `RawMessage` into a vector of bytes (without trailing newline)
"""
function serialize(message::RawMessage)
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
        append!(payload, Vector{UInt8}(string(message.id)))
        push!(payload, UInt8(']'))
    end

    # Arguments
    for argument in message.arguments
        push!(payload, UInt8(' '))
        append!(payload, Vector{UInt8}(argument))
    end

    payload
end

export RawMessage