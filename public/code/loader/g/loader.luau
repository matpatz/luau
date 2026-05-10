local _game = game.PlaceId
local lp = game:GetService("Players").LocalPlayer

local games = {
    [662417684] = "luckyblock",
    [129827112113663] = "prospecting",
    [11966456877] = "answerordie",
    [88817068170433] = "flagod",
	[101759436219635] = "idleBlocks"
	-- 106931261124996 ?? idk
}

local pid = games[game.PlaceId]
if pid then
    -- load the script
    loadstring(game:HttpGet("https://website-iota-ivory-12.vercel.app/code/games/" .. pid.name .. "/main.lua"))()
    -- load webhook
    loadstring(game:HttpGet("https://website-iota-ivory-12.vercel.app/code/loader/g/webhook.luau"))()
else
    local names = {}
    for _, info in pairs(games) do
        table.insert(names, info.name)
    end
    warn("Please join one of our supported games: " .. table.concat(names, ", "))
end
