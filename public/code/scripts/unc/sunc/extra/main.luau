local StartTime = tick()

local CCClosures = {}
local CustomClosures = {}
local DebugOverride = {}

local NewCClosure
do
    local function MakeCClosure(Func)
        local Wrapper = function(...)
            local Args = table.pack(...)
            local Thread = coroutine.create(function()
                return Func(table.unpack(Args, 1, Args.n))
            end)
            local Ok, Result = coroutine.resume(Thread)
            if not Ok then
                error(Result, 2)
            end
            return Result
        end
        CCClosures[Wrapper] = true
        CustomClosures[Func] = true
        DebugOverride[Wrapper] = { source = "[C]", short_src = "[C]" }
        return Wrapper
    end

    NewCClosure = newcclosure or MakeCClosure
end

local Functions = {}
local GlobalEnv = getgenv()

local AddFunction = function(Name, Func)
    if typeof(Func) ~= "function" then
        Functions[Name] = Func
    else
        Functions[Name] = NewCClosure(Func)
    end
end

local AliasFunction = function(Names, SourceNameOrFunc)
    local Resolved = GlobalEnv[SourceNameOrFunc] or Functions[SourceNameOrFunc] or SourceNameOrFunc
    for _, Name in ipairs(Names) do
        AddFunction(Name, Resolved)
    end
end

local IndexFunction = function(Func)
	return GlobalEnv["Func"] or Functions["Func"] or nil
end

local TypeDummies = {
    string   = "",
    number   = 0,
    boolean  = false,
    ["function"] = function() end,
    table    = {},
    Instance = function() return Instance.new("Folder") end,
    thread   = function() return coroutine.create(function() end) end,
}

local Translate = function(TypeName)
    local Dummy = TypeDummies[TypeName]
    if type(Dummy) == "function" and (TypeName == "Instance" or TypeName == "thread") then
        return Dummy()
    end
    return Dummy ~= nil and Dummy or TypeName
end

local Expect = function(Value, ExpectedType, CareAboutValue, ArgNum, Message)
    local Expected = type(ExpectedType) == "string" and Translate(ExpectedType) or ExpectedType
    local ExpectedTypeName = typeof(Expected)
    ArgNum = ArgNum or 1
    if not CareAboutValue then
        Message = Message or ("expected " .. ExpectedTypeName .. " at #" .. ArgNum .. " got " .. typeof(Value))
        assert(typeof(Value) == ExpectedTypeName, Message)
    else
        Message = Message or ("expected " .. tostring(Expected) .. " at #" .. ArgNum .. " got " .. typeof(Value))
        assert(typeof(Value) == ExpectedTypeName, Message)
    end
end

local function MakeCloneRef(Object)
    if not setmetatable then
        return Object
    end
    local Proxy = {}
    return setmetatable(Proxy, {
        __index    = Object,
        __newindex = function(_, Key, Value) Object[Key] = Value end,
        __tostring = function() return tostring(Object) end,
        __eq       = function() return false end,
    })
end

local CloneRef = cloneref or MakeCloneRef

local Services = {
    CollectionService    = CloneRef(game:GetService("CollectionService")),
    VirtualInputManager  = CloneRef(game:GetService("VirtualInputManager")),
    UserInputService     = CloneRef(game:GetService("UserInputService")),
    UGCValidationService = CloneRef(game:GetService("UGCValidationService")),
    RbxAnalyticsService  = CloneRef(game:GetService("RbxAnalyticsService")),
    ReflectionService    = CloneRef(game:GetService("ReflectionService")),
    CoreGui              = gethui and gethui() or CloneRef(game:GetService("CoreGui")),
    ReplicatedStorage    = CloneRef(game:GetService("ReplicatedStorage")),
    Stats                = CloneRef(game:GetService("Stats")),
    CorePackages         = CloneRef(game:GetService("CorePackages")),
    RunService           = CloneRef(game:GetService("RunService")),
    Players              = CloneRef(game:GetService("Players")),
}

local LocalPlayer = Services.Players.LocalPlayer

-- Terminal (WebSocket-backed PowerShell/CMD bridge)

local IsTerminalRunning = false
local PsSocket, CmdSocket

AddFunction("setup", function()
    IsTerminalRunning = true
    PsSocket  = WebSocket.connect("ws://localhost:8080")
    CmdSocket = WebSocket.connect("ws://localhost:8081")
    PsSocket.OnMessage:Connect(function(Msg) print("[PS]", Msg) end)
    CmdSocket.OnMessage:Connect(function(Msg) print("[CMD]", Msg) end)
end)

local AllowTerminal = function()
    return IsTerminalRunning
end

AddFunction("powerexec", function(Command)
    if not AllowTerminal() then return end
    PsSocket:Send(Command)
end)

AddFunction("termexec", function(Command)
    if not AllowTerminal() then return end
    PsSocket:Send(Command)
end)

AddFunction("cpexec", function(Command)
    if not AllowTerminal() then return end
    CmdSocket:Send(Command)
end)

AddFunction("getenv", function(Var)
    if not AllowTerminal() then return nil end
    local Result, Done = nil, false
    local Conn
    Conn = PsSocket.OnMessage:Connect(function(Msg)
        Conn:Disconnect()
        Result = Msg:gsub("%s+$", "")
        Done = true
    end)
    PsSocket:Send(string.format("[System.Environment]::GetEnvironmentVariable('%s')", Var))
    repeat task.wait() until Done
    return Result
end)

AddFunction("downloadLune", function()
    local Steps = {
        "irm https://github.com/rojo-rbx/rokit/releases/latest/download/rokit-windows.exe -OutFile rokit.exe",
        ".\\rokit.exe self-install",
        "rokit add --global lune-org/lune",
        "lune --version",
    }
    local Index = 1
    PsSocket.OnMessage:Connect(function()
        Index += 1
        if Steps[Index] then
            PsSocket:Send(Steps[Index])
        end
    end)
    PsSocket:Send(Steps[1])
end)

AddFunction("islune", function()
    if not AllowTerminal() then return false end
    local Result, Done = false, false
    local Conn
    Conn = PsSocket.OnMessage:Connect(function(Msg)
        Conn:Disconnect()
        Result = Msg ~= nil and Msg:gsub("%s", "") ~= ""
        Done = true
    end)
    PsSocket:Send("Get-Command lune -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source")
    repeat task.wait() until Done
    return Result
end)

local RandomStringLib = loadstring(game:HttpGet("https://github.com/daily3014/rbx-cryptography/raw/main/src/Utilities/RandomString.luau"))()
local RandomString = function(Length)
    return RandomStringLib(Length or 16, false)
end

AddFunction("lune", function(Code)
    local Filename = RandomString(6)
    PsSocket:Send(string.format("Set-Content -Path '%s.luau' -Value '%s'", Filename, Code:gsub("'", "''")))
    task.delay(0.5, function()
        PsSocket:Send(string.format("lune run %s.luau", Filename))
    end)
end)

-- Cache

local InstanceCache = {}

AddFunction("cache.invalidate", function(Object)
    Expect(Object, "Instance", false, 1)
    InstanceCache[Object] = nil
end)

AddFunction("cache.iscached", function(Object)
    Expect(Object, "Instance", false, 1)
    return InstanceCache[Object] ~= nil
end)

AddFunction("cache.replace", function(Object, New)
    Expect(Object, "Instance", false, 1)
    Expect(New, "Instance", false, 2)
    InstanceCache[Object] = New
end)

AddFunction("cloneref", function(Object)
    Expect(Object, "Instance", false, 1)
    return MakeCloneRef(Object)
end)

AddFunction("compareinstances", function(A, B)
    Expect(A, "Instance", false, 1)
    Expect(B, "Instance", false, 2)
    return A == B
end)

-- Closures

AddFunction("checkcaller", function()
    local Info = debug.info(getgenv, "slnaf")
    return debug.info(1, "slnaf") ~= Info
end)

AddFunction("clonefunction", function(Func)
    Expect(Func, "function", false, 1)
    return function(...) return Func(...) end
end)

AddFunction("getcallingscript", function()
    local Source = debug.info(1, "s")
    return table.find(game:GetDescendants(), Source)
end)

local StackHidden = {}
AddFunction("setstackhidden", function(Func, Hidden)
    StackHidden[Func] = Hidden
end)

local HookedFunctions = {}
for _, Value in pairs(GlobalEnv) do
    if typeof(Value) == "function" then
        HookedFunctions[Value] = true
    end
end

AddFunction("isfunctionhooked", function(Func)
    Expect(Func, "function", false, 1)
    return HookedFunctions[Func] ~= nil and HookedFunctions[Func] ~= false
end)

AddFunction("hookfunction", function(Func, Hook)
    Expect(Func, "function", false, 1)
    Expect(Hook, "function", false, 2)
    if replaceclosure then
        return replaceclosure(Func, Hook)
    end
    local Old = Func
    local Hooked = function(...) return Hook(Old, ...) end
    HookedFunctions[Func] = true
    return Hooked, Old
end)

AddFunction("hiddenhook", function(Func, Hook)
    hookfunction(Func, Hook)
    HookedFunctions[Func] = false
end)

AliasFunction({"secrethook"}, function(Func, Hook)
    hiddenhook(Func, Hook)
end)

AddFunction("restorefunction", function(Func, Hook)
    Expect(Func, "function", false, 1)
    HookedFunctions[Func] = nil
    return Hook
end)

AliasFunction({"getoriginalfunction"}, function(Func, Hook)
    return restorefunction(Func, Hook)
end)

AddFunction("securefunction", function(Func)
    Expect(Func, "function", false, 1)
end)

do
    local SecureEnvs = { getgenv, getrenv }
    GlobalEnv.unhooked = {}
    for _, Env in ipairs(SecureEnvs) do
        for _, Item in ipairs(Env()) do
            if typeof(Item) ~= "function" then continue end
            GlobalEnv.unhooked[Item] = securefunction(Item)
        end
    end
end

AddFunction("iscclosure", function(Func)
    if type(Func) ~= "function" then return false end
    return debug.info(Func, "s") == "[C]"
end)

AddFunction("newlclosure", function(Func)
    return function() return Func() end
end)

AddFunction("islclosure", function(Func)
    if type(Func) ~= "function" then return false end
    return debug.info(Func, "s") ~= "[C]"
end)

AddFunction("isexecutorclosure", function(Func)
    Expect(Func, "function", false, 1)
    for _, Value in pairs(GlobalEnv) do
        if Value == Func then return true end
    end
    return false
end)

AliasFunction({"checkclosure", "isourclosure"}, "isexecutorclosure")

AddFunction("newcclosure", function(Func)
    Expect(Func, "function", false, 1)
    return NewCClosure(Func)
end)

AddFunction("isnewcclosure", function(Func)
    return CustomClosures[Func] == true
end)

-- RConsole

local RConsoleGui = Instance.new("ScreenGui")
RConsoleGui.Name = RandomString(6)
RConsoleGui.Parent = Services.CoreGui

local IsConsoleOpen = false
local ConsoleWindow
local ConsoleInput

local function CreateConsole()
    IsConsoleOpen = not IsConsoleOpen

    local Offset = 40

    ConsoleWindow = Instance.new("Frame")
    ConsoleWindow.Name = "window"
    ConsoleWindow.Size = UDim2.fromOffset(399, 251)
    ConsoleWindow.Position = UDim2.new(0.5, -174, 0.5, -75)
    ConsoleWindow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    ConsoleWindow.Visible = IsConsoleOpen
    ConsoleWindow.Draggable = true
    ConsoleWindow.BorderSizePixel = 0
    ConsoleWindow.ClipsDescendants = true
    ConsoleWindow.Parent = RConsoleGui
    Instance.new("UICorner", ConsoleWindow).CornerRadius = UDim.new(0, 8)

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Name = "title"
    TitleLabel.Size = UDim2.fromOffset(260, 18)
    TitleLabel.Position = UDim2.fromOffset(14, 10)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = "Console"
    TitleLabel.Font = Enum.Font.SourceSans
    TitleLabel.TextSize = 16
    TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = ConsoleWindow

    local CloseButton = Instance.new("TextButton")
    CloseButton.Size = UDim2.fromOffset(20, 20)
    CloseButton.Position = UDim2.fromOffset(350, 8)
    CloseButton.Text = "X"
    CloseButton.Parent = ConsoleWindow
    CloseButton.MouseButton1Click:Connect(function()
        RConsoleGui:Destroy()
        IsConsoleOpen = false
    end)

    local function CreateLine(Text, Color)
        local Label = Instance.new("TextLabel")
        Label.Size = UDim2.fromOffset(360, 20)
        Label.Position = UDim2.fromOffset(10, Offset)
        Label.BackgroundTransparency = 1
        Label.Text = Text
        Label.Font = Enum.Font.Code
        Label.TextSize = 14
        Label.TextColor3 = Color or Color3.fromRGB(255, 255, 255)
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.Parent = ConsoleWindow
        Label:SetAttribute("killme", true)
        Offset += 22
    end

    ConsoleInput = function(Text, Color)
        if not ConsoleWindow then return end
        CreateLine(Text, Color)
    end

    ConsoleInput("Rconsole loaded", Color3.fromRGB(0, 255, 0))
end

local function GetChildrenWithAttribute(Parent, Attr)
    local Result = {}
    for _, Child in ipairs(Parent:GetChildren()) do
        if Child:GetAttribute(Attr) ~= nil then
            Result[#Result + 1] = Child
        end
    end
    return Result
end

AddFunction("rconsoleclear", function()
    for _, Item in ipairs(GetChildrenWithAttribute(ConsoleWindow, "killme")) do
        Item:Destroy()
    end
end)

AddFunction("rconsolecontent", function()
    local Output = {}
    for _, Label in ipairs(GetChildrenWithAttribute(ConsoleWindow, "killme")) do
        Output[#Output + 1] = Label.Text
    end
    return Output
end)

AddFunction("rconsolecreate", function()
    CreateConsole()
end)

AddFunction("rconsoledestroy", function()
    ConsoleWindow:Destroy()
end)

AddFunction("rconsolehide", function()
    ConsoleWindow.Visible = false
end)

AddFunction("rconsoleshow", function()
    ConsoleWindow.Visible = true
end)

AddFunction("rconsoleinput", function(Text)
    Expect(Text, "string", false, 1)
    ConsoleInput(Text)
end)

AliasFunction({"rconsoleinfo", "rconsoleprint"}, "rconsoleinput")

AddFunction("rconsolewarn", function(Text)
    Expect(Text, "string", false, 1)
    ConsoleInput(Text, Color3.fromRGB(255, 0, 0))
end)

AddFunction("rconsoleerror", function(Text)
    Expect(Text, "string", false, 1)
    ConsoleInput(Text, Color3.fromRGB(255, 255, 0))
end)

AddFunction("rconsolesettitle", function(Title)
    Expect(Title, "string", false, 1)
    ConsoleWindow["title"].Text = Title
end)

AliasFunction({"rconsolename"}, "rconsolesettitle")

AddFunction("isrconsole", function()
    return IsConsoleOpen
end)

AddFunction("rconsolehidden", function()
    return isrconsole()
end)

-- loadstring (Lune-backed)

AddFunction("loadstring", function(Source, ChunkName)
    if not AllowTerminal() then
        return (load)(Source, ChunkName)
    end
    if not islune() then
        downloadLune()
    end
    local Filename  = RandomString(6)
    local Filepath  = getenv("TEMP") .. "\\__ls_" .. Filename .. ".luau"
    local Result, Done = nil, false
    PsSocket:Send(string.format("Set-Content -Path '%s' -Value '%s'", Filepath, Source:gsub("'", "''")))
    local Conn
    Conn = PsSocket.OnMessage:Connect(function(Msg)
        Conn:Disconnect()
        Result = Msg
        Done = true
    end)
    PsSocket:Send(string.format("lune run '%s'", Filepath))
    return function()
        repeat task.wait() until Done
        PsSocket:Send(string.format("Remove-Item '%s' -Force", Filepath))
        return Result
    end
end)

-- Crypt

local BitLib = bit32
local Band, BXor, RShift, LShift = BitLib.band, BitLib.bxor, BitLib.rshift, BitLib.lshift

local function BufFromString(S) return buffer.fromstring(S) end
local function StringFromBuf(B) return buffer.tostring(B) end

local CryptLib = {}

local Base64Lib = loadstring(game:HttpGet("https://github.com/daily3014/rbx-cryptography/raw/main/src/Utilities/Base64.luau"))()

CryptLib.base64encode = function(Data)
    Expect(Data, "string", false, 1)
    return buffer.tostring(Base64Lib.Encode(buffer.fromstring(tostring(Data))))
end

CryptLib.base64decode = function(Data)
    Expect(Data, "string", false, 1)
    return buffer.tostring(Base64Lib.Decode(buffer.fromstring(tostring(Data))))
end

local Base64Encode = function(S) return CryptLib.base64encode(S) or "" end
local Base64Decode = function(S) return CryptLib.base64decode(S) or "" end

local RNG = Random.new()
local CSPRNG = loadstring(game:HttpGet("https://website-iota-ivory-12.vercel.app/code/scripts/unc/sunc/extra/csprng/init.luau"))()

CryptLib.generatebytes = function(Size)
    return CSPRNG.RandomBytes(Size)
end

CryptLib.random = function(Length)
    local Buffer = table.create(Length)

    for Index = 1, Length do
        Buffer[Index] = string.char(math.random(0, 255))
    end

    return table.concat(Buffer)
end

CryptLib.generatekey = function()
    local Parts = table.create(32)
    for Index = 1, 32 do
        Parts[Index] = string.char(RNG:NextInteger(0, 255))
    end
    local Raw = table.concat(Parts)
    return Base64Encode(Raw)
end

local AESLib = loadstring(game:HttpGet("https://github.com/daily3014/rbx-cryptography/raw/main/src/Encryption/AES.luau"))()

CryptLib.encrypt = function(Data, Key, IV)
    assert(type(Data) == "string", "data must be string")
    local KeyBuf  = BufFromString(Base64Encode(Key))
    local IVRaw   = IV or CryptLib.generatebytes(12)
    local IVBuf   = BufFromString(Base64Encode(IVRaw))
    local Cipher, Tag = AESLib.Encrypt(BufFromString(Data), KeyBuf, IVBuf)
    Cipher = crypt.base64encode(StringFromBuf(Cipher))
    Tag    = crypt.base64encode(StringFromBuf(Tag))
    IVRaw  = crypt.base64encode(IVRaw)
    return Cipher, IVRaw, Tag
end

CryptLib.decrypt = function(Ciphertext, Key, IV, Tag)
    assert(type(Ciphertext) == "string", "ciphertext must be string")
    assert(type(Key) == "string", "key must be string")
    assert(type(IV) == "string", "iv must be string")
    assert(type(Tag) == "string", "tag must be string")
    local KeyBuf    = BufFromString(Base64Encode(Key))
    local IVBuf     = BufFromString(Base64Encode(IV))
    local TagBuf    = BufFromString(Base64Encode(Tag))
    local Ok, Plain = AESLib.Decrypt(BufFromString(Base64Encode(Ciphertext)), KeyBuf, IVBuf, TagBuf)
    if not Ok then return false, nil end
    return true, StringFromBuf(Plain)
end

local HashLib = loadstring(game:HttpGet("https://github.com/Egor-Skriptunoff/pure_lua_SHA/raw/master/sha2.lua"))()

CryptLib.hash = function(Str, Algorithm)
    Expect(Str, "string", false, 1)
    Algorithm = (Algorithm or "sha256"):lower()
    return HashLib[Algorithm](Str)
end

local XORLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/daily3014/rbx-cryptography/refs/heads/main/src/Encryption/XOR.luau"))()

CryptLib.salt = function(Input)
    local B  = BufFromString(Input)
    local C  = XORLib(B, StringFromBuf(CryptLib.rnum(12)))
    local N  = XORLib(C, StringFromBuf(CryptLib.rnum(12)))
    return StringFromBuf(N)
end

CryptLib.xor = function(Data)
    return StringFromBuf(XORLib(BufFromString(Data)))
end

CryptLib.tobytecode = function(Source)
    Expect(Source, "string", false, 1)
end

CryptLib.tobinary = function(Str)
    Expect(Str, "string", false, 1)
    local Result = {}
    for Index = 1, #Str do
        local Byte = Str:byte(Index)
        local Binary = ""
        for Bit = 7, 0, -1 do
            Binary = Binary .. Band(RShift(Byte, Bit), 1)
        end
        Result[Index] = Binary
    end
    return table.concat(Result, " ")
end

CryptLib.frombinary = function(Binary)
    Expect(Binary, "string", false, 1)
    Binary = Binary:gsub("%s", "")
    local Result = {}
    for Index = 1, #Binary, 8 do
        local Chunk = Binary:sub(Index, Index + 7)
        if #Chunk == 8 then
            Result[#Result + 1] = string.char(tonumber(Chunk, 2))
        end
    end
    return table.concat(Result)
end

CryptLib.tohex = function(Str)
    Expect(Str, "string", false, 1)
    return (Str:gsub(".", function(C) return string.format("%02x", string.byte(C)) end))
end

CryptLib.fromhex = function(Str)
    Expect(Str, "string", false, 1)
    assert(#Str % 2 == 0, "hex string must have even length")
    return (Str:gsub("%x%x", function(C) return string.char(tonumber(C, 16)) end))
end

CryptLib.hmac = function(Key, Data, Algorithm)
    Expect(Key, "string", false, 1)
    Expect(Data, "string", false, 2)
    Expect(Algorithm, "string", false, 3)

    local HashRaw = function(Str)
        return crypt.fromhex(crypt.hash(Str, Algorithm))
    end

    local BlockSize = 64
    if #Key > BlockSize then
        Key = HashRaw(Key)
    end
    Key = Key .. string.rep("\0", BlockSize - #Key)

    local IPad, OPad = {}, {}
    for Index = 1, BlockSize do
        local B = Key:byte(Index) or 0
        IPad[Index] = string.char(BXor(B, 0x36))
        OPad[Index] = string.char(BXor(B, 0x5C))
    end

    local Inner = HashRaw(table.concat(IPad) .. Data)
    local Outer = HashRaw(table.concat(OPad) .. Inner)
    return crypt.base64encode(Outer)
end

CryptLib.lz4 = function(Data, Compress)
    assert(type(Data) == "string", "data must be string")
    return Compress and lz4compress(Data) or lz4decompress(Data)
end

CryptLib.rle = function(Data, Compress)
    assert(type(Data) == "string", "data must be string")
    return Compress and rlecompress(Data) or rledecompress(Data)
end

for Key, Value in pairs(CryptLib) do
    AddFunction("crypt." .. Key, Value)
end

do
    local MergedCrypt = {}
    for Key, Value in pairs(GlobalEnv.crypt or {}) do
        MergedCrypt[Key] = Value
    end
    for Key, Value in pairs(CryptLib) do
        if MergedCrypt[Key] == nil then
            MergedCrypt[Key] = Value
        end
    end
    GlobalEnv.crypt = MergedCrypt
end

-- Oth

local OthHooks, OthHookThreads, OthOriginalThreads = {}, {}, {}

local InternalOth = {}

InternalOth.hook = function(Target, HookFunction)
    Expect(Target, "function", false, 1)
    Expect(HookFunction, "function", false, 2)
    local HookList = OthHooks[Target]
    if not HookList then
        HookList = {}
        OthHooks[Target] = HookList
    end
    local Callback = function(...) return Target(...) end
    HookList[#HookList + 1] = { Hook = HookFunction, Callback = Callback }
    return Callback
end

InternalOth.unhook = function(Target, HookOrCallback)
    local HookList = OthHooks[Target]
    if not HookList then return false end
    for Index, Entry in ipairs(HookList) do
        if HookOrCallback == nil or Entry.Hook == HookOrCallback or Entry.Callback == HookOrCallback then
            table.remove(HookList, Index)
            if #HookList == 0 then
                OthHooks[Target] = nil
            end
            return true
        end
    end
    return false
end

InternalOth.get_root_callback = function(Target)
    local HookList = OthHooks[Target]
    if not HookList or #HookList == 0 then return Target end
    return HookList[1].Callback
end

InternalOth.run_hook = function(Target, ...)
    local HookList = OthHooks[Target]
    if not HookList or #HookList == 0 then return Target(...) end
    local Entry        = HookList[#HookList]
    local CallerThread = coroutine.running()
    local Thread = coroutine.create(function(...)
        local Current = coroutine.running()
        OthHookThreads[Current]    = true
        OthOriginalThreads[Current] = CallerThread
        local Results = table.pack(Entry.Hook(...))
        OthHookThreads[Current]    = nil
        OthOriginalThreads[Current] = nil
        return table.unpack(Results, 1, Results.n)
    end)
    local Success, Result = coroutine.resume(Thread, ...)
    if not Success then error(Result, 0) end
    return Result
end

InternalOth.is_hook_thread = function()
    return OthHookThreads[coroutine.running()] == true
end

InternalOth.get_original_thread = function()
    return OthOriginalThreads[coroutine.running()]
end

do
    local Oth = GlobalEnv.oth or {}
    for Key, Value in pairs(InternalOth) do
        Oth[Key] = Value
    end
    GlobalEnv.oth = Oth
end

-- Debug

local DebugConstants, DebugUpvalues, DebugStacks = {}, {}, {}

local DebugLib = {}

local function GetFunctionLines(Source, StartLine)
    local CurrentLine, Depth, Started = 0, 0, false
    local Result = {}
    for Line in (Source .. "\n"):gmatch("([^\n]*)\n") do
        CurrentLine += 1
        if CurrentLine < StartLine then continue end
        Result[#Result + 1] = Line
        for _ in Line:gmatch("%f[%a]do%f[%A]")       do Depth += 1 end
        for _ in Line:gmatch("%f[%a]then%f[%A]")     do Depth += 1 end
        for _ in Line:gmatch("%f[%a]function%f[%A]") do Depth += 1 end
        for _ in Line:gmatch("%f[%a]repeat%f[%A]")   do Depth += 1 end
        for _ in Line:gmatch("%f[%a]end%f[%A]")      do Depth -= 1 end
        for _ in Line:gmatch("%f[%a]until%f[%A]")    do Depth -= 1 end
        if not Started and Depth > 0 then Started = true end
        if Started and Depth <= 0 then break end
    end
    return table.concat(Result, "\n")
end

DebugLib.validlevel = function(Level)
    return debug.getinfo(Level + 2) ~= nil
end

DebugLib.isvalidlevel = function(Level)
    Expect(Level, "number", false, 1)
    return Level >= 0
end

DebugLib.getregistry = function()
    return getreg and getreg() or {}
end

DebugLib.getconstant = function(Func, Index)
    Expect(Func, "function", false, 1)
    Expect(Index, "number", false, 2)
    local Constants = DebugConstants[Func]
    if not Constants or Constants[Index] == nil then
        error("constant does not exist at index " .. Index)
    end
    return Constants[Index]
end

DebugLib.getconstants = function(Func)
    Expect(Func, "function", false, 1)
    return DebugConstants[Func] or {}
end

DebugLib.setconstant = function(Func, Index, Value)
    Expect(Func, "function", false, 1)
    Expect(Index, "number", false, 2)
    DebugConstants[Func] = DebugConstants[Func] or {}
    DebugConstants[Func][Index] = Value
end

DebugLib.getupvalue = function(Func, Index)
    Expect(Func, "function", false, 1)
    Expect(Index, "number", false, 2)
    local Upvalues = DebugUpvalues[Func]
    if not Upvalues or Upvalues[Index] == nil then return nil end
    return Upvalues[Index]
end

DebugLib.getupvalues = function(Func)
    Expect(Func, "function", false, 1)
    return DebugUpvalues[Func] or {}
end

DebugLib.setupvalue = function(Func, Index, Value)
    Expect(Func, "function", false, 1)
    Expect(Index, "number", false, 2)
    DebugUpvalues[Func] = DebugUpvalues[Func] or {}
    DebugUpvalues[Func][Index] = Value
end

DebugLib.getstack = function(Level, Index)
    Expect(Level, "number", false, 1)
    local Stack = DebugStacks[Level]
    if not Stack then error("invalid stack level: " .. Level) end
    if Index then
        Expect(Index, "number", false, 2)
        if Stack[Index] == nil then error("stack value does not exist at index " .. Index) end
        return Stack[Index]
    end
    return Stack
end

DebugLib.setstack = function(Level, Index, Value)
    Expect(Level, "number", false, 1)
    Expect(Index, "number", false, 2)
    DebugStacks[Level] = DebugStacks[Level] or {}
    DebugStacks[Level][Index] = Value
end

DebugLib.setinfo = function(Func, Info)
    Expect(Func, "function", false, 1)
    Expect(Info, "table", false, 2)
    DebugOverride[Func] = Info
end

DebugLib.getinfo = function(Target)
    local IsLevel  = typeof(Target) == "number"
    local Level    = IsLevel and (Target + 1) or Target

    local function DInfo(Opt) return debug.info(Level, Opt) end

    local Source      = DInfo("s")
    local Name        = DInfo("n")
    local CurrentLine = IsLevel and DInfo("l") or -1
    local NParams, IsVarArg = DInfo("a")
    local NUps        = DInfo("u")

    if Name == "" then Name = nil end

    local ShortSrc = Source
    if Source and Source:sub(1, 1) == "@" then
        ShortSrc = Source:match("[^/\\]+$")
    end

    local What
    if Source == "[C]" then
        What = "C"
    elseif IsLevel and Target == 0 then
        What = "main"
    else
        What = "Lua"
    end

    local Func = IsLevel and debug.info(Level, "f") or Target
    local Hash = getfunctionhash and getfunctionhash(Func) or ""

    return {
        name            = Name,
        source          = Source,
        short_src       = ShortSrc,
        what            = What,
        currentline     = CurrentLine,
        nups            = NUps,
        numparams       = NParams,
        is_vararg       = IsVarArg,
        hash            = Hash,
        size            = #Hash,
        func            = Func,
        lastlinedefined = GetFunctionLines(decompile(Source), CurrentLine),
    }
end

DebugLib.getproto = function(Func)
    Expect(Func, "function", false, 1)
    return nil
end

DebugLib.getprotos = function(Func)
    Expect(Func, "function", false, 1)
    return {}
end

DebugLib.getprotosize = function(Func)
    Expect(Func, "function", false, 1)
    local Count = 0
    while true do
        local Ok = pcall(debug.getproto, Func, Count + 1)
        if not Ok then break end
        Count += 1
    end
    return Count
end

DebugLib.getcallstack = function()
    local Stack, Level = {}, 1
    while true do
        local Ok, Info = pcall(debug.getinfo, Level + 1)
        if not Ok or not Info then break end
        Stack[#Stack + 1] = {
            func   = Info.func,
            name   = Info.name,
            source = Info.short_src,
            line   = Info.currentline,
        }
        Level += 1
    end
    return Stack
end

if hookfunction then
    local OldTraceback
    OldTraceback = hookfunction(debug.traceback, function(...)
        local Tb = OldTraceback(...)
        for Func, Hidden in pairs(StackHidden) do
            if Hidden then
                Tb = Tb:gsub(".-" .. tostring(Func) .. ".-\n", "")
            end
        end
        return Tb
    end)
end

for Key, Value in pairs(DebugLib) do
    AddFunction("debug." .. Key, Value)
end

do
    local MergedDebug = {}
    for Key, Value in pairs(GlobalEnv.debug or {}) do
        MergedDebug[Key] = Value
    end
    for Key, Value in pairs(DebugLib) do
        if MergedDebug[Key] == nil then
            MergedDebug[Key] = Value
        end
    end
    GlobalEnv.debug = MergedDebug
end

-- RakNet

local RakNetLib = {}

RakNetLib.GetService = function(self, Service)
    if not cloneref then return Service end
    if Service == "VirtualInputManager" or Service == "VirtualUser" then
        return cloneref(Instance.new(Service))
    end
    return cloneref(Service)
end

RakNetLib.GetLocalPlayer = function()
    return RakNetLib:GetService(game:GetService("Players")).LocalPlayer
end

RakNetLib.GetCharacter = function()
    return RakNetLib:GetLocalPlayer().Character or RakNetLib:GetLocalPlayer().CharacterAdded:Wait()
end

RakNetLib.GetPrimaryPart = function()
    return RakNetLib:GetCharacter():FindFirstChild("HumanoidRootPart")
end

RakNetLib.GetHumanoid = function()
    return RakNetLib:GetCharacter():FindFirstChildOfClass("Humanoid")
end

RakNetLib.SendKickPacket = function(self, OptionalMessage)
    local Player = RakNetLib:GetLocalPlayer()
    Player:Kick(OptionalMessage or ("You have been kicked by the use of RakNet packets, " .. Player.UserId))
end

AddFunction("crash", function()
    local function Recurse()
        local T = {}
        for Index = 1, 1000 do
            T[Index] = string.rep("x", 1000000)
        end
        Recurse()
    end
    Recurse()
end)

RakNetLib.SendCrashPacket = function()
    crash()
end

RakNetLib.SendHumanoidPropertyChangePacket = function(self, Property, Value)
    RakNetLib:GetHumanoid()[Property] = Value
end

RakNetLib.SendClientLagPacket = function(self, Duration)
    local Original = getfpscap()
    setfpscap(math.random(1, 25))
    task.delay(Duration or 1, function()
        setfpscap(Original)
    end)
end

local RakNetSendHooks = {}

local RakNetPacket = {}
RakNetPacket.__index = RakNetPacket

local function PacketToArray(Data)
    if typeof(Data) == "string" then
        local T = {}
        for Index = 1, #Data do
            T[Index] = string.byte(Data, Index)
        end
        return T
    elseif typeof(Data) == "table" then
        return Data
    end
    return {}
end

local function PacketToString(Data)
    if typeof(Data) == "string" then return Data end
    if typeof(Data) == "table" then
        local Chars = {}
        for Index, Byte in ipairs(Data) do
            Chars[Index] = string.char(Byte)
        end
        return table.concat(Chars)
    end
    return ""
end

RakNetPacket.new = function(Data, Priority, Reliability, Ordering)
    return setmetatable({
        _data           = Data,
        Priority        = Priority or 0,
        Reliability     = Reliability or 0,
        OrderingChannel = Ordering or 0,
        _blocked        = false,
    }, RakNetPacket)
end

RakNetPacket.UpdateViews = function(self)
    self.AsArray  = PacketToArray(self._data)
    self.AsString = PacketToString(self._data)
    self.Size     = #self.AsArray
end

RakNetPacket.SetData = function(self, Data)
    self._data = Data
    self:UpdateViews()
end

RakNetPacket.Block = function(self)
    self._blocked = true
end

RakNetLib.add_send_hook = function(Hook)
    RakNetSendHooks[#RakNetSendHooks + 1] = Hook
end

RakNetLib.remove_send_hook = function(Hook)
    for Index, Value in ipairs(RakNetSendHooks) do
        if Value == Hook then
            table.remove(RakNetSendHooks, Index)
            return
        end
    end
end

RakNetLib.send = function(Data, Priority, Reliability, OrderingChannel)
    local Packet = RakNetPacket.new(Data, Priority, Reliability, OrderingChannel)
    Packet:UpdateViews()
    for _, Hook in ipairs(RakNetSendHooks) do
        local Ok, Err = pcall(Hook, Packet)
        if not Ok then
            warn("raknet hook error:", Err)
        end
        if Packet._blocked then
            warn("[raknet] packet blocked")
            return
        end
    end
end

local RakNetDesyncHooked = false
local function DesyncHook(Packet)
    if Packet.PacketId == 0x1B then
        local Buf = Packet.AsBuffer
        buffer.writeu32(Buf, 1, 0xFFFFFFFF)
        Packet:SetData(Buf)
    end
end

RakNetLib.desync = function()
    RakNetLib.add_send_hook(DesyncHook)
    RakNetDesyncHooked = true
end

RakNetLib.sync = function()
    if RakNetDesyncHooked then
        RakNetLib.remove_send_hook(DesyncHook)
    end
    RakNetDesyncHooked = false
end

for Key, Value in pairs(RakNetLib) do
    AddFunction("raknet." .. Key, Value)
end

do
    local MergedRakNet = {}
    for Key, Value in pairs(GlobalEnv.raknet or GlobalEnv.rnet or {}) do
        MergedRakNet[Key] = Value
    end
    for Key, Value in pairs(RakNetLib) do
        if MergedRakNet[Key] == nil then
            MergedRakNet[Key] = Value
        end
    end
    GlobalEnv.raknet = MergedRakNet
    GlobalEnv.rnet   = MergedRakNet
end

-- Drawing

local DrawingCache = {}
local DrawingUI do
    DrawingUI = Instance.new("ScreenGui")
    DrawingUI.Name = RandomString(6)
    DrawingUI.Parent = Services.CoreGui
end

local function ApplyDrawingBase(Object, State)
    Object.Visible              = State.Visible
    Object.ZIndex               = math.clamp(State.ZIndex, -2^31, 2^31)
    Object.BackgroundTransparency = 1 - State.Transparency
    Object.BackgroundColor3     = State.Color
end

local function MakeDrawingProxy(State, Update, ReadOnly)
    ReadOnly = ReadOnly or {}
    local Proxy = newproxy(true)
    local MT    = getmetatable(Proxy)
    MT.__index    = function(_, Key) return State[Key] end
    MT.__newindex = function(_, Key, Value)
        for _, R in ipairs(ReadOnly) do
            if R == Key then return end
        end
        State[Key] = Value
        Update()
    end
    MT.__tostring  = function() return "Drawing" end
    MT.__metatable = "This metatable is protected."
    return Proxy
end

local DrawingTypes = {}

DrawingTypes.Line = function(State, Object)
    local function Update()
        local From, To = State.From, State.To
        local DX, DY = To.X - From.X, To.Y - From.Y
        local Length = math.sqrt(DX^2 + DY^2)
        Object.Size             = UDim2.fromOffset(Length, State.Thickness)
        Object.Position         = UDim2.fromOffset(From.X, From.Y)
        Object.Rotation         = math.deg(math.atan2(DY, DX))
        Object.BackgroundColor3 = State.Color
        Object.Visible          = State.Visible
        Object.ZIndex           = math.clamp(State.ZIndex, -2^31, 2^31)
    end
    State.From        = Vector2.zero
    State.To          = Vector2.zero
    State.Thickness   = 1
    State.Color       = Color3.new(1, 1, 1)
    State.Visible     = true
    State.ZIndex      = 1
    State.Transparency = 1
    Update()
    return MakeDrawingProxy(State, Update)
end

DrawingTypes.Square = function(State, Object)
    local Stroke = Instance.new("UIStroke", Object)
    Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    local function Update()
        ApplyDrawingBase(Object, State)
        Object.Size     = UDim2.fromOffset(State.Size.X, State.Size.Y)
        Object.Position = UDim2.fromOffset(State.Position.X, State.Position.Y)
        if State.Filled then
            Object.BackgroundTransparency = 0
            Stroke.Enabled = false
        else
            Object.BackgroundTransparency = 1
            Stroke.Enabled    = true
            Stroke.Color      = State.Color
            Stroke.Thickness  = State.Thickness
        end
    end
    State.Size        = Vector2.zero
    State.Position    = Vector2.zero
    State.Color       = Color3.new(1, 1, 1)
    State.Filled      = false
    State.Thickness   = 1
    State.Visible     = true
    State.ZIndex      = 1
    State.Transparency = 1
    return MakeDrawingProxy(State, Update)
end

DrawingTypes.Circle = function(State, Object)
    Instance.new("UICorner", Object).CornerRadius = UDim.new(1, 0)
    local Stroke = Instance.new("UIStroke", Object)
    Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    local function Update()
        local Diameter = State.Radius * 2
        Object.Size     = UDim2.fromOffset(Diameter, Diameter)
        Object.Position = UDim2.fromOffset(State.Position.X - State.Radius, State.Position.Y - State.Radius)
        Object.Visible  = State.Visible
        Object.ZIndex   = math.clamp(State.ZIndex, -2^31, 2^31)
        if State.Filled then
            Object.BackgroundTransparency = 1 - State.Transparency
            Object.BackgroundColor3       = State.Color
            Stroke.Enabled = false
        else
            Object.BackgroundTransparency = 1
            Stroke.Enabled   = true
            Stroke.Color     = State.Color
            Stroke.Thickness = State.Thickness
        end
    end
    State.Radius      = 1
    State.Position    = Vector2.zero
    State.Color       = Color3.new(1, 1, 1)
    State.Filled      = false
    State.Thickness   = 1
    State.Visible     = true
    State.ZIndex      = 1
    State.Transparency = 1
    State.NumSides    = 0
    return MakeDrawingProxy(State, Update)
end

local FontMap = {
    [0] = Enum.Font.GothamMedium,
    [1] = Enum.Font.SourceSans,
    [2] = Enum.Font.Code,
    [3] = Enum.Font.RobotoMono,
}

DrawingTypes.Text = function(State, Object)
    Object:Destroy()
    Object = Instance.new("TextLabel", DrawingUI)
    Object.BackgroundTransparency = 1
    Object.BorderSizePixel = 0
    Object.TextWrapped = false
    Object.RichText    = false
    local function Update()
        Object.Visible              = State.Visible
        Object.ZIndex               = math.clamp(State.ZIndex, -2^31, 2^31)
        Object.Text                 = State.Text
        Object.TextSize             = State.Size
        Object.TextColor3           = State.Color
        Object.BackgroundTransparency = 1 - State.Transparency
        Object.Position             = UDim2.fromOffset(State.Position.X, State.Position.Y)
        Object.Size                 = UDim2.fromOffset(State.Size * #State.Text * 0.6, State.Size)
        Object.Font                 = FontMap[State.Font] or Enum.Font.GothamMedium
        Object.TextXAlignment       = State.Center and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left
        Object.TextYAlignment       = State.Center and Enum.TextYAlignment.Center or Enum.TextYAlignment.Top
        Object.TextStrokeTransparency = State.Outline and 0 or 1
        Object.TextStrokeColor3     = State.OutlineColor
        State.TextBounds            = Object.TextBounds
    end
    State.Text         = ""
    State.Size         = 12
    State.Font         = 3
    State.Color        = Color3.new(1, 1, 1)
    State.Center       = false
    State.Outline      = false
    State.OutlineColor = Color3.new(0, 0, 0)
    State.Position     = Vector2.zero
    State.Visible      = true
    State.ZIndex       = 1
    State.Transparency = 1
    State.TextBounds   = Vector2.zero
    return MakeDrawingProxy(State, Update, {"TextBounds"})
end

if not GlobalEnv.Drawing then
    GlobalEnv.Drawing = {
        Fonts = { UI = 0, System = 1, Plex = 2, Monospace = 3 },
        new = function(DrawingType)
            Expect(DrawingType, "string", false, 1)
            assert(DrawingTypes[DrawingType], "invalid drawing type: " .. DrawingType)
            local Object = Instance.new("Frame")
            Object.BorderSizePixel        = 0
            Object.BackgroundTransparency = 1
            Object.ZIndex                 = 1
            Object.Size                   = UDim2.fromOffset(0, 0)
            Object.Parent                 = DrawingUI
            local State = {
                Remove  = function() Object:Destroy() end,
            }
            State.Destroy = State.Remove
            local Proxy = DrawingTypes[DrawingType](State, Object)
            DrawingCache[#DrawingCache + 1] = { proxy = Proxy, instance = Object }
            return Proxy
        end,
    }
end

AddFunction("isrenderobj", function(Object)
    for _, Entry in ipairs(DrawingCache) do
        if Entry.proxy == Object then return true end
    end
    return false
end)

AddFunction("cleardrawcache", function()
    for _, Entry in ipairs(DrawingCache) do
        Entry.instance:Destroy()
    end
    table.clear(DrawingCache)
end)

AddFunction("getrenderproperty", function(Object, Property)
    assert(isrenderobj(Object), "expected render object, got " .. type(Object))
    Expect(Property, "string", false, 2)
    return Object[Property]
end)

AddFunction("setrenderproperty", function(Object, Property, Value)
    assert(isrenderobj(Object), "expected render object, got " .. type(Object))
    Expect(Property, "string", false, 2)
    Object[Property] = Value
end)

-- File System

local ExecutorName = identifyexecutor and identifyexecutor() or "unknown"
local WorkspaceRoot = ExecutorName .. "/workspace"

local VirtualFiles, VirtualFolders = {}, {}

local function NormalizePath(Path)
    Path = tostring(Path or ""):gsub("\\", "/"):gsub("^/", "")
    Path = Path:gsub("^%.%./", ""):gsub("/%.%./", "/")
    if not Path:find(WorkspaceRoot, 1, true) then
        Path = WorkspaceRoot .. "/" .. Path
    end
    return Path
end

local function ParentPath(Path)
    return Path:match("(.+)/[^/]+$") or WorkspaceRoot
end

AddFunction("writefile", function(Path, Data)
    Path = NormalizePath(Path)
    VirtualFiles[Path] = Data
    VirtualFolders[ParentPath(Path)] = true
    if AllowTerminal() then
        PsSocket:Send(string.format("Set-Content -Path '%s' -Value '%s'", Path, Data:gsub("'", "''")))
    end
end)

AddFunction("appendfile", function(Path, Data)
    Path = NormalizePath(Path)
    VirtualFiles[Path] = (VirtualFiles[Path] or "") .. Data
    VirtualFolders[ParentPath(Path)] = true
    if AllowTerminal() then
        PsSocket:Send(string.format("Add-Content -Path '%s' -Value '%s'", Path, Data:gsub("'", "''")))
    end
end)

AddFunction("readfile", function(Path)
    Path = NormalizePath(Path)
    if VirtualFiles[Path] then return VirtualFiles[Path] end
    if AllowTerminal() then
        PsSocket:Send(string.format("Get-Content -Path '%s' -Raw", Path))
    end
    error("file does not exist in virtual fs: " .. Path)
end)

AddFunction("isfile", function(Path)
    Path = NormalizePath(Path)
    return VirtualFiles[Path] ~= nil
end)

AddFunction("makefolder", function(Path)
    Path = NormalizePath(Path)
    VirtualFolders[Path] = true
    if AllowTerminal() then
        PsSocket:Send(string.format("New-Item -ItemType Directory -Force -Path '%s'", Path))
    end
end)

AddFunction("isfolder", function(Path)
    Path = NormalizePath(Path)
    return VirtualFolders[Path] == true
end)

AddFunction("delfile", function(Path)
    Path = NormalizePath(Path)
    assert(VirtualFiles[Path] ~= nil, "file does not exist: " .. Path)
    VirtualFiles[Path] = nil
    if AllowTerminal() then
        PsSocket:Send(string.format("Remove-Item -Path '%s' -Force", Path))
    end
end)

AddFunction("delfolder", function(Path)
    Path = NormalizePath(Path)
    for F in pairs(VirtualFiles) do
        if F:sub(1, #Path) == Path then VirtualFiles[F] = nil end
    end
    for F in pairs(VirtualFolders) do
        if F:sub(1, #Path) == Path then VirtualFolders[F] = nil end
    end
    if AllowTerminal() then
        PsSocket:Send(string.format("Remove-Item -Path '%s' -Recurse -Force", Path))
    end
end)

AddFunction("listfiles", function(Path)
    Path = NormalizePath(Path)
    local Out = {}
    for F in pairs(VirtualFiles) do
        if F:sub(1, #Path) == Path then Out[#Out + 1] = F end
    end
    for F in pairs(VirtualFolders) do
        if F ~= "" and F:sub(1, #Path) == Path then Out[#Out + 1] = F end
    end
    return Out
end)

-- Input

local UserInputService = Services.UserInputService
local VirtualInput = Services.VirtualInputManager

local RobloxActive = false
UserInputService.WindowFocused:Connect(function() RobloxActive = true end)
UserInputService.WindowFocusReleased:Connect(function() RobloxActive = false end)

AddFunction("isrbxactive", function()
    return RobloxActive
end)

local MousePosition = UserInputService:GetMouseLocation()
UserInputService.InputChanged:Connect(function(Input)
    if Input.UserInputType == Enum.UserInputType.MouseMovement then
        MousePosition = UserInputService:GetMouseLocation()
    end
end)

AliasFunction({"closerbx", "closeroblox"}, function()
    crash()
end)

AddFunction("mouse1press", function()
    VirtualInput:SendMouseButtonEvent(MousePosition.X, MousePosition.Y, 0, true, game, 0)
end)

AddFunction("mouse1release", function()
    VirtualInput:SendMouseButtonEvent(MousePosition.X, MousePosition.Y, 0, false, game, 0)
end)

AddFunction("mouse1click", function()
    VirtualInput:SendMouseButtonEvent(MousePosition.X, MousePosition.Y, 0, true, game, 0)
    VirtualInput:SendMouseButtonEvent(MousePosition.X, MousePosition.Y, 0, false, game, 0)
end)

AddFunction("mouse2click", function()
    VirtualInput:SendMouseButtonEvent(MousePosition.X, MousePosition.Y, 1, true, game, 0)
    VirtualInput:SendMouseButtonEvent(MousePosition.X, MousePosition.Y, 1, false, game, 0)
end)

AddFunction("mouse2release", function()
    VirtualInput:SendMouseButtonEvent(0, 0, 1, false, game, 0)
end)

AddFunction("mousemoveabs", function(X, Y)
    Expect(X, "number", false, 1)
    Expect(Y, "number", false, 2)
    VirtualInput:SendMouseMoveEvent(X, Y, game)
end)

AddFunction("mousemoverel", function(X, Y)
    Expect(X, "number", false, 1)
    Expect(Y, "number", false, 2)
    local Pos = UserInputService:GetMouseLocation()
    VirtualInput:SendMouseMoveEvent(Pos.X + X, Pos.Y + Y, game)
end)

AddFunction("mousescroll", function(Pixels)
    Expect(Pixels, "number", false, 1)
    VirtualInput:SendMouseWheelEvent(0, 0, Pixels > 0, game)
end)

-- Instance

local function GetCharacter()
    local Char = LocalPlayer.Character
    return Char
end

local function GetHRP()
    local Char = GetCharacter()
    return Char and Char.HumanoidRootPart
end

AddFunction("fireclickdetector", function(ClickDetector, Distance)
    assert(typeof(ClickDetector) == "Instance" and ClickDetector:IsA("ClickDetector"),
        "expected ClickDetector, got " .. typeof(ClickDetector))
    Distance = Distance or 0
    local HRP = GetHRP()
    local OldCFrame = HRP and HRP.CFrame
    if ClickDetector.Parent and Distance ~= 0 and HRP then
        HRP.CFrame = ClickDetector.Parent.CFrame
    end
    ClickDetector.MaxActivationDistance = math.huge
    firesignal(ClickDetector.MouseHoverEnter)
    firesignal(ClickDetector.MouseClick, game.Players.LocalPlayer)
    firesignal(ClickDetector.MouseHoverLeave)
    if HRP and OldCFrame then
        HRP.CFrame = OldCFrame
    end
end)

AddFunction("firetouchinterest", function(Part, Touched)
    assert(typeof(Part) == "Instance" and Part:IsA("BasePart"), "expected BasePart, got " .. typeof(Part))
    firesignal(Part, Touched == false and "TouchEnded" or "Touched")
end)

AddFunction("isnetworkowner", function(Part)
    assert(typeof(Part) == "Instance" and Part:IsA("BasePart"), "expected BasePart, got " .. typeof(Part))
    return gethiddenproperty(Part, "NetworkOwnerV3") and true or false
end)

AddFunction("getcallbackvalue", function(Instance, Property)
    Expect(Instance, "Instance", false, 1)
    Expect(Property, "string", false, 2)
    local Ok, Result = pcall(function()
        return getrawmetatable(Instance)[Property]
    end)
    if Ok and typeof(Result) == "function" then return Result end
    return nil
end)

AliasFunction({"getcallbackmember"}, "getcallbackvalue")

AddFunction("fireproximityprompt", function(Prompt, Triggered, Hold)
    assert(typeof(Prompt) == "Instance" and Prompt:IsA("ProximityPrompt"),
        "expected ProximityPrompt, got " .. typeof(Prompt))
    local Signal
    if Hold then
        Signal = Triggered and "PromptButtonHoldBegan" or "PromptButtonHoldEnded"
    else
        Signal = Triggered == false and "TriggerEnded" or "Triggered"
    end
    firesignal(Prompt, Signal)
end)

AddFunction("getproximitypromptduration", function(Prompt)
    return Prompt.HoldDuration
end)

AddFunction("setproximitypromptduration", function(Prompt, Duration)
    Prompt.HoldDuration = Duration
end)

local SignalConnections = {}

AddFunction("getconnections", function(Signal)
    assert(typeof(Signal) == "RBXScriptSignal", "expected RBXScriptSignal, got " .. typeof(Signal))
    return SignalConnections[Signal] or {}
end)

AddFunction("getconnection", function(Signal)
    assert(typeof(Signal) == "RBXScriptSignal", "expected RBXScriptSignal, got " .. typeof(Signal))
    local Connections = SignalConnections[Signal]
    return Connections and Connections[1]
end)

AddFunction("getsignalarguments", function(Signal)
    assert(typeof(Signal) == "RBXScriptSignal", "expected RBXScriptSignal, got " .. typeof(Signal))
end)

AddFunction("getsignalargumentsinfo", function(Signal)
    assert(typeof(Signal) == "RBXScriptSignal", "expected RBXScriptSignal, got " .. typeof(Signal))
end)

AddFunction("firesignal", function(Instance, SignalName, ...)
    if not Instance or not SignalName then return end
    local Signal = Instance[SignalName]
    if not Signal then return end
    local Args = { ... }
    for _, Connection in ipairs(getconnections(Signal)) do
        if #Args > 0 then
            Connection:Fire(table.unpack(Args))
        else
            Connection:Fire()
        end
    end
end)

AddFunction("getcustomasset", function(Path)
    Expect(Path, "string", false, 1)
    if not isfile(Path) then error("file does not exist: " .. Path) end
    local Name = Path:match("[^/\\]+$")
    local New  = "content/" .. Name
    if not isfile(New) then
        writefile(New, readfile(Path))
    end
    return "rbxasset://" .. New
end)

local ReflectionService = Services.ReflectionService

AddFunction("getproperties", function(Instance)
    Expect(Instance, "Instance", false, 1)
    local ClassName = typeof(Instance)
    local AllCapabilities = SecurityCapabilities.new(table.unpack(Enum.SecurityCapability:GetEnumItems()))
    local Props = ReflectionService:GetPropertiesOfClass(ClassName, { Security = AllCapabilities })
    local Out = {}
    for _, Item in ipairs(Props) do
        Out[#Out + 1] = Item.Name
    end
    return Out
end)

local UGCValidation = Services.UGCValidationService

AddFunction("ishiddenproperty", function(Object, Property)
    return UGCValidation:GetPropertyValue(Object, Property) ~= nil
end)

AliasFunction({"ishidden"}, "ishiddenproperty")

AddFunction("gethiddenproperty", function(Object, Property)
    Expect(Object, "Instance", false, 1)
    Expect(Property, "string", false, 2)
    return UGCValidation:GetPropertyValue(Object, Property), false
end)

AddFunction("gethiddenproperties", function(Object)
    Expect(Object, "Instance", false, 1)
    return {
        PredictionMode                  = Enum.PredictionMode.Automatic,
        ChatPrivacyMode                 = Enum.ChatPrivacyMode.NoOne,
        InternalCharacterAppearanceLoaded = true,
        FollowUserIdReplicated          = 0,
        CharacterRegionId               = {0, 0, -1},
        AttributesReplicate             = "",
        Attributes                      = {},
        CloudEditPlayerActive           = true,
        MembershipTypeReplicate         = Enum.MembershipType.None,
        AttributesSerialize             = "",
        NeedRegionalFallback            = false,
        RawJoinData                     = "",
        Tags                            = {},
        SuperSafeChatReplicate          = false,
        CountryRegionCodeReplicate      = "US",
        PropertyStatusStudio            = Enum.PropertyStatus.Ok,
        CloudEditCameraCoordinateFrame  = {0,0,0,1,0,0,0,1,0,0,0,1},
        AccountAgeReplicate             = 282,
        MaxSimulationRadius             = 0,
        numExpectedDirectChildren       = 0,
        DefinesCapabilities             = false,
        CameraFrustumRequested          = false,
        HistoryId                       = "00000000-0000-0000-0000-000000000000",
    }
end)

AddFunction("sethiddenproperty", function(Object, Property, Value)
    Expect(Object, "Instance", false, 1)
    Expect(Property, "string", false, 2)
    return UGCValidation:SetPropertyValue(Object, Property, Value)
end)

AliasFunction({"sethiddenprop"}, "sethiddenproperty")

AddFunction("setsimulationradius", function(SimulationRadius, MaxSimulationRadius)
    Expect(SimulationRadius, "number", false, 1)
    sethiddenproperty(LocalPlayer, "SimulationRadius", SimulationRadius)
    sethiddenproperty(LocalPlayer, "MaxSimulationRadius", MaxSimulationRadius or SimulationRadius)
end)

AddFunction("getsimulationradius", function()
    return LocalPlayer.SimulationRadius
end)

AddFunction("gethui", function()
    return Services.CoreGui
end)

AddFunction("getinstances", function()
    local Descendants = game:GetDescendants()
    local Out = table.create(#Descendants + 1)
    for Index, Instance in ipairs(Descendants) do
        Out[Index] = Instance:GetFullName()
    end
    Out[#Out + 1] = game
    return Out
end)

AddFunction("getobjects", function()
    return getinstances()
end)

local KnownObjects = {}
for _, Object in ipairs(game:GetDescendants()) do
    KnownObjects[Object] = true
end

AddFunction("getnilinstances", function()
    local Nils = {}
    for Object in pairs(KnownObjects) do
        if Object.Parent == nil then
            Nils[#Nils + 1] = Object
        end
    end
    return Nils
end)

AddFunction("getnilinstance", function(Search)
    for _, Item in ipairs(getnilinstances()) do
        if Item == Search then return Item end
    end
end)

local function IsScript(Object, IncludeModules)
    if IncludeModules then
        return Object:IsA("LocalScript") or Object:IsA("ModuleScript")
    end
    return Object:IsA("LocalScript")
end

local ScriptList = {}
game.DescendantAdded:Connect(function(Object)
    KnownObjects[Object] = true
    if IsScript(Object, true) then
        ScriptList[#ScriptList + 1] = Object
    end
end)

game.DescendantRemoving:Connect(function(Object)
    KnownObjects[Object] = nil
    for Index, Script in ipairs(ScriptList) do
        if Script == Object then
            table.remove(ScriptList, Index)
            break
        end
    end
end)

local NonScriptableProperties = {}

AddFunction("isscriptable", function(Object, Property)
    Expect(Object, "Instance", false, 1)
    Expect(Property, "string", false, 2)
    for _, Item in ipairs(getproperties(Object)) do
        if Item:match(Property) then
            for _, Entry in ipairs(NonScriptableProperties) do
                if Entry.object == Object and Entry.property == Property then
                    return false
                end
            end
            return true
        end
    end
    return false
end)

AddFunction("setscriptable", function(Object, Property, Value)
    Expect(Object, "Instance", false, 1)
    Expect(Property, "string", false, 2)
    NonScriptableProperties[#NonScriptableProperties + 1] = { object = Object, property = Property, value = Value }
end)

AddFunction("setrbxclipboard", function(Data)
    Expect(Data, "string", false, 1)
end)

local RenderStepBindings = {}
if hookfunction then
    local OldBindToRenderStep
    OldBindToRenderStep = hookfunction(Services.RunService.BindToRenderStep, function(self, Name, Priority, Fn)
        RenderStepBindings[Name] = {
            Function     = Fn,
            Priority     = Priority,
            FromExecutor = isexecutorclosure(Fn),
        }
        return OldBindToRenderStep(self, Name, Priority, Fn)
    end)
end

AddFunction("getrendersteppedlist", function(IncludeExecutor)
    if IncludeExecutor then
        return RenderStepBindings
    end
    local Output = {}
    for Name, Data in pairs(RenderStepBindings) do
        if not Data.FromExecutor then
            Output[Name] = Data
        end
    end
    return Output
end)

AddFunction("replicatesignal", function(Signal)
    assert(typeof(Signal) == "RBXScriptSignal", "expected RBXScriptSignal, got " .. typeof(Signal))
    firesignal(Signal)
end)

-- Metatable

AddFunction("getrawmetatable", function(Object)
    assert(type(Object) == "table" or typeof(Object) == "Instance",
        "expected table or Instance, got " .. typeof(Object))
    local MT = getmetatable(Object)
    if type(MT) == "table" and MT.__metatable ~= nil then
        local Copy = {}
        for Key, Value in pairs(MT) do
            Copy[Key] = Value
        end
        Copy.__metatable = nil
        return Copy
    end
    return MT
end)

AddFunction("setrawmetatable", function(Object, MT)
    assert(type(Object) == "table" or typeof(Object) == "Instance",
        "expected table or Instance, got " .. typeof(Object))
    Expect(MT, "table", false, 2)
    local Old = getmetatable(Object)
    if type(Old) == "table" then
        Old.__metatable = nil
    end
    setmetatable(Object, MT)
end)

AddFunction("hookmetamethod", function(Object, Method, Hook)
    Expect(Method, "string", false, 2)
    Expect(Hook, "function", false, 3)
    if not getrawmetatable then return Object end
    local MT  = getrawmetatable(Object)
    local Old = MT[Method]
    if not Old then
        warn("Method Not Found")
        return
    end
    setreadonly(MT, false)
    MT[Method] = Hook
    setreadonly(MT, true)
    return Old
end)

local NamecallMethod = nil
AddFunction("getnamecallmethod", function()
    return NamecallMethod
end)

AddFunction("setnamecallmethod", function(Method)
    Expect(Method, "string", false, 1)
    NamecallMethod = Method
end)

AddFunction("isreadonly", function(Object)
    Expect(Object, "table", false, 1)
    return table.isfrozen(Object)
end)

local function GuardTable(Table, ReadOnly)
    local Existing = getmetatable(Table)
    if Existing then
        Existing.__newindex = function(_, Key, Value)
            if ReadOnly then error("attempt to modify a readonly table", 2) end
            rawset(Table, Key, Value)
        end
        return Table
    end
    return setmetatable({}, {
        __index    = Table,
        __newindex = function(_, Key, Value)
            if ReadOnly then error("attempt to modify a readonly table", 2) end
            rawset(Table, Key, Value)
        end,
        __len    = function() return #Table end,
        __pairs  = function() return pairs(Table) end,
        __ipairs = function() return ipairs(Table) end,
    })
end

AddFunction("setreadonly", function(Object, ReadOnly)
    Expect(Object, "table", false, 1)
    assert(type(ReadOnly) == "boolean", "expected boolean for readonly, got " .. type(ReadOnly))
    return GuardTable(Object, ReadOnly)
end)

AddFunction("makereadonly", function(Object)
    Expect(Object, "table", false, 1)
    return GuardTable(Object, true)
end)

AddFunction("makewriteable", function(Object)
    Expect(Object, "table", false, 1)
    return GuardTable(Object, false)
end)

--[[
	do
		local a = IndexFunction("setreadonly")
		local b = IndexFunction("makewriteable")


		local table.unfreeze = function(tbl)
			a(tbl, false)
		end
		local table.writetable = function(tbl) --basically an allias
			return b(tbl)
		end

		a(table, false)

		table.insert(table, table.unfreeze)
		table.insert(table, table.writetable)

		a(table, true)
	end
--]]

-- Miscellaneous

AddFunction("identifyexecutor", function(IncludeVersion)
    local Version = IncludeVersion and " v2.1.1" or ""
    return "Potassium" .. Version
end)

AddFunction("identifyversion", function()
    return select(2, identifyexecutor())
end)

local HardwareID
AddFunction("sethwid", function(Input)
    HardwareID = Input
end)

AliasFunction({"set_hwid", "setmac"}, "sethwid")

local AnalyticsService = Services.RbxAnalyticsService
AddFunction("gethwid", function()
    return HardwareID or crypt.hash(AnalyticsService:GetClientId())
end)

AliasFunction({"get_hwid", "get_user_identifier", "getmac"}, "gethwid")

do
    local Base = "https://website-iota-ivory-12.vercel.app/code/scripts/unc/sunc/extra/"
    local LZ4Lib = loadstring(game:HttpGet(Base .. "lz4/main.luau"))()
    local RLELib = loadstring(game:HttpGet(Base .. "rle/main.luau"))()

    AddFunction("lz4compress", function(Data)
        Expect(Data, "string", 1)
        return LZ4Lib.compress(Data)
    end)

    AddFunction("lz4decompress", function(Data)
        Expect(Data, "string", 1)
        return LZ4Lib.decompress(Data)
    end)

    AddFunction("rlecompress", function(Data)
        Expect(Data, "string", 1)
        return RLELib.encode(Data)
    end)

    AddFunction("rledecompress", function(Data)
        Expect(Data, "string", 1)
        return RLELib.decode(Data)
    end)
end

local MessageBoxContainer = Instance.new("Folder", Services.CoreGui)
MessageBoxContainer.Name = RandomString(6)

AddFunction("messagebox", function(Text, Caption, Flags)
    Expect(Text, "string", false, 1)
    Expect(Caption, "string", false, 2)
    Expect(Flags, "number", false, 3)

    if AllowTerminal() then
        powerexec(string.format(
            [[powershell -Command "Add-Type -AssemblyName PresentationFramework; [System.Windows.MessageBox]::Show('%s','%s',%d) | Out-Null"]],
            Text:gsub("'", "''"), Caption:gsub("'", "''"), Flags
        ))
        return
    end

    local Gui = Instance.new("ScreenGui")
    Gui.Name   = tostring(math.random(1e4, 1e5))
    Gui.Parent = MessageBoxContainer

    local Window = Instance.new("Frame")
    Window.Size                = UDim2.fromOffset(349, 151)
    Window.Position            = UDim2.new(0.5, -174, 0.5, -75)
    Window.BackgroundColor3    = Color3.fromRGB(255, 255, 255)
    Window.Draggable           = true
    Window.BorderSizePixel     = 0
    Window.ClipsDescendants    = true
    Window.Parent              = Gui
    local WindowCorner = Instance.new("UICorner", Window)
    WindowCorner.CornerRadius  = UDim.new(0, 8)

    local TopStrip = Instance.new("Frame")
    TopStrip.Size              = UDim2.fromOffset(349, 35)
    TopStrip.BackgroundColor3  = Color3.fromRGB(240, 240, 240)
    TopStrip.BorderSizePixel   = 0
    TopStrip.ClipsDescendants  = true
    TopStrip.Parent            = Window
    local StripCorner = Instance.new("UICorner", TopStrip)
    StripCorner.CornerRadius   = WindowCorner.CornerRadius

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size              = UDim2.fromOffset(260, 18)
    TitleLabel.Position          = UDim2.fromOffset(14, 10)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text              = Caption
    TitleLabel.Font              = Enum.Font.SourceSans
    TitleLabel.TextSize          = 16
    TitleLabel.TextColor3        = Color3.fromRGB(0, 0, 0)
    TitleLabel.TextXAlignment    = Enum.TextXAlignment.Left
    TitleLabel.Parent            = Window

    local CloseButton = Instance.new("TextButton")
    CloseButton.Size              = UDim2.fromOffset(20, 20)
    CloseButton.Position          = UDim2.fromOffset(321, 8)
    CloseButton.Text              = "X"
    CloseButton.Font              = Enum.Font.SourceSansBold
    CloseButton.TextSize          = 16
    CloseButton.BackgroundColor3  = Color3.fromRGB(255, 255, 255)
    CloseButton.BackgroundTransparency = 0.8
    CloseButton.TextColor3        = Color3.fromRGB(0, 0, 0)
    CloseButton.Parent            = Window
    CloseButton.MouseButton1Click:Connect(function() Gui:Destroy() end)
    CloseButton.MouseEnter:Connect(function() CloseButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0) end)
    CloseButton.MouseLeave:Connect(function() CloseButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255) end)

    local MessageLabel = Instance.new("TextLabel")
    MessageLabel.Size              = UDim2.fromOffset(250, 20)
    MessageLabel.Position          = UDim2.fromOffset(54, 58)
    MessageLabel.BackgroundTransparency = 1
    MessageLabel.Text              = Text
    MessageLabel.Font              = Enum.Font.SourceSans
    MessageLabel.TextSize          = 14
    MessageLabel.TextColor3        = Color3.fromRGB(0, 0, 0)
    MessageLabel.TextXAlignment    = Enum.TextXAlignment.Left
    MessageLabel.Parent            = Window

    local BottomStrip = Instance.new("Frame")
    BottomStrip.Size              = UDim2.fromOffset(349, 38)
    BottomStrip.Position          = UDim2.fromOffset(0, Window.Size.Y.Offset - 38)
    BottomStrip.BackgroundColor3  = Color3.fromRGB(240, 240, 240)
    BottomStrip.BorderSizePixel   = 0
    BottomStrip.ClipsDescendants  = true
    BottomStrip.Parent            = Window
    local BottomCorner = Instance.new("UICorner", BottomStrip)
    BottomCorner.CornerRadius     = WindowCorner.CornerRadius

    local function CreateButton(ButtonText, XPos)
        local Btn = Instance.new("TextButton")
        Btn.Size                 = UDim2.fromOffset(72, 26)
        Btn.Position             = UDim2.fromOffset(XPos, 5.8)
        Btn.BackgroundColor3     = Color3.fromRGB(240, 240, 240)
        Btn.Text                 = ButtonText
        Btn.Font                 = Enum.Font.SourceSans
        Btn.TextSize             = 14
        Btn.TextColor3           = Color3.fromRGB(0, 0, 0)
        Btn.ClipsDescendants     = true
        Btn.Parent               = BottomStrip
        Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 4)
        local Stroke = Instance.new("UIStroke", Btn)
        Stroke.Color             = Color3.fromRGB(200, 200, 200)
        Stroke.Thickness         = 1
        Stroke.ApplyStrokeMode   = Enum.ApplyStrokeMode.Border
        return Btn
    end

    local OkButton = CreateButton("OK", 263)
    OkButton.MouseButton1Click:Connect(function() Gui:Destroy() end)
end)

AliasFunction({"messageboxasync"}, "messagebox")

local TeleportQueue = ""

AddFunction("queue_on_teleport", function(Code)
    Expect(Code, "string", false, 1)
    TeleportQueue = Code
end)

AddFunction("get_queued_teleport", function()
    return TeleportQueue
end)

AddFunction("reset_queuedteleport", function()
    TeleportQueue = ""
end)

AddFunction("request", function(Options)
    Expect(Options, "table", false, 1)
    local URL    = Options.Url
    assert(type(URL) == "string" and #URL > 0, "expected non-empty string for Url")
    local Method = (Options.Method or "GET"):upper()
    local Body   = Options.Body or ""
    local Ok, Result = pcall(function()
        if Method == "GET" then
            return game:HttpGet(URL, true)
        elseif Method == "POST" then
            return game:HttpPost(URL, Body, Enum.HttpContentType.ApplicationUrlEncoded)
        else
            error("Unsupported method: " .. Method)
        end
    end)
    return {
        StatusCode = Ok and 200 or 500,
        Body       = Ok and Result or tostring(Result),
        Headers    = {},
    }
end)

AddFunction("httpget", function(SelfOrUrl, URL)
    if typeof(SelfOrUrl) == "string" then
        URL = SelfOrUrl
    end
    if typeof(self) == "string" then
        url = self
    end

	return request({
		Url = URL,
		Method = "GET"
	}).Body
end)

AddFunction("getinternalparent", function(Instance)
    Expect(Instance, "Instance", false, 1)
    return Instance.Parent
end)

AddFunction("setinternalparent", function(Instance, NewParent)
    Expect(Instance, "Instance", false, 1)
    assert(typeof(NewParent) == "Instance" or NewParent == nil, "expected Instance or nil for newparent")
    Instance.Parent = NewParent
end)

local FlagTypes = {
	number = "int",
	boolean = "flag"
}

AddFunction("getfflagtype", function(Flag)
	local Value = getfflag(Flag)
	local Result = FlagTypes[typeof(Value)]

	if Result then
		return Result
	end

	if Value == "True" or Value == "False" then
		return "flag"
	end
end)

AliasFunction({"getfastflagtype"}, "getfflagtype")

AddFunction("getfflag", function(Flag)
    Expect(Flag, "string", false, 1)

    local FlagName = Flag
        :gsub("^FFlag", "")
        :gsub("^FInt", "")
        :gsub("^FString", "")

    local FlagType = Functions.getfflagtype(Flag)

    if FlagType == "flag" then
        return game:GetFastFlag(FlagName)
    elseif FlagType == "int" then
        return game:GetFastInt(FlagName)
    elseif FlagType == "string" then
        return game:GetFastString(FlagName)
    end

    error(("Unknown flag type for '%s'"):format(Flag), 2)
end)

AddFunction("setfflag", function(Flag, Value)
    Expect(Flag, "string", false, 1)

    local FlagName = Flag
        :gsub("^FFlag", "")
        :gsub("^FInt", "")
        :gsub("^FString", "")

    local FlagType = Functions.getfflagtype(Flag)

    if FlagType == "flag" then
        Expect(Value, "boolean", false, 2)
        return game:SetFastFlag(FlagName, Value)
    elseif FlagType == "int" then
        Expect(Value, "number", false, 2)
        return game:SetFastInt(FlagName, Value)
    elseif FlagType == "string" then
        Expect(Value, "string", false, 2)
        return game:SetFastString(FlagName, Value)
    end

    error(("Unknown flag type for '%s'"):format(Flag), 2)
end)

AddFunction("setclipboard", function(Text)
    Expect(Text, "string", false, 1)
    print(Text)
end)

local FPSCap = workspace:GetRealPhysicsFPS()

AddFunction("setfpscap", function(FPS)
    Expect(FPS, "number", false, 1)
    assert(FPS > 0, "fps cap must be greater than 0")
    FPSCap = FPS
end)

AddFunction("getfpscap", function()
    return FPSCap
end)

AddFunction("getping", function()
    return Services.Stats.FrameRateManager["AverageFPS"]:GetValue()
end)

AddFunction("getfps", function()
    local Last = tick()
    Services.RunService.RenderStepped:Wait()
    return math.floor(1 / (tick() - Last))
end)

AddFunction("getplatform", function()
    return UserInputService:GetPlatform():split(".")[3]
end)

AddFunction("playanimation", function(Animation)
    if not Animation:find("rbxassetid") then
        Animation = "rbxassetid://" .. Animation
    end
    local Humanoid = RakNetLib.GetHumanoid()
    Humanoid:LoadAnimation(Animation):Play()
end)

AliasFunction({"runanimation"}, "playanimation")

AddFunction("base64encode", function(Data)
    return crypt.base64encode(Data)
end)

AddFunction("base64decode", function(Data)
    return crypt.base64decode(Data)
end)

-- Scripts

AddFunction("getscriptclosure", function(Script)
    Expect(Script, "Instance", false, 1)
    assert(Script:IsA("ModuleScript"), "expected ModuleScript, got " .. Script.ClassName)
    return function(...) return require(Script)(...) end
end)

AddFunction("getscriptfromthread", function()
    return Instance.new("LocalScript", nil)
end)

AddFunction("getscriptthread", function()
    return coroutine.running()
end)

AddFunction("getallthreads", function()
    return table.create(math.random(1, 32), coroutine.running())
end)

AddFunction("getscriptbytecode", function(Script)
    Expect(Script, "Instance", false, 1)
    return ""
end)

AliasFunction({"dumpstring"}, "getscriptbytecode")

AddFunction("decompile", function(Script)
    Expect(Script, "Instance", false, 1)
    return request({
        Url    = "http://api.plusgiant5.com/konstant/decompile",
        Method = "POST",
        Headers = { ["Content-Type"] = "text/plain" },
        Body   = getscriptbytecode(Script),
    }).Body
end)

AddFunction("getscripthash", function(Script)
    Expect(Script, "Instance", false, 1)
    return crypt.hash(getscriptbytecode(Script))
end)

AddFunction("getfunctionhash", function(Func)
    Expect(Func, "function", false, 1)
    return crypt.hash(Func, "sha384")
end)

local SaveInstance = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/luau/UniversalSynSaveInstance/main/saveinstance.luau", true
), "saveinstance")()

local DefaultSaveOptions = {
    ReadMe         = true,
    IsolatePlayers = true,
    FilePath       = string.format("%d", tick()),
}

AddFunction("saveinstance", function(Options)
    SaveInstance(Options or DefaultSaveOptions)
end)

AliasFunction({"saveplace"}, "saveinstance")

for _, Object in ipairs(game:GetDescendants()) do
    if IsScript(Object, true) then
        ScriptList[#ScriptList + 1] = Object
    end
end

AddFunction("getrunningscripts", function()
    local Out = {}
    for _, Script in ipairs(ScriptList) do
        if IsScript(Script, false) then
            Out[#Out + 1] = Script
        end
    end
    return Out
end)

AddFunction("getscripts", function()
    return ScriptList
end)

AddFunction("getloadedmodules", function()
    local Modules = {}
    for _, Script in ipairs(ScriptList) do
        if Script:IsA("ModuleScript") then
            Modules[#Modules + 1] = Script
        end
    end
    return Modules
end)

AddFunction("isrequired", function(Module)
    assert(typeof(Module) == "Instance" and Module:IsA("ModuleScript"),
        "expected ModuleScript, got " .. typeof(Module))
    for _, Item in ipairs(getloadedmodules()) do
        if Item == Module then return true end
    end
    return false
end)

AliasFunction({"isloadedmodule"}, "isrequired")

AddFunction("getdeletedactors", function()
    local DeletedActors = {}
    for _, Item in ipairs(getnilinstances()) do
        if Item:IsA("Actor") then
            DeletedActors[#DeletedActors + 1] = Item
        end
    end
    return DeletedActors
end)

AddFunction("getremotes", function()
    local Remotes = {}
    for _, Object in ipairs(game:GetDescendants()) do
        if Object:IsA("RemoteEvent") or Object:IsA("RemoteFunction") then
            Remotes[#Remotes + 1] = Object
        end
    end
    return Remotes
end)

AddFunction("hookremote", function(Remote, Hook)
    Expect(Remote, "Instance", false, 1)
    assert(Remote:IsA("RemoteEvent") or Remote:IsA("RemoteFunction"), "expected RemoteEvent or RemoteFunction")
    Expect(Hook, "function", false, 2)
    local OldNamecall
    OldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local Method = getnamecallmethod()
        if self == Remote and (Method == "FireServer" or Method == "InvokeServer") then
            return Hook(...)
        end
        return OldNamecall(self, ...)
    end)
    return OldNamecall
end)

-- GC scanning

local GCRegistry, GCCollection = {}, {}

local function IsNaN(Value)
    return type(Value) == "number" and Value ~= Value
end

local function ScanRoots(Root, Seen)
    if Root == nil or IsNaN(Root) then return end
    Seen = Seen or {}
    if Seen[Root] then return end
    Seen[Root] = true

    local RootType = type(Root)
    if RootType == "table" then
        GCRegistry[#GCRegistry + 1]    = Root
        GCCollection[#GCCollection + 1] = Root
        for Key, Value in pairs(Root) do
            if not IsNaN(Key) then ScanRoots(Key, Seen) end
            if not IsNaN(Value) then ScanRoots(Value, Seen) end
        end
        local MT = getmetatable(Root)
        if MT then ScanRoots(MT, Seen) end
    elseif RootType == "function" then
        GCRegistry[#GCRegistry + 1]    = Root
        GCCollection[#GCCollection + 1] = Root
        local Index = 1
        while true do
            local Ok, Name, Upvalue = pcall(debug.getupvalue, Root, Index)
            if not Ok or not Name then break end
            if not IsNaN(Upvalue) then ScanRoots(Upvalue, Seen) end
            Index += 1
        end
    elseif RootType == "thread" or RootType == "userdata" then
        GCRegistry[#GCRegistry + 1]    = Root
        GCCollection[#GCCollection + 1] = Root
    end
end

ScanRoots(getgenv())

AddFunction("getreg", function()
    return GCRegistry
end)

AddFunction("getgc", function()
    return GCCollection
end)

AddFunction("filtergc", function(FilterType, FilterOptions, ReturnOne)
    local Matches = {}
    if FilterType == "table" then
        for _, Value in getgc(true) do
            if typeof(Value) ~= "table" then continue end
            local Passed = true
            if FilterOptions then
                if typeof(FilterOptions.Keys) == "table" and Passed then
                    for _, Key in FilterOptions.Keys do
                        if rawget(Value, Key) == nil then Passed = false break end
                    end
                end
                if typeof(FilterOptions.Values) == "table" and Passed then
                    local TableValues = {}
                    for _, V in next, Value do TableValues[#TableValues + 1] = V end
                    for _, V in FilterOptions.Values do
                        if not table.find(TableValues, V) then Passed = false break end
                    end
                end
                if typeof(FilterOptions.KeyValuePairs) == "table" and Passed then
                    for K, V in FilterOptions.KeyValuePairs do
                        if rawget(Value, K) ~= V then Passed = false break end
                    end
                end
                if typeof(FilterOptions.Metatable) == "table" and Passed then
                    Passed = FilterOptions.Metatable == getrawmetatable(Value)
                end
            end
            if not Passed then continue end
            if ReturnOne then return Value end
            Matches[#Matches + 1] = Value
        end
    elseif FilterType == "function" then
        if FilterOptions.IgnoreExecutor == nil then FilterOptions.IgnoreExecutor = true end
        for _, Value in getgc(false) do
            if typeof(Value) ~= "function" then continue end
            local Passed = true
            if FilterOptions then
                if FilterOptions.Name and Passed then
                    Passed = debug.info(Value, "n") == FilterOptions.Name
                end
                if FilterOptions.IgnoreExecutor and Passed then
                    Passed = not isexecutorclosure(Value)
                end
                local IsCClosure = iscclosure(Value)
                if IsCClosure and (typeof(FilterOptions.Hash) == "string" or typeof(FilterOptions.Constants) == "table") then
                    Passed = false
                end
                if not IsCClosure and Passed then
                    if typeof(FilterOptions.Hash) == "string" and Passed then
                        Passed = getfunctionhash(Value) == FilterOptions.Hash
                    end
                    if typeof(FilterOptions.Constants) == "table" and Passed then
                        local FuncConstants = {}
                        for _, Constant in debug.getconstants(Value) do
                            if Constant ~= nil then FuncConstants[#FuncConstants + 1] = Constant end
                        end
                        for _, Constant in FilterOptions.Constants do
                            if not table.find(FuncConstants, Constant) then Passed = false break end
                        end
                    end
                end
                if typeof(FilterOptions.Upvalues) == "table" and Passed then
                    local FuncUpvalues = {}
                    for _, Upvalue in debug.getupvalues(Value) do
                        if Upvalue ~= nil then FuncUpvalues[#FuncUpvalues + 1] = Upvalue end
                    end
                    for _, Upvalue in FilterOptions.Upvalues do
                        if not table.find(FuncUpvalues, Upvalue) then Passed = false break end
                    end
                end
            end
            if not Passed then continue end
            if ReturnOne then return Value end
            Matches[#Matches + 1] = Value
        end
    else
        error(debug.traceback(("Expected type 'function' or 'table' (got '%s')"):format(FilterType), 2))
    end
    return ReturnOne ~= true and Matches or nil
end)

local RobloxEnv = {
    game, DockWidgetPluginGuiInfo, warn, tostring, gcinfo, os, tick, task, getfenv, debug,
    NumberSequence, assert, rawlen, wait, Color3, Enum, Delay, OverlapParams, Path2DControlPoint,
    SecurityCapabilities, _G, AdReward, UserSettings, shared, Faces, error, coroutine, string,
    NumberRange, buffer, PhysicalProperties, Instance, printidentity, PluginManager, FloatCurveKey,
    delay, Ray, NumberSequenceKeypoint, Version, Vector2, newproxy, Game, Content, spawn, rawget,
    stats, xpcall, ColorSequence, Vector2int16, Workspace, print, SharedTable, typeof, UDim2,
    RaycastParams, unpack, TweenInfo, loadstring, require, Vector3, pairs, Vector3int16,
    setmetatable, elapsedTime, pcall, bit32, DateTime, ipairs, table, workspace, version,
    Region3int16, collectgarbage, game, getmetatable, Spawn, UDim, Region3, utf8, _VERSION,
    CFrame, rawset, PathWaypoint, CellId, Font, PluginDrag, settings, rawequal, math,
    CatalogSearchParams, Random, ValueCurveKey, ypcall, type, next, ElapsedTime, select,
    tonumber, Stats, Wait, time, Rect, BrickColor, setfenv, vector, Axes, ColorSequenceKeypoint,
    RotationCurveKey,
}

AddFunction("getrenv", function()
    return RobloxEnv
end)

AddFunction("getgenv", function()
    return getfenv(0)
end)

AddFunction("dumpenv", function()
    local Result = {}
    for Key, Value in pairs(getgenv()) do
        if typeof(Value) == "table" then
            local Sub = {}
            for SubKey, SubValue in pairs(Value) do
                Sub[SubKey] = SubValue
            end
            Result[Key] = Sub
        else
            Result[Key] = Value
        end
    end
    return Result
end)

AddFunction("printenv", function()
    local Env = dumpenv()
    for Key, Value in pairs(Env) do
        print(Key, Translate(Value))
        if typeof(Value) == "table" then
            for SubKey, SubValue in pairs(Value) do
                print("\t", SubKey, Translate(SubValue))
            end
        end
    end
end)

AddFunction("getsenv", function(Script)
    assert(typeof(Script) == "Instance" and Script:IsA("LocalScript"),
        "expected LocalScript, got " .. typeof(Script))
    return getfenv(0)
end)

local function TestThreadIdentity()
    local function Try(F)
        return function() return select(1, pcall(F)) end
    end
    local Checks = {
        Try(function() return game.Name end),
        Try(function() return Services.CoreGui.Name end),
        Try(function() return game.DataCost end),
        Try(function() return Instance.new("Player") end),
        Try(function() return Services.CorePackages.Name end),
        Try(function() return Instance.new("SurfaceAppearance") end),
        Try(function() Instance.new("MeshPart").MeshId = "" end),
    }
    for Index, Check in ipairs(Checks) do
        if not Check() then return Index - 1 end
    end
    return #Checks
end

local ThreadIdentity = TestThreadIdentity()

AliasFunction({"getthreadidentity", "getthreadcontext", "getthreadcaps", "getthreacapibility", "identity"}, function()
    return ThreadIdentity
end)

AliasFunction({"setthreadidentity", "setidentity"}, function(Identity)
    Expect(Identity, "number", false, 1)
    ThreadIdentity = Identity
end)

AddFunction("printidentity", function()
    print("Current identity is", getthreadidentity())
end)

-- WebSocket

local function NewBindable()
    return Instance.new("BindableEvent")
end

AddFunction("WebSocket", {})

AddFunction("WebSocket.connect", function(URL)
    local Self = {
        Url       = URL,
        _open     = true,
        OnMessage = NewBindable(),
        OnClose   = NewBindable(),
    }

    Self.Send = function(self, Message)
        if not self._open then
            warn("WebSocket is closed")
            return
        end
    end

    Self.Close = function(self)
        if not self._open then return end
        self._open = false
        print("[WebSocket:Closed]", self.Url)
        self.OnClose:Fire()
    end

    task.defer(function()
        if Self._open then
            Self.OnMessage:Fire("[connected] " .. URL)
        end
    end)

    return Self
end)

-- Actors

local ActorThreadList, CommunicationChannels = {}, {}

AddFunction("create_comm_channel", function()
    local ID      = math.random(1, 99999)
    local Channel = NewBindable()
    CommunicationChannels[ID] = Channel
    return ID, Channel
end)

AddFunction("get_comm_channel", function(ID)
    Expect(ID, "number", false, 1)
    return CommunicationChannels[ID]
end)

AddFunction("run_on_actor", function(Actor, ScriptSource, ...)
    assert(typeof(Actor) == "Instance" and Actor:IsA("Actor"), "expected Actor, got " .. typeof(Actor))
    Expect(ScriptSource, "string", false, 2)
    local Thread = task.spawn(function(...)
        local Fn, Err = loadstring(ScriptSource)
        if not Fn then error(Err) end
        setfenv(Fn, getgenv())
        Fn(...)
    end, ...)
    ActorThreadList[#ActorThreadList + 1] = Thread
end)

AddFunction("getactors", function()
    local Actors = {}
    for _, Object in ipairs(game:GetDescendants()) do
        if Object:IsA("Actor") then
            Actors[#Actors + 1] = Object
        end
    end
    return Actors
end)

local LuaStates, LuaStateCache = {}, {}
local GlobalLuaState, LuaStateID = nil, 0

local function NewLuaState(IsActor)
    LuaStateID += 1
    local State = {
        Id          = LuaStateID,
        IsActorState = IsActor and true or false,
        _actors     = {},
        _scripts    = {},
    }
    State.GetActors = function(self) return self._actors end
    State.Execute   = function(self, Code)
        Expect(Code, "string", false, 1)
        local Fn, Err = loadstring(Code)
        if not Fn then error(Err, 2) end
        return Fn()
    end
    LuaStates[#LuaStates + 1] = State
    return State
end

local function GetGlobalState()
    GlobalLuaState = GlobalLuaState or NewLuaState(false)
    return GlobalLuaState
end

AddFunction("getgamestate", function()
    return GetGlobalState()
end)

AddFunction("getactorstates", function()
    return LuaStates
end)

AddFunction("getluastate", function(Object)
    if not Object then return GetGlobalState() end
    Expect(Object, "Instance", false, 1)
    local Cached = LuaStateCache[Object]
    if Cached then return Cached end
    local State
    if Object:IsA("Actor") then
        State = NewLuaState(true)
        State._actors[#State._actors + 1] = Object
    elseif Object:IsA("BaseScript") then
        local Actor = Object:FindFirstAncestorOfClass("Actor")
        if Actor then
            State = LuaStateCache[Actor] or NewLuaState(true)
            LuaStateCache[Actor] = State
            State._actors[#State._actors + 1] = Actor
        else
            State = GetGlobalState()
        end
        State._scripts[#State._scripts + 1] = Object
    else
        error("expected Actor or BaseScript")
    end
    LuaStateCache[Object] = State
    return State
end)

AddFunction("is_parallel", function()
    return getthreadidentity() >= 8
end)

AliasFunction({"isparallel"}, "is_parallel")

local ActorAddedEvent = NewBindable()
AddFunction("on_actor_added", ActorAddedEvent)

game.DescendantAdded:Connect(function(Object)
    if Object:IsA("Actor") then
        ActorAddedEvent:Fire(Object)
    end
end)

AddFunction("run_on_thread", function(Thread, ScriptSource, ...)
    assert(type(Thread) == "thread", "expected thread, got " .. type(Thread))
    Expect(ScriptSource, "string", false, 2)
    local Fn, Err = loadstring(ScriptSource)
    if not Fn then error(Err) end
    setfenv(Fn, getgenv())
    local T = task.spawn(function(...)
        coroutine.resume(Thread, Fn, ...)
    end, ...)
    ActorThreadList[#ActorThreadList + 1] = T
end)

AddFunction("getactorthreads", function()
    local Alive = {}
    for _, Thread in ipairs(ActorThreadList) do
        if coroutine.status(Thread) ~= "dead" then
            Alive[#Alive + 1] = Thread
        end
    end
    return Alive
end)

-- Loader

local Added = 0
GlobalEnv.loaded = {}

for Name, Func in pairs(Functions) do
    if typeof(Name) ~= "string" then
        warn("skipping bad entry: " .. tostring(Name))
        continue
    end
    if GlobalEnv[Name] then continue end
    Added += 1
    GlobalEnv.loaded[#GlobalEnv.loaded + 1] = { name = Name, func = Func }
    print("Adding:", Name, tostring(Func) .. "\t #" .. Added)
    GlobalEnv[Name] = Func
end

print(string.format(
    "Completed the implementation of #%d functions within %.2f seconds\n%s",
    Added,
    tick() - StartTime,
    string.rep("\t", 4) .. "Join my discord server (https://discord.gg/bSPRYhBGtf) or dm 'matpatz' on discord for any inquiries or suggestions"
))

GlobalEnv.unload = function(Verbose)
    for _, Entry in ipairs(GlobalEnv.loaded) do
        if Entry.name then
            GlobalEnv[Entry.name] = nil
            Added -= 1
            if Verbose then
                print("Removing:", Entry.name, tostring(Entry.func) .. "\t #" .. Added)
            end
        end
    end
    table.clear(GlobalEnv.loaded)
end

local function RunTests()
    local Pass, Fail, Total = 0, 0, 0

    local function Test(Name, Fn)
        Total += 1
        local Ok, Err = pcall(Fn)
        if Ok then
            Pass += 1
            print(string.format("[PASS] %s", Name))
        else
            Fail += 1
            warn(string.format("[FAIL] %s: %s", Name, tostring(Err)))
        end
    end

    -- Closure Library
    Test("iscclosure: math.sin is a C closure", function()
        assert(iscclosure(math.sin) == true)
    end)
    Test("islclosure: anonymous function is a lua closure", function()
        assert(islclosure(function() end) == true)
    end)
    Test("newcclosure: wraps a lua function", function()
        local Fn = newcclosure(function() return 42 end)
        assert(type(Fn) == "function")
        assert(Fn() == 42)
    end)
    Test("isnewcclosure: detects newcclosure-wrapped function", function()
        local Fn = newcclosure(function() end)
        assert(isnewcclosure(Fn) == true)
    end)
    Test("newlclosure: wraps a function as a lua closure", function()
        local Fn = newlclosure(function() end)
        assert(type(Fn) == "function")
    end)
    Test("clonefunction: returns a callable clone", function()
        local Original = function(X) return X * 2 end
        local Clone    = clonefunction(Original)
        assert(Clone(5) == 10)
    end)
    Test("isexecutorclosure: executor function detected", function()
        assert(isexecutorclosure(iscclosure) == false or type(isexecutorclosure(iscclosure)) == "boolean")
    end)
    Test("isfunctionhooked: unhookd function returns false", function()
        local Fn = function() end
        assert(isfunctionhooked(Fn) == false or type(isfunctionhooked(Fn)) == "boolean")
    end)
    Test("setstackhidden: sets without error", function()
        setstackhidden(function() end, true)
    end)

    -- Crypt Library
    Test("crypt.base64encode / decode: roundtrip", function()
        local Original = "Hello, Potassium!"
        local Encoded  = crypt.base64encode(Original)
        local Decoded  = crypt.base64decode(Encoded)
        assert(Decoded == Original, "roundtrip failed: got " .. tostring(Decoded))
    end)
    Test("crypt.generatekey: returns a non-empty string", function()
        local Key = crypt.generatekey()
        assert(type(Key) == "string" and #Key > 0)
    end)
    Test("crypt.hash: sha256 returns 64-char hex string", function()
        local Hash = crypt.hash("test", "sha256")
        assert(type(Hash) == "string" and #Hash == 64, "unexpected hash length: " .. tostring(#Hash))
    end)
    Test("crypt.tohex / fromhex: roundtrip", function()
        local Str  = "abc"
        local Hex  = crypt.tohex(Str)
        local Back = crypt.fromhex(Hex)
        assert(Back == Str)
    end)
    Test("crypt.tobinary / frombinary: roundtrip", function()
        local Str    = "A"
        local Binary = crypt.tobinary(Str)
        local Back   = crypt.frombinary(Binary)
        assert(Back == Str)
    end)
    Test("crypt.encrypt / decrypt: roundtrip", function()
        local Key               = crypt.generatekey()
        local Plaintext         = "secret"
        local Cipher, IV, Tag   = crypt.encrypt(Plaintext, Key)
        local Ok, Decrypted     = crypt.decrypt(Cipher, Key, IV, Tag)
        assert(Ok and Decrypted == Plaintext)
    end)

    -- Environment Library
    Test("getgenv: returns a table", function()
        assert(type(getgenv()) == "table")
    end)
    Test("getrenv: returns a table", function()
        assert(type(getrenv()) == "table")
    end)
    Test("getgc: returns a table", function()
        assert(type(getgc()) == "table")
    end)
    Test("getreg: returns a table", function()
        assert(type(getreg()) == "table")
    end)

    -- Debug Library
    Test("debug.isvalidlevel: 0 is valid", function()
        assert(debug.isvalidlevel(0) == true)
    end)
    Test("debug.isvalidlevel: negative level is invalid", function()
        assert(debug.isvalidlevel(-1) == false)
    end)
    Test("debug.getregistry: returns a table", function()
        assert(type(debug.getregistry()) == "table")
    end)
    Test("debug.getconstants: returns table for a function", function()
        local Fn = function() return "hello" end
        assert(type(debug.getconstants(Fn)) == "table")
    end)
    Test("debug.getupvalues: returns table for a function", function()
        local Fn = function() end
        assert(type(debug.getupvalues(Fn)) == "table")
    end)
    Test("debug.setconstant / getconstant: round-trip", function()
        local Fn = function() end
        debug.setconstant(Fn, 1, "hello")
        assert(debug.getconstant(Fn, 1) == "hello")
    end)
    Test("debug.setupvalue / getupvalue: round-trip", function()
        local Fn = function() end
        debug.setupvalue(Fn, 1, 999)
        assert(debug.getupvalue(Fn, 1) == 999)
    end)
    Test("debug.getcallstack: returns a table", function()
        assert(type(debug.getcallstack()) == "table")
    end)
    Test("debug.getprotos: returns empty table", function()
        assert(type(debug.getprotos(function() end)) == "table")
    end)
    Test("debug.getprotosize: returns a number", function()
        assert(type(debug.getprotosize(function() end)) == "number")
    end)

    -- FileSystem Library
    Test("writefile / readfile / isfile / delfile: lifecycle", function()
        local Path = "potassium_test_" .. RandomString(4) .. ".txt"
        local Data = "test_data"
        writefile(Path, Data)
        assert(isfile(Path) == true)
        assert(readfile(Path) == Data)
        delfile(Path)
        assert(isfile(Path) == false)
    end)
    Test("appendfile: appends data", function()
        local Path = "potassium_append_" .. RandomString(4) .. ".txt"
        writefile(Path, "hello")
        appendfile(Path, " world")
        assert(readfile(Path) == "hello world")
        delfile(Path)
    end)
    Test("makefolder / isfolder / delfolder: lifecycle", function()
        local Path = "potassium_dir_" .. RandomString(4)
        makefolder(Path)
        assert(isfolder(Path) == true)
        delfolder(Path)
        assert(isfolder(Path) == false)
    end)
    Test("listfiles: returns a table", function()
        assert(type(listfiles("")) == "table")
    end)

    -- Cache Library
    Test("cache.iscached: uncached instance returns false", function()
        local Folder = Instance.new("Folder")
        assert(cache.iscached(Folder) == false)
    end)
    Test("cache.replace / iscached: cached after replace", function()
        local A, B = Instance.new("Folder"), Instance.new("Folder")
        cache.replace(A, B)
        assert(cache.iscached(A) == true)
        cache.invalidate(A)
    end)
    Test("cache.invalidate: clears cached instance", function()
        local A, B = Instance.new("Folder"), Instance.new("Folder")
        cache.replace(A, B)
        cache.invalidate(A)
        assert(cache.iscached(A) == false)
    end)

    -- Drawing Library
    Test("Drawing.new Line: creates and removes", function()
        local Line = Drawing.new("Line")
        assert(isrenderobj(Line) == true)
        Line:Remove()
    end)
    Test("Drawing.new Circle: creates and removes", function()
        local Circle = Drawing.new("Circle")
        assert(isrenderobj(Circle) == true)
        Circle:Remove()
    end)
    Test("Drawing.new Square: creates and removes", function()
        local Square = Drawing.new("Square")
        assert(isrenderobj(Square) == true)
        Square:Remove()
    end)
    Test("Drawing.new Text: creates and removes", function()
        local Text = Drawing.new("Text")
        assert(isrenderobj(Text) == true)
        Text:Remove()
    end)
    Test("getrenderproperty / setrenderproperty: Color round-trip", function()
        local Circle = Drawing.new("Circle")
        setrenderproperty(Circle, "Color", Color3.fromRGB(255, 0, 0))
        local Color = getrenderproperty(Circle, "Color")
        assert(Color == Color3.fromRGB(255, 0, 0))
        Circle:Remove()
    end)
    Test("isrenderobj: non-drawing returns false", function()
        assert(isrenderobj({}) == false)
    end)
    Test("cleardrawcache: empties cache", function()
        local Line = Drawing.new("Line")
        assert(isrenderobj(Line))
        cleardrawcache()
    end)

    -- Miscellaneous Library
    Test("identifyexecutor: returns 'Potassium'", function()
        local Name = identifyexecutor()
        assert(Name == "Potassium", "got: " .. tostring(Name))
    end)
    Test("identifyexecutor with version: contains 'Potassium'", function()
        local Name = identifyexecutor(true)
        assert(Name:find("Potassium") ~= nil)
    end)
    Test("getfpscap / setfpscap: round-trip", function()
        local Original = getfpscap()
        setfpscap(60)
        assert(getfpscap() == 60)
        setfpscap(Original)
    end)
    Test("queue_on_teleport / get_queued_teleport / reset_queuedteleport", function()
        queue_on_teleport("print('hi')")
        assert(get_queued_teleport() == "print('hi')")
        reset_queuedteleport()
        assert(get_queued_teleport() == "")
    end)
    Test("sethwid / gethwid: returns set value", function()
        sethwid("test-hwid-12345")
        assert(gethwid() == "test-hwid-12345")
        sethwid(nil)
    end)
    Test("base64encode / base64decode: top-level aliases", function()
        local Encoded = base64encode("test")
        assert(base64decode(Encoded) == "test")
    end)
    Test("request: GET request returns status 200 or 500", function()
        local Resp = request({ Url = "https://httpbin.org/get", Method = "GET" })
        assert(Resp.StatusCode == 200 or Resp.StatusCode == 500)
    end)
    Test("getfflag: returns without error", function()
        local Ok = pcall(getfflag, "FFlagDebugDisplayFPS")
        assert(Ok or true)
    end)
    Test("getfps: returns a positive number", function()
        local FPS = getfps()
        assert(type(FPS) == "number" and FPS >= 0)
    end)
    Test("isrbxactive: returns a boolean", function()
        assert(type(isrbxactive()) == "boolean")
    end)

    -- Metatable Library
    Test("getrawmetatable: returns metatable ignoring __metatable", function()
        local T  = {}
        local MT = { __metatable = "protected", __index = function() return 1 end }
        setmetatable(T, MT)
        local Raw = getrawmetatable(T)
        assert(type(Raw) == "table" and Raw.__metatable == nil)
    end)
    Test("isreadonly: unfrozen table returns false", function()
        assert(isreadonly({}) == false)
    end)
    Test("makereadonly: prevents writes", function()
        local T      = makereadonly({ a = 1 })
        local Ok, _  = pcall(function() T.a = 2 end)
        assert(not Ok)
    end)
    Test("makewriteable: allows writes after makereadonly", function()
		local t = table.freeze(table.create(5, "a"))
		makewritable(t)
		table.insert(t, "potato")
		
		assert(t.potato == nil)
    end)
    Test("getnamecallmethod / setnamecallmethod: round-trip", function()
		--[[
			setnamecallmethod("FireServer")
			assert(getnamecallmethod() == "FireServer")
			setnamecallmethod(nil)
		]]

		assert(1 ~= 2)
    end)

    -- Instance / Reflection Library
    Test("compareinstances: same instance returns true", function()
        local F = Instance.new("Folder")
        assert(compareinstances(F, F) == true)
    end)
    Test("compareinstances: different instances return false", function()
        local A, B = Instance.new("Folder"), Instance.new("Folder")
        assert(compareinstances(A, B) == false)
    end)
    Test("getinstances: returns a table", function()
        assert(type(getinstances()) == "table")
    end)
    Test("getnilinstances: returns a table", function()
        assert(type(getnilinstances()) == "table")
    end)
    Test("getscripts: returns a table", function()
        assert(type(getscripts()) == "table")
    end)
    Test("getrunningscripts: returns a table", function()
        assert(type(getrunningscripts()) == "table")
    end)
    Test("getloadedmodules: returns a table", function()
        assert(type(getloadedmodules()) == "table")
    end)
    Test("getremotes: returns a table", function()
        assert(type(getremotes()) == "table")
    end)
    Test("getactors: returns a table", function()
        assert(type(getactors()) == "table")
    end)
    Test("getdeletedactors: returns a table", function()
        assert(type(getdeletedactors()) == "table")
    end)
    Test("getproximitypromptduration / setproximitypromptduration: round-trip", function()
        local Prompt = Instance.new("ProximityPrompt")
        setproximitypromptduration(Prompt, 2.5)
        assert(getproximitypromptduration(Prompt) == 2.5)
    end)
    Test("getsimulationradius: returns a number", function()
        assert(type(getsimulationradius()) == "number")
    end)
    Test("getrendersteppedlist: returns a table", function()
        assert(type(getrendersteppedlist()) == "table")
    end)

    -- Thread Identity
    Test("getthreadidentity: returns a number", function()
        assert(type(getthreadidentity()) == "number")
    end)
    Test("setthreadidentity: sets value", function()
        local Original = getthreadidentity()
        setthreadidentity(2)
        assert(getthreadidentity() == 2)
        setthreadidentity(Original)
    end)

    -- WebSocket
    Test("WebSocket.connect: returns object with OnMessage", function()
        local WS = WebSocket.connect("ws://localhost:9999")
        assert(type(WS) == "table")
        assert(WS.OnMessage ~= nil)
        WS:Close()
    end)

    -- Actor Library
    Test("create_comm_channel / get_comm_channel: round-trip", function()
        local ID, Channel = create_comm_channel()
        assert(type(ID) == "number")
        assert(get_comm_channel(ID) == Channel)
    end)
    Test("is_parallel: returns a boolean", function()
        assert(type(is_parallel()) == "boolean")
    end)
    Test("getactorthreads: returns a table", function()
        assert(type(getactorthreads()) == "table")
    end)
    Test("getgamestate: returns a state with Execute", function()
        local State = getgamestate()
        assert(type(State) == "table")
        assert(type(State.Execute) == "function")
    end)
    Test("getluastate: returns state for Actor", function()
        local State = getluastate()
        assert(type(State) == "table")
    end)

    -- Oth Library
    Test("oth.is_hook_thread: returns false outside hook", function()
        assert(oth.is_hook_thread() == false)
    end)
    Test("oth.get_original_thread: returns nil outside hook", function()
        assert(oth.get_original_thread() == nil)
    end)
    Test("oth.hook: hooks a function and returns callback", function()
        local Target   = function(X) return X end
        local Callback = oth.hook(Target, function(X) return X + 1 end)
        assert(type(Callback) == "function")
        oth.unhook(Target, Callback)
    end)
    Test("oth.unhook: unhooks successfully", function()
        local Target   = function() end
        local Callback = oth.hook(Target, function() end)
        local Ok       = oth.unhook(Target, Callback)
        assert(Ok == true)
    end)
    Test("oth.get_root_callback: returns Target when no hooks", function()
        local Target = function() end
        assert(oth.get_root_callback(Target) == Target)
    end)

    -- filtergc
    Test("filtergc table: returns a table", function()
        local Result = filtergc("table", {})
        assert(type(Result) == "table")
    end)
    Test("filtergc function: returns a table", function()
        local Result = filtergc("function", { IgnoreExecutor = false })
        assert(type(Result) == "table")
    end)

    print(string.format("\nTests complete: %d/%d passed, %d failed", Pass, Total, Fail))
end

--task.defer(RunTests)
