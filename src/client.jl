# A KATCP client implementation
module Client

using Sockets
import KATCP: RawMessage, AbstractKatcpMessage, AbstractKatcpRequest, Maybe, serialize

struct KatcpClient
    connection::TCPSocket
    msgs::Channel{RawMessage}
end

function KatcpClient(addr::IPAddr, port::Integer; handlers::Dict{String,Function})
    # Connect to the TCP socket
    con = connect(addr, port)

    # Create the "unhandled message" channel
    chan = Channel{RawMessage}()

    # Add our default handlers
    @async begin
        @async while isopen(con)
            line = readline(con)
            if !isempty(line)
                # Parse
                msg = RawMessage(Base.CodeUnits(line))
                if haskey(handlers, msg.name)
                    # Handle
                    handlers[msg.name](msg)
                else
                    # Push
                    put!(chan, msg)
                end
            end
        end
    end

    KatcpClient(con, chan)
end

function transmit(msg::AbstractKatcpMessage, client::KatcpClient; id::Maybe{Integer}=nothing)
    # Create a raw message from the msg
    raw = RawMessage(msg; id)
    # Serialize and send
    write(client.connection, serialize(raw))
    write(client.connection, '\n')
end

export KatcpClient, transmit

end