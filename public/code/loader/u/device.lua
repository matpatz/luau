local uis = game:GetService("UserInputService")

function device()
	return tostring(uis:GetPlatform()):split(".")[3]
end

local info = device()
getgenv().device = info.type

--[[
	local device = getgenv().device or "Mobile"
	print(device)
--]]
