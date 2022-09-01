# In the style of the nom parser combinators, we want no copies

function isalpha(byte::UInt8)
    UInt8('a') <= byte <= UInt8('z') || UInt8('A') <= byte <= UInt8('Z')
end

function isdigit(byte::UInt8)
    UInt8('0') <= byte <= UInt8('9')
end

function isargument(byte::UInt8)
    byte != UInt8(' ') &&
        byte != UInt8('\0') &&
        byte != UInt8('\n') &&
        byte != UInt8('\r') &&
        byte != UInt8('\e') &&
        byte != UInt8('\t')
end

function sentinel(bytes::AbstractArray{UInt8})
    ptr = 1
    kind = if bytes[ptr] == UInt8('#')
        Inform
    elseif bytes[ptr] == UInt8('!')
        Reply
    elseif bytes[ptr] == UInt8('?')
        Request
    else
        println(stderr, "Invlid KATCP type sentinel. Must be one of `!`, `#`, or `?`")
        Base.throw_invalid_char(bytes[ptr])
    end
    ptr + 1, kind
end

function name(bytes::AbstractArray{UInt8}, ptr_start::Integer)
    ptr_end = ptr_start

    # First match the valid start char
    if isalpha(bytes[ptr_end])
        ptr_end += 1
    else
        return error("Invalid start character for name - $(Char(c))")
    end

    # Then keep taking bytes that satisfy the general requirement
    while true
        if ptr_end > length(bytes)
            break
        end
        c = bytes[ptr_end]
        if isalpha(c) || isdigit(c) || c == UInt8('-')
            ptr_end += 1
        else
            break
        end
    end

    # Return
    ptr_end, StringView(@view bytes[ptr_start:ptr_end-1])
end

# After this point, we might have run out of bytes

function maybe_id(bytes::AbstractArray{UInt8}, ptr_start::Integer)
    ptr_end = ptr_start

    if ptr_start > length(bytes)
        return ptr_start, StringView(@view bytes[ptr_start-1:ptr_end-2])
    end

    if bytes[ptr_end] == UInt8('[')
        ptr_end += 1
    else
        return ptr_end, StringView(@view bytes[ptr_start+1:ptr_end-2])
    end

    # The next character *must* be a nonzero digit
    if UInt8('0') < bytes[ptr_end] <= UInt8('9')
        ptr_end += 1
    else
        return error("First digit in ID brackets must be nonzero")
    end

    # Keep taking bytes until end
    while true
        c = bytes[ptr_end]
        if isdigit(c)
            ptr_end += 1
        elseif c == UInt8(']')
            ptr_end += 1
            break
        else
            return error("Invalid character in ID brackets - $(Char(c))")
        end
    end

    ptr_end, StringView(@view bytes[ptr_start+1:ptr_end-2])
end

function argument(bytes::AbstractArray{UInt8}, ptr_start::Integer)
    ptr_end = ptr_start
    arg_start = 0

    if ptr_start > length(bytes)
        return ptr_start, StringView(@view bytes[ptr_start-1:ptr_end-2])
    end

    # Take whitespace until argument char
    while true
        c = bytes[ptr_end]
        if c == UInt8(' ') || c == UInt8('\t')
            ptr_end += 1
        elseif isargument(c)
            arg_start = ptr_end
            ptr_end += 1
            break
        else
            return error("Invalid argument character - $(Char(c))")
        end
    end

    while true
        if ptr_end > length(bytes)
            break
        end
        c = bytes[ptr_end]
        if isargument(c)
            ptr_end += 1
        else
            break
        end
    end

    ptr_end, @view bytes[arg_start:ptr_end-1]
end

function arguments(bytes::AbstractArray{UInt8}, ptr_start::Integer)
    args = SubArray{UInt8}[]
    ptr_end = ptr_start
    while ptr_end < length(bytes)
        ptr_end, arg = argument(bytes, ptr_end)
        push!(args, arg)
    end
    args
end
