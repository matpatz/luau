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

    local boxes, names, tracers, quads = {}, {}, {}, {}

    local function getparts(p)
        local ch = p.Character
        if not ch then return end
        return ch, ch:FindFirstChild("HumanoidRootPart"), ch:FindFirstChild("Head") or ch:FindFirstChild("UpperTorso") or ch:FindFirstChild("Torso")
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

    local function trackplayer(p)
        newbox(p)
        newname(p)
        newtracer(p)
        newquad(p)
    end

    for _,p in pairs(players:GetPlayers()) do if p ~= lp then trackplayer(p) end end
    players.PlayerAdded:Connect(function(p) if p ~= lp then trackplayer(p) end end)
    players.PlayerRemoving:Connect(function(p)
        if boxes[p] then boxes[p]:Remove() boxes[p] = nil end
        if names[p] then names[p]:Remove() names[p] = nil end
        if tracers[p] then tracers[p]:Remove() tracers[p] = nil end
        if quads[p] then quads[p]:Remove() quads[p] = nil end
    end)

    rs.RenderStepped:Connect(function()
        if not esp.active then return end
        for p,b in pairs(boxes) do
            local t, hrp, head = getparts(p)
            if t and hrp and head then
                local hrpPos, on1 = cam:WorldToViewportPoint(hrp.Position)
                local headPos, on2 = cam:WorldToViewportPoint(head.Position)
                local dist = (cam.CFrame.Position - hrp.Position).Magnitude
                if dist > esp.maxdist then b.Visible, names[p].Visible, tracers[p].Visible, quads[p].Visible = false, false, false, false continue end

                local col = (esp.teamcolor and p.Team ~= lp.Team) and Color3.fromRGB(255,0,0) or Color3.fromRGB(255,255,255)

                -- box
                if esp.showbox and on1 and on2 then
                    local h = math.abs(hrpPos.Y - headPos.Y)
                    local w = h * 0.6
                    b.Size = Vector2.new(w,h)
                    b.Position = Vector2.new(hrpPos.X - w/2, headPos.Y)
                    b.Color, b.Visible = col, true
                else b.Visible = false end

                -- name
                if esp.showname and on2 then
                    local txt = p.Name
                    if esp.showheld then
                        local tool = t:FindFirstChildOfClass("Tool")
                        if tool then txt = txt.." | "..tool.Name end
                    end
                    local n = names[p]
                    n.Position, n.Text, n.Color, n.Visible = Vector2.new(headPos.X, headPos.Y-15), txt, col, true
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

            else
                b.Visible = false
                if names[p] then names[p].Visible = false end
                if tracers[p] then tracers[p].Visible = false end
                if quads[p] then quads[p].Visible = false end
            end
        end
    end)

    function esp:enable() self.active = true end
    function esp:disable() self.active = false end
    function esp:box(v) self.showbox = v end
    function esp:name(v) self.showname = v end
    function esp:held(v) self.showheld = v end
    function esp:tracer(v) self.showtracer = v end
    function esp:quad(v) self.showquad = v end
    function esp:dist(d) self.maxdist = d end
    function esp:team(v) self.teamcolor = v end
    function esp:clear()
        for _,b in pairs(boxes) do b:Remove() end
        for _,t in pairs(names) do t:Remove() end
        for _,t in pairs(tracers) do t:Remove() end
        for _,q in pairs(quads) do q:Remove() end
        boxes, names, tracers, quads = {}, {}, {}, {}
        self.active = false
    end

    return esp
end
