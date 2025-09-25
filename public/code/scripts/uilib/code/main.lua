local Library = {}
Library.__index = Library

function Library.new(windowTitle, TabsEnabled)
    local self = setmetatable({}, Library)
    self.TabsEnabled = TabsEnabled or false
    self.TabHeight = self.TabsEnabled and 30 or 0
    self.Tabs = {}
    self.ActiveTab = nil
    self.ContentFrames = {}

    -- ScreenGui
    self.ScreenGui = Instance.new("ScreenGui")
    self.ScreenGui.Name = "e"..math.random(1e9,2e9)
    self.ScreenGui.ResetOnSpawn = false
    self.ScreenGui.Parent = game.CoreGui

    -- Main Frame
    self.Frame = Instance.new("Frame")
    self.Frame.Size = UDim2.new(0,520,0,320)
    self.Frame.Position = UDim2.new(0.3,0,0.2,0)
    self.Frame.BackgroundColor3 = Color3.fromRGB(28,28,28)
    self.Frame.Active = true
    self.Frame.Draggable = true
    self.Frame.Parent = self.ScreenGui
    Instance.new("UICorner", self.Frame).CornerRadius = UDim.new(0,8)

    -- Title
    self.Title = Instance.new("TextLabel")
    self.Title.Text = windowTitle or "Window"
    self.Title.Size = UDim2.new(1,-40,0,30)
    self.Title.Position = UDim2.new(0,10,0,0)
    self.Title.BackgroundTransparency = 1
    self.Title.TextColor3 = Color3.fromRGB(255,255,255)
    self.Title.TextXAlignment = Enum.TextXAlignment.Left
    self.Title.Font = Enum.Font.GothamBold
    self.Title.TextSize = 18
    self.Title.Parent = self.Frame

    -- Close Button
    self.CloseButton = Instance.new("TextButton")
    self.CloseButton.Text = "X"
    self.CloseButton.Size = UDim2.new(0,30,0,30)
    self.CloseButton.Position = UDim2.new(1,-30,0,0)
    self.CloseButton.BackgroundTransparency = 1
    self.CloseButton.TextColor3 = Color3.fromRGB(255,50,50)
    self.CloseButton.Font = Enum.Font.Gotham
    self.CloseButton.TextSize = 18
    self.CloseButton.Parent = self.Frame
    self.CloseButton.MouseButton1Click:Connect(function()
        self.ScreenGui:Destroy()
    end)

    -- Tab bar
    if self.TabsEnabled then
        self.TabBar = Instance.new("Frame")
        self.TabBar.Size = UDim2.new(1,0,0,self.TabHeight)
        self.TabBar.Position = UDim2.new(0,0,0,30)
        self.TabBar.BackgroundColor3 = Color3.fromRGB(45,45,45)
        self.TabBar.BorderSizePixel = 0
        self.TabBar.Parent = self.Frame
    end

    return self
end

-- Get Y offset for content
function Library:GetContentOffset()
    return 30 + self.TabHeight
end

-- Add a new tab
function Library:AddTab(tabName)
    if not self.TabsEnabled then return end
    local tabButton = Instance.new("TextButton")
    tabButton.Size = UDim2.new(0,120,1,0)
    tabButton.Position = UDim2.new(#self.Tabs * 0.22,0,0,0)
    tabButton.Text = tabName
    tabButton.BackgroundColor3 = Color3.fromRGB(60,60,60)
    tabButton.TextColor3 = Color3.fromRGB(255,255,255)
    tabButton.Font = Enum.Font.GothamBold
    tabButton.TextSize = 14
    tabButton.Parent = self.TabBar
    self.Tabs[#self.Tabs+1] = tabButton

    -- Content frame for tab
    local contentFrame = Instance.new("Frame")
    contentFrame.Size = UDim2.new(1,-10,1,-self:GetContentOffset()-10)
    contentFrame.Position = UDim2.new(0,5,0,self:GetContentOffset())
    contentFrame.BackgroundTransparency = 1
    contentFrame.Visible = false
    contentFrame.Parent = self.Frame
    self.ContentFrames[tabButton] = contentFrame

    -- Switch tab
    tabButton.MouseButton1Click:Connect(function()
        for _, frame in pairs(self.ContentFrames) do
            frame.Visible = false
        end
        contentFrame.Visible = true
        self.ActiveTab = contentFrame
    end)

    -- Auto activate first tab
    if #self.Tabs == 1 then
        tabButton:CaptureFocus()
        tabButton.MouseButton1Click:Fire()
    end

    return contentFrame
end

-- Add TextBox
function Library:AddTextBox(tabOrPlaceholder, placeholder)
    local parent = self.Frame
    local textPlaceholder = tabOrPlaceholder
    if typeof(tabOrPlaceholder) == "Instance" then
        parent = tabOrPlaceholder
        textPlaceholder = placeholder or ""
    end

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1,-10,0,100)
    box.Position = UDim2.new(0,5,0,5)
    box.BackgroundColor3 = Color3.fromRGB(35,35,35)
    box.Text = textPlaceholder
    box.TextColor3 = Color3.fromRGB(255,255,255)
    box.Font = Enum.Font.Code
    box.TextSize = 14
    box.MultiLine = true
    box.ClearTextOnFocus = false
    box.Parent = parent
    return box
end

-- Add Button
function Library:AddButton(tabOrText, textOrCallback, callback)
    local parent = self.Frame
    local text = tabOrText
    local cb = textOrCallback
    if typeof(tabOrText) == "Instance" then
        parent = tabOrText
        text = textOrCallback
        cb = callback
    end

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0,120,0,35)
    btn.Position = UDim2.new(0,5,0,110)
    btn.Text = text
    btn.BackgroundColor3 = Color3.fromRGB(60,60,60)
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.Parent = parent
    if cb then
        btn.MouseButton1Click:Connect(cb)
    end
    return btn
end

-- Add Label
function Library:AddLabel(tabOrText, text)
    local parent = self.Frame
    local txt = tabOrText
    if typeof(tabOrText) == "Instance" then
        parent = tabOrText
        txt = text
    end

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,-10,0,20)
    lbl.Position = UDim2.new(0,5,0,150)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = Color3.fromRGB(255,255,255)
    lbl.Text = txt
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 14
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = parent
    return lbl
end

return Library
