# The message interface

abstract type AbstractKatcpMessage end

"""Read a `RawMessage` into a concrete message type `T`.
You would implement `T(msg)` if you have a very custom struct. 
Otherwise, you subtype `AbstractKatcpMessage` and the default methods will take over."""
read(::Type{T}, msg::RawMessage) where {T} = T(msg)

read(t::Type{T}, raw::Vector{UInt8}) where {T} = read(t, RawMessage(raw))

function RawMessage(kind::MessageKind, name::String, msg::T; id::Union{UInt32,Nothing}=nothing) where {T<:AbstractKatcpMessage}
    fields = fieldnames(T)
    args = [map(x -> unparse(getproperty(msg, x)), fields)...]
    RawMessage(kind, name, id, args)
end

function read(::Type{T}, msg::RawMessage) where {T<:AbstractKatcpMessage}
    types = fieldtypes(T)
    @assert length(msg.arguments) == length(types) "Target type $T has $(length(types)) fields while the incoming KATCP message has $(length(msg.arguments))"
    args = map(pair -> parse(pair...), zip(types, msg.arguments))
    T(args...)
end

struct BareReply <: AbstractKatcpMessage
    ret_code::RetCode
end

struct IntReply <: AbstractKatcpMessage
    ret_code::RetCode
    x::Int64
end

export AbstractKatcpMessage, BareReply, IntReply