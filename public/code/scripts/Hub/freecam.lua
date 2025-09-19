local Camera = workspace.CurrentCamera

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = tostring(math.random(1e9, 2e9) + math.random())
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game:GetService("CoreGui")

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 180, 0, 50)
Frame.Position = UDim2.new(0.02, 0, 0.02, 0)
Frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
Frame.BorderSizePixel = 0
Frame.Parent = ScreenGui
Frame.AnchorPoint = Vector2.new(0,0)
Frame.ClipsDescendants = true

local Button = Instance.new("TextButton")
Button.Size = UDim2.new(1, -10, 1, -10)
Button.Position = UDim2.new(0, 5, 0, 5)
Button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
Button.TextColor3 = Color3.fromRGB(255, 255, 255)
Button.Font = Enum.Font.SourceSans
Button.TextSize = 18
Button.Text = "Disabled"
Button.Parent = Frame
Button.AutoButtonColor = true

local dragging, dragInput, dragStart, startPos
Frame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = Frame.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then dragging = false end
		end)
	end
end)

Frame.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

local UserInput = game:GetService("UserInputService")

UserInput.InputChanged:Connect(function(input)
	if dragging and input == dragInput then
		local delta = input.Position - dragStart
		Frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

local freecam = false
local camCF = Camera.CFrame
local texts = {on="Enabled", off="Disabled"}

Button.MouseButton1Click:Connect(function()
	freecam = not freecam
	if freecam then camCF = Camera.CFrame end
	Button.Text = freecam and texts.on or texts.off
end)

local inputTable = {W=false,A=false,S=false,D=false,Up=false,Down=false}
UserInput.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Keyboard then
		if inputTable[input.KeyCode.Name] ~= nil then inputTable[input.KeyCode.Name] = true end
		if input.KeyCode == Enum.KeyCode.Space then inputTable.Up=true end
		if input.KeyCode == Enum.KeyCode.LeftControl then inputTable.Down=true end
	end
end)

UserInput.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Keyboard then
		if inputTable[input.KeyCode.Name] ~= nil then inputTable[input.KeyCode.Name] = false end
		if input.KeyCode == Enum.KeyCode.Space then inputTable.Up=false end
		if input.KeyCode == Enum.KeyCode.LeftControl then inputTable.Down=false end
	end
end)

local yaw, pitch = 0, 0

local cf = Camera.CFrame
yaw = math.atan2(cf.LookVector.X, cf.LookVector.Z)
pitch = math.asin(cf.LookVector.Y)

local lastPos
UserInput.InputChanged:Connect(function(input)
    if freecam and input.UserInputType == Enum.UserInputType.Touch then
        if lastPos then
            local delta = input.Position - lastPos
            yaw = yaw - math.rad(delta.X * 0.2)
            pitch = math.clamp(pitch - math.rad(delta.Y * 0.2), -math.rad(89), math.rad(89))
            
            local rotCF = CFrame.new(camCF.Position) * CFrame.Angles(pitch, yaw, 0)
            camCF = CFrame.new(camCF.Position, camCF.Position + rotCF.LookVector)
        end
        lastPos = input.Position
    elseif input.UserInputType == Enum.UserInputType.Touch and input.UserInputState == Enum.UserInputState.End then
        lastPos = nil
    end
end)

local camSpeed = 0.5

game:GetService("RunService").RenderStepped:Connect(function()
    if freecam then
        local dir = Vector3.new(
            (inputTable.D and 1 or 0) - (inputTable.A and 1 or 0),
            (inputTable.Up and 1 or 0) - (inputTable.Down and 1 or 0),
            (inputTable.S and 1 or 0) - (inputTable.W and 1 or 0)
        )
        camCF = camCF + camCF:VectorToWorldSpace(dir) * camSpeed
        Camera.CFrame = camCF
    end
end)
