return function()
    local get = cloneref or function(x) return x end

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

    local function getparts(p)
        local ch = p.Character
        if not ch then
            return
        end
        return ch, ch:FindFirstChild("HumanoidRootPart"), ch:FindFirstChild("Head"), ch:FindFirstChildOfClass("Humanoid")
    end

    local function getColor(h, m)
        local p = h / m
        return (p > .7 and Color3.fromRGB(0, 255, 0)) or (p > .3 and Color3.fromRGB(255, 255, 0)) or Color3.fromRGB(255, 0, 0)
    end

    local function new(p, type, props)
        local o = (type == "Highlight") and Instance.new("Highlight") or Drawing.new(type)
        for k, v in pairs(props) do
            o[k] = v
        end
        if type == "Highlight" then
            o.Parent = core
        end
        return o
    end

    local function drawSkeleton(char, color)
        local parts = {
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
        for _, t in pairs(objs) do
            if t[p] then
                if type(t[p]) == "table" then
                    for _, o in pairs(t[p]) do
                        if o[1] and o[1].Remove then
                            o[1]:Remove()
                        end
                    end
                elseif t[p].Remove or t[p].Destroy then
                    (t[p].Remove or t[p].Destroy)(t[p])
                end
                t[p] = nil
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

    players.PlayerRemoving:Connect(cleanup)

    rs.RenderStepped:Connect(function()
        if not esp.active then
            return
        end

        frameCount += 1
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

            if dist > esp.maxdist then
                cleanup(p)
                continue
            end

            local col = esp.teamcolor and (p.Team and p.Team.TeamColor.Color or Color3.new(1, 1, 1)) or Color3.new(1, 1, 1)
            if hum and hum.Health <= 0 then
                col = Color3.fromRGB(128, 128, 128)
            end

            local function vis(obj, v)
                if obj then
                    obj.Visible = v
                end
            end

            local function setText(o, text, pos, color)
                o.Text = text
                o.Position = pos
                o.Color = color
                o.Visible = true
            end

            local h = math.abs(hp.Y - hd.Y)
            local w = h * .6

            local n = objs.names[p]
            local tr = objs.tracers[p]
            local q = objs.quads[p]
            local ht = objs.healths[p]
            local d = objs.distances[p]
            local chm = objs.chams[p]
            local hb = objs.healthbars[p]

            -- Box
            if esp.showbox and on1 and on2 then
                b.Size = Vector2.new(w, h)
                b.Position = Vector2.new(hp.X - w / 2, hd.Y)
                b.Color = col
                b.Visible = true
            else
                vis(b, false)
            end

            -- Name + distance
            if on2 then
                local name = esp.showname and (p.Name .. (esp.showheld and (ch:FindFirstChildOfClass("Tool") and (" [" .. ch:FindFirstChildOfClass("Tool").Name .. "]") or "") or "")) or ""
                local distText = esp.showdistance and (math.floor(dist) .. " studs") or ""
                local text = (#name > 0 and #distText > 0) and (name .. " | " .. distText) or name .. distText

                if text ~= "" then
                    setText(n, text, Vector2.new(hd.X, hd.Y - 15), col)
                else
                    vis(n, false)
                end
            end

            -- Tracer
            if esp.showtracer and on1 then
                local v = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y)
                tr.From = v
                tr.To = Vector2.new(hp.X, hp.Y)
                tr.Color = col
                tr.Visible = true
            else
                vis(tr, false)
            end

            -- Quad
            if esp.showquad and on1 and on2 then
                q.PointA = Vector2.new(hp.X - w / 2, hd.Y)
                q.PointB = Vector2.new(hp.X + w / 2, hd.Y)
                q.PointC = Vector2.new(hp.X + w / 2, hp.Y)
                q.PointD = Vector2.new(hp.X - w / 2, hp.Y)
                q.Color = col
                q.Visible = true
            else
                vis(q, false)
            end

            -- Health + bar
            if hum then
                if esp.showhealth and on2 then
                    setText(ht, ("%d/%d"):format(hum.Health, hum.MaxHealth), Vector2.new(hd.X, hd.Y + 5), getColor(hum.Health, hum.MaxHealth))
                else
                    vis(ht, false)
                end

                if esp.showhealthbar and on1 and on2 then
                    local perc = hum.Health / hum.MaxHealth
                    local barH = h * perc
                    hb.From = Vector2.new(hp.X - w / 2 - 6, hd.Y + h - barH)
                    hb.To = Vector2.new(hp.X - w / 2 - 6, hd.Y + h)
                    hb.Color = getColor(hum.Health, hum.MaxHealth)
                    hb.Visible = true
                else
                    vis(hb, false)
                end
            end

            -- Chams
            if esp.showchams then
                chm.Adornee = ch
                chm.FillColor = col
                chm.Enabled = true
            else
                chm.Enabled = false
            end

            -- Skeleton
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
                    if bone[1].Remove then
                        bone[1]:Remove()
                    end
                end
                objs.skeletons[p] = {}
            end
        end
    end)

    function esp:enable()
        self.active = true
    end

    function esp:disable()
        self.active = false

        for name, t in pairs(objs) do
            for _, o in pairs(t) do
                if name == "skeletons" then
                    if o.Remove then
                        o:Remove()
                    elseif o.Destroy then
                        o:Destroy()
                    end
                else
                    if o.Visible ~= nil then
                        o.Visible = false
                    elseif o.Enabled ~= nil then
                        o.Enabled = false
                    end
                end
            end
        end
    end

    function esp:clear()
        for _, t in pairs(objs) do
            for _, o in pairs(t) do
                if type(o) == "table" then
                    for _, b in pairs(o) do
                        if b[1] and b[1].Remove then
                            b[1]:Remove()
                        end
                    end
                elseif o.Remove or o.Destroy then
                    (o.Remove or o.Destroy)(o)
                end
            end
        end

        for k in pairs(objs) do
            objs[k] = {}
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
