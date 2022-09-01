# The concrete message type interface

"""Supertype of the three abstract messages; Replies, Informs, and Requests"""
abstract type AbstractKatcpMessage end

abstract type AbstractKatcpReply <: AbstractKatcpMessage end
abstract type AbstractKatcpInform <: AbstractKatcpMessage end
abstract type AbstractKatcpRequest <: AbstractKatcpMessage end

kind(::Type{<:AbstractKatcpReply}) = Reply
kind(::Type{<:AbstractKatcpInform}) = Inform
kind(::Type{<:AbstractKatcpRequest}) = Request

function RawMessage(msg::T; id::Maybe{Integer}=nothing) where {T<:AbstractKatcpMessage}
    fields = fieldnames(T)
    args = Vector{UInt8}[map(x -> unparse(getproperty(msg, x)), fields)...]
    filter!(x -> !isempty(x), args)
    RawMessage(kind(T), name(T), id, args)
end

function read(::Type{T}, msg::RawMessage) where {T<:AbstractKatcpMessage}
    types = fieldtypes(T)
    filtered_types = filter(x -> !(Nothing <: x), types)
    # We need to deal with the fact that "missing" arguments might not even exist
    @assert length(filtered_types) <= length(msg.arguments) <= length(types) "Target type $T has $(length(types)) fields while the incoming KATCP message has $(length(msg.arguments))"
    actually_missing = length(types) - length(msg.arguments)
    # We will make the assumption that all the missing arguments are at the end, otherwise we wouldn't be able to tell them apart. Anything otherwise needs a real parser
    args = map(pair -> parse(pair...), zip(types[1:end-actually_missing], msg.arguments))
    # Add in the nothings (using multi-position splatting)
    T(args..., fill(nothing, actually_missing)...)
end

read(::Type{T}, bytes::AbstractArray{UInt8}) where {T} = read(T, RawMessage(bytes))

function kebab(string)
    words = lowercase.(split(string, r"(?=[A-Z])"))
    join([i == 1 ? word : "-$word" for (i, word) in enumerate(words)])
end

function name(::Type{T}) where {T<:AbstractKatcpMessage}
    # Pascal-case name, appended with Request, Reply, or Inform
    s = string(T)
    @assert endswith(s, "Request") || endswith(s, "Reply") || endswith(s, "Inform") "Automatic name generation for message struct must end with the message kind. Implement `name` manually otherwise."
    if T <: AbstractKatcpReply
        kebab(s[1:end-5])
    elseif T <: AbstractKatcpRequest
        kebab(s[1:end-7])
    elseif T <: AbstractKatcpInform
        kebab(s[1:end-6])
    else
        error("Struct of type $T not a Reply, Request, or Inform. Did you miss a subtype?")
    end
end

export AbstractKatcpReply, AbstractKatcpInform, AbstractKatcpRequest