# The concrete message type interface

"""Supertype of the three abstract messages; Replies, Informs, and Requests"""
abstract type AbstractKatcpMessage end

abstract type AbstractKatcpReply <: AbstractKatcpMessage end
abstract type AbstractKatcpInform <: AbstractKatcpMessage end
abstract type AbstractKatcpRequest <: AbstractKatcpMessage end

kind(::Type{<:AbstractKatcpReply}) = Reply
kind(::Type{<:AbstractKatcpInform}) = Inform
kind(::Type{<:AbstractKatcpRequest}) = Request

"""
Convert an instance of a `AbstractKatcpMessage` into an args
"""
function materialize(msg::T) where {T<:AbstractKatcpMessage}
    fields = fieldnames(T)
    args = Vector{UInt8}[map(x -> unparse(getproperty(msg, x)), fields)...]
    filter!(x -> !isempty(x), args)
    args
end

function KatcpMessage(msg::T; id::Maybe{Integer}=nothing) where {T<:AbstractKatcpMessage}
    KatcpMessage(kind(T), name(T), id, materialize(msg))
end

function read(::Type{T}, msg::KatcpMessage) where {T<:AbstractKatcpMessage}
    types = fieldtypes(T)
    filtered_types = filter(x -> !(Nothing <: x), types)
    # We need to deal with the fact that "missing" arguments might not even exist
    arg_size_check = msg.kind == Reply ? length(msg.arguments) - 1 : length(msg.arguments)
    @assert length(filtered_types) <= arg_size_check <= length(types) "Target type $T has $(length(types)) fields while the incoming KATCP message has $arg_size_check"
    actually_missing = length(types) - arg_size_check
    # If the message is of type reply, we require that the first arg is a return code, but don't care about that when we read into the body of the reply
    if msg.kind == Reply
        @assert parse(RetCode, msg.arguments[1]) isa RetCode "First argument of a reply message must be a return code"
    end
    start = msg.kind == Reply ? 2 : 1
    # We will make the assumption that all the missing arguments are at the end, otherwise we wouldn't be able to tell them apart. Anything otherwise needs a real parser
    args = map(pair -> parse(pair...), zip(types[1:end-actually_missing], msg.arguments[start:end]))
    # Add in the nothings (using multi-position splatting)
    T(args..., fill(nothing, actually_missing)...)
end

read(::Type{T}, bytes::AbstractArray{UInt8}) where {T} = read(T, KatcpMessage(bytes))

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

### Reply Messages are weird because they are different

function ret_code(msg::KatcpMessage)
    @assert msg.kind == Reply "Only Reply messages have return codes"
    parse(RetCode, msg.arguments[1])
end

### Reply message constructors

function reply(ret_code::RetCode, name::AbstractString; id=nothing)
    KatcpMessage(Reply, name, id, [unparse(ret_code)])
end

function reply(ret_code::RetCode, name::AbstractString, body::AbstractKatcpMessage; id=nothing)
    KatcpMessage(Reply, name, id, [unparse(ret_code), materialize(body)...])
end

function reply(ret_code::RetCode, body::T; id=nothing) where {T<:AbstractKatcpMessage}
    KatcpMessage(Reply, name(T), id, [unparse(ret_code), materialize(body)...])
end

export AbstractKatcpReply, AbstractKatcpInform, AbstractKatcpRequest, ret_code, reply