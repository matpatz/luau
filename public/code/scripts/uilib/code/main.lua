local Library = {}
Library.__index = Library

function Library.new(windowTitle, TabsEnabled)
    local self = setmetatable({}, Library)
    self.TabsEnabled = TabsEnabled or false
    self.TabHeight = self.TabsEnabled and 30 or 0
    self.Tabs = {}
    
    self.ScreenGui = Instance.new("ScreenGui")
    self.ScreenGui.Name = "e"..math.random(1e9,2e9)
    self.ScreenGui.ResetOnSpawn = false
    self.ScreenGui.Parent = game.CoreGui

    self.Frame = Instance.new("Frame")
    self.Frame.Size = UDim2.new(0, 520, 0, 320)
    self.Frame.Position = UDim2.new(0.3, 0, 0.2, 0)
    self.Frame.BackgroundColor3 = Color3.fromRGB(28,28,28)
    self.Frame.Active = true
    self.Frame.Draggable = true
    self.Frame.Parent = self.ScreenGui
    Instance.new("UICorner", self.Frame).CornerRadius = UDim.new(0,8)

    self.Title = Instance.new("TextLabel")
    self.Title.Text = windowTitle or "Window"
    self.Title.Size = UDim2.new(1, -40, 0, 30)
    self.Title.Position = UDim2.new(0, 10, 0, 0)
    self.Title.BackgroundTransparency = 1
    self.Title.TextColor3 = Color3.fromRGB(255,255,255)
    self.Title.TextXAlignment = Enum.TextXAlignment.Left
    self.Title.Font = Enum.Font.GothamBold
    self.Title.TextSize = 18
    self.Title.Parent = self.Frame

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

function Library:AddTab(tabName)
    if not self.TabsEnabled then return end
    local tabButton = Instance.new("TextButton")
    tabButton.Size = UDim2.new(0,120,1,0)
    tabButton.Position = UDim2.new(#self.Tabs * 0.22,0,0,0)
    tabButton.Text = tabName
    tabButton.Parent = self.TabBar
    self.Tabs[#self.Tabs+1] = tabButton
    return tabButton
end

function Library:GetContentOffset()
    return 30 + self.TabHeight
end

return Library
