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
    esp.showcorners = true -- NEW: toggle for corner boxes
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

    -- per element colors (default)
    esp.boxcolor = Color3.fromRGB(255, 255, 255)
    esp.cornercolor = Color3.fromRGB(255, 255, 255)
    esp.namecolor = Color3.fromRGB(255, 255, 255)
    esp.tracercolor = Color3.fromRGB(255, 255, 255)
    esp.quadcolor = Color3.fromRGB(255, 255, 255)
    esp.healthtextcolor = Color3.fromRGB(0, 255, 0)
    esp.distancecolor = Color3.fromRGB(255, 255, 255)
    esp.chamscolor = Color3.fromRGB(255, 255, 255)
    esp.healthbarcoloroverride = nil -- nil = use HP gradient

    local boxes, names, tracers, quads, healths, distances, chams, healthbars = {}, {}, {}, {}, {}, {}, {}, {}
    local corners = {} -- NEW: corner lines per player

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

    local function newcorners(p)
        -- 4 corner lines: TL, TR, BL, BR
        local t = {}
        for i = 1, 4 do
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
            Thickness = 1, Color = esp.tracercolor, Visible = false
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
    end

    local function cleanupPlayer(p)
        local objects = {
            boxes, names, tracers, quads, healths, distances, chams, healthbars, corners
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

    for _, p in pairs(players:GetPlayers()) do
        trackplayer(p)
    end

    players.PlayerAdded:Connect(trackplayer)
    players.PlayerRemoving:Connect(cleanupPlayer)

    rs.RenderStepped:Connect(function()
        if not esp.active then return end

        frameCount = frameCount + 1
        if esp.performancemode and frameCount % uInterval ~= 0 then return end

        viewportSize = cam.ViewportSize
        local cameraPos = cam.CFrame.Position

        for p, b in pairs(boxes) do
            local ch, hrp, head, humanoid = getparts(p)

            if not ch or not hrp or not head then
                b.Visible = false
                if corners[p] then
                    for _, ln in ipairs(corners[p]) do ln.Visible = false end
                end
                if names[p] then names[p].Visible = false end
                if tracers[p] then tracers[p].Visible = false end
                if quads[p] then quads[p].Visible = false end
                if healths[p] then healths[p].Visible = false end
                if distances[p] then distances[p].Visible = false end
                if chams[p] then chams[p].Enabled = false end
                if healthbars[p] then healthbars[p].Visible = false end
                continue
            end

            local hrpPos, hrpOnScreen = cam:WorldToViewportPoint(hrp.Position)
            local headPos, headOnScreen = cam:WorldToViewportPoint(head.Position)
            local dist = (cameraPos - hrp.Position).Magnitude

            if dist > esp.maxdist then
                b.Visible = false
                if corners[p] then
                    for _, ln in ipairs(corners[p]) do ln.Visible = false end
                end
                if names[p] then names[p].Visible = false end
                if tracers[p] then tracers[p].Visible = false end
                if quads[p] then quads[p].Visible = false end
                if healths[p] then healths[p].Visible = false end
                if distances[p] then distances[p].Visible = false end
                if chams[p] then chams[p].Enabled = false end
                if healthbars[p] then healthbars[p].Visible = false end
                continue
            end

            -- base team/dead color modifier
            local baseCol = white
            if esp.teamcolor and p.Team ~= lp.Team then
                baseCol = red
            end
            if humanoid and humanoid.Health <= 0 then
                baseCol = gray
            end

            -- box
            local height, width, boxLeft, boxTop
            if (esp.showbox or esp.showcorners) and hrpOnScreen and headOnScreen then
                height = math.abs(hrpPos.Y - headPos.Y)
                width = height * 0.6
                boxLeft = hrpPos.X - width/2
                boxTop = headPos.Y

                if esp.showbox then
                    b.Size = Vector2.new(width, height)
                    b.Position = Vector2.new(boxLeft, boxTop)
                    -- per element color *with* team/death tint
                    b.Color = esp.boxcolor or baseCol
                    b.Visible = true
                else
                    b.Visible = false
                end
            else
                b.Visible = false
            end

            -- corner box
            if esp.showcorners and hrpOnScreen and headOnScreen and height and width then
                local c = corners[p]
                if c then
                    local x1, y1 = boxLeft, boxTop
                    local x2, y2 = boxLeft + width, boxTop
                    local x3, y3 = boxLeft, boxTop + height
                    local x4, y4 = boxLeft + width, boxTop + height

                    local cornerLen = math.max(3, height * 0.2)

                    -- TL
                    c[1].From = Vector2.new(x1, y1 + cornerLen)
                    c[1].To   = Vector2.new(x1, y1)
                    c[1].Color = esp.cornercolor or baseCol
                    c[1].Visible = true

                    c[2].From = Vector2.new(x1, y1)
                    c[2].To   = Vector2.new(x1 + cornerLen, y1)
                    c[2].Color = esp.cornercolor or baseCol
                    c[2].Visible = true

                    -- TR
                    c[3].From = Vector2.new(x2, y2 + cornerLen)
                    c[3].To   = Vector2.new(x2, y2)
                    c[3].Color = esp.cornercolor or baseCol
                    c[3].Visible = true

                    c[4].From = Vector2.new(x2 - cornerLen, y2)
                    c[4].To   = Vector2.new(x2, y2)
                    c[4].Color = esp.cornercolor or baseCol
                    c[4].Visible = true

                end
            elseif corners[p] then
                for _, ln in ipairs(corners[p]) do ln.Visible = false end
            end

            -- name + distance
            if (esp.showname or esp.showdistance) and headOnScreen then
                local nameText = ""
                local distanceText = ""

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

            -- Tracer
            if esp.showtracer and hrpOnScreen then
                local tr = tracers[p]
                tr.From = Vector2.new(viewportSize.X/2, viewportSize.Y)
                tr.To = Vector2.new(hrpPos.X, hrpPos.Y)
                tr.Color = esp.tracercolor or baseCol
                tr.Visible = true
            elseif tracers[p] then
                tracers[p].Visible = false
            end

            -- quad
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

            -- health (text)
            if esp.showhealth and humanoid and headOnScreen then
                local health = healths[p]
                local healthText = math.floor(humanoid.Health) .. "/" .. math.floor(humanoid.MaxHealth)
                local healthCol = esp.healthtextcolor or getColor(humanoid.Health, humanoid.MaxHealth)
                health.Position = Vector2.new(headPos.X, headPos.Y + 5)
                health.Text = healthText
                health.Color = healthCol
                health.Visible = true
            elseif healths[p] then
                healths[p].Visible = false
            end

            -- health (bar/line)
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

            -- chams
            if esp.showchams then
                local cham = chams[p]
                cham.Adornee = ch
                cham.Enabled = true
                cham.FillColor = esp.chamscolor or baseCol
            elseif chams[p] then
                chams[p].Enabled = false
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
        end
    end

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

    function esp:setBoxColor(c) self.boxcolor = c end
    function esp:setCornerColor(c) self.cornercolor = c end
    function esp:setNameColor(c) self.namecolor = c end
    function esp:setTracerColor(c) self.tracercolor = c end
    function esp:setQuadColor(c) self.quadcolor = c end
    function esp:setHealthTextColor(c) self.healthtextcolor = c end
    function esp:setDistanceColor(c) self.distancecolor = c end
    function esp:setChamsColor(c) self.chamscolor = c end
    function esp:setHealthbarColor(c) self.healthbarcoloroverride = c end

    function esp:clear()
        for p in pairs(boxes) do
            cleanupPlayer(p)
        end
        boxes, names, tracers, quads, healths, distances, chams, healthbars, corners =
            {}, {}, {}, {}, {}, {}, {}, {}, {}
        self.active = false
    end

    return esp
end
