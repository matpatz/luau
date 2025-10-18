getgenv().text = getgenv().text or "EnterText"
getgenv().keybind = getgenv().keybind or Enum.KeyCode.RightShift
getgenv().radius = getgenv().radius or 1.2 -- center of screen / radius (makes drawings tigher)

local center = workspace.CurrentCamera.ViewportSize / 2
local rsize = center / getgenv().radius

local drawings = {}
for i = 1, math.random(25, 35) do
    local drawing = Drawing.new("Text")
    drawing.Text = getgenv().text
    drawing.Size = math.random(80, 100)
    drawing.Center = true
    drawing.Outline = true
    drawing.OutlineColor = Color3.fromRGB(math.random(0, 255), math.random(0, 255), math.random(0, 255))
    drawing.Color = Color3.fromRGB(math.random(0, 255), math.random(0, 255), math.random(0, 255))
    drawing.Visible = true
    drawing.Position = Vector2.new(
        center.X + math.random(-rsize.X/2, rsize.X/2),
        center.Y + math.random(-rsize.Y/2, rsize.Y/2)
    )
    drawings[i] = {drawing = drawing, speed = Vector2.new(math.random(-3, 3), math.random(-3, 3))}
end

game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == getgenv().keybind then
        for i, v in pairs(drawings) do
            v.drawing.Visible = not v.drawing.Visible
        end
    end
end)

game:GetService("RunService").Heartbeat:Connect(function()
    for i, v in pairs(drawings) do
        v.drawing.Text = getgenv().text
        v.drawing.Position = v.drawing.Position + v.speed
        
        if v.drawing.Position.X < center.X - rsize.X/2 or v.drawing.Position.X > center.X + rsize.X/2 then
            v.speed = Vector2.new(-v.speed.X, v.speed.Y)
        end
        if v.drawing.Position.Y < center.Y - rsize.Y/2 or v.drawing.Position.Y > center.Y + rsize.Y/2 then
            v.speed = Vector2.new(v.speed.X, -v.speed.Y)
        end
    end
end)
