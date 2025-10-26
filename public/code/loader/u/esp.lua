return function()
    local get = (type(cloneref) == "function") and cloneref or function(x) return x end
    local players = get(game:GetService("Players"))
    local rs = get(game:GetService("RunService"))
    local ws = get(game:GetService("Workspace"))
    local cam = ws.CurrentCamera
    local lp = players.LocalPlayer

    local esp = {}
    esp.active = false
    esp.maxdist = 2000
    esp.showbox = true
    esp.showname = true
    esp.showheld = true
    esp.showtracer = true
    esp.showquad = false
    esp.teamcolor = false
    esp.showhealth = false
    esp.showdistance = false
    esp.showchams = false
    esp.showhealthbar = false
    esp.performancemode = false

    local boxes, names, tracers, quads, healths, distances, chams, healthbars = {}, {}, {}, {}, {}, {}, {}, {}
    local frameCount, uInterval = 0, 2

    local function getparts(p)
        local ch = p.Character
        if not ch then return end
        local hrp = ch:FindFirstChild("HumanoidRootPart")
        local head = ch:FindFirstChild("Head") or ch:FindFirstChild("UpperTorso") or ch:FindFirstChild("Torso")
        local humanoid = ch:FindFirstChildOfClass("Humanoid")
        
        if not hrp or not head then return end
        return ch, hrp, head, humanoid
    end

    local function getColor(health, maxhealth)
        local percentage = health / maxhealth
        if percentage > 0.7 then
            return Color3.fromRGB(0, 255, 0)
        elseif percentage > 0.3 then
            return Color3.fromRGB(255, 255, 0)
        else
            return Color3.fromRGB(255, 0, 0)
        end
    end

    local function newbox(p)
        local b = Drawing.new("Square")
        b.Thickness, b.Filled, b.Transparency = 2, false, 1
        b.Color, b.Visible = Color3.fromRGB(255,255,255), false
        boxes[p] = b
    end

    local function newname(p)
        local t = Drawing.new("Text")
        t.Size, t.Center, t.Outline, t.Font = 16, true, true, 2
        t.Color, t.Visible = Color3.fromRGB(255,255,255), false
        names[p] = t
    end

    local function newtracer(p)
        local t = Drawing.new("Line")
        t.Thickness, t.Color, t.Visible = 1, Color3.fromRGB(255,255,255), false
        tracers[p] = t
    end

    local function newquad(p)
        local q = Drawing.new("Quad")
        q.Color, q.Visible, q.Thickness = Color3.fromRGB(255,255,255), false, 1
        quads[p] = q
    end

    local function newhealth(p)
        local t = Drawing.new("Text")
        t.Size, t.Center, t.Outline, t.Font = 14, true, true, 2
        t.Color, t.Visible = Color3.fromRGB(0,255,0), false
        healths[p] = t
    end

    local function newdistance(p)
        local t = Drawing.new("Text")
        t.Size, t.Center, t.Outline, t.Font = 14, true, true, 2
        t.Color, t.Visible = Color3.fromRGB(255,255,255), false
        distances[p] = t
    end

    local function newchams(p) --cf
        local highlight = Instance.new("Highlight")
        highlight.FillTransparency = 0.7
        highlight.OutlineTransparency = 1
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Enabled = false
        highlight.Parent = ws
        chams[p] = highlight
    end

    local function newhealthbar(p)
        local bar = Drawing.new("Line")
        bar.Thickness, bar.Color, bar.Visible = 3, Color3.fromRGB(0,255,0), false
        healthbars[p] = bar
    end

    local function trackplayer(p)
        newbox(p)
        newname(p)
        newtracer(p)
        newquad(p)
        newhealth(p)
        newdistance(p)
        newchams(p)
        newhealthbar(p)
    end

    for _,p in pairs(players:GetPlayers()) do if p ~= lp then trackplayer(p) end end
    players.PlayerAdded:Connect(function(p) if p ~= lp then trackplayer(p) end end)
    players.PlayerRemoving:Connect(function(p)
        if boxes[p] then boxes[p]:Remove() boxes[p] = nil end
        if names[p] then names[p]:Remove() names[p] = nil end
        if tracers[p] then tracers[p]:Remove() tracers[p] = nil end
        if quads[p] then quads[p]:Remove() quads[p] = nil end
        if healths[p] then healths[p]:Remove() healths[p] = nil end
        if distances[p] then distances[p]:Remove() distances[p] = nil end
        if chams[p] then chams[p]:Destroy() chams[p] = nil end
        if healthbars[p] then healthbars[p]:Remove() healthbars[p] = nil end
    end)

    rs.RenderStepped:Connect(function()
        if not esp.active then return end
        
        frameCount = frameCount + 1
        if esp.performancemode and frameCount % uInterval ~= 0 then return end
        
        for p,b in pairs(boxes) do
            local t, hrp, head, humanoid = getparts(p)
            if t and hrp and head then
                local hrpPos, on1 = cam:WorldToViewportPoint(hrp.Position)
                local headPos, on2 = cam:WorldToViewportPoint(head.Position)
                local dist = (cam.CFrame.Position - hrp.Position).Magnitude
                
                if dist > esp.maxdist then 
                    b.Visible, names[p].Visible, tracers[p].Visible, quads[p].Visible = false, false, false, false 
                    if healths[p] then healths[p].Visible = false end
                    if distances[p] then distances[p].Visible = false end
                    if chams[p] then chams[p].Enabled = false end
                    if healthbars[p] then healthbars[p].Visible = false end
                    continue 
                end

                local col = (esp.teamcolor and p.Team ~= lp.Team) and Color3.fromRGB(255,0,0) or Color3.fromRGB(255,255,255)

                -- coloring
                if humanoid and humanoid.Health <= 0 then
                    col = Color3.fromRGB(128, 128, 128)
                end

                -- box
                if esp.showbox and on1 and on2 then
                    local h = math.abs(hrpPos.Y - headPos.Y)
                    local w = h * 0.6
                    b.Size = Vector2.new(w,h)
                    b.Position = Vector2.new(hrpPos.X - w/2, headPos.Y)
                    b.Color, b.Visible = col, true
                else b.Visible = false end

                -- name + distance
                if (esp.showname or esp.showdistance) and on2 then
                    local nameText = ""
                    local distanceText = ""
                    
                    if esp.showname then
                        nameText = p.Name
                        if esp.showheld then
                            local tool = t:FindFirstChildOfClass("Tool")
                            if tool then nameText = nameText .. " [" .. tool.Name .. "]" end
                        end
                    end
                    
                    if esp.showdistance then
                        distanceText = math.floor(dist) .. " studs"
                    end
                    
                    local combinedText = nameText
                    if nameText ~= "" and distanceText ~= "" then
                        combinedText = nameText .. " | " .. distanceText
                    elseif distanceText ~= "" then
                        combinedText = distanceText
                    end
                    
                    local n = names[p]
                    n.Position, n.Text, n.Color, n.Visible = Vector2.new(headPos.X, headPos.Y-15), combinedText, col, true
                elseif names[p] then names[p].Visible = false end

                -- tracer
                if esp.showtracer and on1 then
                    local tr = tracers[p]
                    tr.From, tr.To, tr.Color, tr.Visible = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y), Vector2.new(hrpPos.X, hrpPos.Y), col, true
                elseif tracers[p] then tracers[p].Visible = false end

                -- quad
                if esp.showquad and on1 and on2 then
                    local q = quads[p]
                    local h = math.abs(hrpPos.Y - headPos.Y)
                    local w = h * 0.6
                    q.PointA, q.PointB, q.PointC, q.PointD, q.Color, q.Visible = 
                        Vector2.new(hrpPos.X-w/2, headPos.Y),
                        Vector2.new(hrpPos.X+w/2, headPos.Y),
                        Vector2.new(hrpPos.X+w/2, hrpPos.Y),
                        Vector2.new(hrpPos.X-w/2, hrpPos.Y),
                        col, true
                elseif quads[p] then quads[p].Visible = false end

                -- health text
                if esp.showhealth and humanoid and on2 then
                    local health = healths[p]
                    local healthText = math.floor(humanoid.Health) .. "/" .. math.floor(humanoid.MaxHealth)
                    local healthCol = getColor(humanoid.Health, humanoid.MaxHealth)
                    health.Position, health.Text, health.Color, health.Visible = Vector2.new(headPos.X, headPos.Y+5), healthText, healthCol, true
                elseif healths[p] then healths[p].Visible = false end

                -- health bar
                if esp.showhealthbar and humanoid and on1 and on2 then
                    local bar = healthbars[p]
                    local h = math.abs(hrpPos.Y - headPos.Y)
                    local w = h * 0.6
                    local boxLeft = hrpPos.X - w/2
                    local boxTop = headPos.Y
                    
                    local healthPercentage = humanoid.Health / humanoid.MaxHealth
                    local barHeight = h * healthPercentage
                    local barColor = getColor(humanoid.Health, humanoid.MaxHealth)
                    
                    bar.From = Vector2.new(boxLeft - 6, boxTop + h - barHeight)
                    bar.To = Vector2.new(boxLeft - 6, boxTop + h)
                    bar.Color = barColor
                    bar.Visible = true
                elseif healthbars[p] then healthbars[p].Visible = false end

                -- chams
                if esp.showchams then
                    local cham = chams[p]
                    cham.Adornee = t
                    cham.Enabled = true
                    cham.FillColor = col
                elseif chams[p] then chams[p].Enabled = false end

            else
                b.Visible = false
                if names[p] then names[p].Visible = false end
                if tracers[p] then tracers[p].Visible = false end
                if quads[p] then quads[p].Visible = false end
                if healths[p] then healths[p].Visible = false end
                if distances[p] then distances[p].Visible = false end
                if chams[p] then chams[p].Enabled = false end
                if healthbars[p] then healthbars[p].Visible = false end
            end
        end
    end)

    function esp:enable() self.active = true end
    
    function esp:disable() 
        self.active = false 
        for p, b in pairs(boxes) do
            if b then b.Visible = false end
            if names[p] then names[p].Visible = false end
            if tracers[p] then tracers[p].Visible = false end
            if quads[p] then quads[p].Visible = false end
            if healths[p] then healths[p].Visible = false end
            if distances[p] then distances[p].Visible = false end
            if chams[p] then chams[p].Enabled = false end
            if healthbars[p] then healthbars[p].Visible = false end
        end
    end

    function esp:box(v) self.showbox = v end -- square
    function esp:name(v) self.showname = v end -- text
    function esp:held(v) self.showheld = v end -- text (name)
    function esp:tracer(v) self.showtracer = v end -- line
    function esp:quad(v) self.showquad = v end -- quad (idk why you would need this)
    function esp:dist(d) self.maxdist = d end -- text
    function esp:team(v) self.teamcolor = v end -- color
    function esp:health(v) self.showhealth = v end -- text
    function esp:distance(v) self.showdistance = v end -- text
    function esp:chams(v) self.showchams = v end -- highlight
    function esp:healthbar(v) self.showhealthbar = v end -- line
    function esp:performance(v) self.performancemode = v end
    
    function esp:clear()
        for _,b in pairs(boxes) do b:Remove() end
        for _,t in pairs(names) do t:Remove() end
        for _,t in pairs(tracers) do t:Remove() end
        for _,q in pairs(quads) do q:Remove() end
        for _,h in pairs(healths) do h:Remove() end
        for _,d in pairs(distances) do d:Remove() end
        for _,c in pairs(chams) do c:Destroy() end
        for _,b in pairs(healthbars) do b:Remove() end
        boxes, names, tracers, quads, healths, distances, chams, healthbars = {}, {}, {}, {}, {}, {}, {}, {}
        self.active = false
    end

    return esp
end
