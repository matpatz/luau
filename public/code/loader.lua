local hps = "https://website-iota-ivory-12.vercel.app/code/"
local type = "games/" -- or scripts/

local function exec(ext) loadstring(game:HttpGet(hps .. type .. ext .. "/main.lua"))() end

local games = {
    [1087852616] = "catastrophia",
    [105938112304055] = "luckyblock",
    [13253735473] = "trident",
    [129827112113663] = "prospecting"
}

local ext = games[game.PlaceId]
if ext then
    exec(ext)
else
    local names = {}
    for _, v in pairs(games) do
        table.insert(names, v)
    end
    print("Please join one of our supported games: " .. table.concat(names, ", "))
end
