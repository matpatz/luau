local v = loadstring(game:HttpGet("https://website-iota-ivory-12.vercel.app/code/loader/u/vars.lua"))()
local players. cam = v.players, workspace.CurrentCamera; local lp = players["LocalPlayer"]

local module = {}

function module.gclosest(maxDist, teamcheck)
    local cPlayer
    local cDist = maxDist * maxDist

    local centerX = cam.ViewportSize.X * 0.5
    local centerY = cam.ViewportSize.Y * 0.5

    local lp = players.LocalPlayer

    for _, plr in ipairs(players:GetPlayers()) do
        if plr ~= lp then
            local char = plr.Character
            if char then
                local root = char:FindFirstChild("HumanoidRootPart")
                if root then
                    local screenPos, onScreen = cam:WorldToViewportPoint(root.Position)
                    if onScreen then
                        local dx = screenPos.X - centerX
                        local dy = screenPos.Y - centerY
                        local dist = dx*dx + dy*dy

                        if dist < cDist then
                            cPlayer = plr
                            cDist = dist
                        end
                    end
                end
            end
        end
    end

    return cPlayer
end

return module
