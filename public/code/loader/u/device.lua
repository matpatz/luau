local uis = game:GetService("UserInputService")

function device()
	return tostring(uis:GetPlatform()):split(".")[3]
end

getgenv().device = device()

--[[
	local device = getgenv().device or "Mobile"
	print(device)
--]]
