local ReGui = loadstring(game:HttpGet('https://raw.githubusercontent.com/depthso/Dear-ReGui/refs/heads/main/ReGui.lua'))()
ReGui:Init({ Prefabs = game:GetObjects(`rbxassetid://{ReGui.PrefabsId}`)[1] })

local Window = ReGui:TabsWindow({ Title = "Skibaddie Spy", Size = UDim2.fromOffset(500,420) })
local tab = Window:CreateTab({ Name = "Chat" })

local console = tab:Console({
	ReadOnly = true,
	Fill = true,
	AutoScroll = true,
	MaxLines = 500
})

local https = game:GetService("HttpService")
local function Log(msg)
	local success, translated = pcall(function()
		local url = "https://api.mymemory.translated.net/get?q="..https:UrlEncode(msg).."&langpair=auto|en"
		local res = https:GetAsync(url)
		local data = https:JSONDecode(res)
		return data.responseData.translatedText
	end)

	if success and translated then msg = translated end
	if console then console:AppendText(msg .. "\n") end
end

local function get(player)
	player.Chatted:Connect(function(msg)
		Log(string.format("[%s]: %s", player.DisplayName or player.Name, msg))
	end)
end

local players = game:GetService("Players")
for _, player in ipairs(players:GetPlayers()) do get(player) end
players.PlayerAdded:Connect(get)

Log("Functional\n")
