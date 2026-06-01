local _game = game.PlaceId
local lp = game:GetService("Players").LocalPlayer

local games = {
    [662417684] = {name = "luckyblock"},
    [129827112113663] = {name = "prospecting"},
    [11966456877] = {name = "answerordie"},
    [88817068170433] = {name = "flagod"},
	[101759436219635] = {name = "idleBlocks"},
	[3082002798] = {name = "teentitan"}
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

-- loadstring(game:HttpGet("https://website-iota-ivory-12.vercel.app/code/loader/g/loader.luau"))()
