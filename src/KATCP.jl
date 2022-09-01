module KATCP

# I'm not sure why this isn't apart of Julia yet
const Maybe{T} = Union{T,Nothing}

include("parser.jl")
include("protocol.jl")
include("types.jl")
include("messages/interface.jl")
include("messages/core.jl")

end
