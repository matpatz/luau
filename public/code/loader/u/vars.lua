local _g, _s = game, {
    ["players"] = "Players",
    ["workspace"] = "Workspace",
    ["run"] = "RunService",
    ["core"] = "CoreGui",
    ["input"] = "UserInputService",
    ["rep"] = "ReplicatedStorage",
    ["lighting"] = "Lighting",
    ["vim"] = "VirtualInputManager",
    ["text"] = "TextChatService",
    ["analytics"] = "RbxAnalyticsService",
    ["marketplace"] = "MarketplaceService",
    ["teleport"] = "TeleportService",
    ["http"] = "HttpService",
    ["gui"] = "GuiService",
    ["startergui"] = "StarterGui",
    ["teams"] = "Teams",
    ["sound"] = "SoundService",
    ["collection"] = "CollectionService",
    ["tween"] = "TweenService",
    ["stats"] = "Stats",
    ["debris"] = "Debris",
    ["pathfinding"] = "PathfindingService",
    ["insert"] = "InsertService",
    ["context"] = "ContextActionService",
    ["physics"] = "PhysicsService",
    ["proximity"] = "ProximityPromptService",
    ["group"] = "GroupService",
    ["localization"] = "LocalizationService",
    ["chat"] = "Chat",
    ["voice"] = "VoiceChatService",
    ["starterpack"] = "StarterPack",
    ["starterplayer"] = "StarterPlayer",
    ["material"] = "MaterialService",
    ["asset"] = "AssetService",
    ["scriptcontext"] = "ScriptContext",
    ["content"] = "ContentProvider"
}

local _clone = (typeof(cloneref) == "function" and cloneref) or function(x)
    return x
end

local services = {}

for alias, serviceName in next, _s do
    services[alias] = _clone(_g:GetService(serviceName))
end

do
    local lp = services["players"].LocalPlayer
    local char = lp and lp.Character

    services["player"] = lp
    services["char"] = char
    services["hum"] = char and char:FindFirstChildOfClass("Humanoid")
    services["hrp"] = char and char:FindFirstChild("HumanoidRootPart")
    services["cam"] = workspace.CurrentCamera
    services["mouse"] = lp and lp:GetMouse()
end

services["players"].LocalPlayer.CharacterAdded:Connect(function(char)
    services["char"] = char
    services["hum"] = char:FindFirstChildOfClass("Humanoid")
    services["hrp"] = char:FindFirstChild("HumanoidRootPart")
end)

return setmetatable(services, {
    __index = function(_, k)
        warn(("[services] unknown index -> %s"):format(tostring(k)))
    end
})

--[[

local services = loadstring(game:HttpGet(
    "https://website-iota-ivory-12.vercel.app/code/loader/u/vars.lua"
))()

print(services["workspace"])
print(services["hrp"])

]]
