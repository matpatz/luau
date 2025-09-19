local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local function showUserInfo(targetPlayer)
	if targetPlayer == LocalPlayer then return end

	local function displayInfo(character)
		local head = character:WaitForChild("Head", 5)
		if not head then return end

		local existingGui = head:FindFirstChild("UserInfoDisplay")
		if existingGui then existingGui:Destroy() end

		local infoGui = Instance.new("BillboardGui")
		infoGui.Name = "UserInfoDisplay"
		infoGui.Adornee = head
		infoGui.Size = UDim2.new(0, 200, 0, 20)
		infoGui.StudsOffset = Vector3.new(0, 2, 0)
		infoGui.AlwaysOnTop = true
		infoGui.Parent = head

		local text = Instance.new("TextLabel")
		text.Size = UDim2.new(1, 0, 1, 0)
		text.BackgroundTransparency = 1
		text.TextColor3 = Color3.fromRGB(255, 255, 255)
		text.TextStrokeTransparency = 0.3
		text.TextScaled = false
		text.Font = Enum.Font.SourceSansBold
		text.TextSize = 20
		text.Text = "[ " .. targetPlayer.Name .. " ] [ " .. targetPlayer.AccountAge .. "d ]"
		text.Parent = infoGui
	end

	if targetPlayer.Character then
		displayInfo(targetPlayer.Character)
	end

	targetPlayer.CharacterAdded:Connect(displayInfo)
end

for _, player in ipairs(Players:GetPlayers()) do
	showUserInfo(player)
end

Players.PlayerAdded:Connect(showUserInfo)
