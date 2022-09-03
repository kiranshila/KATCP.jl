"""
Before sending a reply, the client-list request will send a client-list in-
form message containing the address of a client for each client connected to the device, including the
client making the request.
"""
struct ClientListRequest <: AbstractKatcpRequest end

struct ClientListInform <: AbstractKatcpInform
    addr::KatcpAddress
end

struct ClientListReply <: AbstractKatcpReply
    num_clients::Int64
end

struct ClientConnectedInform <: AbstractKatcpInform
    msg::String
end