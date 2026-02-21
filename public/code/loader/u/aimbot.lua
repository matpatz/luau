local v = loadstring(game:HttpGet("https://website-iota-ivory-12.vercel.app/code/loader/u/vars.lua"))()
local lp, cam = v.players.LocalPlayer, v.workspace.CurrentCamera

local module = {}

local function isVisible(part) return part and part:IsDescendantOf(workspace) end

function module.gclosest(maxDist, teamcheck)
    local cPlayer, cDist = nil, maxDist*maxDist
    local centerX, centerY = cam.ViewportSize.X*0.5, cam.ViewportSize.Y*0.5
    local lp = players.LocalPlayer

    for _, plr in ipairs(players:GetPlayers()) do
        if plr ~= lp then
            local char = plr.Character
            if char then
                local root = char:FindFirstChild("HumanoidRootPart")
                if root and root:IsDescendantOf(workspace) then
                    local screenPos, onScreen = cam:WorldToViewportPoint(root.Position)
                    if onScreen then
                        local dx, dy = screenPos.X - centerX, screenPos.Y - centerY
                        local dist = dx*dx + dy*dy
                        if dist < cDist then
                            cPlayer, cDist = plr, dist
                        end
                    end
                end
            end
        end
    end

    return cPlayer
end

return module
