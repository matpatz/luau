getgenv().PlayerHelper = true
local services = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/matpatz/luau/refs/heads/main/public/code/Modules/Services.lua"
))()

local _game = services.MarketplaceService:GetProductInfo(game.PlaceId).Name

local Rayfield = loadstring(game:HttpGet(
    "https://website-iota-ivory-12.vercel.app/code/loader/u/ui/rayfield.lua"
))()

local Player = services.Player
local Camera = services.Camera
local RunService = services.RunService
local Workspace = services.Workspace
local UserInputService = services.UserInputService

local window = Rayfield:CreateWindow({
    Name = _game,
    LoadingTitle = "Slowdown Script",
    LoadingSubtitle = "Enemy Detection Enabled",
})

local tabs = {
    main = window:CreateTab("Main", 4483362458),
    settings = window:CreateTab("Settings", 4483362458),
}

local connections = {
    detection = {},
}

local states = {
    values = {
        SlowdownEnabled = true,
        BodySlowdown = 0.3,
        HeadSlowdown = 0.1,
        DetectionRange = 1000,
        TeamCheck = true,
        IsSlowedDown = false,

        communication = Instance.new("BindableEvent"),
    },
}

local LastCameraPos = Camera.CFrame
local LastCameraTime = tick()

local function SetValue(obj, key, value)
    obj[key] = value
    states.values.communication:Fire({
        Object = obj,
        Key = key,
        Value = value,
    })
end

local function addConnection(category, name, connection)
    if category[name] then
        pcall(function()
            if typeof(category[name]) == "RBXScriptConnection" then
                category[name]:Disconnect()
            else
                task.cancel(category[name])
            end
        end)
    end
    category[name] = connection
end

local function IsEnemy(target)
    if not target or not target.Parent then return false end
    if target == Player.Character then return false end
    
    if states.values.TeamCheck then
        local TargetHumanoidRootPart = target.Parent:FindFirstChild("HumanoidRootPart")
        local TargetHumanoid = target.Parent:FindFirstChild("Humanoid")
        
        if not TargetHumanoidRootPart or not TargetHumanoid then return false end
        
        local PlayerTeam = Player.Team
        local TargetTeam = target.Parent.Parent
        
        if TargetTeam and TargetTeam:IsA("Team") then
            return PlayerTeam ~= TargetTeam
        end
    end
    
    return true
end

local function GetCrosshairTarget()
    local UnitRay = Camera:ScreenPointToRay(
        UserInputService:GetMouseLocation().X,
        UserInputService:GetMouseLocation().Y
    )
    
    local RaycastParams = RaycastParams.new()
    RaycastParams.FilterType = Enum.RaycastFilterType.Exclude
    RaycastParams.FilterDescendantsInstances = { Player.Character }
    
    local Result = Workspace:Raycast(UnitRay.Origin, UnitRay.Direction * states.values.DetectionRange, RaycastParams)
    
    if Result then
        local Hit = Result.Instance
        local Character = Hit.Parent
        
        if Character and Character:FindFirstChild("Humanoid") then
            if IsEnemy(Hit) then
                local IsHeadshot = Hit.Name == "Head"
                return true, IsHeadshot
            end
        end
    end
    
    return false, false
end

local function UpdateSlowdown()
    if not states.values.SlowdownEnabled then return end
    
    local OnEnemy, IsHeadshot = GetCrosshairTarget()
    local CurrentTime = tick()
    
    if OnEnemy then
        local SlowdownFactor = IsHeadshot and states.values.HeadSlowdown or states.values.BodySlowdown
        local TargetCFrame = Camera.CFrame
        
        Camera.CFrame = LastCameraPos:Lerp(TargetCFrame, SlowdownFactor)
        SetValue(states.values, "IsSlowedDown", true)
    else
        LastCameraPos = Camera.CFrame
        SetValue(states.values, "IsSlowedDown", false)
    end
    
    LastCameraTime = CurrentTime
end

tabs.main:CreateLabel("Slowdown Control")

tabs.main:CreateToggle({
    Name = "Enable Slowdown",
    CurrentValue = true,
    Callback = function(value)
        SetValue(states.values, "SlowdownEnabled", value)
    end,
})

tabs.main:CreateLabel("Current Status: " .. (states.values.IsSlowedDown and "ON TARGET" or "WAITING"))

tabs.settings:CreateLabel("Body Slowdown")

tabs.settings:CreateSlider({
    Name = "Body Slowdown %",
    Range = { 0, 1 },
    Increment = 0.01,
    CurrentValue = 0.3,
    Callback = function(value)
        SetValue(states.values, "BodySlowdown", value)
    end,
})

tabs.settings:CreateLabel("Headshot Slowdown")

tabs.settings:CreateSlider({
    Name = "Head Slowdown %",
    Range = { 0, 1 },
    Increment = 0.01,
    CurrentValue = 0.1,
    Callback = function(value)
        SetValue(states.values, "HeadSlowdown", value)
    end,
})

tabs.settings:CreateLabel("Advanced")

tabs.settings:CreateSlider({
    Name = "Detection Range",
    Range = { 100, 5000 },
    Increment = 100,
    CurrentValue = 1000,
    Callback = function(value)
        SetValue(states.values, "DetectionRange", value)
    end,
})

tabs.settings:CreateToggle({
    Name = "Team Check",
    CurrentValue = true,
    Callback = function(value)
        SetValue(states.values, "TeamCheck", value)
    end,
})

tabs.settings:CreateButton({
    Name = "Reset to Defaults",
    Callback = function()
        SetValue(states.values, "BodySlowdown", 0.3)
        SetValue(states.values, "HeadSlowdown", 0.1)
        SetValue(states.values, "DetectionRange", 1000)
        Rayfield:Notify({
            Title = "Reset",
            Content = "Settings reset to default values.",
            Duration = 3,
            Image = 4483362458,
        })
    end,
})

addConnection(connections.detection, "SlowdownLoop", RunService.RenderStepped:Connect(function()
    if window.Visible then return end
    UpdateSlowdown()
end))

Rayfield:Notify({
    Title = _game,
    Content = "Slowdown script loaded!",
    Duration = 5,
    Image = 4483362458,
})
