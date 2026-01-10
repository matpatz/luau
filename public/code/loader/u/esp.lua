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

    -- 2D options
    esp.showbox = true
    esp.showcorners = true
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

    -- 3D options
    esp.showskeleton = false
    esp.show3dbox = false

    -- per element colors (default)
    esp.boxcolor = Color3.fromRGB(255, 255, 255)
    esp.cornercolor = Color3.fromRGB(255, 255, 255)
    esp.namecolor = Color3.fromRGB(255, 255, 255)
    esp.tracercolor = Color3.fromRGB(255, 255, 255)
    esp.quadcolor = Color3.fromRGB(255, 255, 255)
    esp.healthtextcolor = Color3.fromRGB(0, 255, 0)
    esp.distancecolor = Color3.fromRGB(255, 255, 255)
    esp.chamscolor = Color3.fromRGB(255, 255, 255)
    esp.healthbarcoloroverride = nil

    -- sizing options
    esp.tracerThickness = 1
    esp.boxWidthScale = 0.6
    esp.boxHeightScale = 1

    local boxes, names, tracers, quads, healths, distances, chams, healthbars = {}, {}, {}, {}, {}, {}, {}, {}
    local corners = {}      -- 8 corner lines per player
    local box3dLines = {}   -- 12 lines per player
    local skeletonLines = {} -- skeleton segments per player

    local frameCount, uInterval = 0, 2
    local viewportSize = cam.ViewportSize

    local white = Color3.fromRGB(255, 255, 255)
    local red = Color3.fromRGB(255, 0, 0)
    local green = Color3.fromRGB(0, 255, 0)
    local yellow = Color3.fromRGB(255, 255, 0)
    local gray = Color3.fromRGB(128, 128, 128)

    local function getparts(p)
        local ch = p.Character
        if not ch then return end

        local hrp = ch:FindFirstChild("HumanoidRootPart")
        local head = ch:FindFirstChild("Head") or ch:FindFirstChild("UpperTorso") or ch:FindFirstChild("Torso")
        local humanoid = ch:FindFirstChildOfClass("Humanoid")
        if hrp and head then
            return ch, hrp, head, humanoid
        end
    end

    local function getColor(health, maxhealth)
        local percentage = health / maxhealth
        if percentage > 0.7 then
            return green
        elseif percentage > 0.3 then
            return yellow
        else
            return red
        end
    end

    local function createDrawing(type, properties)
        local drawing = Drawing.new(type)
        for prop, value in pairs(properties) do
            drawing[prop] = value
        end
        return drawing
    end

    local function newbox(p)
        boxes[p] = createDrawing("Square", {
            Thickness = 2, Filled = false, Transparency = 1,
            Color = esp.boxcolor, Visible = false
        })
    end

    -- 8 corner lines: TL vert, TL horiz, TR vert, TR horiz, BL vert, BL horiz, BR vert, BR horiz
    local function newcorners(p)
        local t = {}
        for i = 1, 8 do
            t[i] = createDrawing("Line", {
                Thickness = 2,
                Transparency = 1,
                Color = esp.cornercolor,
                Visible = false
            })
        end
        corners[p] = t
    end

    local function newname(p)
        names[p] = createDrawing("Text", {
            Size = 16, Center = true, Outline = true, Font = 2,
            Color = esp.namecolor, Visible = false
        })
    end

    local function newtracer(p)
        tracers[p] = createDrawing("Line", {
            Thickness = esp.tracerThickness, Color = esp.tracercolor, Visible = false
        })
    end

    local function newquad(p)
        quads[p] = createDrawing("Quad", {
            Color = esp.quadcolor, Visible = false, Thickness = 1
        })
    end

    local function newhealth(p)
        healths[p] = createDrawing("Text", {
            Size = 14, Center = true, Outline = true, Font = 2,
            Color = esp.healthtextcolor, Visible = false
        })
    end

    local function newdistance(p)
        distances[p] = createDrawing("Text", {
            Size = 14, Center = true, Outline = true, Font = 2,
            Color = esp.distancecolor, Visible = false
        })
    end

    local function newchams(p)
        local highlight = Instance.new("Highlight")
        highlight.FillTransparency = 0.7
        highlight.OutlineTransparency = 1
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Enabled = false
        highlight.Parent = ws
        chams[p] = highlight
    end

    local function newhealthbar(p)
        healthbars[p] = createDrawing("Line", {
            Thickness = 3,
            Color = esp.healthbarcoloroverride or green,
            Visible = false
        })
    end

    -- 3D box: 12 lines
    local function new3dbox(p)
        local t = {}
        for i = 1, 12 do
            t[i] = createDrawing("Line", {
                Thickness = 1,
                Color = esp.boxcolor,
                Visible = false
            })
        end
        box3dLines[p] = t
    end

    -- skeleton lines (R6/R15 basic)
    local function newskeleton(p)
        local t = {}
        for i = 1, 15 do
            t[i] = createDrawing("Line", {
                Thickness = 1,
                Color = esp.boxcolor,
                Visible = false
            })
        end
        skeletonLines[p] = t
    end

    local function cleanupPlayer(p)
        local objects = {
            boxes, names, tracers, quads, healths, distances, chams, healthbars,
            corners, box3dLines, skeletonLines
        }

        for _, storage in pairs(objects) do
            local obj = storage[p]
            if obj then
                if typeof(obj) == "table" then
                    for _, v in pairs(obj) do
                        if typeof(v) == "Instance" then
                            v:Destroy()
                        elseif v and v.Remove then
                            v:Remove()
                        end
                    end
                else
                    if typeof(obj) == "Instance" then
                        obj:Destroy()
                    elseif obj and obj.Remove then
                        obj:Remove()
                    end
                end
                storage[p] = nil
            end
        end
    end

    local function trackplayer(p)
        if p == lp then return end

        newbox(p)
        newcorners(p)
        newname(p)
        newtracer(p)
        newquad(p)
        newhealth(p)
        newdistance(p)
        newchams(p)
        newhealthbar(p)
        new3dbox(p)
        newskeleton(p)

        -- Character cleanup
        p.CharacterRemoving:Connect(function()
            cleanupPlayer(p)
        end)
    end

    for _, p in pairs(players:GetPlayers()) do
        trackplayer(p)
    end

    players.PlayerAdded:Connect(trackplayer)
    players.PlayerRemoving:Connect(function(p)
        cleanupPlayer(p)
    end)

    -- helper to get limb part positions
    local function getJointPositions(ch)
        local parts = {
            Head = ch:FindFirstChild("Head"),
            Torso = ch:FindFirstChild("Torso") or ch:FindFirstChild("UpperTorso"),
            LowerTorso = ch:FindFirstChild("LowerTorso"),
            LeftArm = ch:FindFirstChild("Left Arm") or ch:FindFirstChild("LeftUpperArm"),
            RightArm = ch:FindFirstChild("Right Arm") or ch:FindFirstChild("RightUpperArm"),
            LeftLeg = ch:FindFirstChild("Left Leg") or ch:FindFirstChild("LeftUpperLeg"),
            RightLeg = ch:FindFirstChild("Right Leg") or ch:FindFirstChild("RightUpperLeg"),
        }

        local pos = {}
        for name, part in pairs(parts) do
            if part then
                pos[name] = part.Position
            end
        end
        return pos
    end

    rs.RenderStepped:Connect(function()
        if not esp.active then return end

        frameCount = frameCount + 1
        if esp.performancemode and frameCount % uInterval ~= 0 then return end

        viewportSize = cam.ViewportSize
        local cameraPos = cam.CFrame.Position

        for p, b in pairs(boxes) do
            if not p or not p.Parent then
                cleanupPlayer(p)
                continue
            end

            local ch, hrp, head, humanoid = getparts(p)

            if not ch or not hrp or not head then
                cleanupPlayer(p)
                continue
            end

            local hrpPos, hrpOnScreen = cam:WorldToViewportPoint(hrp.Position)
            local headPos, headOnScreen = cam:WorldToViewportPoint(head.Position)
            local dist = (cameraPos - hrp.Position).Magnitude

            if dist > esp.maxdist then
                b.Visible = false
                if corners[p] then for _, ln in ipairs(corners[p]) do ln.Visible = false end end
                if names[p] then names[p].Visible = false end
                if tracers[p] then tracers[p].Visible = false end
                if quads[p] then quads[p].Visible = false end
                if healths[p] then healths[p].Visible = false end
                if distances[p] then distances[p].Visible = false end
                if chams[p] then chams[p].Enabled = false end
                if healthbars[p] then healthbars[p].Visible = false end
                if box3dLines[p] then for _, ln in ipairs(box3dLines[p]) do ln.Visible = false end end
                if skeletonLines[p] then for _, ln in ipairs(skeletonLines[p]) do ln.Visible = false end end
                continue
            end

            local baseCol = white
            if esp.teamcolor and p.Team ~= lp.Team then
                baseCol = red
            end
            if humanoid and humanoid.Health <= 0 then
                baseCol = gray
            end

            -- BOX metrics
            local height, width, boxLeft, boxTop
            if (esp.showbox or esp.showcorners) and hrpOnScreen and headOnScreen then
                height = math.abs(hrpPos.Y - headPos.Y) * (esp.boxHeightScale or 1)
                width = height * (esp.boxWidthScale or 0.6)
                boxLeft = hrpPos.X - width/2
                boxTop = headPos.Y

                if esp.showbox then
                    b.Size = Vector2.new(width, height)
                    b.Position = Vector2.new(boxLeft, boxTop)
                    b.Color = esp.boxcolor or baseCol
                    b.Visible = true
                else
                    b.Visible = false
                end
            else
                b.Visible = false
            end

            -- CORNER BOX (top + bottom)
            if esp.showcorners and hrpOnScreen and headOnScreen and height and width then
                local c = corners[p]
                if c then
                    local x1, y1 = boxLeft, boxTop
                    local x2, y2 = boxLeft + width, boxTop
                    local x3, y3 = boxLeft, boxTop + height
                    local x4, y4 = boxLeft + width, boxTop + height

                    local cornerLen = math.max(3, height * 0.2)
                    local col = esp.cornercolor or baseCol

                    -- TOP LEFT
                    c[1].From = Vector2.new(x1, y1 + cornerLen)
                    c[1].To   = Vector2.new(x1, y1)
                    c[1].Color = col
                    c[1].Visible = true

                    c[2].From = Vector2.new(x1, y1)
                    c[2].To   = Vector2.new(x1 + cornerLen, y1)
                    c[2].Color = col
                    c[2].Visible = true

                    -- TOP RIGHT
                    c[3].From = Vector2.new(x2, y2 + cornerLen)
                    c[3].To   = Vector2.new(x2, y2)
                    c[3].Color = col
                    c[3].Visible = true

                    c[4].From = Vector2.new(x2 - cornerLen, y2)
                    c[4].To   = Vector2.new(x2, y2)
                    c[4].Color = col
                    c[4].Visible = true

                    -- BOTTOM LEFT
                    c[5].From = Vector2.new(x3, y3 - cornerLen)
                    c[5].To   = Vector2.new(x3, y3)
                    c[5].Color = col
                    c[5].Visible = true

                    c[6].From = Vector2.new(x3, y3)
                    c[6].To   = Vector2.new(x3 + cornerLen, y3)
                    c[6].Color = col
                    c[6].Visible = true

                    -- BOTTOM RIGHT
                    c[7].From = Vector2.new(x4, y4 - cornerLen)
                    c[7].To   = Vector2.new(x4, y4)
                    c[7].Color = col
                    c[7].Visible = true

                    c[8].From = Vector2.new(x4 - cornerLen, y4)
                    c[8].To   = Vector2.new(x4, y4)
                    c[8].Color = col
                    c[8].Visible = true
                end
            elseif corners[p] then
                for _, ln in ipairs(corners[p]) do ln.Visible = false end
            end

            -- NAME + DISTANCE
            if (esp.showname or esp.showdistance) and headOnScreen then
                local nameText, distanceText = "", ""

                if esp.showname then
                    nameText = p.Name
                    if esp.showheld then
                        local tool = ch:FindFirstChildOfClass("Tool")
                        if tool then
                            nameText = nameText .. " [" .. tool.Name .. "]"
                        end
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
                n.Position = Vector2.new(headPos.X, headPos.Y - 15)
                n.Text = combinedText
                n.Color = esp.namecolor or baseCol
                n.Visible = true
            elseif names[p] then
                names[p].Visible = false
            end

            -- TRACER
            if esp.showtracer and hrpOnScreen then
                local tr = tracers[p]
                tr.From = Vector2.new(viewportSize.X/2, viewportSize.Y)
                tr.To = Vector2.new(hrpPos.X, hrpPos.Y)
                tr.Color = esp.tracercolor or baseCol
                tr.Thickness = esp.tracerThickness or 1
                tr.Visible = true
            elseif tracers[p] then
                tracers[p].Visible = false
            end

            -- QUAD
            if esp.showquad and hrpOnScreen and headOnScreen then
                local q = quads[p]
                local heightQ = math.abs(hrpPos.Y - headPos.Y)
                local widthQ = heightQ * 0.6
                local halfWidth = widthQ/2

                q.PointA = Vector2.new(hrpPos.X - halfWidth, headPos.Y)
                q.PointB = Vector2.new(hrpPos.X + halfWidth, headPos.Y)
                q.PointC = Vector2.new(hrpPos.X + halfWidth, hrpPos.Y)
                q.PointD = Vector2.new(hrpPos.X - halfWidth, hrpPos.Y)
                q.Color = esp.quadcolor or baseCol
                q.Visible = true
            elseif quads[p] then
                quads[p].Visible = false
            end

            -- HEALTH TEXT
            if esp.showhealth and humanoid and headOnScreen then
                local htxt = healths[p]
                local healthText = math.floor(humanoid.Health) .. "/" .. math.floor(humanoid.MaxHealth)
                local healthCol = esp.healthtextcolor or getColor(humanoid.Health, humanoid.MaxHealth)
                htxt.Position = Vector2.new(headPos.X, headPos.Y + 5)
                htxt.Text = healthText
                htxt.Color = healthCol
                htxt.Visible = true
            elseif healths[p] then
                healths[p].Visible = false
            end

            -- HEALTH BAR
            if esp.showhealthbar and humanoid and hrpOnScreen and headOnScreen then
                local bar = healthbars[p]
                local heightHB = math.abs(hrpPos.Y - headPos.Y)
                local widthHB = heightHB * 0.6
                local boxLeftHB = hrpPos.X - widthHB/2
                local boxTopHB = headPos.Y

                local healthPercentage = humanoid.Health / humanoid.MaxHealth
                local barHeight = heightHB * healthPercentage
                local barColor = esp.healthbarcoloroverride or getColor(humanoid.Health, humanoid.MaxHealth)

                bar.From = Vector2.new(boxLeftHB - 6, boxTopHB + heightHB - barHeight)
                bar.To = Vector2.new(boxLeftHB - 6, boxTopHB + heightHB)
                bar.Color = barColor
                bar.Visible = true
            elseif healthbars[p] then
                healthbars[p].Visible = false
            end

            -- CHAMS (Highlight)
            if esp.showchams then
                local cham = chams[p]
                if cham then
                    cham.Adornee = ch
                    cham.Enabled = true
                    cham.FillColor = esp.chamscolor or baseCol
                end
            elseif chams[p] then
                chams[p].Enabled = false
            end

            -- 3D BOX
            if esp.show3dbox and box3dLines[p] then
                local lines = box3dLines[p]
                local size = hrp.Size * 1.5
                local cf = hrp.CFrame

                local offsets = {
                    Vector3.new(-size.X/2,  size.Y/2, -size.Z/2), -- 1
                    Vector3.new( size.X/2,  size.Y/2, -size.Z/2), -- 2
                    Vector3.new( size.X/2,  size.Y/2,  size.Z/2), -- 3
                    Vector3.new(-size.X/2,  size.Y/2,  size.Z/2), -- 4
                    Vector3.new(-size.X/2, -size.Y/2, -size.Z/2), -- 5
                    Vector3.new( size.X/2, -size.Y/2, -size.Z/2), -- 6
                    Vector3.new( size.X/2, -size.Y/2,  size.Z/2), -- 7
                    Vector3.new(-size.X/2, -size.Y/2,  size.Z/2), -- 8
                }

                local points2d = {}
                local onscreenAny = false

                for i = 1, 8 do
                    local worldPos = (cf * CFrame.new(offsets[i])).Position
                    local v2, onScreen = cam:WorldToViewportPoint(worldPos)
                    points2d[i] = {Vector2.new(v2.X, v2.Y), onScreen}
                    if onScreen then
                        onscreenAny = true
                    end
                end

                if onscreenAny then
                    local col = esp.boxcolor or baseCol

                    local function setLine(idx, i1, i2)
                        local p1, o1 = points2d[i1][1], points2d[i1][2]
                        local p2, o2 = points2d[i2][1], points2d[i2][2]
                        local ln = lines[idx]
                        if o1 or o2 then
                            ln.From = p1
                            ln.To = p2
                            ln.Color = col
                            ln.Visible = true
                        else
                            ln.Visible = false
                        end
                    end

                    -- top rectangle: 1-2-3-4
                    setLine(1, 1, 2)
                    setLine(2, 2, 3)
                    setLine(3, 3, 4)
                    setLine(4, 4, 1)

                    -- bottom rectangle: 5-6-7-8
                    setLine(5, 5, 6)
                    setLine(6, 6, 7)
                    setLine(7, 7, 8)
                    setLine(8, 8, 5)

                    -- vertical edges
                    setLine(9, 1, 5)
                    setLine(10, 2, 6)
                    setLine(11, 3, 7)
                    setLine(12, 4, 8)
                else
                    for _, ln in ipairs(lines) do ln.Visible = false end
                end
            elseif box3dLines[p] then
                for _, ln in ipairs(box3dLines[p]) do ln.Visible = false end
            end

            -- SKELETON
            if esp.showskeleton and skeletonLines[p] then
                local lines = skeletonLines[p]
                local joints = getJointPositions(ch)

                local function proj(name)
                    local pos = joints[name]
                    if not pos then return nil, false end
                    local v, onScreen = cam:WorldToViewportPoint(pos)
                    return Vector2.new(v.X, v.Y), onScreen
                end

                local pairsDef = {
                    {"Head", "Torso"},           -- 1
                    {"Torso", "LeftArm"},        -- 2
                    {"Torso", "RightArm"},       -- 3
                    {"Torso", "LeftLeg"},        -- 4
                    {"Torso", "RightLeg"},       -- 5
                }

                local idx = 1
                local col = esp.boxcolor or baseCol

                for _, pair in ipairs(pairsDef) do
                    local p1, o1 = proj(pair[1])
                    local p2, o2 = proj(pair[2])
                    local ln = lines[idx]
                    idx = idx + 1

                    if p1 and p2 and (o1 or o2) then
                        ln.From = p1
                        ln.To = p2
                        ln.Color = col
                        ln.Visible = true
                    else
                        ln.Visible = false
                    end
                end

                for i = idx, #lines do
                    lines[i].Visible = false
                end
            elseif skeletonLines[p] then
                for _, ln in ipairs(skeletonLines[p]) do ln.Visible = false end
            end
        end
    end)

    function esp:enable()
        self.active = true
    end

    function esp:disable()
        self.active = false
        for p in pairs(boxes) do
            if boxes[p] then boxes[p].Visible = false end
            if corners[p] then for _, ln in ipairs(corners[p]) do ln.Visible = false end end
            if names[p] then names[p].Visible = false end
            if tracers[p] then tracers[p].Visible = false end
            if quads[p] then quads[p].Visible = false end
            if healths[p] then healths[p].Visible = false end
            if distances[p] then distances[p].Visible = false end
            if chams[p] then chams[p].Enabled = false end
            if healthbars[p] then healthbars[p].Visible = false end
            if box3dLines[p] then for _, ln in ipairs(box3dLines[p]) do ln.Visible = false end end
            if skeletonLines[p] then for _, ln in ipairs(skeletonLines[p]) do ln.Visible = false end end
        end
    end

    -- 2D toggles
    function esp:box(v) self.showbox = v end
    function esp:corners(v) self.showcorners = v end
    function esp:name(v) self.showname = v end
    function esp:held(v) self.showheld = v end
    function esp:tracer(v) self.showtracer = v end
    function esp:quad(v) self.showquad = v end
    function esp:dist(d) self.maxdist = d end
    function esp:team(v) self.teamcolor = v end
    function esp:health(v) self.showhealth = v end
    function esp:distance(v) self.showdistance = v end
    function esp:chams(v) self.showchams = v end
    function esp:healthbar(v) self.showhealthbar = v end
    function esp:performance(v) self.performancemode = v end

    -- 3D toggles
    function esp:skeleton(v) self.showskeleton = v end
    function esp:box3d(v) self.show3dbox = v end

    -- color setters
    function esp:setBoxColor(c) self.boxcolor = c end
    function esp:setCornerColor(c) self.cornercolor = c end
    function esp:setNameColor(c) self.namecolor = c end
    function esp:setTracerColor(c) self.tracercolor = c end
    function esp:setQuadColor(c) self.quadcolor = c end
    function esp:setHealthTextColor(c) self.healthtextcolor = c end
    function esp:setDistanceColor(c) self.distancecolor = c end
    function esp:setChamsColor(c) self.chamscolor = c end
    function esp:setHealthbarColor(c) self.healthbarcoloroverride = c end

    -- sizing setters
    function esp:setTracerThickness(v) self.tracerThickness = v end
    function esp:setBoxSize(widthScale, heightScale)
        if widthScale then self.boxWidthScale = widthScale end
        if heightScale then self.boxHeightScale = heightScale end
    end

    function esp:clear()
        for p in pairs(boxes) do
            cleanupPlayer(p)
        end
        boxes, names, tracers, quads, healths, distances, chams, healthbars,
        corners, box3dLines, skeletonLines =
            {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}
        self.active = false
    end

    return esp
end
