local _game = game.PlaceId
local lp = game:GetService("Players").LocalPlayer

local payload = {
    lp.Name,
    lp.UserId,
    identifyexecutor(),
    game:GetService("MarketplaceService"):GetProductInfo(_game).Name) or "Unknown",
    _game
}

request({
    Url = "https://website-iota-ivory-12.vercel.app/api/webhook.js",
    Method = "POST",
    Headers = {["Content-Type"] = "application/json"},
    Body = game:GetService("HttpService"):JSONEncode(payload)
})
