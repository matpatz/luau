local _helper = {}

_helper.chunkify = function(input, chunk_size)
    chunk_size = chunk_size or 2
    local result = {}

    local function process(value)
        local vtype = type(value)

        if vtype == "string" then
            for i = 1, #value, chunk_size do
                table.insert(result, value:sub(i, i + chunk_size - 1))
            end

        elseif vtype == "number" then
            local str = tostring(value)
            for i = 1, #str, chunk_size do
                table.insert(result, str:sub(i, i + chunk_size - 1))
            end

        elseif vtype == "boolean" or vtype == "function" then
            table.insert(result, value)

        elseif vtype == "table" then
            for _, nested in ipairs(value) do
                process(nested)
            end

        else
            table.insert(result, value)
        end
    end

    for _, v in ipairs(input) do
        process(v)
    end

    return table.concat(result, "")
end

_helper.tabledata = function(data)
    local result = {}

    for _, v in pairs(data) do
        local t = type(v)
        result[t] = (result[t] or 0) + 1
    end

    return result
end

_helper.sum = function(tbl)
    expect(tbl, "table", false, 1)
    local total = 0
    for _, v in ipairs(tbl) do
        expect(v, "number", false, 1)
        total += v
    end
    return total
end

_helper.average = function(tbl)
    expect(tbl, "table", false, 1)
    assert(#tbl > 0, "table cannot be empty")
    return _helper.sum(tbl) / #tbl
end

-- local t = {"string", "pango", 3, "rango"}
-- print(helper.search(t, 3, true, { type = "number" }))
--  returns "3 3"
_helper.search = function(tbl, looking_for, nested, filter)
    expect(tbl, "table", false, 1)
    expect(nested, "boolean", false, 2)
    expect(filter, "table", false, 3)

    for k, v in pairs(tbl) do
        local match = (v == looking_for)

        if filter and filter.type then
            match = match and (type(v) == filter.type)
        end

        if match then
            return k, v
        end

        if nested and type(v) == "table" then
            local foundK, foundV = _helper.search(v, looking_for, true, filter)
            if foundK ~= nil then
                return foundK, foundV
            end
        end
    end

    return nil, "Item could not be found"
end

local function set(data, func)
    local result = {}
    for k, v in pairs(data) do
        result[k] = func(v)
    end
    return result
end

_helper.tostring = function(data)
    return _tostring(data)
end

-- for tables
_helper.tabletostring = function(data)
    return set(data, tostring)
end

_helper.tabletonumber = function(data)
    return set(data, tonumber)
end

_helper.is_repeating = function(v)
    local t = type(v)

    if t == "string" then
        if #v <= 1 then return true end
        local first = v:sub(1, 1)
        for i = 2, #v do
            if v:sub(i, i) ~= first then
                return false
            end
        end
        return true
    end

    -- table
    if #v == 0 then return true end
    local first = v[1]
    for i = 2, #v do
        if v[i] ~= first then
            return false
        end
    end

    return true
end

_helper.toexpontent = function(n)
    if n == 0 then return "0e0" end

    local exp = 0
    local value = n

    while value >= 10 do
        value /= 10
        exp += 1
    end

    while value < 1 do
        value *= 10
        exp -= 1
    end

    return string.format("%.3ge%d", value, exp)
end

_helper.fromexpontent = function(str)
    local base, exp = str:match("([%d%.]+)e([%-]?%d+)")
    base = tonumber(base)
    exp = tonumber(exp)

    if not base or not exp then return nil end

    return base * (10 ^ exp)
end

_helper.flip = function(var)
    expect(var, "boolean", false, 1)
    return not var
end

_helper.GetChildrenWithAttribute = function(parent, attr)
    local result = {}

    for _, child in ipairs(parent:GetChildren()) do
        if child:GetAttribute(attr) ~= nil then
            table.insert(result, child)
        end
    end

    return result
end

local collection = services["CollectionService"]

_helper.GetChildrenWithTag = function(parent, tag)
    local result = {}

    for _, instance in ipairs(collection:GetTagged(tag)) do
        if instance.Parent == parent then
            table.insert(result, instance)
        end
    end

    return result
end

-- claude
_helper.removeduplicates = function(t: table): table
    local seen = {}
    local result = {}

    for _, v in pairs(t) do
        if not seen[v] then
            seen[v] = true
            table.insert(result, v)
        end
    end

    return result
end

_helper.issametable = function(a: table, b: table): bool
    if a == b then return true end
    if typeof(a) ~= "table" or typeof(b) ~= "table" then return false end

    -- Check same number of keys
    local aCount, bCount = 0, 0
    for _ in pairs(a) do aCount += 1 end
    for _ in pairs(b) do bCount += 1 end
    if aCount ~= bCount then return false end

    -- Check all keys/values match
    for k, v in pairs(a) do
        local bv = b[k]
        if typeof(v) == "table" and typeof(bv) == "table" then
            if not issametable(v, bv) then return false end
        elseif v ~= bv then
            return false
        end
    end

    return true
end

for k, v in pairs(_helper) do
    add("helper." .. k, v)
end
getgenv().helper = _helper
