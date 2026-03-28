local v, s, get = {}, {players = "Players", workspace = "Workspace", rs = "RunService", core = "CoreGui", input = "UserInputService", rep = "ReplicatedStorage", lighting = "Lighting", vim = "VirtualInputManager", tcs = "TextChatService", analytics = "RbxAnalyticsService", marketplace = "MarketplaceService"},  (type(cloneref) == "function") and cloneref or function(x) return x end

for short, name in pairs(s) do
    local svc = get(game:GetService(name))
    v[short] = svc

    if short == "players" then
        local lp = svc.LocalPlayer
        local char = lp and lp.Character
        v.player, v.char, v.hrp, v.cam = lp, char, char and char:FindFirstChild("HumanoidRootPart"), workspace.CurrentCamera
    end
end

return v

--[[
    local v = loadstring(game:HttpGet("https://website-iota-ivory-12.vercel.app/code/loader/u/vars.lua"))()
    print(v.workspace)
--]]
