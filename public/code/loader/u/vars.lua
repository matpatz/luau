local v, s, get = {}, {players = "Players", workspace = "Workspace", rs = "RunService", core = "CoreGui", input = "UserInputService", rep = "ReplicatedStorage", lighting = "Lighting", vim = "VirtualInputManager", vcr = "TextChatService"},  (type(cloneref) == "function") and cloneref or function(x) return x end
for short, name in pairs(s) do
    v[short] = get(game:GetService(name))
end

return v

--[[
    local v = loadstring(game:HttpGet("https://website-iota-ivory-12.vercel.app/code/loader/u/vars.lua"))()
    print(v.workspace)
--]]
