local gui = Instance.new("ScreenGui")
gui.Name = "e" .. math.random(1e8, 1e9)
gui.Parent = game:GetService("CoreGui")["RobloxGui"]

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 520, 0, 320)
frame.Position = UDim2.new(0.5, 0, 0.5, 0)
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
frame.Active = true
frame.Draggable = true
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8); Instance.new("UIScale", frame)

local title = Instance.new("TextLabel")
title.Text = "Functions"
title.Size = UDim2.new(1, -40, 0, 30)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(125, 217, 217)
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = frame

local close = Instance.new("TextButton", frame)
close.Text = "X"
close.Size = UDim2.new(0, 30, 0, 30)
close.Position = UDim2.new(1, -30, 0, 0)
close.BackgroundTransparency = 1
close.TextColor3 = Color3.fromRGB(255, 60, 60)
close.MouseButton1Click:Connect(function() gui:Destroy() end)

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(0.94, 0, 0.70, 0)
scroll.Position = UDim2.new(0.03, 0, 0.12, 0)
scroll.CanvasSize = UDim2.new(0, 0, 3, 0)
scroll.ScrollBarThickness = 6
scroll.BorderSizePixel = 0
scroll.BackgroundColor3 = Color3.fromRGB(35,35,35)
scroll.Parent = frame
Instance.new("UICorner", scroll).CornerRadius = UDim.new(0, 6)

local textbox = Instance.new("TextBox")
textbox.Size = UDim2.new(1, -10, 3, 0)
textbox.Position = UDim2.new(0, 5, 0, 0)
textbox.MultiLine = true
textbox.ClearTextOnFocus = false
textbox.TextWrapped = false
textbox.TextYAlignment = Enum.TextYAlignment.Top
textbox.TextXAlignment = Enum.TextXAlignment.Left
textbox.Font = Enum.Font.Code
textbox.TextSize = 14
textbox.TextColor3 = Color3.new(1,1,1)
textbox.BackgroundTransparency = 1
textbox.Text = "-- function name"
textbox.Parent = scroll

local search = Instance.new("TextButton")
search.Size = UDim2.new(0, 120, 0, 30)
search.Position = UDim2.new(0.03, 0, 0.85, 0)
search.Text = "Send"
search.TextSize = 12
search.TextColor3 = Color3.new(1,1,1)
search.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
search.Parent = frame
Instance.new("UICorner", search).CornerRadius = UDim.new(0, 5)

local find = getgenv().search or function(x) return x end
search.MouseButton1Click:Connect(function()
    textbox.Text = find(textbox.Text)
end)

task.wait(0.2)
for _, item in pairs(gui:GetDescendants()) do
    if not item:IsA("Frame") and not item:IsA("ScrollingFrame") and not item:IsA("UICorner") and not item:IsA("UIScale") and item.Font == Enum.Font.Legacy then
        item.Font = Enum.Font.GothamBold
    end
end
