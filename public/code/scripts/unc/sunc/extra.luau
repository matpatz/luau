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

-- 100% mine dw abt it
add("cloneref", function(object)
    assert(typeof(object) == "Instance", "expected Instance, got " .. typeof(object))

    local p = newproxy(true)
    local mt = getmetatable(p)
    mt.__index = function(_, k) return object[k] end
    mt.__newindex = function(_, k, v) object[k] = v end
    mt.__tostring = function() return tostring(object) end
    return p
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

local b = bit32
local band, bxor, rshift, lshift, rrotate = b.band, b.bxor, b.rshift, b.lshift, b.rrotate

local crypt = {}

local b64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
crypt.base64encode = function(data)
    assert(type(data) == "string", "expected string, got " .. type(data))
    
    local out = {}
    
    for i = 1, #data, 3 do
        local b1, b2, b3 = data:byte(i, i + 2)
        b2 = b2 or 0
        b3 = b3 or 0
        
        local n = b1 * 65536 + b2 * 256 + b3
        
        out[#out + 1] = b64:sub(math.floor(n / 262144) % 64 + 1, math.floor(n / 262144) % 64 + 1)
        out[#out + 1] = b64:sub(math.floor(n / 4096)   % 64 + 1, math.floor(n / 4096)   % 64 + 1)
        out[#out + 1] = b64:sub(math.floor(n / 64)     % 64 + 1, math.floor(n / 64)     % 64 + 1)
        out[#out + 1] = b64:sub(                n       % 64 + 1,                 n      % 64 + 1)
    end
    
    local result = table.concat(out)
    local pad = (3 - #data % 3) % 3
    
    return result:sub(1, #result - pad) .. string.rep("=", pad)
end

crypt.base64decode = function(data)
    assert(type(data) == "string", "expected string, got " .. type(data))

    local out = {}
    
    data = data:gsub("[^%w%+%/%=]", "")
    
    for i = 1, #data, 4 do
        local c1, c2, c3, c4 = data:sub(i,i), data:sub(i+1,i+1), data:sub(i+2,i+2), data:sub(i+3,i+3)
        
        local n1 = b64:find(c1, 1, true) - 1
        local n2 = b64:find(c2, 1, true) - 1
        local n3 = c3 == "=" and 0 or (b64:find(c3, 1, true) - 1)
        local n4 = c4 == "=" and 0 or (b64:find(c4, 1, true) - 1)
        
        local n = n1 * 262144 + n2 * 4096 + n3 * 64 + n4
        
        out[#out + 1] = string.char(math.floor(n / 65536) % 256)
        if c3 ~= "=" then
            out[#out + 1] = string.char(math.floor(n / 256) % 256)
        end
        if c4 ~= "=" then
            out[#out + 1] = string.char(n % 256)
        end
    end
    
    return table.concat(out)
end

crypt.encrypt = function(data, key)
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
end

crypt.decrypt = crypt.encrypt -- <<>> = sourcey

-- none of these are algos the normal hash function provides
crypt.hash = function(str, algorithm)
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
    elseif algorithm == "sha256" then -- we love skidding
        local K = {
            0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,
            0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,
            0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,
            0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,
            0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,
            0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,
            0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,
            0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2
        }

        local H0 = 0x6a09e667
        local H1 = 0xbb67ae85
        local H2 = 0x3c6ef372
        local H3 = 0xa54ff53a
        local H4 = 0x510e527f
        local H5 = 0x9b05688c
        local H6 = 0x1f83d9ab
        local H7 = 0x5be0cd19

        local msg = str
        local bitLen = #msg * 8

        msg = msg .. "\128"
        while (#msg % 64) ~= 56 do
            msg = msg .. "\0"
        end

        for i = 7,0,-1 do
            msg = msg .. string.char(band(rshift(bitLen,i*8),255))
        end

        for i = 1,#msg,64 do
            local w = {}

            for j = 0,15 do
                local a,b,c,d = msg:byte(i+j*4,i+j*4+3)
                w[j] = lshift(a,24) + lshift(b,16) + lshift(c,8) + d
            end

            for j = 16,63 do
                local s0 = bxor(rrotate(w[j-15],7), rrotate(w[j-15],18), rshift(w[j-15],3))
                local s1 = bxor(rrotate(w[j-2],17), rrotate(w[j-2],19), rshift(w[j-2],10))
                w[j] = (w[j-16] + s0 + w[j-7] + s1) % 4294967296
            end

            local a = H0
            local b = H1
            local c = H2
            local d = H3
            local e = H4
            local f = H5
            local g = H6
            local h = H7

            for j = 0,63 do
                local S1 = bxor(rrotate(e,6), rrotate(e,11), rrotate(e,25))
                local ch = bxor(band(e,f), band(bit32.bnot(e),g))
                local temp1 = (h + S1 + ch + K[j+1] + w[j]) % 4294967296

                local S0 = bxor(rrotate(a,2), rrotate(a,13), rrotate(a,22))
                local maj = bxor(band(a,b), band(a,c), band(b,c))
                local temp2 = (S0 + maj) % 4294967296

                h = g
                g = f
                f = e
                e = (d + temp1) % 4294967296
                d = c
                c = b
                b = a
                a = (temp1 + temp2) % 4294967296
            end

            H0 = (H0 + a) % 4294967296
            H1 = (H1 + b) % 4294967296
            H2 = (H2 + c) % 4294967296
            H3 = (H3 + d) % 4294967296
            H4 = (H4 + e) % 4294967296
            H5 = (H5 + f) % 4294967296
            H6 = (H6 + g) % 4294967296
            H7 = (H7 + h) % 4294967296
        end

        return string.format("%08x%08x%08x%08x%08x%08x%08x%08x",
            H0,H1,H2,H3,H4,H5,H6,H7
        )
    elseif algorithm == "sha1" then
        local h0 = 0x67452301
        local h1 = 0xEFCDAB89
        local h2 = 0x98BADCFE
        local h3 = 0x10325476
        local h4 = 0xC3D2E1F0

        local msg = str
        local bitLen = #msg * 8

        msg = msg .. "\128"
        while (#msg % 64) ~= 56 do
            msg = msg .. "\0"
        end

        for i = 7,0,-1 do
            msg = msg .. string.char(band(rshift(bitLen,i*8),255))
        end

        for i = 1,#msg,64 do
            local w = {}

            for j = 0,15 do
                local a,b,c,d = msg:byte(i+j*4,i+j*4+3)
                w[j] = lshift(a,24) + lshift(b,16) + lshift(c,8) + d
            end

            for j = 16,79 do
                w[j] = lrotate(bxor(w[j-3], w[j-8], w[j-14], w[j-16]),1)
            end

            local a = h0
            local b = h1
            local c = h2
            local d = h3
            local e = h4

            for j = 0,79 do
                local f, k

                if j <= 19 then
                    f = bor(band(b,c), band(bnot(b),d))
                    k = 0x5A827999
                elseif j <= 39 then
                    f = bxor(b,c,d)
                    k = 0x6ED9EBA1
                elseif j <= 59 then
                    f = bor(bor(band(b,c), band(b,d)), band(c,d))
                    k = 0x8F1BBCDC
                else
                    f = bxor(b,c,d)
                    k = 0xCA62C1D6
                end

                local temp = (lrotate(a,5) + f + e + k + w[j]) % 4294967296
                e = d
                d = c
                c = lrotate(b,30)
                b = a
                a = temp
            end

            h0 = (h0 + a) % 4294967296
            h1 = (h1 + b) % 4294967296
            h2 = (h2 + c) % 4294967296
            h3 = (h3 + d) % 4294967296
            h4 = (h4 + e) % 4294967296
        end

        return string.format("%08x%08x%08x%08x%08x", h0,h1,h2,h3,h4)
    else
        error("unsupported algorithm: " .. algorithm)
    end
end

crypt.random = function(len)
    assert(type(len) == "number", "expected number, got " .. type(len))
    assert(len > 0, "length must be greater than 0")
    local t = {}
    for i = 1, len do
        t[i] = string.char(math.random(0, 255))
    end
    return table.concat(t)
end

crypt.rstring = function(len)
    len = len or 16
    local chars, str = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789", {}
    for i = 1, len do
        local idx = math.random(1, #chars)
        str[i] = chars:sub(idx, idx)
    end
    return table.concat(str)
end

crypt.tohex = function(str)
    assert(type(str) == "string", "expected string, got " .. type(str))
    return (str:gsub(".", function(c)
        return string.format("%02x", string.byte(c))
    end))
end

crypt.fromhex = function(str)
    assert(type(str) == "string", "expected string, got " .. type(str))
    assert(#str % 2 == 0, "hex string must have even length")
    return (str:gsub("%x%x", function(c)
        return string.char(tonumber(c, 16))
    end))
end

-- inaccurate idk vruh
crypt.hmac = function(data, key, algorithm)
    assert(type(data) == "string", "expected string for data, got " .. type(data))
    assert(type(key) == "string", "expected string for key, got " .. type(key))
    assert(type(algorithm) == "string", "expected string for algorithm, got " .. type(algorithm))

    local hash = crypt.hash
    local fromhex = crypt.fromhex
    local tobase64 = crypt.base64encode

    -- internal hash that returns raw bytes, not hex
    local function hashraw(str)
        return fromhex(hash(str, algorithm))
    end

    local blockSize = 64
    if #key > blockSize then
        key = hashraw(key)
    end

    -- pad key to blockSize
    if #key < blockSize then
        key = key .. string.rep("\0", blockSize - #key)
    end

    local ipad, opad = {}, {}
    for i = 1, blockSize do
        local b = key:byte(i) or 0
        ipad[i] = string.char(bxor(b, 0x36))
        opad[i] = string.char(bxor(b, 0x5C))
    end

    local inner = hashraw(table.concat(ipad) .. data)
    local outer = hashraw(table.concat(opad) .. inner)

    return tobase64(outer)
end

crypt.lz4 = function(data, step)
    assert(type(data) == "string", "data must be string")

    local out
    if step == true then -- encrypt
        out = lz4compress(data)
    else
        out = lz4decompress(data)
    end
    return out
end

for k, v in pairs(crypt) do
    add("crypt." .. k, v)
end

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

local debug_lib = {}

local constants = {}
local upvalues = {}
local stacks = {}
local debug_override = setmetatable({}, {__mode = "k"})

debug_lib.validlevel = function(level)
    return debug.getinfo(level + 2) ~= nil
end

debug_lib.isvalidlevel = function(level)
    assert(type(level) == "number", "expected number, got " .. type(level))
    return level >= 0
end

debug_lib.getregistry = function()
    return getreg and getreg() or {}
end

debug_lib.getconstant = function(func, index)
    assert(type(func) == "function", "expected function, got " .. type(func))
    assert(type(index) == "number", "expected number for index, got " .. type(index))
    local c = constants[func]
    if not c or c[index] == nil then
        error("constant does not exist at index " .. index)
    end
    return c[index]
end

debug_lib.getconstants = function(func)
    assert(type(func) == "function", "expected function, got " .. type(func))
    return constants[func] or {}
end

debug_lib.setconstant = function(func, index, value)
    assert(type(func) == "function", "expected function, got " .. type(func))
    assert(type(index) == "number", "expected number for index, got " .. type(index))
    constants[func] = constants[func] or {}
    constants[func][index] = value
end

debug_lib.getupvalue = function(func, index)
    assert(type(func) == "function", "expected function, got " .. type(func))
    assert(type(index) == "number", "expected number for index, got " .. type(index))
    local u = upvalues[func]
    if not u or u[index] == nil then
        return nil
    end
    return u[index]
end

debug_lib.getupvalues = function(func)
    assert(type(func) == "function", "expected function, got " .. type(func))
    return upvalues[func] or {}
end

debug_lib.setupvalue = function(func, index, value)
    assert(type(func) == "function", "expected function, got " .. type(func))
    assert(type(index) == "number", "expected number for index, got " .. type(index))
    upvalues[func] = upvalues[func] or {}
    upvalues[func][index] = value
end

debug_lib.getstack = function(level, index)
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
end

debug_lib.setstack = function(level, index, value)
    assert(type(level) == "number", "expected number for level, got " .. type(level))
    assert(type(index) == "number", "expected number for index, got " .. type(index))
    stacks[level] = stacks[level] or {}
    stacks[level][index] = value
end

debug_lib.setinfo = function(func, info)
    assert(type(func) == "function", "expected function")
    assert(type(info) == "table", "expected table")
    debug_override[func] = info
end

debug_lib.info = function(func, what)
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
end

debug_lib.getproto = function()
    return nil
end

debug_lib.getprotos = function()
    return {}
end

debug_lib.getcallstack = function()
    local stack = {}
    local level = 1
    while true do
        local info = debug.getinfo(level + 1)
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
end

for k, v in pairs(debug_lib) do
    add("debug." .. k, v)
end

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

-- Drawing

local dache = {}

local function applyBase(obj, self)
    obj.Visible = self.Visible
    obj.ZIndex = math.clamp(self.ZIndex, -2^31, 2^31)
    obj.BackgroundTransparency = 1 - self.Transparency
    obj.BackgroundColor3 = self.Color
end

local function makeProxy(self, update, readonly)
    readonly = readonly or {}
    local proxy = newproxy(true)
    local mt = getmetatable(proxy)

    mt.__index = function(_, k)
        return self[k]
    end

    mt.__newindex = function(_, k, v)
        for _, r in ipairs(readonly) do
            if r == k then return end
        end
        self[k] = v
        update()
    end

    mt.__tostring = function()
        return "Drawing"
    end

    mt.__metatable = "This metatable is protected."
    return proxy
end

local types = {}

types.Line = function(self, Object)
    local function update()
        local from, to = self.From, self.To
        local dx, dy = to.X - from.X, to.Y - from.Y
        local len = math.sqrt(dx^2 + dy^2)
        Object.Size = UDim2.fromOffset(len, self.Thickness)
        Object.Position = UDim2.fromOffset(from.X, from.Y)
        Object.Rotation = math.deg(math.atan2(dy, dx))
        Object.BackgroundColor3 = self.Color
        Object.Visible = self.Visible
        Object.ZIndex = math.clamp(self.ZIndex, -2^31, 2^31)
    end

    self.From = Vector2.zero
    self.To = Vector2.zero
    self.Thickness = 1
    self.Color = Color3.new(1, 1, 1)
    self.Visible = true
    self.ZIndex = 1
    self.Transparency = 1

    return makeProxy(self, update)
end

types.Square = function(self, Object)
    local stroke = Instance.new("UIStroke", Object)
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local function update()
        applyBase(Object, self)
        Object.Size = UDim2.fromOffset(self.Size.X, self.Size.Y)
        Object.Position = UDim2.fromOffset(self.Position.X, self.Position.Y)
        if self.Filled then
            Object.BackgroundTransparency = 0
            stroke.Enabled = false
        else
            Object.BackgroundTransparency = 1
            stroke.Enabled = true
            stroke.Color = self.Color
            stroke.Thickness = self.Thickness
        end
    end

    self.Size = Vector2.zero
    self.Position = Vector2.zero
    self.Color = Color3.new(1, 1, 1)
    self.Filled = false
    self.Thickness = 1
    self.Visible = true
    self.ZIndex = 1
    self.Transparency = 1

    return makeProxy(self, update)
end

types.Circle = function(self, Object)
    Instance.new("UICorner", Object).CornerRadius = UDim.new(1, 0)
    local stroke = Instance.new("UIStroke", Object)
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local function update()
        local d = self.Radius * 2
        Object.Size = UDim2.fromOffset(d, d)
        Object.Position = UDim2.fromOffset(
            self.Position.X - self.Radius,
            self.Position.Y - self.Radius
        )
        Object.Visible = self.Visible
        Object.ZIndex = math.clamp(self.ZIndex, -2^31, 2^31)
        if self.Filled then
            Object.BackgroundTransparency = 1 - self.Transparency
            Object.BackgroundColor3 = self.Color
            stroke.Enabled = false
        else
            Object.BackgroundTransparency = 1
            stroke.Enabled = true
            stroke.Color = self.Color
            stroke.Thickness = self.Thickness
        end
    end

    self.Radius = 1
    self.Position = Vector2.zero
    self.Color = Color3.new(1, 1, 1)
    self.Filled = false
    self.Thickness = 1
    self.Visible = true
    self.ZIndex = 1
    self.Transparency = 1
    self.NumSides = 0

    return makeProxy(self, update)
end

types.Text = function(self, Object)
    Object:Destroy()
    Object = Instance.new("TextLabel", UI)
    Object.BackgroundTransparency = 1
    Object.BorderSizePixel = 0
    Object.TextWrapped = false
    Object.RichText = false

    local function update()
        Object.Visible = self.Visible
        Object.ZIndex = math.clamp(self.ZIndex, -2^31, 2^31)
        Object.Text = self.Text
        Object.TextSize = self.Size
        Object.TextColor3 = self.Color
        Object.BackgroundTransparency = 1 - self.Transparency
        Object.Position = UDim2.fromOffset(self.Position.X, self.Position.Y)
        Object.Size = UDim2.fromOffset(self.Size * #self.Text * 0.6, self.Size)
        Object.Font = ({
            [0] = Enum.Font.GothamMedium,
            [1] = Enum.Font.SourceSans,
            [2] = Enum.Font.Code,
            [3] = Enum.Font.RobotoMono,
        })[self.Font] or Enum.Font.GothamMedium
        Object.TextXAlignment = self.Center and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left
        Object.TextYAlignment = self.Center and Enum.TextYAlignment.Center or Enum.TextYAlignment.Top
        Object.TextStrokeTransparency = self.Outline and 0 or 1
        Object.TextStrokeColor3 = self.OutlineColor
        self.TextBounds = Object.TextBounds
    end

    self.Text = ""
    self.Size = 12
    self.Font = 3
    self.Color = Color3.new(1, 1, 1)
    self.Center = false
    self.Outline = false
    self.OutlineColor = Color3.new(0, 0, 0)
    self.Position = Vector2.zero
    self.Visible = true
    self.ZIndex = 1
    self.Transparency = 1
    self.TextBounds = Vector2.zero

    return makeProxy(self, update, {"TextBounds"})
end

local Drawing = {
    Fonts = {
        UI = 0,
        System = 1,
        Plex = 2,
        Monospace = 3,
    },

    new = function(Type)
        assert(type(Type) == "string", "expected string for Type, got " .. type(Type))
        assert(types[Type], "invalid drawing type: " .. Type)

        local Object = Instance.new("Frame")
        Object.BorderSizePixel = 0
        Object.BackgroundTransparency = 1
        Object.ZIndex = 1
        Object.Size = UDim2.fromOffset(0, 0)
        Object.Parent = UI

        local self = {
            Remove = function() Object:Destroy() end,
        }
        self.Destroy = self.Remove

        local proxy = types[Type](self, Object)
        table.insert(dache, {proxy = proxy, instance = Object})
        return proxy
    end
}

if getgenv()["Drawing"] == nil then
    getgenv().Drawing = Drawing
end

add("isrenderobj", function(a)
    for _, obj in ipairs(dache) do
        if obj.proxy == a then return true end
    end
    return false
end)

add("cleardrawcache", function()
    for _, obj in ipairs(dache) do
        obj.instance:Destroy()
    end
    table.clear(dache)
end)

add("getrenderproperty", function(a, b)
    assert(isrenderobj(a), "expected render object, got " .. type(a))
    assert(type(b) == "string", "expected string for property, got " .. type(b))
    return a[b]
end)

add("setrenderproperty", function(a, b, c)
    assert(isrenderobj(a), "expected render object, got " .. type(a))
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

local mouse = uis:GetMouseLocation()

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

local anal = game:GetService("RbxAnalyticsService")
add("gethwid", function()
    return crypt.hash(anal:GetClientId())
end)

add("get_hwid", function()
    return gethwid()
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
-- if you dont have either i think youre cooked innit
add("decompile", function(item)
    assert(typeof(item) == "Instance", "expected Instance, got " .. typeof(item))
    return getscriptbytecode(item)
end)

add("getscripthash", function(item)
    assert(typeof(item) == "Instance", "expected Instance, got " .. typeof(item))
    return crypt.hash(getscriptbytecode(item))
end)

add("getfunctionhash", function(item)
    assert(typeof(item) == "function", "expected Function, got " .. typeof(item))
    return crypt.hash(item)
end)

local synsaveinstance = loadstring(game:HttpGet("https://raw.githubusercontent.com/luau/UniversalSynSaveInstance/main/saveinstance.luau", true), "saveinstance")()
local options = {
    ReadMe = true,
    IsolatePlayers = true,
    FilePath = string.format("%d", tick())
}
add("saveinstance", function(opts)
    if not opts then opts = options end
    synsaveinstance(opts)
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

add("getgenv", function()
    return getfenv(0)
end)

add("getsenv", function(scr)
    assert(typeof(scr) == "Instance" and scr:IsA("LocalScript"), "expected LocalScript, got " .. typeof(scr))
    return getfenv(0)
end)

local function test()
    local function try(f)
        return function()
            return select(1, pcall(f))
        end
    end

    local checks = {
        try(function() return game.Name end),
        try(function() return game:GetService("CoreGui").Name end),
        try(function() return game.DataCost end),
        try(function() return Instance.new("Player") end),
        try(function() return game:GetService("CorePackages").Name end),
        try(function() return Instance.new("SurfaceAppearance") end),
        try(function() Instance.new("MeshPart").MeshId = "" end)
    }

    for i, v in ipairs(checks) do
        if not v() then
            return i - 1
        end
    end

    return #checks
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

add("getthreadcontext", function()
    return getthreadidentity()
end)

add("identity", function() -- just added this for testing
   return getthreadidentity()
end)

add("printidentity", function()
   print("Current identity is", getthreadidentity())
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

local existing_crypt = getgenv()["crypt"]
if type(existing_crypt) == "table" then
    for k, v in pairs(crypt) do
        if existing_crypt[k] == nil then
            existing_crypt[k] = v
        end
    end
else
    getgenv().crypt = crypt
end

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
