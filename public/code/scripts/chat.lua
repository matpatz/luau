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

local function aLog(...)
	local msg = table.concat({...}, " ")
	if console then
		console:AppendText(msg .. "\n")
	end
end

local function Log(...)
	local ok, err = pcall(aLog, ...)
	if not ok then warn("error:", err) end
end

local players = game:GetService("Players")

local function get(player)
	player.Chatted:Connect(function(msg)
		Log(string.format("[%s]: %s", player.DisplayName or player.Name, msg))
	end)
end

for _, player in ipairs(players:GetPlayers()) do get(player) end

players.PlayerAdded:Connect(get)

Log("Functional\n")
