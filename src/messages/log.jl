# Logging

@enum Level Off = -1 Fatal = 10000 Error = 2000 Warn = 1000 Info = 0 Debug = -1000 Trace = -2000 All = -10000

struct LogLevelRequest <: AbstractKatcpRequest
    level::Maybe{Level}
end

LogLevelRequest(level::Level) = LogLevelRequest(Some(level))

struct LogLevelReply <: AbstractKatcpReply
    level::Level
end

struct LogInform <: AbstractKatcpInform
    level::Level
    timestamp::DateTime
    name::String
    message::String
end

export LogLevelRequest, LogLevelReply, LogInform