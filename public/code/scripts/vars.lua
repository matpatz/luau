local cloneref = cloneref or function(x) return x end
local services = {"Players","Workspace","ReplicatedStorage","Lighting","TweenService","RunService","UserInputService","ContextActionService","StarterGui","GuiService","TeleportService","HttpService","MarketplaceService","InsertService","CoreGui","StarterPack","StarterPlayer","SoundService","PolicyService","Debris","Chat","CollectionService","PathfindingService","ProximityPromptService","VirtualUser","VirtualInputManager","AdService","LocalizationService","Stats","Teams","TextService","PhysicsService","BadgeService","PointsService","DataStoreService","GroupService","MessagingService","AssetService","ScriptContext","AnalyticsService","LogService","VoiceChatService","TextChatService"}

local list = {}
for i = 1, #services do
    local ok, s = pcall(game.GetService, game, services[i])
    if ok and s then
        list[services[i]] = cloneref(s)
    end
end

return list

--[[ usage :
    local list = loadstring(game:HttpGet("https://website-iota-ivory-12.vercel.app//code/scripts/vars.lua"))()
    print(list.Playyers)
]]
