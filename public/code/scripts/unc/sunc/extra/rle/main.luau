local rle = {}

function rle.encode(str: string): buffer
    local parts = {}
    local len = #str
    local i = 1

    while i <= len do
        local char = str:sub(i, i)
        local count = 1
        while i + count <= len and str:sub(i + count, i + count) == char do
            count += 1
        end
        parts[#parts + 1] = count
        parts[#parts + 1] = string.byte(char)
        i += count
    end

    -- Each run = 4 bytes (u16 count + u8 char + u8 padding)
    local out = buffer.create(#parts * 2)
    local offset = 0

    for i = 1, #parts, 2 do
        buffer.writeu16(out, offset, parts[i])
        buffer.writeu8(out, offset + 2, parts[i + 1])
        offset += 3
    end

    -- Return only the used portion
    local trimmed = buffer.create(offset)
    buffer.copy(trimmed, 0, out, 0, offset)
    return trimmed
end

function rle.decode(encoded: buffer): string
    local len = buffer.len(encoded)
    local parts = {}
    local offset = 0

    while offset < len do
        local count = buffer.readu16(encoded, offset)
        local char = string.char(buffer.readu8(encoded, offset + 2))
        parts[#parts + 1] = char:rep(count)
        offset += 3
    end

    return table.concat(parts)
end

return rle
