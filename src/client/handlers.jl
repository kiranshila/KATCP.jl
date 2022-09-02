# Default handlers

using Logging

function handle_log(msg::KatcpMessage)
    # Parse into log
    log = KATCP.read(LogInform, msg)
    # Send the log
    lvl = LogLevel(log.level |> Int)
    @logmsg lvl log.message name = log.name
end

const DEFAULT_HANDLERS = Dict(
    "log" => handle_log
)