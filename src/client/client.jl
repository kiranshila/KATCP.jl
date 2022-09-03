# A KATCP client implementation
module Client

using Sockets
using KATCP
import KATCP: Maybe, serialize

include("handlers.jl")

struct KatcpClient
    connection::TCPSocket
    msgs::Channel{KatcpMessage}
end

"""
Construct and connect to a `KatcpClient`
"""
function KatcpClient(addr::IPAddr, port::Integer; handlers::Dict{String,Function}=Dict{String,Function}())
    # Connect to the TCP socket
    con = connect(addr, port)

    # Create the "unhandled message" channel
    chan = Channel{KatcpMessage}()

    # Merge external handlers
    combined_handlers = merge(DEFAULT_HANDLERS, handlers)

    # Add our default handlers
    @async begin
        @async while isopen(con)
            line = readline(con)
            @trace "New incoming line" line = line
            if !isempty(line)
                # Parse
                msg = KatcpMessage(Base.CodeUnits(line))
                @trace "Message parsed" msg = msg
                if haskey(combined_handlers, msg.name)
                    # Handle
                    @trace "Message matched handler" name = msg.name
                    combined_handlers[msg.name](msg)
                else
                    # Push
                    put!(chan, msg)
                end
            end
        end
    end

    KatcpClient(con, chan)
end

"""
Send an `AbstractKatcpMessage` to the connected `KacpClient`
"""
function transmit(msg::AbstractKatcpMessage, client::KatcpClient; id::Maybe{Integer}=nothing)
    # Create a raw message from the msg
    raw = KatcpMessage(msg; id)
    # Serialize and send
    write(client.connection, serialize(raw))
    write(client.connection, '\n')
end

"""
Internal function to perform requests
"""
function request_informs_until_reply(msg::AbstractKatcpRequest, client::KatcpClient; id::Maybe{Integer})
    transmit(msg, client; id)
    informs = KatcpMessage[]
    last_msg = take!(client.msgs)
    while true
        if last_msg.kind == KATCP.Reply
            break
        elseif last_msg.kind == KATCP.Inform
            @assert last_msg.name == KATCP.name(typeof(msg)) "We recieved an inform message that didn't match the name of the request - $(last_msg.name)"
            push!(informs, last_msg)
        elseif last_msg.kind == KATCP.Request
            return error("Got a request message as a response during a request cycle")
        end
        last_msg = take!(client.msgs)
    end
    (last_msg, informs)
end

"""
Perform a KATCP request given the concrete request `msg`

This will transmit the request message, collect inform messages until the return.
This function will return a tuple of the return code and the collect raw inform messages (unparsed into concrete types)
"""
function request(msg::AbstractKatcpRequest, client::KatcpClient; id::Maybe{Integer}=nothing)
    ret, informs = request_informs_until_reply(msg, client; id=id)
    (ret_code(ret), informs)
end

"""
Perform a KATCP request given the concrete request `msg` and collect into concrete inform messages `innform_type`
"""
function request(msg::AbstractKatcpRequest, client::KatcpClient, inform_type::Type{<:AbstractKatcpInform}; id::Maybe{Integer}=nothing)
    ret, informs = request_informs_until_reply(msg, client; id=id)
    xform(msg) = KATCP.read(inform_type, msg)
    (ret_code(ret), xform.(informs))
end

"""
Perform a KATCP request given the concrete request `msg` and collect concrete reply `reply_type`
"""
function request(msg::AbstractKatcpRequest, client::KatcpClient, reply_type::Type{<:AbstractKatcpReply}; id::Maybe{Integer}=nothing)
    ret, informs = request_informs_until_reply(msg, client; id=id)
    (ret_code(ret), KATCP.read(reply_type, ret), informs)
end

"""
Perform a KATCP request given the concrete request `msg` and collect into concrete inform messages `inform_type` and concrete reply `reply_type`
"""
function request(
    msg::AbstractKatcpRequest,
    client::KatcpClient,
    inform_type::Type{<:AbstractKatcpInform},
    reply_type::Type{<:AbstractKatcpReply}; id::Maybe{Integer}=nothing)
    ret, informs = request_informs_until_reply(msg, client; id=id)
    xform(msg) = KATCP.read(inform_type, msg)
    (ret_code(ret), KATCP.read(reply_type, ret), xform.(informs))
end

export KatcpClient, transmit, request

end