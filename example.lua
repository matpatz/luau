local api = loadstring(game:HttpGet("https://website-api-bay.vercel.app/version.js"))()
local data = api[tostring(game.PlaceId)]

if data then
    print("Version:", data.version)
    print("Game last update:", data.updated)
else
    warn("Invalid game.. you need to join one of our supported games")
end
