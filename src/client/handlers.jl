# Default handlers

using Logging

function handle_log(msg::KatcpMessage)
    # Parse into log
    log = KATCP.read(LogInform, msg)
    # Send the log
    lvl = LogLevel(log.level |> Int)
    @logmsg lvl log.message name = log.name
end

function handle_client_connected(msg::KatcpMessage)
    cc = KATCP.read(ClientConnectedInform, msg)
    @info cc.msg
end

function handle_build_state(msg::KatcpMessage)
    bs = KATCP.read(BuildStateInform, msg)
    @info bs.version
end

function handle_version(msg::KatcpMessage)
    v = KATCP.read(VersionInform, msg)
    @info v.version
end

const DEFAULT_HANDLERS = Dict(
    "log" => handle_log,
    "client-connected" => handle_client_connected,
    "build-state" => handle_build_state,
    "version" => handle_version,
)