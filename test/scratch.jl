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

struct ReadRequest <: AbstractKatcpRequest
    name::String
    offset::Int64
    num_bytes::Int64
end

struct ReadReply <: AbstractKatcpReply
    bytes::Vector{UInt8}
end

const handlers = Dict(
    "version" => x -> (@info KATCP.read(VersionInform, x)),
    "build-state" => x -> (@info KATCP.read(BuildStateInform, x)),
)

client = KATCP.Client.KatcpClient(ip"127.0.0.1", 7147; handlers=handlers)

function listdev(client::KatcpClient)
    request(ListdevRequest(Detail), client, ListdevInform)
end

function read_bytes(client::KatcpClient, name, offset=0, num_bytes=1)
    ret, bytes, _ = request(ReadRequest(name, offset, num_bytes), client, ReadReply)
    @assert ret == KATCP.Ok "Return wasn't OK"
    bytes.bytes
end

function read_uint(client::KatcpClient, name, offset=0)
    bytes = read_bytes(client, name, offset, 4)
    # Swap endianness to host
    reinterpret(UInt32, bytes)[1] |> ntoh
end

function read_int(client::KatcpClient, name, offset=0)
    bytes = read_bytes(client, name, offset, 4)
    # Swap endianness to host
    reinterpret(Int32, bytes)[1] |> ntoh
end