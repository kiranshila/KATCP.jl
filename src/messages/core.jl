# Core messages

### Halt

"""
This request should trigger a software halt. It is expected to close the connection and put the
software and hardware into a state where it is safe to power down.
"""
struct HaltRequest <: AbstractKatcpRequest end

"""
This reply is sent just before the halt occurs.
"""
struct HaltReply <: AbstractKatcpReply
    ret_code::RetCode
end

### Help

struct HelpRequest <: AbstractKatcpRequest
    name::Maybe{String}
end

HelpRequest() = HelpRequest(nothing)

struct HelpInform <: AbstractKatcpInform
    name::String
    description::String
end

struct HelpReply <: AbstractKatcpReply
    ret_code::RetCode
    num_commands::Int64
end

### Restart

### Watchdog

### VersionList

struct VersionListInform <: AbstractKatcpInform
    name::String
    version::String
    identifier::Maybe{String}
end


export HaltRequest, HaltReply, HelpRequest, HelpInform, HelpReply, VersionListInform