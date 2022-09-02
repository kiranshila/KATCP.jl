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
ListdevRequest(kind::ListdevKind) = ListdevRequest(Some(kind))

struct ListdevInform <: AbstractKatcpInform
    name::String
    extra::Maybe{String}
end

ListdevInform(name, extra::String) = ListdevInform(name, Some(extra))

const handlers = Dict(
    "version" => x -> (@info KATCP.read(VersionInform, x)),
    "build-state" => x -> (@info KATCP.read(BuildStateInform, x)),
)

client = KATCP.Client.KatcpClient(ip"127.0.0.1", 7147; handlers=handlers)

function listdev(client::KatcpClient)
    request(ListdevRequest(Detail), client, ListdevInform)
end