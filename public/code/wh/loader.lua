local HttpService = game:GetService("HttpService")

local exec = identifyexecutor()
local user = game.Players.LocalPlayer.Name
local gme = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name

local payload = HttpService:JSONEncode({
    content = string.format(
        "Username : %s - Executor : %s - Game : %s",
        user, exec, gme
    )
})

local req = request or (http and http.request) or (syn and syn.request)
if not req then return warn("this is a pretty basic function") end

pcall(function()
    req({
        Url = _G.wh,
        Method = "POST",
        Headers = {["Content-Type"] = "application/json"},
        Body = payload
    })
end)
