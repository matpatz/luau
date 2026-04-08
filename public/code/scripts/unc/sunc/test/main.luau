local time = tick()
local tcount, sunc, failed = 0, 0, 0

local searchable, tests = {}, {}

local chars = "abcdefghijklmnopqrstuvwxyz"
local function rname()
    local name = ""
    for i = 1, 12 do
        local idx = math.random(1, #chars)
        name = name .. chars:sub(idx, idx)
    end
    return name
end

local function sendTest(item, result, extra, emsg)
    local output; tcount += 1

    if result == true then
        output = "✅"
        sunc += 1
    elseif result == false then
        output = "❌"
        failed += 1
    elseif result == "unfinished" then
        output = "~skipped~"
    else
        output = "~~~"
    end

    if extra == nil then extra = false; emsg = "-" end

    local out = ""
    if extra == false then
        out = output .. " " .. tostring(item)
    else
        out = "\t" .. " | " .. tostring(emsg) .. " | "
    end

    print(out)
end

getgenv().search = function(search)
    for _, item in pairs(searchable) do
        if item.name == search then return item.fn() end
    end
    for _, item in pairs(tests) do
        if item.name == search then return item.fn() end
    end
    return "Sorry, but this functions test are yet to be implemented. Feel free to request the functions support"
end

local function newline(input) return "\n" .. input .. "\n" end
local function wrap(input, _newline, count)
    _newline = _newline or true; count = count or 10
    return string.rep("=", count), input, string.rep("=", count)
end

-- Closures

print(wrap("Closures"))

-- checkcaller
do
    local test = "checkcaller: returns true when called from executor context"
    local success, result = pcall(function()
        return checkcaller()
    end)
    sendTest(test, success and result == true)
end

do
    local test = "checkcaller: returns false inside a game connection"
    local success, result = pcall(function()
        local val = nil
        local conn
        conn = game:GetService("RunService").Heartbeat:Connect(function()
            val = checkcaller()
            conn:Disconnect()
        end)
        task.wait(0.1)
        return val == false
    end)
    sendTest(test, success and result == true)
end

-- clonefunction
do
    local test = "clonefunction: cloned function produces same output"
    local success, result = pcall(function()
        local function foo() return 42 end
        local bar = clonefunction(foo)
        return bar() == 42
    end)
    sendTest(test, success and result == true)
end

do
    local test = "clonefunction: cloned function is not equal to original"
    local success, result = pcall(function()
        local function foo() return 42 end
        local bar = clonefunction(foo)
        return bar ~= foo
    end)
    sendTest(test, success and result == true)
end

do
    local test = "clonefunction: cloned C function works correctly"
    local success, result = pcall(function()
        local cloned = clonefunction(print)
        return type(cloned) == "function" and cloned ~= print
    end)
    sendTest(test, success and result == true)
end

-- getcallingscript
do
    local test = "getcallingscript: returns nil or BaseScript"
    local success, result = pcall(function()
        local s = getcallingscript()
        return s == nil or typeof(s) == "Instance"
    end)
    sendTest(test, success and result == true)
end

-- hookfunction
do
    local test = "hookfunction: hook replaces original function behavior"
    local success, result = pcall(function()
        local function foo() return "original" end
        local ref = hookfunction(foo, function() return "hooked" end)
        return foo() == "hooked" and ref() == "original"
    end)
    sendTest(test, success and result == true)
end

do
    local test = "hookfunction: works on C closures"
    local success, result = pcall(function()
        local original = hookfunction(type, function(v)
            return "hooked_type"
        end)
        local res = type(123)
        hookfunction(type, original)
        return res == "hooked_type"
    end)
    sendTest(test, success and result == true)
end

-- iscclosure
do
    local test = "iscclosure: print is a C closure"
    local success, result = pcall(function()
        return iscclosure(print)
    end)
    sendTest(test, success and result == true)
end

do
    local test = "iscclosure: lua function is not a C closure"
    local success, result = pcall(function()
        return iscclosure(function() end) == false
    end)
    sendTest(test, success and result == true)
end

-- islclosure
do
    local test = "islclosure: lua function is an L closure"
    local success, result = pcall(function()
        return islclosure(function() end)
    end)
    sendTest(test, success and result == true)
end

do
    local test = "islclosure: print is not an L closure"
    local success, result = pcall(function()
        return islclosure(print) == false
    end)
    sendTest(test, success and result == true)
end

-- isexecutorclosure
do
    local test = "isexecutorclosure: executor function returns true"
    local success, result = pcall(function()
        return isexecutorclosure(isexecutorclosure)
    end)
    sendTest(test, success and result == true)
end

do
    local test = "isexecutorclosure: game function returns false"
    local success, result = pcall(function()
        return isexecutorclosure(game.GetService) == false
    end)
    sendTest(test, success and result == true)
end

-- loadstring
do
    local test = "loadstring: compiles and runs valid code"
    local success, result = pcall(function()
        local fn = loadstring("return 1 + 1")
        return fn() == 2
    end)
    sendTest(test, success and result == true)
end

do
    local test = "loadstring: returns nil and error for invalid code"
    local success, result = pcall(function()
        local fn, err = loadstring("this is not valid lua {{{{")
        return fn == nil and type(err) == "string"
    end)
    sendTest(test, success and result == true)
end

do
    local test = "loadstring: respects chunkname parameter"
    local success, result = pcall(function()
        local fn = loadstring("error('test')", "mychunk")
        local ok, err = pcall(fn)
        return not ok and string.find(err, "mychunk") ~= nil
    end)
    sendTest(test, success and result == true)
end

-- newcclosure
do
    local test = "newcclosure: wraps lua function as C closure"
    local success, result = pcall(function()
        local foo = function() return true end
        local bar = newcclosure(foo)
        return bar() == true and iscclosure(bar)
    end)
    sendTest(test, success and result == true)
end

do
    local test = "newcclosure: result is not equal to original"
    local success, result = pcall(function()
        local foo = function() return true end
        local bar = newcclosure(foo)
        return bar ~= foo
    end)
    sendTest(test, success and result == true)
end

-- Cache

print(wrap("Cache"))

-- cache.iscached
do
    local test = "cache.iscached: workspace is cached"
    local success, result = pcall(function()
        return cache.iscached(workspace)
    end)
    sendTest(test, success and result == true)
end

-- cache.invalidate and cache.iscached
do
    local test = "cache.invalidate: removes instance from cache"
    local success, result = pcall(function()
        local part = Instance.new("Part", workspace)
        local wasCached = cache.iscached(part)
        cache.invalidate(part)
        local isNowCached = cache.iscached(part)
        part:Destroy()
        return wasCached == true and isNowCached == false
    end)
    sendTest(test, success and result == true)
end

-- cache.replace
do
    local test = "cache.replace: replaces instance in cache"
    local success, result = pcall(function()
        local partA = Instance.new("Part", workspace)
        local partB = Instance.new("Part", workspace)
        cache.replace(partA, partB)
        local result = cache.iscached(partB)
        partA:Destroy()
        partB:Destroy()
        return result
    end)
    sendTest(test, success and result == true)
end

-- cloneref
do
    local test = "cloneref: returns a different reference"
    local success, result = pcall(function()
        local ref = cloneref(workspace)
        return ref ~= workspace
    end)
    sendTest(test, success and result == true)
end

-- compareinstances
do
    local test = "compareinstances: cloned ref and original reference same instance"
    local success, result = pcall(function()
        local ref = cloneref(workspace)
        return compareinstances(ref, workspace)
    end)
    sendTest(test, success and result == true)
end

do
    local test = "compareinstances: different instances return false"
    local success, result = pcall(function()
        local a = Instance.new("Part")
        local b = Instance.new("Part")
        local res = compareinstances(a, b)
        a:Destroy()
        b:Destroy()
        return res == false
    end)
    sendTest(test, success and result == true)
end

-- Rconsole
--[[

print(wrap("Rconsole"))

do
    local test = "rconsoleprint: exists and is callable"
    local success, result = pcall(function()
        return type(rconsoleprint) == "function"
    end)
    sendTest(test, success and result == true)
end

do
    local test = "rconsolewarn: exists and is callable"
    local success, result = pcall(function()
        return type(rconsolewarn) == "function"
    end)
    sendTest(test, success and result == true)
end

do
    local test = "rconsoleerror: exists and is callable"
    local success, result = pcall(function()
        return type(rconsoleerror) == "function"
    end)
    sendTest(test, success and result == true)
end

do
    local test = "rconsoleclear: exists and is callable"
    local success, result = pcall(function()
        return type(rconsoleclear) == "function"
    end)
    sendTest(test, success and result == true)
end
--]]

-- Crypt

print(wrap("Crypt"))

-- crypt.base64encode / crypt.base64decode
do
    local test = "crypt.base64encode/decode: roundtrip preserves data"
    local success, result = pcall(function()
        local original = "Hello, World!"
        local encoded = crypt.base64encode(original)
        local decoded = crypt.base64decode(encoded)
        return decoded == original
    end)
    sendTest(test, success and result == true)
end

local encoding = game:GetService("EncodingService")
do
    local test = "crypt.base64encode: known encoding"

    local rstring = rname()
    local success, result = pcall(function()
        return crypt.base64encode("Hello") == "SGVsbG8="
    end)
    sendTest(test, success and result == true)
end

-- crypt.generatekey
do
    local test = "crypt.generatekey: returns a base64 string"
    local success, result = pcall(function()
        local key = crypt.generatekey()
        return type(key) == "string" and #key == 44
    end)
    sendTest(test, success and result == true)
end

-- crypt.generatebytes
do
    local test = "crypt.generatebytes: returns base64 encoded bytes"
    local success, result = pcall(function()
        local rnum = math.random(16, 32)
        local bytes = crypt.generatebytes(rnum)
        local decoded = crypt.base64decode(bytes)
        return #decoded == rnum
    end)
    sendTest(test, success and result == true)
end

-- crypt.encrypt / crypt.decrypt
do
    local test = "crypt.encrypt/decrypt: roundtrip CBC preserves data"
    local success, result = pcall(function()
        local key = crypt.generatekey()
        local data = "Secret message!"
        local encrypted, iv = crypt.encrypt(data, key, nil, "CBC")
        local decrypted = crypt.decrypt(encrypted, key, iv, "CBC")
        return decrypted == data
    end)
    sendTest(test, success and result == true)
end

do
    local test = "crypt.encrypt/decrypt: roundtrip ECB preserves data"
    local success, result = pcall(function()
        local key = crypt.generatekey()
        local data = "Secret message!!"  -- 16 bytes for ECB
        local encrypted = crypt.encrypt(data, key, nil, "ECB")
        local decrypted = crypt.decrypt(encrypted, key, "", "ECB")
        return decrypted == data
    end)
    sendTest(test, success and result == true)
end

-- crypt.hash
do
    local test = "crypt.hash: SHA256 produces 64 hex chars"
    local success, result = pcall(function()
        local hash = crypt.hash("hello", "sha256")
        return type(hash) == "string" and #hash == 64
    end)
    sendTest(test, success and result == true)
end

do
    local test = "crypt.hash: SHA256 known hash"
    local success, result = pcall(function()
        local hash = crypt.hash("hello", "sha256")
        return hash == "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824"
    end)
    sendTest(test, success and result == true)
end

do
    local test = "crypt.hash: MD5 produces 32 hex chars"
    local success, result = pcall(function()
        local hash = crypt.hash("hello", "md5")
        return type(hash) == "string" and #hash == 32
    end)
    sendTest(test, success and result == true)
end

-- ============================================================
-- DEBUG
-- ============================================================

print("\n========== DEBUG ==========\n")

-- debug.getregistry
do
    local test = "debug.getregistry: returns a table"
    local success, result = pcall(function()
        local reg = debug.getregistry()
        return type(reg) == "table"
    end)
    sendTest(test, success and result == true)
end

-- debug.getconstants
do
    local test = "debug.getconstants: returns constants of a function"
    local success, result = pcall(function()
        local function foo()
            local x = "hello"
            print(x)
        end
        local constants = debug.getconstants(foo)
        return type(constants) == "table" and #constants > 0
    end)
    sendTest(test, success and result == true)
end

-- debug.getconstant
do
    local test = "debug.getconstant: retrieves correct constant"
    local success, result = pcall(function()
        local function foo()
            print("test_value")
        end
        local constants = debug.getconstants(foo)
        local found = false
        for i, v in pairs(constants) do
            if v == "test_value" then
                found = debug.getconstant(foo, i) == "test_value"
                break
            end
        end
        return found
    end)
    sendTest(test, success and result == true)
end

-- debug.setconstant
do
    local test = "debug.setconstant: modifies constant successfully"
    local success, result = pcall(function()
        local function foo()
            return "original"
        end
        local constants = debug.getconstants(foo)
        for i, v in pairs(constants) do
            if v == "original" then
                debug.setconstant(foo, i, "modified")
                break
            end
        end
        return foo() == "modified"
    end)
    sendTest(test, success and result == true)
end

-- debug.getupvalues
do
    local test = "debug.getupvalues: returns upvalues table"
    local success, result = pcall(function()
        local upval = 42
        local function foo()
            return upval
        end
        local ups = debug.getupvalues(foo)
        return type(ups) == "table"
    end)
    sendTest(test, success and result == true)
end

-- debug.getupvalue
do
    local test = "debug.getupvalue: retrieves correct upvalue"
    local success, result = pcall(function()
        local upval = "hello_upval"
        local function foo()
            return upval
        end
        local val = debug.getupvalue(foo, 1)
        return val == "hello_upval"
    end)
    sendTest(test, success and result == true)
end

-- debug.setupvalue
do
    local test = "debug.setupvalue: modifies upvalue successfully"
    local success, result = pcall(function()
        local upval = "before"
        local function foo()
            return upval
        end
        debug.setupvalue(foo, 1, "after")
        return foo() == "after"
    end)
    sendTest(test, success and result == true)
end

-- debug.getinfo
do
    local test = "debug.getinfo: returns valid DebugInfo table"
    local success, result = pcall(function()
        local function foo() end
        local info = debug.getinfo(foo)
        return type(info) == "table" and info.func == foo and type(info.nups) == "number"
    end)
    sendTest(test, success and result == true)
end

do
    local test = "debug.getinfo: what field is 'Lua' for Lua function"
    local success, result = pcall(function()
        local function foo() end
        local info = debug.getinfo(foo)
        return info.what == "Lua"
    end)
    sendTest(test, success and result == true)
end

do
    local test = "debug.getinfo: what field is 'C' for C function"
    local success, result = pcall(function()
        local info = debug.getinfo(print)
        return info.what == "C"
    end)
    sendTest(test, success and result == true)
end

-- debug.getprotos
do
    local test = "debug.getprotos: returns protos of a function"
    local success, result = pcall(function()
        local function foo()
            local function inner() return 1 end
            return inner
        end
        local protos = debug.getprotos(foo)
        return type(protos) == "table" and #protos >= 1
    end)
    sendTest(test, success and result == true)
end

-- debug.getproto
do
    local test = "debug.getproto: returns proto at index"
    local success, result = pcall(function()
        local function foo()
            local function inner() return "proto_test" end
            return inner
        end
        local proto = debug.getproto(foo, 1)
        return type(proto) == "function"
    end)
    sendTest(test, success and result == true)
end

-- debug.getstack
do
    local test = "debug.getstack: returns stack values"
    local success, result = pcall(function()
        local function foo()
            local x = 123
            return debug.getstack(1)
        end
        local stack = foo()
        return type(stack) == "table"
    end)
    sendTest(test, success and result == true)
end

-- debug.isvalidlevel
do
    local test = "debug.isvalidlevel: level 1 is valid"
    local success, result = pcall(function()
        return debug.isvalidlevel(1) == true
    end)
    sendTest(test, success and result == true)
end

do
    local test = "debug.isvalidlevel: very high level is invalid"
    local success, result = pcall(function()
        return debug.isvalidlevel(99999) == false
    end)
    sendTest(test, success and result == true)
end

-- ============================================================
-- DRAWING
-- ============================================================

print("\n========== DRAWING ==========\n")

-- Drawing.new
do
    local test = "Drawing.new: creates Line object"
    local success, result = pcall(function()
        local line = Drawing.new("Line")
        local valid = isrenderobj(line)
        line:Destroy()
        return valid
    end)
    sendTest(test, success and result == true)
end

do
    local test = "Drawing.new: creates Circle object"
    local success, result = pcall(function()
        local circle = Drawing.new("Circle")
        circle.Radius = 50
        local valid = isrenderobj(circle) and circle.Radius == 50
        circle:Destroy()
        return valid
    end)
    sendTest(test, success and result == true)
end

do
    local test = "Drawing.new: creates Square object"
    local success, result = pcall(function()
        local square = Drawing.new("Square")
        square.Size = Vector2.new(100, 100)
        local valid = isrenderobj(square)
        square:Destroy()
        return valid
    end)
    sendTest(test, success and result == true)
end

do
    local test = "Drawing.new: creates Text object"
    local success, result = pcall(function()
        local text = Drawing.new("Text")
        text.Text = "Hello"
        local valid = isrenderobj(text) and text.Text == "Hello"
        text:Destroy()
        return valid
    end)
    sendTest(test, success and result == true)
end

do
    local test = "Drawing.new: creates Triangle object"
    local success, result = pcall(function()
        local tri = Drawing.new("Triangle")
        local valid = isrenderobj(tri)
        tri:Destroy()
        return valid
    end)
    sendTest(test, success and result == true)
end

do
    local test = "Drawing.new: creates Quad object"
    local success, result = pcall(function()
        local quad = Drawing.new("Quad")
        local valid = isrenderobj(quad)
        quad:Destroy()
        return valid
    end)
    sendTest(test, success and result == true)
end

do
    local test = "Drawing.new: creates Image object"
    local success, result = pcall(function()
        local img = Drawing.new("Image")
        local valid = isrenderobj(img)
        img:Destroy()
        return valid
    end)
    sendTest(test, success and result == true)
end

-- Drawing.Fonts
do
    local test = "Drawing.Fonts: contains expected font indices"
    local success, result = pcall(function()
        return Drawing.Fonts.UI == 0 and Drawing.Fonts.System == 1 and Drawing.Fonts.Plex == 2 and Drawing.Fonts.Monospace == 3
    end)
    sendTest(test, success and result == true)
end

-- isrenderobj
do
    local test = "isrenderobj: returns false for non-drawing objects"
    local success, result = pcall(function()
        return isrenderobj("hello") == false and isrenderobj(123) == false
    end)
    sendTest(test, success and result == true)
end

-- getrenderproperty / setrenderproperty
do
    local test = "getrenderproperty/setrenderproperty: get and set work"
    local success, result = pcall(function()
        local circle = Drawing.new("Circle")
        setrenderproperty(circle, "Radius", 75)
        local val = getrenderproperty(circle, "Radius")
        circle:Destroy()
        return val == 75
    end)
    sendTest(test, success and result == true)
end

-- cleardrawcache
do
    local test = "cleardrawcache: exists and is callable"
    local success, result = pcall(function()
        return type(cleardrawcache) == "function"
    end)
    sendTest(test, success and result == true)
end

-- ============================================================
-- FILE SYSTEM
-- ============================================================

print("\n========== FILE SYSTEM ==========\n")

-- writefile / readfile
do
    local test = "writefile/readfile: roundtrip preserves data"
    local success, result = pcall(function()
        local path = "potassium_test_file.txt"
        local data = "Hello, Potassium!"
        writefile(path, data)
        local read = readfile(path)
        delfile(path)
        return read == data
    end)
    sendTest(test, success and result == true)
end

-- appendfile
do
    local test = "appendfile: appends data to file"
    local success, result = pcall(function()
        local path = "potassium_test_append.txt"
        writefile(path, "Hello")
        appendfile(path, ", World!")
        local read = readfile(path)
        delfile(path)
        return read == "Hello, World!"
    end)
    sendTest(test, success and result == true)
end

-- isfile
do
    local test = "isfile: returns true for existing file"
    local success, result = pcall(function()
        local path = "potassium_test_isfile.txt"
        writefile(path, "test")
        local res = isfile(path)
        delfile(path)
        return res == true
    end)
    sendTest(test, success and result == true)
end

do
    local test = "isfile: returns false for non-existing file"
    local success, result = pcall(function()
        return isfile("potassium_nonexistent_file_12345.txt") == false
    end)
    sendTest(test, success and result == true)
end

-- isfolder
do
    local test = "isfolder: returns true for existing folder"
    local success, result = pcall(function()
        local path = "potassium_test_folder"
        makefolder(path)
        local res = isfolder(path)
        delfolder(path)
        return res == true
    end)
    sendTest(test, success and result == true)
end

do
    local test = "isfolder: returns false for non-existing folder"
    local success, result = pcall(function()
        return isfolder("potassium_nonexistent_folder_12345") == false
    end)
    sendTest(test, success and result == true)
end

-- makefolder / delfolder
do
    local test = "makefolder/delfolder: creates and removes folder"
    local success, result = pcall(function()
        local path = "potassium_test_mkdir"
        makefolder(path)
        local exists = isfolder(path)
        delfolder(path)
        local deleted = isfolder(path)
        return exists == true and deleted == false
    end)
    sendTest(test, success and result == true)
end

-- listfiles
do
    local test = "listfiles: lists files in directory"
    local success, result = pcall(function()
        local folder = "potassium_test_listdir"
        makefolder(folder)
        writefile(folder .. "/a.txt", "a")
        writefile(folder .. "/b.txt", "b")
        local files = listfiles(folder)
        delfile(folder .. "/a.txt")
        delfile(folder .. "/b.txt")
        delfolder(folder)
        return type(files) == "table" and #files >= 2
    end)
    sendTest(test, success and result == true)
end

-- delfile
do
    local test = "delfile: removes file"
    local success, result = pcall(function()
        local path = "potassium_test_del.txt"
        writefile(path, "test")
        delfile(path)
        return isfile(path) == false
    end)
    sendTest(test, success and result == true)
end

-- loadfile
do
    local test = "loadfile: loads file and executes"
    local success, result = pcall(function()
        local path = "potassium_test_loadfile.lua"
        writefile(path, "return 99")
        local fn, err = loadfile(path)
        local res = fn()
        delfile(path)
        return res == 99
    end)
    sendTest(test, success and result == true)
end

-- dofile
do
    local test = "dofile: exists and is callable"
    local success, result = pcall(function()
        return type(dofile) == "function"
    end)
    sendTest(test, success and result == true)
end

-- ============================================================
-- INPUT
-- ============================================================

print("\n========== INPUT ==========\n")

-- isrbxactive
do
    local test = "isrbxactive: returns a boolean"
    local success, result = pcall(function()
        return type(isrbxactive()) == "boolean"
    end)
    sendTest(test, success and result == true)
end

-- mouse functions exist
do
    local test = "mouse1click: exists and is callable"
    local success, result = pcall(function()
        return type(mouse1click) == "function"
    end)
    sendTest(test, success and result == true)
end

do
    local test = "mouse1press: exists and is callable"
    local success, result = pcall(function()
        return type(mouse1press) == "function"
    end)
    sendTest(test, success and result == true)
end

do
    local test = "mouse1release: exists and is callable"
    local success, result = pcall(function()
        return type(mouse1release) == "function"
    end)
    sendTest(test, success and result == true)
end

do
    local test = "mouse2click: exists and is callable"
    local success, result = pcall(function()
        return type(mouse2click) == "function"
    end)
    sendTest(test, success and result == true)
end

do
    local test = "mousemoveabs: exists and is callable"
    local success, result = pcall(function()
        return type(mousemoveabs) == "function"
    end)
    sendTest(test, success and result == true)
end

do
    local test = "mousemoverel: exists and is callable"
    local success, result = pcall(function()
        return type(mousemoverel) == "function"
    end)
    sendTest(test, success and result == true)
end

do
    local test = "mousescroll: exists and is callable"
    local success, result = pcall(function()
        return type(mousescroll) == "function"
    end)
    sendTest(test, success and result == true)
end

-- ============================================================
-- INSTANCE
-- ============================================================

print("\n========== INSTANCE ==========\n")

-- fireclickdetector
do
    local test = "fireclickdetector: exists and is callable"
    local success, result = pcall(function()
        return type(fireclickdetector) == "function"
    end)
    sendTest(test, success and result == true)
end

-- firetouchinterest
do
    local test = "firetouchinterest: exists and is callable"
    local success, result = pcall(function()
        return type(firetouchinterest) == "function"
    end)
    sendTest(test, success and result == true)
end

-- getconnections
do
    local test = "getconnections: returns table of connections"
    local success, result = pcall(function()
        local part = Instance.new("Part")
        local conn = part.Changed:Connect(function() end)
        local connections = getconnections(part.Changed)
        conn:Disconnect()
        part:Destroy()
        return type(connections) == "table" and #connections >= 1
    end)
    sendTest(test, success and result == true)
end

do
    local test = "getconnections: connection has expected fields"
    local success, result = pcall(function()
        local part = Instance.new("Part")
        local conn = part.Changed:Connect(function() end)
        local connections = getconnections(part.Changed)
        local c = connections[1]
        conn:Disconnect()
        part:Destroy()
        return type(c.Enabled) == "boolean" and type(c.ForeignState) == "boolean" and type(c.LuaConnection) == "boolean"
    end)
    sendTest(test, success and result == true)
end

do
    local test = "getconnections: Disable/Enable works"
    local success, result = pcall(function()
        local part = Instance.new("Part")
        local fired = false
        local conn = part.Changed:Connect(function() fired = true end)
        local connections = getconnections(part.Changed)
        connections[1]:Disable()
        part.Name = "test_disable"
        task.wait(0.05)
        local wasFiredWhenDisabled = fired
        connections[1]:Enable()
        part.Name = "test_enable"
        task.wait(0.05)
        local wasFiredWhenEnabled = fired
        conn:Disconnect()
        part:Destroy()
        return wasFiredWhenDisabled == false and wasFiredWhenEnabled == true
    end)
    sendTest(test, success and result == true)
end

-- firesignal
do
    local test = "firesignal: fires signal connections"
    local success, result = pcall(function()
        local part = Instance.new("Part")
        local received = false
        local conn = part.Changed:Connect(function()
            received = true
        end)
        firesignal(part.Changed)
        task.wait(0.05)
        conn:Disconnect()
        part:Destroy()
        return received == true
    end)
    sendTest(test, success and result == true)
end

-- getcustomasset
do
    local test = "getcustomasset: returns rbxasset string"
    local success, result = pcall(function()
        writefile("potassium_test_asset.png", "fake_image_data")
        local asset = getcustomasset("potassium_test_asset.png")
        delfile("potassium_test_asset.png")
        return type(asset) == "string" and string.find(asset, "rbxasset://") ~= nil
    end)
    sendTest(test, success and result == true)
end

-- gethiddenproperty / sethiddenproperty
do
    local test = "gethiddenproperty: reads hidden property"
    local success, result = pcall(function()
        local fire = Instance.new("Fire")
        local val, hidden = gethiddenproperty(fire, "size_xml")
        fire:Destroy()
        return type(val) == "number" and hidden == true
    end)
    sendTest(test, success and result == true)
end

do
    local test = "sethiddenproperty: sets hidden property"
    local success, result = pcall(function()
        local fire = Instance.new("Fire")
        local wasHidden = sethiddenproperty(fire, "size_xml", 15)
        local val = gethiddenproperty(fire, "size_xml")
        fire:Destroy()
        return wasHidden == true and val == 15
    end)
    sendTest(test, success and result == true)
end

-- gethui
do
    local test = "gethui: returns a valid Instance"
    local success, result = pcall(function()
        local hui = gethui()
        return typeof(hui) == "Instance"
    end)
    sendTest(test, success and result == true)
end

-- getinstances
do
    local test = "getinstances: returns a table of instances"
    local success, result = pcall(function()
        local instances = getinstances()
        return type(instances) == "table" and #instances > 0
    end)
    sendTest(test, success and result == true)
end

-- getnilinstances
do
    local test = "getnilinstances: returns a table"
    local success, result = pcall(function()
        local instances = getnilinstances()
        return type(instances) == "table"
    end)
    sendTest(test, success and result == true)
end

-- isscriptable
do
    local test = "isscriptable: Name is scriptable"
    local success, result = pcall(function()
        local part = Instance.new("Part")
        local res = isscriptable(part, "Name")
        part:Destroy()
        return res == true
    end)
    sendTest(test, success and result == true)
end

-- setscriptable
do
    local test = "setscriptable: can toggle scriptable"
    local success, result = pcall(function()
        local fire = Instance.new("Fire")
        local wasBefore = isscriptable(fire, "size_xml")
        setscriptable(fire, "size_xml", true)
        local isNow = isscriptable(fire, "size_xml")
        setscriptable(fire, "size_xml", wasBefore)
        fire:Destroy()
        return isNow == true
    end)
    sendTest(test, success and result == true)
end

-- setsimulationradius
do
    local test = "setsimulationradius: exists and is callable"
    local success, result = pcall(function()
        return type(setsimulationradius) == "function"
    end)
    sendTest(test, success and result == true)
end

-- isnetworkowner
do
    local test = "isnetworkowner: exists and is callable"
    local success, result = pcall(function()
        return type(isnetworkowner) == "function"
    end)
    sendTest(test, success and result == true)
end

-- getcallbackvalue
do
    local test = "getcallbackvalue: returns callback function"
    local success, result = pcall(function()
        local bd = Instance.new("BindableFunction")
        bd.OnInvoke = function() return "test" end
        local cb = getcallbackvalue(bd, "OnInvoke")
        bd:Destroy()
        return type(cb) == "function"
    end)
    sendTest(test, success and result == true)
end

-- fireproximityprompt
do
    local test = "fireproximityprompt: exists and is callable"
    local success, result = pcall(function()
        return type(fireproximityprompt) == "function"
    end)
    sendTest(test, success and result == true)
end

-- setrbxclipboard
do
    local test = "setrbxclipboard: exists and is callable"
    local success, result = pcall(function()
        return type(setrbxclipboard) == "function"
    end)
    sendTest(test, success and result == true)
end

-- getrendersteppedlist
do
    local test = "getrendersteppedlist: returns a table"
    local success, result = pcall(function()
        local list = getrendersteppedlist()
        return type(list) == "table"
    end)
    sendTest(test, success and result == true)
end

-- replicatesignal
do
    local test = "replicatesignal: exists and is callable"
    local success, result = pcall(function()
        return type(replicatesignal) == "function"
    end)
    sendTest(test, success and result == true)
end

-- ============================================================
-- METATABLE
-- ============================================================

print("\n========== METATABLE ==========\n")

-- getrawmetatable
do
    local test = "getrawmetatable: bypasses __metatable"
    local success, result = pcall(function()
        local t = setmetatable({}, {__metatable = "locked", __index = function() return 1 end})
        local mt = getrawmetatable(t)
        return type(mt) == "table" and mt.__index ~= nil
    end)
    sendTest(test, success and result == true)
end

-- isreadonly / setreadonly
do
    local test = "isreadonly/setreadonly: table freeze and unfreeze"
    local success, result = pcall(function()
        local t = {}
        setreadonly(t, true)
        local frozen = isreadonly(t)
        setreadonly(t, false)
        local unfrozen = isreadonly(t)
        return frozen == true and unfrozen == false
    end)
    sendTest(test, success and result == true)
end

-- makewriteable / makereadonly
do
    local test = "makewriteable/makereadonly: works correctly"
    local success, result = pcall(function()
        local t = {}
        makereadonly(t)
        local frozen = isreadonly(t)
        makewriteable(t)
        local unfrozen = isreadonly(t)
        return frozen == true and unfrozen == false
    end)
    sendTest(test, success and result == true)
end

-- setrawmetatable
do
    local test = "setrawmetatable: bypasses __metatable lock"
    local success, result = pcall(function()
        local t = setmetatable({}, {__metatable = "locked"})
        setrawmetatable(t, {__index = function() return 42 end})
        return t.anything == 42
    end)
    sendTest(test, success and result == true)
end

-- hookmetamethod
do
    local test = "hookmetamethod: hooks __index metamethod"
    local success, result = pcall(function()
        local t = setmetatable({}, {__index = function(_, k) return k end})
        local old = hookmetamethod(t, "__index", function(self, key)
            if key == "hooked" then return "yes" end
            return old(self, key)
        end)
        return t.hooked == "yes"
    end)
    sendTest(test, success and result == true)
end

-- getnamecallmethod
do
    local test = "getnamecallmethod: exists and is callable"
    local success, result = pcall(function()
        return type(getnamecallmethod) == "function"
    end)
    sendTest(test, success and result == true)
end

-- setnamecallmethod
do
    local test = "setnamecallmethod: exists and is callable"
    local success, result = pcall(function()
        return type(setnamecallmethod) == "function"
    end)
    sendTest(test, success and result == true)
end

-- ============================================================
-- MISCELLANEOUS
-- ============================================================

print("\n========== MISCELLANEOUS ==========\n")

-- identifyexecutor
do
    local test = "identifyexecutor: returns name and version strings"
    local success, result = pcall(function()
        local name, version = identifyexecutor()
        return type(name) == "string" and type(version) == "string"
    end)
    sendTest(test, success and result == true)
end

-- lz4compress / lz4decompress
do
    local test = "lz4compress/lz4decompress: roundtrip preserves data"
    local success, result = pcall(function()
        local original = "Hello, World! This is a test of LZ4 compression."
        local compressed = lz4compress(original)
        local decompressed = lz4decompress(compressed, #original)
        return decompressed == original
    end)
    sendTest(test, success and result == true)
end

-- setclipboard
do
    local test = "setclipboard: exists and is callable"
    local success, result = pcall(function()
        return type(setclipboard) == "function"
    end)
    sendTest(test, success and result == true)
end

-- setfpscap
do
    local test = "setfpscap: exists and is callable"
    local success, result = pcall(function()
        return type(setfpscap) == "function"
    end)
    sendTest(test, success and result == true)
end

-- messagebox
do
    local test = "messagebox: exists and is callable"
    local success, result = pcall(function()
        return type(messagebox) == "function"
    end)
    sendTest(test, success and result == true)
end

-- queue_on_teleport
do
    local test = "queue_on_teleport: exists and is callable"
    local success, result = pcall(function()
        return type(queue_on_teleport) == "function"
    end)
    sendTest(test, success and result == true)
end

-- request
do
    local test = "request: sends HTTP GET and returns response"
    local success, result = pcall(function()
        local response = request({
            Url = "https://httpbin.org/get",
            Method = "GET"
        })
        return type(response) == "table" and response.StatusCode == 200
    end)
    sendTest(test, success and result == true)
end

do
    local test = "request: sends HTTP POST with body"
    local success, result = pcall(function()
        local response = request({
            Url = "https://httpbin.org/post",
            Method = "POST",
            Body = "hello=world",
            Headers = {
                ["Content-Type"] = "application/x-www-form-urlencoded"
            }
        })
        return type(response) == "table" and response.StatusCode == 200
    end)
    sendTest(test, success and result == true)
end

-- getfflag / setfflag
do
    local test = "getfflag: exists and is callable"
    local success, result = pcall(function()
        return type(getfflag) == "function"
    end)
    sendTest(test, success and result == true)
end

do
    local test = "setfflag: exists and is callable"
    local success, result = pcall(function()
        return type(setfflag) == "function"
    end)
    sendTest(test, success and result == true)
end

-- getinternalparent / setinternalparent
do
    local test = "getinternalparent: exists and is callable"
    local success, result = pcall(function()
        return type(getinternalparent) == "function"
    end)
    sendTest(test, success and result == true)
end

do
    local test = "setinternalparent: exists and is callable"
    local success, result = pcall(function()
        return type(setinternalparent) == "function"
    end)
    sendTest(test, success and result == true)
end

-- ============================================================
-- SCRIPTS
-- ============================================================

print("\n========== SCRIPTS ==========\n")

-- getgc
do
    local test = "getgc: returns a table"
    local success, result = pcall(function()
        local gc = getgc()
        return type(gc) == "table" and #gc > 0
    end)
    sendTest(test, success and result == true)
end

do
    local test = "getgc: includes tables when flag is true"
    local success, result = pcall(function()
        local gc = getgc(true)
        local hasTable = false
        for _, v in pairs(gc) do
            if type(v) == "table" then hasTable = true; break end
        end
        return hasTable
    end)
    sendTest(test, success and result == true)
end

-- getgenv
do
    local test = "getgenv: returns a table"
    local success, result = pcall(function()
        local env = getgenv()
        return type(env) == "table"
    end)
    sendTest(test, success and result == true)
end

do
    local test = "getgenv: setting a value persists"
    local success, result = pcall(function()
        getgenv().__potassium_test = "test_value"
        return getgenv().__potassium_test == "test_value"
    end)
    sendTest(test, success and result == true)
    getgenv().__potassium_test = nil
end

-- getrenv
do
    local test = "getrenv: returns a table with game globals"
    local success, result = pcall(function()
        local env = getrenv()
        return type(env) == "table" and env.game ~= nil
    end)
    sendTest(test, success and result == true)
end

-- getreg
do
    local test = "getreg: returns a table"
    local success, result = pcall(function()
        local reg = getreg()
        return type(reg) == "table"
    end)
    sendTest(test, success and result == true)
end

-- getloadedmodules
do
    local test = "getloadedmodules: returns table of ModuleScripts"
    local success, result = pcall(function()
        local modules = getloadedmodules()
        if type(modules) ~= "table" then return false end
        if #modules > 0 then
            return modules[1]:IsA("ModuleScript")
        end
        return true
    end)
    sendTest(test, success and result == true)
end

-- getrunningscripts
do
    local test = "getrunningscripts: returns table of scripts"
    local success, result = pcall(function()
        local scripts = getrunningscripts()
        return type(scripts) == "table"
    end)
    sendTest(test, success and result == true)
end

-- getscripts
do
    local test = "getscripts: returns table of scripts"
    local success, result = pcall(function()
        local scripts = getscripts()
        return type(scripts) == "table" and #scripts > 0
    end)
    sendTest(test, success and result == true)
end

-- getscriptbytecode
do
    local test = "getscriptbytecode: returns bytecode string for a module"
    local success, result = pcall(function()
        local modules = getloadedmodules()
        if #modules == 0 then return true end -- skip if no modules
        local bytecode = getscriptbytecode(modules[1])
        return type(bytecode) == "string" and #bytecode > 0
    end)
    sendTest(test, success and result == true)
end

-- getscriptclosure
do
    local test = "getscriptclosure: returns a function"
    local success, result = pcall(function()
        local modules = getloadedmodules()
        if #modules == 0 then return true end
        local closure = getscriptclosure(modules[1])
        return type(closure) == "function"
    end)
    sendTest(test, success and result == true)
end

-- getscripthash
do
    local test = "getscripthash: returns a hash string"
    local success, result = pcall(function()
        local modules = getloadedmodules()
        if #modules == 0 then return true end
        local hash = getscripthash(modules[1])
        return type(hash) == "string" and #hash > 0
    end)
    sendTest(test, success and result == true)
end

-- getsenv
do
    local test = "getsenv: returns environment table for a script"
    local success, result = pcall(function()
        local scripts = getrunningscripts()
        for _, s in pairs(scripts) do
            if s:IsA("LocalScript") then
                local env = getsenv(s)
                return type(env) == "table"
            end
        end
        return true -- skip if no local scripts running
    end)
    sendTest(test, success and result == true)
end

-- gettenv
do
    local test = "gettenv: returns environment table for current thread"
    local success, result = pcall(function()
        local env = gettenv(coroutine.running())
        return type(env) == "table"
    end)
    sendTest(test, success and result == true)
end

-- getthreadidentity / setthreadidentity
do
    local test = "getthreadidentity: returns a number"
    local success, result = pcall(function()
        return type(getthreadidentity()) == "number"
    end)
    sendTest(test, success and result == true)
end

do
    local test = "setthreadidentity/getthreadidentity: set and restore identity"
    local success, result = pcall(function()
        local original = getthreadidentity()
        setthreadidentity(3)
        local changed = getthreadidentity()
        setthreadidentity(original)
        local restored = getthreadidentity()
        return changed == 3 and restored == original
    end)
    sendTest(test, success and result == true)
end

-- ============================================================
-- WEBSOCKETS
-- ============================================================

print("\n========== WEBSOCKETS ==========\n")

do
    local test = "WebSocket.connect: exists and is callable"
    local success, result = pcall(function()
        return type(WebSocket) == "table" and type(WebSocket.connect) == "function"
    end)
    sendTest(test, success and result == true)
end

-- ============================================================
-- ACTOR
-- ============================================================

print("\n========== ACTOR ==========\n")

do
    local test = "getactors: exists and returns table"
    local success, result = pcall(function()
        local actors = getactors()
        return type(actors) == "table"
    end)
    sendTest(test, success and result == true)
end

do
    local test = "is_parallel: returns false in main thread"
    local success, result = pcall(function()
        return is_parallel() == false
    end)
    sendTest(test, success and result == true)
end

do
    local test = "create_comm_channel: returns id and BindableEvent"
    local success, result = pcall(function()
        local id, event = create_comm_channel()
        return type(id) == "number" and typeof(event) == "Instance" and event:IsA("BindableEvent")
    end)
    sendTest(test, success and result == true)
end

do
    local test = "get_comm_channel: retrieves created channel"
    local success, result = pcall(function()
        local id, event = create_comm_channel()
        local retrieved = get_comm_channel(id)
        return typeof(retrieved) == "Instance" and retrieved:IsA("BindableEvent")
    end)
    sendTest(test, success and result == true)
end

do
    local test = "getactorthreads: exists and returns table"
    local success, result = pcall(function()
        local threads = getactorthreads()
        return type(threads) == "table"
    end)
    sendTest(test, success and result == true)
end

do
    local test = "run_on_actor: exists and is callable"
    local success, result = pcall(function()
        return type(run_on_actor) == "function"
    end)
    sendTest(test, success and result == true)
end

do
    local test = "run_on_thread: exists and is callable"
    local success, result = pcall(function()
        return type(run_on_thread) == "function"
    end)
    sendTest(test, success and result == true)
end

-- ============================================================
-- RESULTS
-- ============================================================

print("\n========== RESULTS ==========\n")

print(string.format(
    "Completed the tests with a success rate of %.2f%% (%d/%d; Failed: %d) within %.2f seconds\n\n%s",
    (sunc / tcount) * 100,
    sunc,
    tcount,
    failed,
    tick() - time,
    string.rep("\t", 4) .. "View 'https://docs.sunc.su' for more accurate and detailed results."
))

local gui = Instance.new("ScreenGui")
gui.Name = rname()
gui.Parent = gethui() or game.CoreGui

local button = Instance.new("TextButton", gui)
button.Name = rname()
button.Text = "Load Extra?"
button.AnchorPoint = Vector2.new(0.5, 0.5); button.Position = UDim2.fromScale(0.75, 0.5)
button.Size = UDim2.fromScale(0.1, 0.05)
Instance.new("UICorner", button).CornerRadius = UDim.new(0.2, 0)

button.Activated:Connect(function()
    loadstring(game:HttpGet("https://website-iota-ivory-12.vercel.app/code/scripts/unc/sunc/extra.luau"))()
end)
