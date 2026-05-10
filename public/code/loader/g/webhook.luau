local _game = game.PlaceId
local name = game:GetService("MarketplaceService"):GetProductInfo(_game).Name or "Unknown"

local lp = game:GetService("Players").LocalPlayer

local payload = {
    username = lp.Name,
    userid = lp.UserId,
    executor = identifyexecutor(),
    gname = name,
    placeid = _game
}

request({
    Url = "https://website-iota-ivory-12.vercel.app/api/webhook.js",
    Method = "POST",
    Headers = {["Content-Type"] = "application/json"},
    Body = game:GetService("HttpService"):JSONEncode(payload)
})

