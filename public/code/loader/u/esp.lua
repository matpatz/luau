return function()
    local get = (type(cloneref) == "function") and cloneref or function(x) return x end
    local Plrs = get(game:GetService("Players"))
    local Rs = get(game:GetService("RunService"))
    local Ws = get(game:GetService("Workspace"))
    local Cam = Ws.CurrentCamera

    local inst = {}
    local _players = {}
    local _boxes = {}
    local _names = {}
    local _conn, _runConn = {}, nil
    local _opts = {
        maxDist = 2000,
        teamColor = true,
        forceColor = nil,
        showBox = true,
        showName = true,
        showHeld = false,
        boxThickness = 2,
        boxFilled = false,
        nameSize = 16,
        outline = true,
        boxAlpha = 1
    }

    local function teamColorFor(p)
        if _opts.forceColor then return _opts.forceColor end
        if not _opts.teamColor then return Color3.new(1,1,1) end
        local t = p.Team
        if not t then return Color3.new(1,1,1) end
        local tc = t.TeamColor
        if tc and tc.Color then return tc.Color end
        return Color3.new(1,1,1)
    end

    local function makeBox(p)
        local box = Drawing.new("Square")
        box.Thickness = _opts.boxThickness
        box.Filled = _opts.boxFilled
        box.Transparency = _opts.boxAlpha
        box.Visible = false
        box.Color = teamColorFor(p)
        return box
    end
    local function makeName()
        local t = Drawing.new("Text")
        t.Size = _opts.nameSize
        t.Center = true
        t.Outline = _opts.outline
        t.Visible = false
        t.Font = 2
        t.Color = Color3.new(1,1,1)
        return t
    end

    local function ensurePlayer(p)
        if _players[p] then return end
        _players[p] = {enabled = true}
        _boxes[p] = makeBox(p)
        _names[p] = makeName()
    end

    local function removeData(p)
        if _boxes[p] then pcall(function() _boxes[p]:Remove() end); _boxes[p] = nil end
        if _names[p] then pcall(function() _names[p]:Remove() end); _names[p] = nil end
        _players[p] = nil
    end

    local function onAdded(p)
        ensurePlayer(p)
        table.insert(_conn, p.AncestryChanged:Connect(function()
            if not p:IsDescendantOf(game) then removeData(p) end
        end))
    end
    local function onRemoving(p)
        removeData(p)
    end

    function inst:setOption(k, v)
        _opts[k] = v
        if k == "boxThickness" or k == "boxFilled" or k == "boxAlpha" or k == "forceColor" then
            for p,box in pairs(_boxes) do
                if box then
                    box.Thickness = _opts.boxThickness
                    box.Filled = _opts.boxFilled
                    box.Transparency = _opts.boxAlpha
                    box.Color = teamColorFor(p)
                end
            end
        end
        if k == "nameSize" or k == "outline" then
            for _,t in pairs(_names) do
                if t then
                    t.Size = _opts.nameSize
                    t.Outline = _opts.outline
                end
            end
        end
    end

    function inst:togglePlayer(p, on)
        ensurePlayer(p)
        _players[p].enabled = (on == nil) and (not _players[p].enabled) or (not not on)
        if not _players[p].enabled then
            if _boxes[p] then _boxes[p].Visible = false end
            if _names[p] then _names[p].Visible = false end
        end
    end

    function inst:enable()
        if _runConn then return end
        for _,p in pairs(Plrs:GetPlayers()) do
            if p ~= Plrs.LocalPlayer then ensurePlayer(p) end
        end
        _runConn = Rs.RenderStepped:Connect(function()
            Cam = Ws.CurrentCamera
            if not Cam then return end
            for p,data in pairs(_players) do
                if not p or not p.Parent then removeData(p); continue end
                if not data.enabled then continue end
                local ch = p.Character
                if not ch then
                    if _boxes[p] then _boxes[p].Visible = false end
                    if _names[p] then _names[p].Visible = false end
                    continue
                end
                local hrp = ch:FindFirstChild("HumanoidRootPart") or ch.PrimaryPart
                local head = ch:FindFirstChild("Head") or ch:FindFirstChild("UpperTorso") or ch:FindFirstChild("Torso")
                if not hrp or not head then
                    if _boxes[p] then _boxes[p].Visible = false end
                    if _names[p] then _names[p].Visible = false end
                    continue
                end

                local dist = (Cam.CFrame.Position - hrp.Position).Magnitude
                if _opts.maxDist and dist > _opts.maxDist then
                    if _boxes[p] then _boxes[p].Visible = false end
                    if _names[p] then _names[p].Visible = false end
                    continue
                end

                local hrp2, on1 = Cam:WorldToViewportPoint(hrp.Position)
                local head2, on2 = Cam:WorldToViewportPoint(head.Position)

                local box = _boxes[p]
                if _opts.showBox and box and on1 and on2 then
                    local height = math.abs(hrp2.Y - head2.Y)
                    local width = math.clamp(height * 0.6, 10, 2000)
                    box.Size = Vector2.new(width, height)
                    box.Position = Vector2.new(hrp2.X - width/2, head2.Y)
                    box.Color = teamColorFor(p)
                    box.Visible = true
                else
                    if box then box.Visible = false end
                end

                local nameT = _names[p]
                if _opts.showName and nameT and on2 then
                    local txt = p.Name .. " [" .. math.floor(dist) .. "m]"
                    if _opts.showHeld then
                        local tool = ch:FindFirstChildOfClass("Tool")
                        if tool then txt = txt .. " | " .. tool.Name end
                    end
                    nameT.Position = Vector2.new(head2.X, head2.Y - 15)
                    nameT.Text = txt
                    nameT.Color = Color3.new(1,1,1)
                    nameT.Visible = true
                else
                    if nameT then nameT.Visible = false end
                end
            end
        end)
    end

    function inst:disable()
        if _runConn then
            pcall(function() _runConn:Disconnect() end)
            _runConn = nil
        end
        for p,box in pairs(_boxes) do if box then box.Visible = false end end
        for p,t in pairs(_names) do if t then t.Visible = false end end
    end

    function inst:init(opts)
        if type(opts) == "table" then
            for k,v in pairs(opts) do if _opts[k] ~= nil then _opts[k] = v end end
        end

        for _,p in pairs(Plrs:GetPlayers()) do
            if p ~= Plrs.LocalPlayer then ensurePlayer(p) end
        end
        table.insert(_conn, Plrs.PlayerAdded:Connect(onAdded))
        table.insert(_conn, Plrs.PlayerRemoving:Connect(onRemoving))
    end

    function inst:destroy()
        inst:disable()
        for _,c in ipairs(_conn) do
            if c and c.Disconnect then pcall(c.Disconnect, c) end
        end
        _conn = {}
        for p,b in pairs(_boxes) do if b then pcall(function() b:Remove() end) end _boxes[p] = nil end
        for p,t in pairs(_names) do if t then pcall(function() t:Remove() end) end _names[p] = nil end
        _players = {}
    end

    function inst:setMaxDist(n) if type(n)=="number" then _opts.maxDist = n end end
    function inst:setTeamColor(v) _opts.teamColor = not not v end
    function inst:setForceColor(col) _opts.forceColor = col end
    function inst:setShowHeld(v) _opts.showHeld = not not v end
    function inst:setShowBox(v) _opts.showBox = not not v end
    function inst:setShowName(v) _opts.showName = not not v end

    return inst
end
