local functions = functions or {} -- reuse previous table if exists
local function add(name, func)
    functions[name] = func
end

-- Cache

add("cache.invalidate", function(object)
    print("[stub] cache.invalidate", object)
end)

add("cache.iscached", function(object)
    return false
end)

add("cache.replace", function(object, newobject)
    print("[stub] cache.replace", object, newobject)
end)

add("cloneref", function(object)
    return object
end)

add("compareinstances", function(a, b)
    return a == b
end)

-- Closures

add("checkcaller", function()
    return false
end)

add("clonefunction", function(func)
    return func
end)

add("getcallingscript", function()
    return nil
end)

local ishooked = {}
add("hookfunction", function(func, hook)
    return ishooked[func]
end)

add("hookfunction", function(func, hook)
    ishooked[func] = hook
    return func
end)

add("restorefunction", function(func, hook)
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
    if iscclosure and iscclosure(func) then
        return false
    end

    if islclosure and islclosure(func) then
        return false
    end

    return true
end)

add("loadstring", function(source)
    do end
end)

add("newcclosure", function(func)
    return func
end)

-- Rconsole

-- just make rconsole a ui? probbaly
add("rconsoleclear", function()
    do end
end)
add("rconsolecreate", function()
    do end -- PEAK
end)
add("rconsoledestroy", function()
    do end
end)
add("rconsoleinput", function()
    return ""
end)
add("rconsoleprint", function(text)
    print(text)
end)
add("rconsolewarn", function(text)
    warn(text)
end)
add("rconsoleerror", function(text)
    error(text)
end)
add("rconsolesettitle", function(title)
    do end -- PEAK
end)

-- Crypt

-- Base64 encode/decode
local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/' 

add("crypt.base64encode", function(data)
    return ((data:gsub('.', function(x)
        local r,binary='',x:byte()
        for i=8,1,-1 do r=r..(binary%2^i-binary%2^(i-1)>0 and '1' or '0') end
        return r
    end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if #x < 6 then return '' end
        local c=0
        for i=1,6 do c=c + (x:sub(i,i)=='1' and 2^(6-i) or 0) end
        return b:sub(c+1,c+1)
    end)..({ '', '==', '=' })[#data%3+1])
end)

add("crypt.base64decode", function(data)
    data = data:gsub('[^'..b..'=]', '')
    return (data:gsub('.', function(x)
        if x=='=' then return '' end
        local r,f='',(b:find(x)-1)
        for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
        return r
    end):gsub('%d%d%d%d%d%d%d%d', function(x)
        local c=0
        for i=1,8 do c=c + (x:sub(i,i)=='1' and 2^(8-i) or 0) end
        return string.char(c)
    end))
end)

-- Simple XOR encrypt/decrypt
add("crypt.encrypt", function(data, key, iv, mode)
    key = key or ""
    iv = iv or ""
    local out = {}
    for i=1,#data do
        local di = data:byte(i)
        local ki = key:byte((i-1)%#key + 1)
        out[i] = string.char(bit32.bxor(di, ki))
    end
    return table.concat(out), iv
end)

add("crypt.decrypt", function(data, key, iv, mode)
    -- XOR decrypt is identical to encrypt
    key = key or ""
    local out = {}
    for i=1,#data do
        local di = data:byte(i)
        local ki = key:byte((i-1)%#key + 1)
        out[i] = string.char(bit32.bxor(di, ki))
    end
    return table.concat(out)
end)

-- Generate bytes/key
add("crypt.generatebytes", function(size)
    local out = {}
    for i=1,size do out[i] = string.char(math.random(0,255)) end
    return table.concat(out)
end)

add("crypt.generatekey", function()
    return crypt.generatebytes(32)
end)

-- Hashing (simple Lua SHA-1 alternative using md5 if available, otherwise fallback)
add("crypt.hash", function(data, algo)
    algo = algo or "md5"
    if algo:lower() == "md5" then
        local md5 = game:GetService("HttpService"):GenerateGUID(false)
        return md5:sub(1,#data) -- simple pseudo-hash fallback
    else
        return data -- fallback for unsupported algorithms
    end
end)

-- Debug

add("debug.isvalidlevel", function(level)
    return type(level) == "number" and level >= 0
end)

local registry = {} -- i dunno
add("debug.getregistry", function()
    return getreg and getreg() or {}
end)

local constants = {}
add("debug.getconstant", function(func, index)
    local c = constants[func]
    if not c or c[index] == nil then
        error("constant does not exist")
    end
    return c[index]
end)

add("debug.getconstants", function(func)
    return constants[func] or {}
end)

add("debug.setconstant", function(func, index, value)
    constants[func] = constants[func] or {}
    constants[func][index] = value
end)

local upvalues = {}
add("debug.getupvalue", function(func, index)
    local u = upvalues[func]
    if not u or u[index] == nil then
        error("upvalue does not exist")
    end
    return u[index]
end)

add("debug.getupvalues", function(func)
    return upvalues[func] or {}
end)

add("debug.setupvalue", function(func, index, value)
    upvalues[func] = upvalues[func] or {}
    upvalues[func][index] = value
end)

local stacks = {}
add("debug.getstack", function(level, index)
    local stack = stacks[level]
    if not stack then
        error("invalid stack level")
    end

    if index then
        if stack[index] == nil then
            error("stack value does not exist")
        end
        return stack[index]
    end

    return stack
end)

add("debug.setstack", function(level, index, value)
    stacks[level] = stacks[level] or {}
    stacks[level][index] = value
end)

add("debug.getinfo", function(func)
    local source = debug.info(func, "s")
    local name = debug.info(func, "n")
    local line = debug.info(func, "l")
    local nups = debug.info(func, "u") or 0
    local params, vararg = debug.info(func, "a")

    return {
        source = source,
        short_src = source,
        func = func,
        what = "Lua",
        currentline = line,
        name = name,
        nups = nups,
        numparams = params or 0,
        is_vararg = vararg and 1 or 0
    }
end)

-- protos (cannot exist in luau without executor)
add("debug.getproto", function()
    return nil
end)

add("debug.getprotos", function()
    return {}
end)


-- Drawing

-- Input

-- Instance

add("gethui", function()
    return cloneref(game:GetService("CoreGui"))["RobloxGui"]
end)

add("getinstances", function()
    local t = {game}

    for _,v in ipairs(game:GetDescendants()) do
        t[#t+1] = v
    end

    return t
end)

local nilinstances = {}
add("getnilinstances", function()
    local t = {}

    for _,v in ipairs(nilinstances) do
        if v.Parent == nil then
            t[#t+1] = v
        end
    end

    return t
end)

add("isscriptable", function(obj, prop)
    if typeof(obj) ~= "Instance" then
        return nil
    end

    if obj[prop] ~= nil then
        return true
    end

    local ok = obj:GetPropertyChangedSignal(prop)
    if ok then
        return false
    end

    return nil
end)

-- Misc

add("identifyexecutor", function()
    return "Potassium", "1.0"
end)

-- not actually lz4
add("lz4compress", function(data)
    -- run length
    local out = {}
    local count = 1
    for i = 2,#data+1 do
        if data:sub(i,i) == data:sub(i-1,i-1) then
            count = count + 1
        else
            if count > 1 then
                table.insert(out, string.char(count))
            end
            table.insert(out, data:sub(i-1,i-1))
            count = 1
        end
    end
    return table.concat(out)
end)

add("lz4decompress", function(data, size)
    local out = {}
    local i = 1
    while i <= #data do
        local byte = data:byte(i)
        if byte >= 2 then -- count marker
            local char = data:sub(i+1,i+1)
            table.insert(out, string.rep(char, byte))
            i = i + 2
        else
            table.insert(out, data:sub(i,i))
            i = i + 1
        end
    end
    return table.concat(out)
end)

local parent = Instance.new("Folder", gethui())
parent.Name = "mboxes"

add("messagebox", function(text, caption, flags)
    local gui = Instance.new("ScreenGui")
    gui.Name = tostring(math.random(1e4, 1e5))
    gui.Parent = parent

    local window = Instance.new("Frame")
    window.Size = UDim2.fromOffset(349,151)
    window.Position = UDim2.new(0.5,-174,0.5,-75)
    window.BackgroundColor3 = Color3.fromRGB(255,255,255)
    window.Draggable = true
    window.BorderSizePixel = 0
    window.ClipsDescendants = true
    window.Parent = gui

    local wc = Instance.new("UICorner", window)
    wc.CornerRadius = UDim.new(0, 8)

    local strip = Instance.new("Frame")
    strip.Size = UDim2.fromOffset(349,35)
    strip.Position = UDim2.fromOffset(0,0)
    strip.BackgroundColor3 = Color3.fromRGB(240,240,240)
    strip.BorderSizePixel = 0
    strip.ClipsDescendants = true
    strip.Parent = window

    Instance.new("UICorner", strip).CornerRadius = wc.CornerRadius

    local title = Instance.new("TextLabel")
    title.Size = UDim2.fromOffset(260,18)
    title.Position = UDim2.fromOffset(14,10)
    title.BackgroundTransparency = 1
    title.Text = tostring(caption or "Title")
    title.Font = Enum.Font.SourceSans
    title.TextSize = 16
    title.TextColor3 = Color3.fromRGB(0,0,0)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = window

    local close = Instance.new("TextButton")
    close.Size = UDim2.fromOffset(20,20)
    close.Position = UDim2.fromOffset(321,8)
    close.Text = "X"
    close.Font = Enum.Font.SourceSansBold
    close.TextSize = 16
    close.BackgroundColor3 = Color3.fromRGB(255,255,255)
    close.BackgroundTransparency = 1
    close.TextColor3 = Color3.fromRGB(0,0,0)
    close.Parent = window

    close.MouseButton1Click:Connect(function()
        gui:Destroy()
    end)

    close.MouseEnter:Connect(function()
        close.BackgroundColor3 = Color3.fromRGB(255,0,0)
    end)

    close.MouseLeave:Connect(function()
        close.BackgroundColor3 = Color3.fromRGB(255,255,255)
    end)

    local msg = Instance.new("TextLabel")
    msg.Size = UDim2.fromOffset(250,20)
    msg.Position = UDim2.fromOffset(54,58)
    msg.BackgroundTransparency = 1
    msg.Text = tostring(text or "Message text")
    msg.Font = Enum.Font.SourceSans
    msg.TextSize = 14
    msg.TextColor3 = Color3.fromRGB(0,0,0)
    msg.TextXAlignment = Enum.TextXAlignment.Left
    msg.Parent = window

    local strip2 = Instance.new("Frame")
    strip2.Size = UDim2.fromOffset(349,38)
    strip2.Position = UDim2.fromOffset(0,window.Size.Y.Offset - 38)
    strip2.BackgroundColor3 = Color3.fromRGB(240,240,240)
    strip2.BorderSizePixel = 0
    strip2.ClipsDescendants = true
    strip2.Parent = window

    local s2c = Instance.new("UICorner")
    s2c.CornerRadius = wc.CornerRadius
    s2c.Parent = strip2

    local function create(text, pos)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.fromOffset(72,26)
        btn.Position = UDim2.fromOffset(pos, 5.8)
        btn.BackgroundColor3 = Color3.fromRGB(240,240,240)
        btn.Text = text
        btn.Font = Enum.Font.SourceSans
        btn.TextSize = 14
        btn.TextColor3 = Color3.fromRGB(0,0,0)
        btn.ClipsDescendants = true
        btn.Parent = strip2

        Instance.new("UICorner", btn).CornerRadius = UDim.new(0,4)

        local stroke = Instance.new("UIStroke", btn)
        stroke.Color = Color3.fromRGB(200,200,200)
        stroke.Thickness = 1
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

        return btn
    end

    local ok = create("OK", 263)
    ok.MouseButton1Click:Connect(function()
        gui:Destroy()
    end)
end)

add("queue_on_teleport", function(code)
    do end -- writefile -- useless anyway -- PEAK
end)

add("request", function(options)
    options = options or {}
    local url = options.Url or ""
    local method = (options.Method or "GET"):upper()
    local headers = options.Headers or {}
    local body = options.Body or ""

    local response = {
        StatusCode = 0,
        Body = "",
        Headers = {},
    }

    local success, result = pcall(function()
        if method == "GET" then
            return game:HttpGet(url, true)
        elseif method == "POST" then
            return game:HttpPost(url, body, Enum.HttpContentType.ApplicationUrlEncoded)
        else
            error("Unsupported method: "..method)
        end
    end)

    if success then
        response.StatusCode = 200
        response.Body = result
    else
        response.StatusCode = 500
        response.Body = tostring(result)
    end

    return response
end)

add("getinternalparent", function(instance)
    return instance.Parent
end)

add("setinternalparent", function(instance, newparent)
    instance.Parent = newparent
end)

local s = settings()
add("getfflag", function(fflag)
    return s:GetFFlag(fflag)
end)

add("setfflag", function(fflag, value)
    s:SetFFlag(fflag, value)
end)

add("setclipboard", function(text)
    print(text)
end)

local fps = workspace:GetRealPhysicsFPS() -- close enough
add("setfpscap", function(f)
    fps = f
end)

add("getfpscap", function()
    return fps
end)

-- Scripts

add("getscriptclosure", function(scr)
    if typeof(scr) == "Instance" and scr:IsA("ModuleScript") then
        return function(...)
            return require(scr)(...)
        end
    end
end)

add("getscriptbyetcode", function(item)
    return decompile(item)
end)

add("getscripthash", function(item)
    return crypt.hash(getscriptbytecode(item))
end)

local scripts = {}
add("getrunningscripts", function()
    for _,v in ipairs(game:GetDescendants()) do
        if v:IsA("LocalScript") and v.Enabled then
            scripts[#scripts+1] = v
        elseif v:IsA("ModuleScript") then
            scripts[#scripts+1] = v
        end
    end

    return scripts
end)

add("getloadedmodules", function()
    local modules = {}
    for _,s in ipairs(getrunningscripts()) do
        if s.ClassName == "ModuleScript" then
            modules[#modules+1] = s
        end
    end
    return modules
end)

add("getreg", function()
    return debug.getregistry and debug.getregistry() or {}
end)

add("getgenv", function()
    return getfenv(0)
end)

add("getrenv", function()
    return getfenv(0)
end)

add("getenv", function(obj)
    if type(obj) == "function" then
        return getfenv(obj)
    end
    if type(obj) == "number" then
        return getfenv(obj)
    end
end)

add("getsenv", function(scr)
    if typeof(scr) == "Instance" and scr:IsA("LocalScript") then
        return getfenv(0)
    end
end)

local thread_identity = 8
add("getthreadidentity", function()
    return thread_identity
end)

add("setthreadidentity", function(identity)
    thread_identity = identity
end)

-- Actors

add("create_comm_channel", function()
    local be = Instance.new("BindableEvent")
    return math.random(1,99999), be
end)

add("get_comm_channel", function(id)
    return Instance.new("BindableEvent")
end)

add("run_on_actor", function(actor, scriptStr, ...)
    do end -- PEAK
end)

add("getactors", function()
    return {}
end)

add("is_parallel", function()
    return false
end)

add("run_on_thread", function(thread, scriptStr, ...)
    do end -- PEAK
end)

add("getactorthreads", function()
    return {}
end)

for name, func in pairs(functions) do
    local parts = {}
    for part in name:gmatch("[^%.]+") do
        table.insert(parts, part)
    end

    local tbl = getgenv()
    for i = 1, #parts - 1 do
        if tbl[parts[i]] == nil then
            tbl[parts[i]] = {}
        end
        tbl = tbl[parts[i]]
    end

    if tbl[parts[#parts]] == nil then
        tbl[parts[#parts]] = func
    end
end
