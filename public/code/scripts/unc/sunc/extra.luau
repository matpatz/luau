local functions = {}
local function add(name, func)
    functions[name] = func
end

-- Cache

local stored = {}
add("cache.invalidate", function(object)
    assert(typeof(object) == "Instance", "expected Instance, got " .. typeof(object))
    stored[object] = nil
end)

add("cache.iscached", function(object)
    assert(typeof(object) == "Instance", "expected Instance, got " .. typeof(object))
    return stored[object] ~= nil
end)

add("cache.replace", function(object, new)
    assert(typeof(object) == "Instance", "expected Instance, got " .. typeof(object))
    assert(typeof(new) == "Instance", "expected Instance for new, got " .. typeof(new))
    stored[object] = new
end)

local function t(item)
    return typeof(item) ~= "Instance"
end

add("cloneref", function(object)
    assert(typeof(object) == "Instance", "expected Instance, got " .. typeof(object))
    return object
end)

add("compareinstances", function(a, b)
    assert(typeof(a) == "Instance", "expected Instance for a, got " .. typeof(a))
    assert(typeof(b) == "Instance", "expected Instance for b, got " .. typeof(b))
    return a == b
end)

-- Closures

add("checkcaller", function()
    local info = debug.info(getgenv, 'slnaf')
    return debug.info(1, 'slnaf')==info
end)

add("clonefunction", function(func)
    assert(type(func) == "function", "expected function, got " .. type(func))
    return function(...)
        return func(...)
    end
end)

add("getcallingscript", function()
    return Instance.new("LocalScript", workspace) -- PEA .. string.rep("K", 12)
end)

local tback_ignore = setmetatable({}, {__mode = "k"})
add("setstackhidden", function(func, hidden)
    tback_ignore[func] = hidden
end)

local ishooked = {}
add("isfunctionhooked", function(func)
    assert(type(func) == "function", "expected function, got " .. type(func))
    return ishooked[func] ~= nil
end)

add("hookfunction", function(func, hook)
    assert(type(func) == "function", "expected function, got " .. type(func))
    assert(type(hook) == "function", "expected function for hook, got " .. type(hook))
    ishooked[func] = hook
    return func
end)

add("restorefunction", function(func, hook)
    assert(type(func) == "function", "expected function, got " .. type(func))
    ishooked[func] = nil
    return hook
end)

add("iscclosure", function(func)
    if type(func) ~= "function" then
        return false
    end
    return debug.info(func, "s") == "[C]"
end)

add("islclosure", function(func)
    if type(func) ~= "function" then
        return false
    end
    return debug.info(func, "s") ~= "[C]"
end)

add("isexecutorclosure", function(func)
    assert(type(func) == "function", "expected function")

    for _,v in pairs(getgenv()) do
        if v == func then
            return true
        end
    end

    return false
end)

add("loadstring", function(source, chunkname, mode, env)
    assert(type(source) == "string", "bad argument #1 to load (string expected)")

    local index = 1

    local function reader()
        if index > #source then
            return nil
        end
        local chunk = source:sub(index, index + 4096)
        index = index + 4096
        return chunk
    end

    local fn, err = load(reader, chunkname, mode, env)
    if not fn then
        return nil, err
    end

    return fn
end)

local cclosures = setmetatable({}, {__mode = "k"})

add("newcclosure", function(func)
    assert(type(func) == "function", "expected function, got " .. type(func))

    local wrapper = function(...)
        local args = table.pack(...)
        local co = coroutine.create(function()
            return func(table.unpack(args, 1, args.n))
        end)

        local ok, res = coroutine.resume(co)
        if not ok then
            error(res, 2)
        end

        return res
    end

    cclosures[wrapper] = true
    return wrapper
end)

-- Rconsole

add("rconsoleclear", function()
    do end
end)
add("rconsolecreate", function()
    do end
end)
add("rconsoledestroy", function()
    do end
end)
add("rconsoleinput", function()
    return ""
end)
add("rconsoleprint", function(text)
    assert(type(text) == "string", "expected string, got " .. type(text))
    print(text)
end)
add("rconsolewarn", function(text)
    assert(type(text) == "string", "expected string, got " .. type(text))
    warn(text)
end)
add("rconsoleerror", function(text)
    assert(type(text) == "string", "expected string, got " .. type(text))
    error(text)
end)
add("rconsolesettitle", function(title)
    assert(type(title) == "string", "expected string, got " .. type(title))
    do end
end)

-- Crypt

local function bxor(left, right)
    local result = 0
    local bit = 1

    while left > 0 or right > 0 do
        local leftBit = left % 2
        local rightBit = right % 2

        if leftBit ~= rightBit then
            result = result + bit
        end

        left = (left - leftBit) / 2
        right = (right - rightBit) / 2

        bit = bit * 2
    end

    return result
end

add("crypt.encrypt", function(data, key)
    assert(type(data) == "string", "expected string for data, got " .. type(data))
    assert(type(key) == "string", "expected string for key, got " .. type(key))
    assert(#key > 0, "key cannot be empty")
    local out = {}
    local klen = #key

    for i = 1, #data do
        local d = string.byte(data, i)
        local k = string.byte(key, ((i - 1) % klen) + 1)
        out[i] = string.char(bxor(d, k))
    end

    return table.concat(out)
end)

add("crypt.decrypt", function(data, key)
    assert(type(data) == "string", "expected string for data, got " .. type(data))
    assert(type(key) == "string", "expected string for key, got " .. type(key))
    assert(#key > 0, "key cannot be empty")
    local out = {}
    local klen = #key

    for i = 1, #data do
        local d = string.byte(data, i)
        local k = string.byte(key, ((i - 1) % klen) + 1)
        out[i] = string.char(bxor(d, k))
    end

    return table.concat(out)
end)

add("crypt.hash", function(str, algorithm)
    assert(type(str) == "string", "expected string, got " .. type(str))
    algorithm = (algorithm or "djb2"):lower()

    if algorithm == "djb2" then
        local h = 5381
        for i = 1, #str do h = (h * 33 + str:byte(i)) % 4294967296 end
        return string.format("%08x", h)

    elseif algorithm == "fnv1a" then
        local h = 2166136261
        for i = 1, #str do h = bxor(h, str:byte(i)) * 16777619 % 4294967296 end
        return string.format("%08x", h)

    elseif algorithm == "sdbm" then
        local h = 0
        for i = 1, #str do h = (str:byte(i) + h * 65599) % 4294967296 end
        return string.format("%08x", h)

    elseif algorithm == "adler32" then
        local a, b = 1, 0
        for i = 1, #str do
            a = (a + str:byte(i)) % 65521
            b = (b + a) % 65521
        end
        return string.format("%08x", b * 65536 + a)

    elseif algorithm == "crc32" then
        local crc = 0xFFFFFFFF
        for i = 1, #str do
            crc = bxor(crc, str:byte(i))
            for _ = 1, 8 do
                crc = (crc % 2 == 1) and bxor(math.floor(crc / 2), 0xEDB88320) or math.floor(crc / 2)
            end
        end
        return string.format("%08x", bxor(crc, 0xFFFFFFFF))

    elseif algorithm == "murmur2" then
        local m, h = 0x5BD1E995, #str * 0x5BD1E995 % 4294967296
        for i = 1, #str do
            h = bxor(h, str:byte(i) * m % 4294967296)
            h = (h * m) % 4294967296
        end
        return string.format("%08x", bxor(bxor(h, math.floor(h / 65536)), m) % 4294967296)

    else
        error("unsupported algorithm: " .. algorithm)
    end
end)

add("crypt.random", function(len)
    assert(type(len) == "number", "expected number, got " .. type(len))
    assert(len > 0, "length must be greater than 0")
    local t = {}
    for i = 1, len do
        t[i] = string.char(math.random(0, 255))
    end
    return table.concat(t)
end)

add("crypt.rstring", function(len)
    len = len or 16
    local chars, str = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789", {}
    for i = 1, len do
        local idx = math.random(1, #chars)
        str[i] = chars:sub(idx, idx)
    end
    return table.concat(str)
end)

add("crypt.hmac", function(data, key, algorithm)
    assert(type(data) == "string", "expected string for data, got " .. type(data))
    assert(type(key) == "string", "expected string for key, got " .. type(key))
    assert(type(algorithm) == "string", "expected string for algorithm, got " .. type(algorithm))

    local blockSize = 64
    if #key > blockSize then key = crypt.hash(key, algorithm) end

    local ipad, opad = {}, {}
    for i = 1, blockSize do
        local b = key:byte(i) or 0
        ipad[i] = string.char(bxor(b, 0x36))
        opad[i] = string.char(bxor(b, 0x5C))
    end

    return crypt.tohex(crypt.hash(table.concat(opad) .. crypt.hash(table.concat(ipad) .. data, algorithm), algorithm))
end)

add("crypt.tohex", function(str)
    assert(type(str) == "string", "expected string, got " .. type(str))
    return (str:gsub(".", function(c)
        return string.format("%02x", string.byte(c))
    end))
end)

add("crypt.fromhex", function(str)
    assert(type(str) == "string", "expected string, got " .. type(str))
    assert(#str % 2 == 0, "hex string must have even length")
    return (str:gsub("%x%x", function(c)
        return string.char(tonumber(c, 16))
    end))
end)

add("crypt.lz4", function(data, step)
    assert(type(data) == "string", "data must be string")

    local out
    if step == true then -- encrypt
        out = lz4compress(data)
    else
        out = lz4decompress(data)
    end
    return out
end)

-- Oth

local hooks = {}
local hook_threads, og_threads = setmetatable({}, {__mode = "k"}), setmetatable({}, {__mode = "k"})

add("oth.hook", function(target, hookfn)
    assert(type(target) == "function", "target must be function")
    assert(type(hookfn) == "function", "hook must be function")

    hooks[target] = hooks[target] or {}

    local original = target

    local callback = function(...)
        return original(...)
    end

    local function wrapper(...)
        local caller = coroutine.running()

        local co = coroutine.create(function(...)
            local current = coroutine.running()
            hook_threads[current] = true
            og_threads[current] = caller

            return hookfn(...)
        end)

        local ok, result = coroutine.resume(co, ...)
        if not ok then
            error(result)
        end

        return result
    end

    table.insert(hooks[target], {
        hook = hookfn,
        wrapper = wrapper,
        callback = callback
    })

    return callback
end)

add("oth.unhook", function(target, hook_or_callback)
    local list = hooks[target]
    if not list then
        return false
    end

    for i,v in ipairs(list) do
        if v.hook == hook_or_callback or v.callback == hook_or_callback or hook_or_callback == nil then
            table.remove(list, i)

            if #list == 0 then
                hooks[target] = nil
            end

            return true
        end
    end

    return false
end)

add("oth.get_root_callback", function(target)
    local list = hooks[target]
    if not list or #list == 0 then
        return target
    end

    return list[1].callback
end)

add("oth.is_hook_thread", function()
    return hook_threads[coroutine.running()] == true
end)

add("oth.get_original_thread", function()
    return og_threads[coroutine.running()]
end)

-- Debug

add("debug.validlevel", function(level)
    return debug.getinfo(level + 2) ~= nil
end)

add("debug.isvalidlevel", function(level)
    assert(type(level) == "number", "expected number, got " .. type(level))
    return level >= 0
end)

add("debug.getregistry", function()
    return getreg and getreg() or {}
end)

local constants = {}
add("debug.getconstant", function(func, index)
    assert(type(func) == "function", "expected function, got " .. type(func))
    assert(type(index) == "number", "expected number for index, got " .. type(index))
    local c = constants[func]
    if not c or c[index] == nil then
        error("constant does not exist at index " .. index)
    end
    return c[index]
end)

add("debug.getconstants", function(func)
    assert(type(func) == "function", "expected function, got " .. type(func))
    return constants[func] or {}
end)

add("debug.setconstant", function(func, index, value)
    assert(type(func) == "function", "expected function, got " .. type(func))
    assert(type(index) == "number", "expected number for index, got " .. type(index))
    constants[func] = constants[func] or {}
    constants[func][index] = value
end)

local upvalues = {}
add("debug.getupvalue", function(func, index)
    assert(type(func) == "function", "expected function, got " .. type(func))
    assert(type(index) == "number", "expected number for index, got " .. type(index))
    local u = upvalues[func]
    if not u or u[index] == nil then
        return nil  -- out of range, just return nil like standard Lua
    end
    return u[index]
end)

add("debug.getupvalues", function(func)
    assert(type(func) == "function", "expected function, got " .. type(func))
    return upvalues[func] or {}
end)

add("debug.setupvalue", function(func, index, value)
    assert(type(func) == "function", "expected function, got " .. type(func))
    assert(type(index) == "number", "expected number for index, got " .. type(index))
    upvalues[func] = upvalues[func] or {}
    upvalues[func][index] = value
end)

local stacks = {}
add("debug.getstack", function(level, index)
    assert(type(level) == "number", "expected number for level, got " .. type(level))
    local stack = stacks[level]
    if not stack then
        error("invalid stack level: " .. level)
    end

    if index then
        assert(type(index) == "number", "expected number for index, got " .. type(index))
        if stack[index] == nil then
            error("stack value does not exist at index " .. index)
        end
        return stack[index]
    end

    return stack
end)

add("debug.setstack", function(level, index, value)
    assert(type(level) == "number", "expected number for level, got " .. type(level))
    assert(type(index) == "number", "expected number for index, got " .. type(index))
    stacks[level] = stacks[level] or {}
    stacks[level][index] = value
end)

local debug_override = setmetatable({}, {__mode = "k"})
add("debug.setinfo", function(func, info)
    assert(type(func) == "function", "expected function")
    assert(type(info) == "table", "expected table")

    debug_override[func] = info
end)

add("debug.info", function(func, what)
    if type(func) ~= "function" then return end

    local override = debug_override[func]

    local map = {
        s = override and override.short_src,
        n = override and override.name,
        l = override and override.currentline,
        f = func
    }

    local results = {}

    for i = 1, #what do
        local c = what:sub(i,i)

        if map[c] ~= nil then
            table.insert(results, map[c])
        else
            if c == "s" then
                table.insert(results, "unknown")
            elseif c == "n" then
                table.insert(results, nil)
            elseif c == "l" then
                table.insert(results, 0)
            elseif c == "f" then
                table.insert(results, func)
            end
        end
    end

    return table.unpack(results)
end)

add("debug.getproto", function()
    return nil
end)

add("debug.getprotos", function()
    return {}
end)

local old_traceback
old_traceback = hookfunction(debug.traceback, function(...)
    local tb = old_traceback(...)

    for func, hidden in pairs(tback_ignore) do
        if hidden then
            local name = tostring(func)
            tb = tb:gsub(".-"..name..".-\n", "")
        end
    end

    return tb
end)

add("debug.getcallstack", function()
    local stack = {}
    local level = 1
    while true do
        local info = debug.getinfo(level + 1)  -- use native, not the overridden one
        if not info then break end
        stack[#stack + 1] = {
            func = info.func,
            name = info.name,
            source = info.short_src,
            line = info.currentline
        }
        level += 1
    end
    return stack
end)

-- Drawing

local Drawing = {
    Fonts = {
        UI = 0,
        System = 1,
        Plex = 2,
        Monospace = 3,
    },
    new = function(Type)
        assert(type(Type) == "string", "expected string for Type, got " .. type(Type))
        local validTypes = {Line = true, Square = true, Circle = true, Text = true}
        assert(validTypes[Type], "invalid drawing type: " .. Type)

        local Object = Create("Frame", {
            Visible = true,
            Size = UDim2_fromOffset(0, 0),
            BackgroundColor3 = Color3.new(0, 0, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 1,
            Parent = UI
        })

        local self = {
            Visible = Object.Visible,
            Color = Object.BackgroundColor3,
            Transparency = 1,
            ZIndex = Object.ZIndex,
            Remove = function() Object:Destroy() end
        }

        self.Destroy = self.Remove

        local function Construct(Update, Defaults, Default, Readonly)
            Readonly = Readonly or {}
            local function inlined()
                if not Default then
                    Object.Visible = self.Visible
                    Object.BackgroundColor3 = self.Color
                    Object.BackgroundTransparency = 1 - self.Transparency
                    Object.ZIndex = clamp(self.ZIndex, -B, B)
                end
                Update()
            end

            for i, v in next, Defaults do
                self[i] = v
            end

            local proxy = newproxy(true)
            local mt = getmetatable(proxy)

            mt.__index = function(_, b)
                return self[b]
            end
            mt.__newindex = function(_, Key, Value)
                if tfind(Readonly, Key) then return end
                self[Key] = Value
                inlined()
            end
            mt.__metatable = "This metatable is protected."

            tinsert(DrawingCache, {proxy = proxy, instance = Object})

            return proxy
        end

        if Type == "Line" then
            return Construct(function()
                local from, to = self.From, self.To
                local dX, dY = to.X - from.X, to.Y - from.Y
                Object.Size = UDim2_fromOffset(sqrt(dX ^ 2 + dY ^ 2), self.Thickness)
                Object.Position = UDim2_fromOffset(from.X, from.Y)
                Object.Rotation = deg(atan2(dY, dX))
            end, {
                Thickness = 1,
                From = Vector2.zero,
                To = Vector2.zero
            })
        elseif Type == "Square" then
            local Stroke = Create("UIStroke", {
                Parent = Object,
                Color = self.Color,
                Enabled = true,
                Thickness = 1
            })

            return Construct(function()
                Object.Size = UDim2.new(0, self.Size.X, 0, self.Size.Y)
                Object.Position = UDim2.new(0, self.Position.X, 0, self.Position.Y)
                Stroke.Enabled = self.Filled
                Stroke.Color = self.Color
                Stroke.Thickness = self.Thickness
            end, {
                Size = Vector2.zero,
                Position = Vector2.zero,
                Filled = false,
                Thickness = 1,
                Transparency = 0
            })
        elseif Type == "Circle" then
            local Stroke = Create("UIStroke", {
                Parent = Object,
                Color = self.Color,
                Enabled = true
            })
            Create("UICorner", {
                Parent = Object,
                CornerRadius = UDim.new(1, 0)
            })

            return Construct(function()
                Object.Size = UDim2.fromScale(self.Radius, self.Radius)
                Object.Position = UDim2.fromScale(self.Position.X, self.Position.Y)
                Stroke.Enabled = not self.Filled
                Stroke.Color = self.Color
                Stroke.Thickness = self.Thickness
            end, {
                Thickness = 1,
                NumSides = 0,
                Radius = 1,
                Filled = false,
                Position = Vector2.zero
            })
        elseif Type == "Text" then
            Object:Destroy()
            Object = Create("TextLabel", {
                Parent = UI,
                Visible = self.Visible,
                Size = UDim2.fromOffset(0, 0),
                BackgroundColor3 = self.Color,
                BackgroundTransparency = 1 - self.Transparency,
                BorderSizePixel = 0,
                TextStrokeColor3 = self.Color,
                TextStrokeTransparency = 1,
                TextSize = self.Size,
                TextWrapped = false
            })

            return Construct(function()
                Object.Size = UDim2.fromOffset(self.Size * 3, self.Size / 2)
                Object.Position = UDim2.fromOffset(self.Position.X, self.Position.Y)
                Object.Text = self.Text
                Object.Font = Fonts[self.Font]
                Object.TextColor3 = self.Color
                Object.BackgroundTransparency = 1 - self.Transparency

                if self.Center then
                    Object.TextXAlignment = Enum.TextXAlignment.Center
                    Object.TextYAlignment = Enum.TextYAlignment.Center
                else
                    Object.TextXAlignment = Enum.TextXAlignment.Left
                    Object.TextYAlignment = Enum.TextYAlignment.Top
                end

                Object.TextStrokeTransparency = self.Outline and 0 or 1
                Object.TextStrokeColor3 = self.OutlineColor
                self.TextBounds = Object.TextBounds
            end, {
                Text = "",
                Size = 0,
                Center = false,
                Outline = false,
                OutlineColor = self.Color,
                Position = Vector2.zero,
                Font = 3
            }, true, {"TextBounds"})
        end
    end
}

add("isrenderobj", function(a)
    for _, object in next, DrawingCache do
        if object.proxy == a then
            return true
        end
    end
    return false
end)

add("cleardrawcache", function()
    for _, Object in next, DrawingCache do
        Object.instance:Destroy()
    end
end)

add("getrenderproperty", function(a, b)
    assert(isrenderobj(a), "Invalid argument #1 to 'getrenderproperty', render object expected, got " .. type(a))
    assert(type(b) == "string", "expected string for property, got " .. type(b))
    return a[b]
end)

add("setrenderproperty", function(a, b, c)
    assert(isrenderobj(a), "Invalid argument #1 to 'setrenderproperty', render object expected, got " .. typeof(a))
    assert(type(b) == "string", "expected string for property, got " .. type(b))
    a[b] = c
end)

-- File System

local function normalize(path)
    path = tostring(path or "")
    path = path:gsub("\\", "/")
    path = path:gsub("^/", "")
    return path
end

local function parent(path)
    return path:match("(.+)/[^/]+$") or ""
end

local fs_files = {}
local fs_folders = {[""] = true}

add("writefile", function(path, data)
    assert(type(path) == "string", "expected string for path, got " .. type(path))
    assert(type(data) == "string", "expected string for data, got " .. type(data))
    path = normalize(path)
    fs_files[path] = data
    fs_folders[parent(path)] = true
end)

add("appendfile", function(path, data)
    assert(type(path) == "string", "expected string for path, got " .. type(path))
    assert(type(data) == "string", "expected string for data, got " .. type(data))
    path = normalize(path)
    fs_files[path] = (fs_files[path] or "") .. data
    fs_folders[parent(path)] = true
end)

add("readfile", function(path)
    assert(type(path) == "string", "expected string for path, got " .. type(path))
    path = normalize(path)
    if fs_files[path] == nil then
        error("file does not exist: " .. path)
    end
    return fs_files[path]
end)

add("isfile", function(path)
    assert(type(path) == "string", "expected string for path, got " .. type(path))
    path = normalize(path)
    return fs_files[path] ~= nil
end)

add("makefolder", function(path)
    assert(type(path) == "string", "expected string for path, got " .. type(path))
    path = normalize(path)
    fs_folders[path] = true
end)

add("isfolder", function(path)
    assert(type(path) == "string", "expected string for path, got " .. type(path))
    path = normalize(path)
    return fs_folders[path] == true
end)

add("listfiles", function(path)
    assert(type(path) == "string", "expected string for path, got " .. type(path))
    path = normalize(path)
    local out = {}

    for f, _ in pairs(fs_files) do
        if f:sub(1, #path) == path then
            table.insert(out, f)
        end
    end

    for f, _ in pairs(fs_folders) do
        if f ~= "" and f:sub(1, #path) == path then
            table.insert(out, f)
        end
    end

    return out
end)

add("delfile", function(path)
    assert(type(path) == "string", "expected string for path, got " .. type(path))
    path = normalize(path)
    assert(fs_files[path] ~= nil, "file does not exist: " .. path)
    fs_files[path] = nil
end)

add("delfolder", function(path)
    assert(type(path) == "string", "expected string for path, got " .. type(path))
    path = normalize(path)

    for f, _ in pairs(fs_files) do
        if f:sub(1, #path) == path then
            fs_files[f] = nil
        end
    end

    for f, _ in pairs(fs_folders) do
        if f:sub(1, #path) == path then
            fs_folders[f] = nil
        end
    end
end)

add("loadfile", function(path, chunkname)
    assert(type(path) == "string", "expected string for path, got " .. type(path))
    local ok, src = pcall(readfile, path)
    if not ok then
        return nil, src
    end

    local fn, err = loadstring(src, chunkname or path)
    if not fn then
        return nil, err
    end

    setfenv(fn, getgenv())
    return fn
end)

add("dofile", function(path)
    assert(type(path) == "string", "expected string for path, got " .. type(path))
    local fn, err = loadfile(path)
    return fn()
end)

-- Input

local vim = game:GetService("VirtualInputManager")
local uis = game:GetService("UserInputService")

add("isrbxactive", function()
    return uis.WindowFocused
end)

add("mouse1press", function()
    vim:SendMouseButtonEvent(mouse.X, mouse.Y, 0, true, game, 0)
end)

add("mouse1release", function()
    vim:SendMouseButtonEvent(mouse.X, mouse.Y, 0, false, game, 0)
end)

add("mouse1click", function()
    vim:SendMouseButtonEvent(mouse.X, mouse.Y, 0, true, game, 0)
    vim:SendMouseButtonEvent(mouse.X, mouse.Y, 0, false, game, 0)
end)

add("mouse2click", function()
    vim:SendMouseButtonEvent(mouse.X, mouse.Y, 1, true, game, 0)
    vim:SendMouseButtonEvent(mouse.X, mouse.Y, 1, false, game, 0)
end)

add("mouse2release", function()
    vim:SendMouseButtonEvent(0, 0, 1, false, game, 0)
end)

add("mousemoveabs", function(x, y)
    assert(type(x) == "number", "expected number for x, got " .. type(x))
    assert(type(y) == "number", "expected number for y, got " .. type(y))
    vim:SendMouseMoveEvent(x, y, game)
end)

add("mousemoverel", function(x, y)
    assert(type(x) == "number", "expected number for x, got " .. type(x))
    assert(type(y) == "number", "expected number for y, got " .. type(y))
    local pos = uis:GetMouseLocation()
    vim:SendMouseMoveEvent(pos.X + x, pos.Y + y, game)
end)

add("mousescroll", function(pixels)
    assert(type(pixels) == "number", "expected number for pixels, got " .. type(pixels))
    vim:SendMouseWheelEvent(0, 0, pixels > 0, game)
end)

-- Instance

local lp = game:GetService("Players").LocalPlayer
local char = lp.Character
local hrp = char.HumanoidRootPart

add("fireclickdetector", function(cd, distance)
    assert(typeof(cd) == "Instance" and cd:IsA("ClickDetector"), "expected ClickDetector, got " .. typeof(cd))
    distance = distance or 0

    local old = hrp.CFrame
    if cd.Parent and distance ~= 0 then
        hrp.CFrame = cd.Parent.CFrame
    end

    cd.MaxActivationDistance = math.huge
    cd:InputHoldBegin()
    cd:InputHoldEnd()

    hrp.CFrame = old
end)

add("firetouchinterest", function(part, state)
    assert(typeof(part) == "Instance" and part:IsA("BasePart"), "expected BasePart, got " .. typeof(part))
    assert(type(state) == "number", "expected number for state, got " .. type(state))

    if state == 0 then
        hrp.CFrame = part.CFrame
    end
end)

add("isnetworkowner", function(part)
    assert(typeof(part) == "Instance" and part:IsA("BasePart"), "expected BasePart, got " .. typeof(part))
    return part:GetNetworkOwner() == lp
end)

add("getcallbackvalue", function(obj, property)
    assert(typeof(obj) == "Instance", "expected Instance, got " .. typeof(obj))
    assert(type(property) == "string", "expected string for property, got " .. type(property))
end)

add("fireproximityprompt", function(prompt)
    assert(typeof(prompt) == "Instance" and prompt:IsA("ProximityPrompt"), "expected ProximityPrompt, got " .. typeof(prompt))

    local old = prompt.HoldDuration
    prompt.HoldDuration = 0
    prompt:InputHoldBegin()
    prompt:InputHoldEnd()
    prompt.HoldDuration = old
end)

local signal_store = setmetatable({}, {__mode = "k"})

add("getconnections", function(signal)
    assert(typeof(signal) == "RBXScriptSignal", "expected RBXScriptSignal, got " .. typeof(signal))
    return signal_store[signal] or {}
end)

add("getconnection", function(signal)
    assert(typeof(signal) == "RBXScriptSignal", "expected RBXScriptSignal, got " .. typeof(signal))
    local t = signal_store[signal]
    return t and t[1]
end)

add("firesignal", function(signal, ...)
    assert(typeof(signal) == "RBXScriptSignal", "expected RBXScriptSignal, got " .. typeof(signal))
    local t = signal_store[signal]
    if not t then return end

    for _, conn in ipairs(t) do
        if conn.Function then
            task.spawn(conn.Function, ...)
        end
    end
end)

add("getcustomasset", function(path)
    assert(type(path) == "string", "expected string for path, got " .. type(path))
    if not isfile(path) then
        error("file does not exist: " .. path)
    end

    local name = path:match("[^/\\]+$")
    local new = "content/" .. name

    if not isfile(new) then
        writefile(new, readfile(path))
    end

    return "rbxasset://" .. new
end)

local ugc = game:GetService("UGCValidationService")

add("gethiddenproperty", function(object, property)
    assert(typeof(object) == "Instance", "expected Instance, got " .. typeof(object))
    assert(type(property) == "string", "expected string for property, got " .. type(property))
    return ugc:GetPropertyValue(object, property)
end)

add("sethiddenproperty", function(object, property, value)
    assert(typeof(object) == "Instance", "expected Instance, got " .. typeof(object))
    assert(type(property) == "string", "expected string for property, got " .. type(property))
    return ugc:SetPropertyValue(object, property, value)
end)

add("setsimulationradius", function(simrad, maxsimrad)
    assert(type(simrad) == "number", "expected number for simrad, got " .. type(simrad))
    sethiddenproperty(lp, "SimulationRadius", simrad)
    sethiddenproperty(lp, "MaxSimulationRadius", maxsimrad or simrad)
end)

add("getsimulationradius", function()
    return lp.SimulationRadius
end)

add("gethui", function()
    return cloneref(game:GetService("CoreGui")).RobloxGui
end)

add("getinstances", function()
    local t = {game}
    for _, v in ipairs(game:GetDescendants()) do
        t[#t + 1] = v
    end
    return t
end)

local objs = {}
for _,v in ipairs(game:GetDescendants()) do
    objs[v] = true
end

add("getnilinstances", function()
    local nils = {}

    for obj in pairs(objs) do
        if obj.Parent == nil then
            table.insert(nils, obj)
        end
    end

    return nils
end)

add("getnilinstance", function(search)
    -- search = string
    for _, item in ipairs(getnilinstances()) do
        if item == search then
            return item
        end
    end
end)

local function isScript(obj, includem) -- ~Script
    local a = false
    if includem then
        if obj:IsA("LocalScript") or obj:IsA("ModuleScript") then
            a = true
        end
    else
        if obj:IsA("LocalScript") then
            a = true
        end
    end
    return a
end

local scripts = {}
game.DescendantAdded:Connect(function(obj)
    if isScript(obj, true) then
        scripts[#scripts + 1] = obj
    end
    objs[obj] = true
end)

game.DescendantRemoving:Connect(function(obj)
    objs[obj] = nil
    for i, v in ipairs(scripts) do
        if v == obj then
            table.remove(scripts, i)
            break
        end
    end
end)

add("isscriptable", function(obj, prop)
    assert(typeof(obj) == "Instance", "expected Instance, got " .. typeof(obj))
    assert(type(prop) == "string", "expected string for prop, got " .. type(prop))

    if obj[prop] ~= nil then
        return true
    end

    local ok = pcall(function() return obj:GetPropertyChangedSignal(prop) end)
    if ok then
        return false
    end

    return nil
end)

add("setscriptable", function(object, property, value)
    assert(typeof(object) == "Instance", "expected Instance, got " .. typeof(object))
    assert(type(property) == "string", "expected string for property, got " .. type(property))
end)

add("setrbxclipboard", function(data)
    assert(type(data) == "string", "expected string, got " .. type(data))
end)

add("getrendersteppedlist", function()
    return {}
end)

add("replicatesignal", function(signal, ...)
    assert(typeof(signal) == "RBXScriptSignal", "expected RBXScriptSignal, got " .. typeof(signal))
end)

-- Metatable

add("getrawmetatable", function(object)
    assert(type(object) == "table" or typeof(object) == "Instance", "expected table or Instance, got " .. typeof(object))

    local mt = getmetatable(object)

    if type(mt) == "table" and mt.__metatable ~= nil then
        local copy = {}
        for k, v in pairs(mt) do
            copy[k] = v
        end
        copy.__metatable = nil
        return copy
    end

    return mt
end)

add("setrawmetatable", function(object, mt)
    assert(type(object) == "table" or typeof(object) == "Instance", "expected table or Instance, got " .. typeof(object))
    assert(type(mt) == "table", "expected table for mt, got " .. type(mt))

    local old = getmetatable(object)
    if type(old) == "table" then
        old.__metatable = nil
    end

    setmetatable(object, mt)
end)

add("hookmetamethod", function(object, method, hook)
    assert(type(method) == "string", "expected string for method, got " .. type(method))
    assert(type(hook) == "function", "expected function for hook, got " .. type(hook))

    local mt = getrawmetatable(object)
    assert(mt, "no metatable on object")

    local old = mt[method]
    assert(old, "method does not exist: " .. method)

    mt[method] = function(...)
        return hook(old, ...)
    end

    return function(...)
        return old(...)
    end
end)

local namecallmethod = nil
add("getnamecallmethod", function()
    return namecallmethod
end)

add("setnamecallmethod", function(method)
    assert(type(method) == "string", "expected string, got " .. type(method))
    namecallmethod = method
end)

add("isreadonly", function(object)
    assert(type(object) == "table", "expected table, got " .. type(object))
    return table.isfrozen(object)
end)

add("setreadonly", function(object, readonly)
    assert(type(object) == "table", "expected table, got " .. type(object))
    assert(type(readonly) == "boolean", "expected boolean for readonly, got " .. type(readonly))
    if readonly then
        table.freeze(object)
    else
        object = table.clone(object)
        return object -- so like uhm not good
    end
end)

add("makewriteable", function(object)
    assert(type(object) == "table", "expected table, got " .. type(object))
    local clone = table.clone(object)
    return clone
end)

add("makereadonly", function(object)
    assert(type(object) == "table", "expected table, got " .. type(object))
    setreadonly(object, true)
end)

-- Misc

add("identifyexecutor", function()
    return "Potassium", "1.0"
end)

-- RLE Compression (not lz4)
add("lz4compress", function(data)
    assert(type(data) == "string", "expected string, got " .. type(data))
    local out, i = {}, 1
    while i <= #data do
        local char = data:sub(i, i)
        local count = 1
        while i + count <= #data and data:sub(i + count, i + count) == char and count < 255 do
            count += 1
        end
        if count > 1 then
            out[#out + 1] = string.char(count)
        end
        out[#out + 1] = char
        i += count
    end
    return table.concat(out)
end)

add("lz4decompress", function(data)
    assert(type(data) == "string", "expected string, got " .. type(data))
    local out, i = {}, 1
    while i <= #data do
        local byte = data:byte(i)
        if byte > 127 and i + 1 <= #data then
            out[#out + 1] = string.rep(data:sub(i + 1, i + 1), byte - 128)
            i += 2
        else
            out[#out + 1] = data:sub(i, i)
            i += 1
        end
    end
    return table.concat(out)
end)

local mboxParent = Instance.new("Folder", gethui())
mboxParent.Name = "mboxes"

add("messagebox", function(text, caption, flags)
    assert(type(text) == "string", "expected string for text, got " .. type(text))
    assert(type(caption) == "string", "expected string for caption, got " .. type(caption))

    local gui = Instance.new("ScreenGui")
    gui.Name = tostring(math.random(1e4, 1e5))
    gui.Parent = mboxParent

    local window = Instance.new("Frame")
    window.Size = UDim2.fromOffset(349, 151)
    window.Position = UDim2.new(0.5, -174, 0.5, -75)
    window.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    window.Draggable = true
    window.BorderSizePixel = 0
    window.ClipsDescendants = true
    window.Parent = gui

    local wc = Instance.new("UICorner", window)
    wc.CornerRadius = UDim.new(0, 8)

    local strip = Instance.new("Frame")
    strip.Size = UDim2.fromOffset(349, 35)
    strip.Position = UDim2.fromOffset(0, 0)
    strip.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
    strip.BorderSizePixel = 0
    strip.ClipsDescendants = true
    strip.Parent = window

    Instance.new("UICorner", strip).CornerRadius = wc.CornerRadius

    local title = Instance.new("TextLabel")
    title.Size = UDim2.fromOffset(260, 18)
    title.Position = UDim2.fromOffset(14, 10)
    title.BackgroundTransparency = 1
    title.Text = caption
    title.Font = Enum.Font.SourceSans
    title.TextSize = 16
    title.TextColor3 = Color3.fromRGB(0, 0, 0)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = window

    local close = Instance.new("TextButton")
    close.Size = UDim2.fromOffset(20, 20)
    close.Position = UDim2.fromOffset(321, 8)
    close.Text = "X"
    close.Font = Enum.Font.SourceSansBold
    close.TextSize = 16
    close.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    close.BackgroundTransparency = 0.8
    close.TextColor3 = Color3.fromRGB(0, 0, 0)
    close.Parent = window

    close.MouseButton1Click:Connect(function() gui:Destroy() end)
    close.MouseEnter:Connect(function() close.BackgroundColor3 = Color3.fromRGB(255, 0, 0) end)
    close.MouseLeave:Connect(function() close.BackgroundColor3 = Color3.fromRGB(255, 255, 255) end)

    local msg = Instance.new("TextLabel")
    msg.Size = UDim2.fromOffset(250, 20)
    msg.Position = UDim2.fromOffset(54, 58)
    msg.BackgroundTransparency = 1
    msg.Text = text
    msg.Font = Enum.Font.SourceSans
    msg.TextSize = 14
    msg.TextColor3 = Color3.fromRGB(0, 0, 0)
    msg.TextXAlignment = Enum.TextXAlignment.Left
    msg.Parent = window

    local strip2 = Instance.new("Frame")
    strip2.Size = UDim2.fromOffset(349, 38)
    strip2.Position = UDim2.fromOffset(0, window.Size.Y.Offset - 38)
    strip2.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
    strip2.BorderSizePixel = 0
    strip2.ClipsDescendants = true
    strip2.Parent = window

    local s2c = Instance.new("UICorner")
    s2c.CornerRadius = wc.CornerRadius
    s2c.Parent = strip2

    local function createBtn(btnText, pos)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.fromOffset(72, 26)
        btn.Position = UDim2.fromOffset(pos, 5.8)
        btn.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
        btn.Text = btnText
        btn.Font = Enum.Font.SourceSans
        btn.TextSize = 14
        btn.TextColor3 = Color3.fromRGB(0, 0, 0)
        btn.ClipsDescendants = true
        btn.Parent = strip2

        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

        local stroke = Instance.new("UIStroke", btn)
        stroke.Color = Color3.fromRGB(200, 200, 200)
        stroke.Thickness = 1
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

        return btn
    end

    local ok = createBtn("OK", 263)
    ok.MouseButton1Click:Connect(function() gui:Destroy() end)
end)

add("queue_on_teleport", function(code)
    assert(type(code) == "string", "expected string, got " .. type(code))
end)

add("request", function(options)
    assert(type(options) == "table", "expected table for options, got " .. type(options))
    local url = options.Url
    assert(type(url) == "string" and #url > 0, "expected non-empty string for Url")

    local method = (options.Method or "GET"):upper()
    local body = options.Body or ""

    local success, result = pcall(function()
        if method == "GET" then
            return game:HttpGet(url, true)
        elseif method == "POST" then
            return game:HttpPost(url, body, Enum.HttpContentType.ApplicationUrlEncoded)
        else
            error("Unsupported method: " .. method)
        end
    end)

    return {
        StatusCode = success and 200 or 500,
        Body = success and result or tostring(result),
        Headers = {},
    }
end)

add("getinternalparent", function(instance)
    assert(typeof(instance) == "Instance", "expected Instance, got " .. typeof(instance))
    return instance.Parent
end)

add("setinternalparent", function(instance, newparent)
    assert(typeof(instance) == "Instance", "expected Instance, got " .. typeof(instance))
    assert(typeof(newparent) == "Instance" or newparent == nil, "expected Instance or nil for newparent")
    instance.Parent = newparent
end)

add("getfflag", function(fflag)
    assert(type(fflag) == "string", "expected string, got " .. type(fflag))
    return game:GetFastFlag(fflag:gsub("^FFlag", ""))
end)

add("setfflag", function(fflag, value)
    assert(type(fflag) == "string", "expected string for fflag, got " .. type(fflag))
    assert(type(value) == "string", "expected string for value, got " .. type(value))
    game:SetFastFlag(fflag:gsub("^FFlag", ""), value)
end)

add("setclipboard", function(text)
    assert(type(text) == "string", "expected string, got " .. type(text))
    print(text)
end)

local fps = workspace:GetRealPhysicsFPS()
add("setfpscap", function(f)
    assert(type(f) == "number", "expected number, got " .. type(f))
    assert(f > 0, "fps cap must be greater than 0")
    fps = f
end)

add("getfpscap", function()
    return fps
end)

-- Scripts

add("getscriptclosure", function(scr)
    assert(typeof(scr) == "Instance", "expected Instance, got " .. typeof(scr))
    assert(scr:IsA("ModuleScript"), "expected ModuleScript, got " .. scr.ClassName)
    return function(...)
        return require(scr)(...)
    end
end)

add("getscriptbytecode", function(item)
    assert(typeof(item) == "Instance", "expected Instance, got " .. typeof(item))
    return decompile(item)
end)

add("getscripthash", function(item)
    assert(typeof(item) == "Instance", "expected Instance, got " .. typeof(item))
    return crypt.hash(getscriptbytecode(item))
end)

for _, v in ipairs(game:GetDescendants()) do
    if isScript(v, true) then
        scripts[#scripts + 1] = v
    end
end

add("getrunningscripts", function()
    local out = {}
    for _, item in ipairs(scripts) do
        if isScript(item, false) then
            out[#out + 1] = item
        end
    end
    return out
end)

add("getscripts", function()
    return scripts
end)

add("getloadedmodules", function()
    local modules = {}
    for _, s in ipairs(scripts) do
        if s:IsA("ModuleScript") then
            modules[#modules + 1] = s
        end
    end
    return modules
end)

add("isrequired", function(module)
    assert(typeof(module) == "Instance" and module:IsA("ModuleScript"), "expected ModuleScript, got " .. typeof(module))

    local loaded = getloadedmodules()
    for _, item in ipairs(loaded) do
        if item == module then
            return true
        end
    end
    return false
end)

add("getdeletedactors", function()
    local del_actors = {}

    for _, item in ipairs(getnilinstances()) do
        if item:IsA("Actor") then
            table.insert(del_actors, item)
        end
    end
    return del_actors
end)

local trgr, trgc = {}, {}

local function track(obj)
    if type(obj) == "table" or type(obj) == "function" or type(obj) == "thread" or type(obj) == "userdata" then
        trgr[#trgr + 1] = obj
        trgc[#trgc + 1] = obj
    end
    return obj
end

local function sr(root, seen)
    if root == nil then return end
    seen = seen or {}
    if seen[root] then return end
    seen[root] = true

    if type(root) == "table" then
        track(root)
        for k,v in pairs(root) do
            sr(k, seen)
            sr(v, seen)
        end
        local mt = getmetatable(root)
        if mt then sr(mt, seen) end
    elseif type(root) == "function" then
        track(root)
        local i = 1
        while true do
            local ok, name, val = pcall(debug.getupvalue, root, i)
            if not ok or not name then break end
            sr(val, seen)
            i += 1
        end
    elseif type(root) == "thread" or type(root) == "userdata" then
        track(root)
    end
end

sr(getgenv())

add("getreg", function()
    return trgr
end)

add("getgc", function()
    return trgc
end)

add("filtergc", function(filter)
    local results = {}
    for _, obj in ipairs(trgc) do
        if type(filter) == "string" then
            if type(obj) == filter then
                results[#results + 1] = obj
            end
        elseif type(filter) == "function" then
            if filter(obj) then
                results[#results + 1] = obj
            end
        end
    end
    return results
end)

local renv = {DockWidgetPluginGuiInfo,warn,tostring,gcinfo,os,tick,task,getfenv,debug,NumberSequence,assert,rawlen,wait,Color3,Enum,Delay,OverlapParams,Path2DControlPoint,SecurityCapabilities,_G,AdReward,UserSettings,shared,Faces,error,coroutine,string,NumberRange,buffer,PhysicalProperties,Instance,printidentity,PluginManager,FloatCurveKey,delay,Ray,NumberSequenceKeypoint,Version,Vector2,newproxy,Game,Content,spawn,rawget,stats,xpcall,ColorSequence,Vector2int16,Workspace,print,SharedTable,typeof,UDim2,RaycastParams,unpack,TweenInfo,loadstring,require,Vector3,pairs,Vector3int16,setmetatable,elapsedTime,pcall,bit32,DateTime,ipairs,table,workspace,version,Region3int16,collectgarbage,game,getmetatable,Spawn,UDim,Region3,utf8,_VERSION,CFrame,rawset,PathWaypoint,CellId,Font,PluginDrag,settings,rawequal,math,CatalogSearchParams,Random,ValueCurveKey,ypcall,type,next,ElapsedTime,select,tonumber,Stats,Wait,time,Rect,BrickColor,setfenv,vector,Axes,ColorSequenceKeypoint,RotationCurveKey}
add("getrenv", function()
    return renv
end)

add("gettenv", function(obj)
    return getfenv(obj)
end)

add("getsenv", function(scr)
    assert(typeof(scr) == "Instance" and scr:IsA("LocalScript"), "expected LocalScript, got " .. typeof(scr))
    return getfenv(0)
end)

local function test()
    if pcall(function() return game.CoreGui end) then
        return 7
    end

    if pcall(function() return game:GetService("LogService"):GetLogHistory() end) then
        return 6
    end

    if pcall(function() return game:GetService("Players").LocalPlayer end) then
        return 5
    end

    return 2
end

local thread_identity = 1
add("getthreadidentity", function()
    if thread_identity == 1 then
        return test()
    end
    return thread_identity
end)

add("setthreadidentity", function(identity)
    assert(type(identity) == "number", "expected number, got " .. type(identity))
    thread_identity = identity
end)

add("setidentity", function(identity)
    assert(type(identity) == "number", "expected number, got " .. type(identity))
    setthreadidentity(identity)
end)

add("getidentity", function()
    return getthreadidentity()
end)

add("printidentity", function()
   print("Current identity is", getthreadidentit())
end)

-- Actors

local actor_threads = setmetatable({}, {__mode = "v"})
local comm_channels = {}

local function createBindable()
    return Instance.new("BindableEvent")
end

add("create_comm_channel", function()
    local num = math.random(1, 99999)
    local int = createBindable()
    comm_channels[num] = int
    return num, int
end)

add("get_comm_channel", function(id)
    assert(type(id) == "number", "expected number for id, got " .. type(id))
    return comm_channels[id]
end)

add("run_on_actor", function(actor, scriptStr, ...)
    assert(typeof(actor) == "Instance" and actor:IsA("Actor"), "expected Actor, got " .. typeof(actor))
    assert(type(scriptStr) == "string", "expected string for script, got " .. type(scriptStr))

    local thread = task.spawn(function(...)
        local fn, err = loadstring(scriptStr)
        if not fn then error(err) end
        setfenv(fn, getgenv())
        fn(...)
    end, ...)

    actor_threads[#actor_threads + 1] = thread
end)

add("getactors", function()
    local actors = {}
    for _, v in ipairs(game:GetDescendants()) do
        if v:IsA("Actor") then
            actors[#actors + 1] = v
        end
    end
    return actors
end)

add("is_parallel", function()
    return getthreadidentity() >= 8
end)

add("run_on_thread", function(thread, scriptStr, ...)
    assert(type(thread) == "thread", "expected thread, got " .. type(thread))
    assert(type(scriptStr) == "string", "expected string for script, got " .. type(scriptStr))

    local fn, err = loadstring(scriptStr)
    if not fn then error(err) end
    setfenv(fn, getgenv())

    local t = task.spawn(function(...)
        coroutine.resume(thread, fn, ...)
    end, ...)

    actor_threads[#actor_threads + 1] = t
end)

add("getactorthreads", function()
    local alive = {}
    for _, t in ipairs(actor_threads) do
        if coroutine.status(t) ~= "dead" then
            alive[#alive + 1] = t
        end
    end
    return alive
end)

-- Loader

for name, func in pairs(functions) do
    if typeof(name) ~= "string" or typeof(func) ~= "function" then
        warn("skipping bad entry: " .. tostring(name))
        continue
    end
    if getgenv()[name] then
        continue
    end
    getgenv()[name] = func
end
