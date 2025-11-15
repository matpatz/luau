local v = loadstring(game:HttpGet("https://website-iota-ivory-12.vercel.app/code/loader/u/vars.lua"))()
local lp, cam = v.players.LocalPlayer, v.workspace.CurrentCamera

local function isVisible(part) return part and part:IsDescendantOf(workspace) end

function gclosest(dist, teamcheck)
    local cPlayer, cDist, diff = nil, dist, nil
    local mpos = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/2) -- using screen center

    for _, plr in ipairs(v.players:GetPlayers()) do
        if plr ~= lp then
            local char = plr.Character
            if char then
                local rootPart = char:FindFirstChild("HumanoidRootPart")
                if rootPart and isVisible(rootPart) then
                    local screenPos, onScreen = cam:WorldToViewportPoint(rootPart.Position)
                    if onScreen then
                        diff = Vector2.new(screenPos.X, screenPos.Y) - mpos
                        local dist = diff.X * diff.X + diff.Y * diff.Y
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
