using KATCP, Sockets
using KATCP.Client
import KATCP.Maybe

struct VersionInform <: AbstractKatcpInform
    commit::String
end

struct BuildStateInform <: AbstractKatcpInform
    date::String
end

@enum ListdevKind Detail Size

struct ListdevRequest <: AbstractKatcpRequest
    kind::Maybe{ListdevKind}
end

ListdevRequest() = ListdevRequest(nothing)

struct ListdevInform <: AbstractKatcpInform
    name::String
    extra::Maybe{String}
end

const handlers = Dict(
    "version" => x -> (@info KATCP.read(VersionInform, x)),
    "build-state" => x -> (@info KATCP.read(BuildStateInform, x)),
)

client = KATCP.Client.KatcpClient(ip"127.0.0.1", 7147; handlers=handlers)

function listdev(client::KatcpClient)
    transmit(ListdevRequest(Detail), client)
    devs = ListdevInform[]
    while true
        msg = take!(client.msgs)
        if msg.kind == KATCP.Reply
            @assert msg.arguments[1] == b"ok"
            break
        else
            push!(devs, KATCP.read(ListdevInform, msg))
        end
    end
    devs
end