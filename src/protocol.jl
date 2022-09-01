using StringViews

@enum MessageKind Request Reply Inform

"""
The core message type of KATCP.
"""
struct RawMessage
    kind::MessageKind
    name::String
    id::Union{UInt32,Nothing}
    arguments::Vector{Vector{UInt8}}
end

# Const regexes to "precompile" them
const NAME_RE = Regex("\\G[a-zA-Z](?:[a-zA-Z]|\\d|-|)*")
const MSGID_RE = Regex("\\G\\[([123456789]\\d*)\\]")
const ARGS_RE = Regex("[\\t ]+((?:[^\\\\ \\0\\n\\r\\t]|\\\\[\\\\|_|0|n|r|e|r|@])+)")

"""
Parse an incoming vector of bytes (without trailing newline) into a `RawMessage`.
"""
function RawMessage(raw::Vector{UInt8})
    # Construct the StringView that allows us to kinda do string processing
    sv = StringView(raw)

    # Keep track of where the parser is
    ptr = 1

    # Identify sentinel
    kind = if sv[ptr] == '#'
        Inform
    elseif sv[ptr] == '?'
        Request
    elseif sv[ptr] == '!'
        Reply
    else
        println(stderr, "Invlid KATCP type sentinel. Must be one of `!`, `#`, or `?`")
        Base.throw_invalid_char(sv[ptr])
    end
    ptr += 1

    # Identity name
    maybe_name = match(NAME_RE, sv, ptr)
    @assert !isnothing(maybe_name) "No valid name field found in given input"
    ptr += length(maybe_name.match)
    name = maybe_name.match

    # Identify optional ID
    maybe_id = match(MSGID_RE, sv, ptr)
    id = if isnothing(maybe_id)
        nothing
    else
        ptr += length(maybe_id.match)
        Base.parse(UInt32, maybe_id[1])
    end

    # Identify arguments
    arguments = Vector{UInt8}[]
    while true
        maybe_arg = match(ARGS_RE, sv, ptr)
        !isnothing(maybe_arg) || break
        ptr += length(maybe_arg.match)
        push!(arguments, Vector{UInt8}(maybe_arg[1]))
    end

    # Put it all together
    RawMessage(kind, name, id, arguments)
end

"""
Serialize a `RawMessage` into a vector of bytes (without trailing newline)
"""
function Vector{UInt8}(message::RawMessage)
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