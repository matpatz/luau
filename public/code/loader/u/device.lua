local uis = game:GetService("UserInputService")
local pf = (uis.GetPlatform and uis:GetPlatform()) or nil

function device()
    local touch = uis.TouchEnabled
    local pad = uis.GamepadEnabled
    local kb = uis.KeyboardEnabled
    local mouse = uis.MouseEnabled

    local name = (pf and pf.Name) or ""

    if pad and (name:match("Xbox") or name:match("XBox")) then
        return {type="Console", conf=0.99, detail=name}
    end

    if touch and not kb and not mouse then
        return {type="Mobile", conf=0.98, detail=name}
    end

    if kb and mouse then
        return {type="PC", conf=0.98, detail=name}
    end

    if name:match("Android") or name:match("IOS") or name:match("IPhone") then
        return {type="Mobile", conf=0.85, detail=name}
    end

    return {type="Unknown", conf=0.3, detail=name}
end

local info = device()
getgenv().device = info.type

--[[
	local device = getgenv().device or "Mobile"
	print(device)
--]]
