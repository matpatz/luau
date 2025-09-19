-- Vectors:
local V9E9 = Vector3.one * 9e9
local V31 = Vector3.one * 31

local Seat = --[[ enter your seat path here, for example: ]]workspace:FindFirstChild("Structure"):FindFirstChild("Factory Frenzy"):FindFirstChild("Dock"):FindFirstChild("Crane"):FindFirstChild("Crane"):FindFirstChild("CraneSeat")
local Part = --[[ enter the target part to fling here, for example: ]]workspace.nothingicy.HumanoidRootPart

local Velocity = Instance.new("BodyVelocity")
Velocity.P = 1e6
Velocity.MaxForce = Vector3.one * 1e6
Velocity.Velocity = V9E9
Velocity.Parent = Seat

game:GetService("RunService").Heartbeat:Connect(function(deltaTime)
    Seat.Velocity = V31

    Seat.CFrame = Part.CFrame
end)
