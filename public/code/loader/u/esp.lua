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
            Color = white, Visible = false
        })
    end

    local function newname(p)
        names[p] = createDrawing("Text", {
            Size = 16, Center = true, Outline = true, Font = 2,
            Color = white, Visible = false
        })
    end

    local function newtracer(p)
        tracers[p] = createDrawing("Line", {
            Thickness = 1, Color = white, Visible = false
        })
    end

    local function newquad(p)
        quads[p] = createDrawing("Quad", {
            Color = white, Visible = false, Thickness = 1
        })
    end

    local function newhealth(p)
        healths[p] = createDrawing("Text", {
            Size = 14, Center = true, Outline = true, Font = 2,
            Color = green, Visible = false
        })
    end

    local function newdistance(p)
        distances[p] = createDrawing("Text", {
            Size = 14, Center = true, Outline = true, Font = 2,
            Color = white, Visible = false
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
            Thickness = 3, Color = green, Visible = false
        })
    end

    local function trackplayer(p)
        if p == lp then return end
        
        newbox(p)
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
            boxes, names, tracers, quads, healths, distances, chams, healthbars
        }
        
        for _, storage in pairs(objects) do
            if storage[p] then
                if typeof(storage[p]) == "Instance" then
                    storage[p]:Destroy()
                else
                    storage[p]:Remove()
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
                if names[p] then names[p].Visible = false end
                if tracers[p] then tracers[p].Visible = false end
                if quads[p] then quads[p].Visible = false end
                if healths[p] then healths[p].Visible = false end
                if distances[p] then distances[p].Visible = false end
                if chams[p] then chams[p].Enabled = false end
                if healthbars[p] then healthbars[p].Visible = false end
                continue 
            end

            local col = white
            if esp.teamcolor and p.Team ~= lp.Team then
                col = red
            end
            
            if humanoid and humanoid.Health <= 0 then
                col = gray
            end

            -- box
            if esp.showbox and hrpOnScreen and headOnScreen then
                local height = math.abs(hrpPos.Y - headPos.Y)
                local width = height * 0.6
                b.Size = Vector2.new(width, height)
                b.Position = Vector2.new(hrpPos.X - width/2, headPos.Y)
                b.Color = col
                b.Visible = true
            else
                b.Visible = false
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
                n.Color = col
                n.Visible = true
            elseif names[p] then
                names[p].Visible = false
            end

            -- Tracer
            if esp.showtracer and hrpOnScreen then
                local tr = tracers[p]
                tr.From = Vector2.new(viewportSize.X/2, viewportSize.Y)
                tr.To = Vector2.new(hrpPos.X, hrpPos.Y)
                tr.Color = col
                tr.Visible = true
            elseif tracers[p] then
                tracers[p].Visible = false
            end

            -- quad
            if esp.showquad and hrpOnScreen and headOnScreen then
                local q = quads[p]
                local height = math.abs(hrpPos.Y - headPos.Y)
                local width = height * 0.6
                local halfWidth = width/2
                
                q.PointA = Vector2.new(hrpPos.X - halfWidth, headPos.Y)
                q.PointB = Vector2.new(hrpPos.X + halfWidth, headPos.Y)
                q.PointC = Vector2.new(hrpPos.X + halfWidth, hrpPos.Y)
                q.PointD = Vector2.new(hrpPos.X - halfWidth, hrpPos.Y)
                q.Color = col
                q.Visible = true
            elseif quads[p] then
                quads[p].Visible = false
            end

            -- health (text)
            if esp.showhealth and humanoid and headOnScreen then
                local health = healths[p]
                local healthText = math.floor(humanoid.Health) .. "/" .. math.floor(humanoid.MaxHealth)
                local healthCol = getColor(humanoid.Health, humanoid.MaxHealth)
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
                local height = math.abs(hrpPos.Y - headPos.Y)
                local width = height * 0.6
                local boxLeft = hrpPos.X - width/2
                local boxTop = headPos.Y
                
                local healthPercentage = humanoid.Health / humanoid.MaxHealth
                local barHeight = height * healthPercentage
                local barColor = getColor(humanoid.Health, humanoid.MaxHealth)
                
                bar.From = Vector2.new(boxLeft - 6, boxTop + height - barHeight)
                bar.To = Vector2.new(boxLeft - 6, boxTop + height)
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
                cham.FillColor = col
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
    
    function esp:clear()
        for p in pairs(boxes) do
            cleanupPlayer(p)
        end
        boxes, names, tracers, quads, healths, distances, chams, healthbars = {}, {}, {}, {}, {}, {}, {}, {}
        self.active = false
    end

    return esp
end
