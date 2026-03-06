local functions = {}
local function add(name, func)
    functions[name] = func
end

-- Cache

-- add : table.insert(stored, object)

local stored = {}
add("cache.invalidate", function(object)
    stored[object] = nil
end)

add("cache.iscached", function(object)
    return stored[object] ~= nil
end)

add("cache.replace", function(object, new)
    stored[object] = new
end)

local function t(item)
    return typeof(item) ~= "Instance" -- false
end

add("cloneref", function(object)
    if t(object) then return end 
    return object
end)

add("compareinstances", function(a, b)
    if t(a) or t(b) then return end

    return a == b
end)

-- Closures

add("checkcaller", function()
    return true -- iscclosure idk
end)

add("clonefunction", function(func)
    return func
end)

add("getcallingscript", function()
    return nil
end)

local ishooked = {}
add("isfunctionhooked", function(func, hook)
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

local function vm(source, env)
    env = env or {}

    -- convert source to instructions
    local instructions = {}

    for token in source:gmatch("%S+") do
        if tonumber(token) then
            table.insert(instructions, {"PUSH", tonumber(token)})
        elseif token == "true" then
            table.insert(instructions, {"PUSH", true})
        elseif token == "false" then
            table.insert(instructions, {"PUSH", false})
        elseif token == "nil" then
            table.insert(instructions, {"PUSH", nil})
        elseif token:match("^%a[%w_]*$") then
            table.insert(instructions, {"LOAD", token})
        elseif token == "+" then
            table.insert(instructions, {"ADD"})
        elseif token == "-" then
            table.insert(instructions, {"SUB"})
        elseif token == "*" then
            table.insert(instructions, {"MUL"})
        elseif token == "/" then
            table.insert(instructions, {"DIV"})
        elseif token == "return" then
            table.insert(instructions, {"RET"})
        else
            error("Unsupported token: "..token)
        end
    end

    local stack, ip = {}, 1
    -- ip = instruction pointer

    while ip <= #instructions do
        local instr = instructions[ip]
        local op = instr[1]
        if op == "PUSH" then
            table.insert(stack, instr[2])
        elseif op == "LOAD" then
            table.insert(stack, env[instr[2]])
        elseif op == "ADD" then
            local b = table.remove(stack)
            local a = table.remove(stack)
            table.insert(stack, a + b)
        elseif op == "SUB" then
            local b = table.remove(stack)
            local a = table.remove(stack)
            table.insert(stack, a - b)
        elseif op == "MUL" then
            local b = table.remove(stack)
            local a = table.remove(stack)
            table.insert(stack, a * b)
        elseif op == "DIV" then
            local b = table.remove(stack)
            local a = table.remove(stack)
            table.insert(stack, a / b)
        elseif op == "RET" then
            return table.remove(stack)
        end
        ip += 1
    end

    return table.remove(stack)
end

add("load", function(source)
    return function(...)
        local ok, res = pcall(vm, source, getgenv())
        if not ok then
            error(res)
        end
        return res
    end
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

local function bxor(left, right)
    local result = 0
    local bit = 1

    while left > 0 or right > 0 do
        -- lowest num
        local leftBit = left % 2
        local rightBit = right % 2

        if leftBit ~= rightBit then
            result = result + bit
        end

        -- shift right one bit
        left = (left - leftBit) / 2
        right = (right - rightBit) / 2

        bit = bit * 2 -- next pos
    end

    return result
end

add("crypt.encrypt", function(data,key)
    local out = {}
    local klen = #key

    for i=1,#data do
        local d = string.byte(data,i)
        local k = string.byte(key,((i-1)%klen)+1)
        out[i] = string.char(bxor(d,k))
    end

    return table.concat(out)
end)

add("crypt.decrypt", function(data,key)
    local out = {}
    local klen = #key

    for i=1,#data do
        local d = string.byte(data,i)
        local k = string.byte(key,((i-1)%klen)+1)
        out[i] = string.char(bxor(d,k))
    end

    return table.concat(out)
end)

add("crypt.hash", function(str)
    local h = 0
    for i=1,#str do
        h = (h*31 + string.byte(str,i)) % 4294967296
    end
    return h
end)

add("crypt.random", function(len)
    local t = {}
    for i=1,len do
        t[i] = string.char(math.random(0,255))
    end
    return table.concat(t)
end)

-- these arent yk real but i dont see why it shouldnt be implemented
add("crypt.tohex", function(str)
    return (str:gsub(".", function(c)
        return string.format("%02x", string.byte(c))
    end))
end)

add("crypt.fromhex", function(str)
    return (str:gsub("%x%x", function(c)
        return string.char(tonumber(c,16))
    end))
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

add("debug.getproto", function()
    return nil
end)

add("debug.getprotos", function()
    return {}
end)

-- Drawing

local drawings, Drawing = {}, {}

Drawing.Fonts = {
    UI = 0,
    System = 1,
    Plex = 2,
    Monospace = 3
}

local valid = {
    Line = true,
    Text = true,
    Image = true,
    Circle = true,
    Square = true,
    Quad = true,
    Triangle = true
}

local function base()
    return {
        Visible = false,
        ZIndex = 0,
        Transparency = 1,
        Color = Color3.new(1,1,1)
    }
end

local function create(type)
    local obj = base()
    obj.__type = type

    if type == "Line" then
        obj.From = Vector2.zero
        obj.To = Vector2.zero
        obj.Thickness = 1
    elseif type == "Text" then
        obj.Text = ""
        obj.TextBounds = Vector2.zero
        obj.Font = 0
        obj.Size = 13
        obj.Position = Vector2.zero
        obj.Center = false
        obj.Outline = false
        obj.OutlineColor = Color3.new(0,0,0)
    elseif type == "Image" then
        obj.Data = ""
        obj.Size = Vector2.zero
        obj.Position = Vector2.zero
        obj.Rounding = 0
    elseif type == "Circle" then
        obj.NumSides = 20
        obj.Radius = 0
        obj.Position = Vector2.zero
        obj.Thickness = 1
        obj.Filled = false
    elseif type == "Square" then
        obj.Size = Vector2.zero
        obj.Position = Vector2.zero
        obj.Thickness = 1
        obj.Filled = false
    elseif type == "Quad" then
        obj.PointA = Vector2.zero
        obj.PointB = Vector2.zero
        obj.PointC = Vector2.zero
        obj.PointD = Vector2.zero
        obj.Thickness = 1
        obj.Filled = false
    elseif type == "Triangle" then
        obj.PointA = Vector2.zero
        obj.PointB = Vector2.zero
        obj.PointC = Vector2.zero
        obj.Thickness = 1
        obj.Filled = false
    end

    function obj:Destroy()
        drawings[self] = nil
    end

    drawings[obj] = true

    return obj
end

Drawing.new = function(type)
    if not valid[type] then
        error("invalid drawing type: "..tostring(type))
    end

    return create(type)
end

add("cleardrawcache", function()
    for v in pairs(drawings) do
        if v.Destroy then
            v:Destroy()
        end
    end
end)

add("getrenderproperty", function(drawing, prop)
    return drawing[prop]
end)

add("setrenderproperty", function(drawing, prop, val)
    drawing[prop] = val
end)

add("isrenderobj", function(obj)
    return drawings[obj] ~= nil
end)

-- File System

local function normalize(path)
    path = tostring(path or "")
    path = path:gsub("\\","/")
    path = path:gsub("^/","")
    return path
end

local function parent(path)
    return path:match("(.+)/[^/]+$") or ""
end

local fs_files = {}; local fs_folders = {[""] = true}
add("writefile", function(path, data)
    path = normalize(path)
    fs_files[path] = tostring(data or "")
    fs_folders[parent(path)] = true
end)

add("appendfile", function(path, data)
    path = normalize(path)
    fs_files[path] = (fs_files[path] or "") .. tostring(data or "")
    fs_folders[parent(path)] = true
end)

add("readfile", function(path)
    path = normalize(path)
    if fs_files[path] == nil then
        error("file does not exist")
    end
    return fs_files[path]
end)

add("isfile", function(path)
    path = normalize(path)
    return fs_files[path] ~= nil
end)

add("makefolder", function(path)
    path = normalize(path)
    fs_folders[path] = true
end)

add("isfolder", function(path)
    path = normalize(path)
    return fs_folders[path] == true
end)

add("listfiles", function(path)
    path = normalize(path)
    local out = {}

    for f,_ in pairs(fs_files) do
        if f:sub(1,#path) == path then
            table.insert(out, f)
        end
    end

    for f,_ in pairs(fs_folders) do
        if f ~= "" and f:sub(1,#path) == path then
            table.insert(out, f)
        end
    end

    return out
end)

add("delfile", function(path)
    path = normalize(path)
    fs_files[path] = nil
end)

add("delfolder", function(path)
    path = normalize(path)

    for f,_ in pairs(fs_files) do
        if f:sub(1,#path) == path then
            fs_files[f] = nil
        end
    end

    for f,_ in pairs(fs_folders) do
        if f:sub(1,#path) == path then
            fs_folders[f] = nil
        end
    end
end)

add("loadfile", function(path, chunkname)
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
    local fn, err = loadfile(path)
    if not fn then
        error(err)
    end

    task.spawn(fn)
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
    vim:SendMouseMoveEvent(x, y, game)
end)

add("mousemoverel", function(x, y)
    local pos = uis:GetMouseLocation()
    vim:SendMouseMoveEvent(pos.X + x, pos.Y + y, game)
end)

add("mousescroll", function(pixels)
    vim:SendMouseWheelEvent(0, 0, pixels > 0, game)
end)

-- Instance


local lp = game:GetService("Players")["LocalPlayer"]
local char = lp["Character"]
local hrp = char["HumanoidRootPart"]

add("fireclickdetector", function(cd, distance)
    if typeof(cd) ~= "Instance" or not cd:IsA("ClickDetector") then return end
    
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
    if typeof(part) ~= "Instance" or not part:IsA("BasePart") then return end

    if state == 0 then
        hrp.CFrame = part.CFrame
    else
        hrp.CFrame = hrp.CFrame
    end
end)

add("isnetworkowner", function(part)
    if typeof(part) ~= "Instance" or not part:IsA("BasePart") then
        return false
    end

    return part:GetNetworkOwner() == lp
end)

add("getcallbackvalue", function(obj, property)
    do end
end)

add("fireproximityprompt", function(prompt)
    if typeof(prompt) ~= "Instance" or not prompt:IsA("ProximityPrompt") then
        return
    end

    local old = prompt.HoldDuration
    prompt.HoldDuration = 0

    prompt:InputHoldBegin()
    prompt:InputHoldEnd()

    prompt.HoldDuration = old
end)

-- no way shit works
local stored = setmetatable({}, {__mode = "k"}); local old
old = hookfunction(getrawmetatable(game).__index, function(self, key)
    local v = old(self, key)

    if typeof(v) == "RBXScriptSignal" then
        stored[v] = stored[v] or {}
    end

    return v
end)

add("getconnections", function(signal)
    return stored[signal] or {}
end)

add("getconnection", function(signal)
    local t = stored[signal]
    return t and t[1]
end)

add("firesignal", function(signal, ...)
    local t = stored[signal]
    if not t then return end

    for _, conn in ipairs(t) do
        if conn.Function then
            task.spawn(conn.Function, ...)
        end
    end
end)

add("getcustomasset", function(path)
    if not isfile(path) then
        error("file does not exist: "..tostring(path))
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
    return ugc:GetPropertyValue(object, property)
end)

add("sethiddenproperty", function(object, property, value)
    return ugc:SetPropertyValue(object, property, value)
end)

add("setsimulationradius", function(simrad, maxsimrad)
    sethiddenproperty(lp, "SimulationRadius", simrad)
    sethiddenproperty(lp, "MaxSimulationRadius", maxsimrad or simrad)
end)

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

add("setscriptable", function(object, property, value)
    do end
end)

add("setrbxclipboard", function(data)
    do end
end)

add("getrendersteppedlist", function()
    do end
end)

add("replicatesignal", function(data)
    do end
end)

-- Metatable

add("getrawmetatable", function(object)
    if type(object) ~= "table" and typeof(object) ~= "Instance" then
        return nil
    end

    local mt = getmetatable(object)

    if type(mt) == "table" and mt.__metatable ~= nil then
        local copy = {}
        for k,v in pairs(mt) do
            copy[k] = v
        end
        copy.__metatable = nil
        return copy
    end

    return mt
end)

add("setrawmetatable", function(object, mt)
    if type(object) ~= "table" and typeof(object) ~= "Instance" then
        return
    end

    local old = getmetatable(object)

    if type(old) == "table" then
        old.__metatable = nil
    end

    setmetatable(object, mt)
end)

add("hookmetamethod", function(object, method, hook)
    local mt = getrawmetatable(object)

    if not mt then
        error("no metatable")
    end

    local old = mt[method]

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
    namecallmethod = method
end)

local readonly_tbl = setmetatable({}, {__mode = "k"})
add("isreadonly", function(object)
    return readonly_tbl[object] == true
end)

add("setreadonly", function(object, readonly)
    if readonly then
        readonly_tbl[object] = true
    else
        readonly_tbl[object] = nil
    end
end)

add("makewriteable", function(object)
    readonly_tbl[object] = nil
end)

add("makereadonly", function(object)
    readonly_tbl[object] = true
end)

-- Misc

add("identifyexecutor", function()
    return "Potassium", "1.0"
end)

-- RLE Compression not lz4
add("lz4compress", function(data)
    local out, i = {}, 1
    while i <= #data do
        local char = data:sub(i, i)
        local count = 1
        while i + count <= #data and data:sub(i + count, i + count) == char and count < 255 do
            count += 1
        end
        if count > 1 then
            out[#out+1] = string.char(count)
        end
        out[#out+1] = char
        i += count
    end
    return table.concat(out)
end)

add("lz4decompress", function(data)
    local out, i = {}, 1
    while i <= #data do
        local byte = data:byte(i)
        -- should avoid printing ASCII
        if byte > 127 and i + 1 <= #data then
            out[#out+1] = string.rep(data:sub(i + 1, i + 1), byte - 128)
            i += 2
        else
            out[#out+1] = data:sub(i, i)
            i += 1
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
    close.BackgroundTransparency = 0.8
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
    local url    = options.Url or ""
    local method = (options.Method or "GET"):upper()
    local body   = options.Body or ""

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
        Body       = success and result or tostring(result),
        Headers    = {},
    }
end)

add("getinternalparent", function(instance)
    return instance.Parent
end)

add("setinternalparent", function(instance, newparent)
    instance.Parent = newparent
end)

-- return game:GetFastFlag(gsub(fflag, "FFlag", ""))

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
    scripts = {}

    for _,v in ipairs(game:GetDescendants()) do
        if v:IsA("LocalScript") and v.Enabled then
            scripts[#scripts+1] = v
        elseif v:IsA("ModuleScript") then
            scripts[#scripts+1] = v
        end
    end

    return scripts
end)

add("getscripts", function()
    scripts = {}

    for _,v in ipairs(game:GetDescendants()) do
        if v:IsA("LocalScript") then
            scripts[#scripts+1] = v
        elseif v:IsA("ModuleScript") then
            scripts[#scripts+1] = v
        end
    end

    return scripts
end)

local modules = {}
add("getloadedmodules", function()
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

add("getgc", function()
    return collectgarbage("collect")
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

local function test()
  if pcall(function()
      return game.CoreGui
  end) then
      return 7
  end
  
  if pcall(function()
      return game:GetService("LogService"):GetLogHistory()
  end) then
      return 6
  end
  
  if pcall(function()
      return game:GetService("Players").LocalPlayer
  end) then
      return 5
  end
  
  return 2
end

local thread_identity = 1
add("getthreadidentity", function()
  local out = test()

  if thread_identity == 1 then -- defualt so not changed by sethidden
    out = test()
  else -- sethidden was used so override real answer
    out = thread_identity
  end
end)

add("setthreadidentity", function(identity)
    thread_identity = identity
end)

-- Actors

local function create()
  return Instance.new("BindableEvent")
end

local ids = {}
add("create_comm_channel", function()
    local num, int = math.random(1,99999), create()
    table.insert(ids, {id = num, instance = int})
    
    return num, int
end)

add("get_comm_channel", function(id)
    local i = ids["nums"].id
    if not i then return end

    return ids["instance"]
end)

add("run_on_actor", function(actor, scriptStr, ...)
    do end -- PEAK
end)

add("getactors", function()
    return {}
end)

add("is_parallel", function()
    getthreadidentity < 8 then
      return false
    else
        true
    end
end)

add("run_on_thread", function(thread, scriptStr, ...)
    do end -- PEAK
end)

add("getactorthreads", function()
    return {}
end)

for name, func in pairs(functions) do
    local parts = {}
    for part in name do
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
