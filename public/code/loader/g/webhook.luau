local services = loadstring(game:HttpGet("https://website-iota-ivory-12.vercel.app/code/loader/u/vars.lua"))()

local place = game.PlaceId
local gname = services["marketplace"]:GetProductInfo(place).Name

local payload = {
    username = services["player"].Name,
    userid = services["player"].UserId,

    executor = identifyexecutor() or "Unknown",

    gname = gname or "Unknown",
    placeid = place
}

request({
    Url = "https://website-iota-ivory-12.vercel.app/api/webhook.js",

    Method = "POST",

    Headers = {
        ["Content-Type"] = "application/json"
    },

    Body = services["http"]:JSONEncode(payload)
})
