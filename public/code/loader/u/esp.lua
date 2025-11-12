return function()
    local get = cloneref or function(x)
        return x
    end

    local players = get(game:GetService("Players"))
    local rs, ws = get(game:GetService("RunService")), get(game:GetService("Workspace"))

    local core = gethui() or get(game:GetService("CoreGui"))
    local cam, lp = ws.CurrentCamera, players.LocalPlayer

    local esp = setmetatable({
        active = false,
        maxdist = 2000,
        showbox = true,
        showname = true,
        showheld = true,
        showtracer = true,
        showquad = false,
        teamcolor = false,
        showhealth = false,
        showdistance = false,
        showchams = false,
        showhealthbar = false,
        performancemode = false,
        skeleton = false
    }, {})

    local objs = {
        boxes = {},
        names = {},
        tracers = {},
        quads = {},
        healths = {},
        distances = {},
        chams = {},
        healthbars = {},
        skeletons = {}
    }

    local frameCount, uInterval = 0, 2

    local function setVisible(o, val)
        if not o then
            return
        end
        pcall(function()
            o.Visible = val
        end)
    end

    local function setEnabled(o, val)
        if not o then
            return
        end
        pcall(function()
            o.Enabled = val
        end)
    end

    local function withinViewport(x, y)
        if not cam or not cam.ViewportSize then
            return false
        end
        return x >= 0 and x <= cam.ViewportSize.X and y >= 0 and y <= cam.ViewportSize.Y
    end

    local function getparts(p)
        local ch = p.Character
        if not ch then
            return
        end
        return ch, ch:FindFirstChild("HumanoidRootPart"), ch:FindFirstChild("Head"), ch:FindFirstChildOfClass("Humanoid")
    end

    local function getColor(h, m)
        local p = h / m
        if p > 0.7 then
            return Color3.fromRGB(0, 255, 0)
        elseif p > 0.3 then
            return Color3.fromRGB(255, 255, 0)
        else
            return Color3.fromRGB(255, 0, 0)
        end
    end

    local function new(p, type, props)
        local o
        if type == "Highlight" then
            o = Instance.new("Highlight")
        else
            o = Drawing.new(type)
        end

        if props then
            for k, v in pairs(props) do
                pcall(function()
                    o[k] = v
                end)
            end
        end

        if type == "Highlight" then
            o.Parent = core
        end

        return o
    end

    local function drawSkeleton(char, color)
        local parts =
        {
            { "Head", "UpperTorso" },
            { "UpperTorso", "LowerTorso" },
            { "UpperTorso", "LeftUpperArm" },
            { "LeftUpperArm", "LeftLowerArm" },
            { "LeftLowerArm", "LeftHand" },
            { "UpperTorso", "RightUpperArm" },
            { "RightUpperArm", "RightLowerArm" },
            { "RightLowerArm", "RightHand" },
            { "LowerTorso", "LeftUpperLeg" },
            { "LeftUpperLeg", "LeftLowerLeg" },
            { "LeftLowerLeg", "LeftFoot" },
            { "LowerTorso", "RightUpperLeg" },
            { "RightUpperLeg", "RightLowerLeg" },
            { "RightLowerLeg", "RightFoot" },
        }

        local bones = {}

        for _, pair in ipairs(parts) do
            local a = char:FindFirstChild(pair[1])
            local b = char:FindFirstChild(pair[2])
            if a and b then
                local line = Drawing.new("Line")
                line.Thickness = 1.5
                line.Color = color
                line.Visible = false
                table.insert(bones, { line, a, b })
            end
        end

        return bones
    end

    local function removeSkeleton(p)
        local set = objs.skeletons[p]
        if not set then
            return
        end

        for _, bone in ipairs(set) do
            local line = bone[1]
            if line and line.Remove then
                pcall(function()
                    line:Remove()
                end)
            end
        end

        objs.skeletons[p] = nil
    end

    local function track(p)
        objs.boxes[p] = new(p, "Square", { Thickness = 2, Filled = false, Transparency = 1, Visible = false })
        objs.names[p] = new(p, "Text", { Size = 16, Center = true, Outline = true, Font = 2, Visible = false })
        objs.tracers[p] = new(p, "Line", { Thickness = 1, Visible = false })
        objs.quads[p] = new(p, "Quad", { Thickness = 1, Visible = false })
        objs.healths[p] = new(p, "Text", { Size = 14, Center = true, Outline = true, Font = 2, Visible = false })
        objs.distances[p] = new(p, "Text", { Size = 14, Center = true, Outline = true, Font = 2, Visible = false })
        objs.chams[p] = new(p, "Highlight", { FillTransparency = .7, OutlineTransparency = 1, DepthMode = Enum.HighlightDepthMode.AlwaysOnTop, Enabled = false })
        objs.healthbars[p] = new(p, "Line", { Thickness = 3, Visible = false })
        objs.skeletons[p] = {}
    end

    local function cleanup(p)
        for name, t in pairs(objs) do
            if t[p] then
                if name == "removeSkeleton" then
                    removeSkeleton(p)
                else
                    local o = t[p]
                    if type(o) == "table" then

                        for _, v in pairs(o) do
                            pcall(function()
                                if v.Remove then
                                    v:Remove()
                                elseif v.Destroy then
                                    v:Destroy()
                                end
                            end)
                        end
                    else
                        pcall(function()
                            if o.Remove then
                                o:Remove()
                            elseif o.Destroy then
                                o:Destroy()
                            end
                        end)
                    end
                    t[p] = nil
                end
            end
        end
    end

    for _, p in ipairs(players:GetPlayers()) do
        if p ~= lp then
            track(p)
        end
    end

    players.PlayerAdded:Connect(function(p)
        if p ~= lp then
            track(p)
        end
    end)

    players.PlayerRemoving:Connect(function(p)
        cleanup(p)
    end)

    rs.RenderStepped:Connect(function()
        if not esp.active then
            return
        end

        frameCount = frameCount + 1
        if esp.performancemode and frameCount % uInterval ~= 0 then
            return
        end

        local camPos = cam.CFrame.Position

        for p, b in pairs(objs.boxes) do
            local ch, hrp, head, hum = getparts(p)
            if not (ch and hrp and head) then
                cleanup(p)
                continue
            end

            local hp, on1 = cam:WorldToViewportPoint(hrp.Position)
            local hd, on2 = cam:WorldToViewportPoint(head.Position)
            local dist = (camPos - hrp.Position).Magnitude

            local validOn1 = on1 and withinViewport(hp.X, hp.Y)
            local validOn2 = on2 and withinViewport(hd.X, hd.Y)

           
            if dist > esp.maxdist then
                setVisible(objs.boxes[p], false)
                setVisible(objs.names[p], false)
                setVisible(objs.tracers[p], false)
                setVisible(objs.quads[p], false)
                setVisible(objs.healths[p], false)
                setVisible(objs.distances[p], false)
                setEnabled(objs.chams[p], false)
                setVisible(objs.healthbars[p], false)
                removeSkeleton(p)
                continue
            end

            local col = Color3.new(1, 1, 1)
            if esp.teamcolor and p.Team then
                col = p.Team.TeamColor.Color
            end

            if hum and hum.Health <= 0 then
                col = Color3.fromRGB(128, 128, 128)
            end

            local function setText(o, text, pos, color)
                if not o then
                    return
                end
                pcall(function()
                    o.Text = text
                    o.Position = pos
                    o.Color = color
                    o.Visible = true
                end)
            end

            local h = math.abs(hp.Y - hd.Y)
            local w = h * 0.6

            local n = objs.names[p]
            local tr = objs.tracers[p]
            local q = objs.quads[p]
            local ht = objs.healths[p]
            local d = objs.distances[p]
            local chm = objs.chams[p]
            local hb = objs.healthbars[p]

            -- Box
            if esp.showbox and validOn1 and validOn2 then
                pcall(function()
                    b.Size = Vector2.new(w, h)
                    b.Position = Vector2.new(hp.X - w / 2, hd.Y)
                    b.Color = col
                    b.Visible = true
                end)
            else
                setVisible(b, false)
            end

            -- Name + distance
            if validOn2 then
                local toolName = ""
                if esp.showheld then
                    local tool = ch:FindFirstChildOfClass("Tool")
                    if tool then
                        toolName = " [" .. tool.Name .. "]"
                    end
                end

                local name = esp.showname and (p.Name .. toolName) or ""
                local distText = esp.showdistance and (math.floor(dist) .. " studs") or ""
                local text = (#name > 0 and #distText > 0) and (name .. " | " .. distText) or name .. distText

                if text ~= "" then
                    setText(n, text, Vector2.new(hd.X, hd.Y - 15), col)
                else
                    setVisible(n, false)
                end
            else
                setVisible(n, false)
            end

            -- Tracer
            if esp.showtracer and validOn1 then
                pcall(function()
                    local origin = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y)
                    tr.From = origin
                    tr.To = Vector2.new(hp.X, hp.Y)
                    tr.Color = col
                    tr.Visible = true
                end)
            else
                setVisible(tr, false)
            end

            -- Quad
            if esp.showquad and validOn1 and validOn2 then
                pcall(function()
                    q.PointA = Vector2.new(hp.X - w / 2, hd.Y)
                    q.PointB = Vector2.new(hp.X + w / 2, hd.Y)
                    q.PointC = Vector2.new(hp.X + w / 2, hp.Y)
                    q.PointD = Vector2.new(hp.X - w / 2, hp.Y)
                    q.Color = col
                    q.Visible = true
                end)
            else
                setVisible(q, false)
            end

            -- Health + bar
            if hum then
                if esp.showhealth and validOn2 then
                    setText(ht, ("%d/%d"):format(hum.Health, hum.MaxHealth), Vector2.new(hd.X, hd.Y + 5), getColor(hum.Health, hum.MaxHealth))
                else
                    setVisible(ht, false)
                end

                if esp.showhealthbar and validOn1 and validOn2 then
                    pcall(function()
                        local perc = hum.Health / hum.MaxHealth
                        local barH = h * perc
                        hb.From = Vector2.new(hp.X - w / 2 - 6, hd.Y + h - barH)
                        hb.To = Vector2.new(hp.X - w / 2 - 6, hd.Y + h)
                        hb.Color = getColor(hum.Health, hum.MaxHealth)
                        hb.Visible = true
                    end)
                else
                    setVisible(hb, false)
                end
            end

            -- chams
            if esp.showchams then
                pcall(function()
                    chm.Adornee = ch
                    chm.FillColor = col
                    chm.Enabled = true
                end)
            else
                setEnabled(chm, false)
            end

            -- skeleton (eh)
            if esp.skeleton then
                if not objs.skeletons[p] or #objs.skeletons[p] == 0 then
                    objs.skeletons[p] = drawSkeleton(ch, col)
                end

                for _, bone in ipairs(objs.skeletons[p]) do
                    local line, a, bPart = bone[1], bone[2], bone[3]
                    if a and bPart and a:IsDescendantOf(ws) and bPart:IsDescendantOf(ws) then
                        local pa, onA = cam:WorldToViewportPoint(a.Position)
                        local pb, onB = cam:WorldToViewportPoint(bPart.Position)

                        if onA and onB then
                            line.From = Vector2.new(pa.X, pa.Y)
                            line.To = Vector2.new(pb.X, pb.Y)
                            line.Color = col
                            line.Visible = true
                        else
                            line.Visible = false
                        end
                    else
                        line.Visible = false
                    end
                end
            elseif objs.skeletons[p] and #objs.skeletons[p] > 0 then
            
                for _, bone in ipairs(objs.skeletons[p]) do
                    if bone[1] and bone[1].Remove then
                        bone[1]:Remove()
                    end
                end
                objs.skeletons[p] = {}
            end

            players.PlayerAdded:Connect(function(p)
                if p ~= lp then
                    track(p)
                    if esp.skeleton then
                        objs.skeletons[p] = drawSkeleton(p.Character, esp.teamcolor and (p.Team and p.Team.TeamColor.Color or Color3.new(1,1,1)) or Color3.new(1,1,1))
                    end
                end
            end)

            players.PlayerRemoving:Connect(function(p)
                cleanup(p)
            end)

        end
    end)

    function esp:enable()
        self.active = true
    end

    function esp:disable()
        self.active = false

        for name, t in pairs(objs) do
            for key, o in pairs(t) do
                if name == "skeletons" then
                    removeSkeleton(key)
                else
                    setVisible(o, false)
                    setEnabled(o, false)
                end
            end
        end
    end

    function esp:clear()
        for name, t in pairs(objs) do
            for key, o in pairs(t) do
                if name == "skeletons" then
                    removeSkeleton(key)
                else
                    pcall(function()
                        if type(o) == "table" then
                            for _, v in pairs(o) do
                                if v.Remove then v:Remove() end
                                if v.Destroy then v:Destroy() end
                            end
                        else
                            if o.Remove then o:Remove() end
                            if o.Destroy then o:Destroy() end
                        end
                    end)
                end
            end
            objs[name] = {}
        end

        self.active = false
    end

    for _, flag in ipairs({
        "box", "name", "held", "tracer", "quad",
        "health", "distance", "chams", "healthbar", "performance", "skeleton"
    }) do
        esp[flag] = function(self, v)
            self["show" .. flag] = v
        end
    end

    function esp:dist(v)
        self.maxdist = v
    end

    function esp:team(v)
        self.teamcolor = v
    end

    return esp
end
