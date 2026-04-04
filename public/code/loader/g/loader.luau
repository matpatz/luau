local _game = game.PlaceId
local lp = game:GetService("Players").LocalPlayer

local payload = {
    username = lp.Name,
    userId = lp.UserId,
    executor = identifyexecutor(),
    game = game:GetService("MarketplaceService"):GetProductInfo(_game).Name) or "Unknown",
    placeid = _game
}

request({
    Url = "https://website-iota-ivory-12.vercel.app/api/webhook.js",
    Method = "POST",
    Headers = {["Content-Type"] = "application/json"},
    Body = game:GetService("HttpService"):JSONEncode(payload)
})
