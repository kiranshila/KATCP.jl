module KATCP

# I'm not sure why this isn't apart of Julia yet
const Maybe{T} = Union{Some{T},Nothing}

include("parser.jl")
include("protocol.jl")
include("types.jl")

include("messages/interface.jl")
include("messages/core.jl")
include("messages/log.jl")
include("messages/multi_client.jl")
include("messages/deprecated.jl")

include("client/client.jl")

end
