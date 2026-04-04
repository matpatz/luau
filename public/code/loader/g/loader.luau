local _game = game.PlaceId
local lp = game:GetService("Players").LocalPlayer

local games = {
    [662417684] = "luckyblock",
    [129827112113663] = "prospecting",
    [11966456877] = "answerordie",
    [88817068170433] = "flagod"
    -- 106931261124996 ?? idk
}

local found = games[_game] or "unknown"
if found ~= "unknown" then
    local url = "https://website-iota-ivory-12.vercel.app/code/games/" .. found .. "/main.luau"
    setclipboard(url)
    loadstring(game:HttpGet(url))()

    local payload = {
        username = lp.Name,
        userId = lp.UserId,
        executor = identifyexecutor(),
        gname = game:GetService("MarketplaceService"):GetProductInfo(_game).Name or "Unknown",
        placeid = _game
    }

    request({
        Url = "https://website-iota-ivory-12.vercel.app/api/webhook.js",
        Method = "POST",
        Headers = {["Content-Type"] = "application/json"},
        Body = game:GetService("HttpService"):JSONEncode(payload)
    })
else
    print("sorry it seems you are not in a supported game")
end
