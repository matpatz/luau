--[[ 
    Simple UI Library
    Features: Tabs, Sections, Themes, Toggles, Buttons, Sliders, Dropdowns
--]]

local Library = {}
Library.__index = Library

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- Theme defaults
Library.Theme = {
    Background = Color3.fromRGB(30,30,30),
    Accent = Color3.fromRGB(0,170,255),
    TextColor = Color3.fromRGB(255,255,255),
    SectionColor = Color3.fromRGB(45,45,45),
    ToggleActive = Color3.fromRGB(0,170,255),
    ToggleInactive = Color3.fromRGB(80,80,80)
}

-- Create UI
function Library.new(title)
    local self = setmetatable({}, Library)

    -- Main ScreenGui
    self.ScreenGui = Instance.new("ScreenGui")
    self.ScreenGui.Name = title or "CustomUI"
    self.ScreenGui.ResetOnSpawn = false
    self.ScreenGui.Parent = game:GetService("CoreGui")

    -- Main Frame
    self.MainFrame = Instance.new("Frame")
    self.MainFrame.Size = UDim2.new(0,400,0,300)
    self.MainFrame.Position = UDim2.new(0.5, -200, 0.5, -150)
    self.MainFrame.BackgroundColor3 = self.Theme.Background
    self.MainFrame.Parent = self.ScreenGui

    -- UI Corner & Stroke
    local corner = Instance.new("UICorner", self.MainFrame)
    corner.CornerRadius = UDim.new(0,8)
    local stroke = Instance.new("UIStroke", self.MainFrame)
    stroke.Color = self.Theme.Accent
    stroke.Thickness = 2

    -- Tab holder
    self.TabHolder = Instance.new("Frame")
    self.TabHolder.Size = UDim2.new(1,0,0,40)
    self.TabHolder.BackgroundTransparency = 1
    self.TabHolder.Parent = self.MainFrame

    self.Tabs = {}
    self.CurrentTab = nil

    return self
end

-- Create a tab
function Library:CreateTab(tabName)
    local tabButton = Instance.new("TextButton")
    tabButton.Size = UDim2.new(0,100,1,0)
    tabButton.Position = UDim2.new(#self.Tabs*0,0,0,0)
    tabButton.BackgroundColor3 = self.Theme.SectionColor
    tabButton.Text = tabName
    tabButton.TextColor3 = self.Theme.TextColor
    tabButton.Parent = self.TabHolder

    local corner = Instance.new("UICorner", tabButton)
    corner.CornerRadius = UDim.new(0,6)

    local tabContent = Instance.new("Frame")
    tabContent.Size = UDim2.new(1,0,1,-40)
    tabContent.Position = UDim2.new(0,0,0,40)
    tabContent.BackgroundTransparency = 1
    tabContent.Visible = false
    tabContent.Parent = self.MainFrame

    self.Tabs[tabName] = tabContent

    tabButton.MouseButton1Click:Connect(function()
        for name,frame in pairs(self.Tabs) do
            frame.Visible = false
        end
        tabContent.Visible = true
        self.CurrentTab = tabContent
    end)

    return tabContent
end

-- Create section
function Library:CreateSection(tab, sectionName)
    local section = Instance.new("Frame")
    section.Size = UDim2.new(1, -20, 0, 100)
    section.Position = UDim2.new(0,10,0,0)
    section.BackgroundColor3 = self.Theme.SectionColor
    section.Parent = tab

    local corner = Instance.new("UICorner", section)
    corner.CornerRadius = UDim.new(0,6)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1,0,0,20)
    label.Position = UDim2.new(0,0,0,0)
    label.BackgroundTransparency = 1
    label.Text = sectionName
    label.TextColor3 = self.Theme.TextColor
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 16
    label.Parent = section

    return section
end

-- Toggle
function Library:CreateToggle(section, name, callback)
    local toggleFrame = Instance.new("Frame")
    toggleFrame.Size = UDim2.new(1,0,0,30)
    toggleFrame.Position = UDim2.new(0,0,0,20)
    toggleFrame.BackgroundTransparency = 1
    toggleFrame.Parent = section

    local toggleButton = Instance.new("TextButton")
    toggleButton.Size = UDim2.new(0,40,0,20)
    toggleButton.Position = UDim2.new(1,-50,0,5)
    toggleButton.BackgroundColor3 = self.Theme.ToggleInactive
    toggleButton.Text = ""
    toggleButton.Parent = toggleFrame

    local corner = Instance.new("UICorner", toggleButton)
    corner.CornerRadius = UDim.new(0,4)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1,-60,1,0)
    label.Position = UDim2.new(0,0,0,0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = self.Theme.TextColor
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = toggleFrame

    local toggled = false
    toggleButton.MouseButton1Click:Connect(function()
        toggled = not toggled
        toggleButton.BackgroundColor3 = toggled and self.Theme.ToggleActive or self.Theme.ToggleInactive
        if callback then callback(toggled) end
    end)
end

-- Button
function Library:CreateButton(section, name, callback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1,0,0,30)
    button.Position = UDim2.new(0,0,0,50)
    button.BackgroundColor3 = self.Theme.Accent
    button.TextColor3 = Color3.fromRGB(255,255,255)
    button.Text = name
    button.Parent = section

    local corner = Instance.new("UICorner", button)
    corner.CornerRadius = UDim.new(0,6)

    button.MouseButton1Click:Connect(function()
        if callback then callback() end
    end)
end

-- Slider
function Library:CreateSlider(section, name, min, max, callback)
    local sliderFrame = Instance.new("Frame")
    sliderFrame.Size = UDim2.new(1,0,0,30)
    sliderFrame.Position = UDim2.new(0,0,0,90)
    sliderFrame.BackgroundTransparency = 1
    sliderFrame.Parent = section

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1,-10,0,20)
    label.Position = UDim2.new(0,0,0,0)
    label.BackgroundTransparency = 1
    label.Text = name.." ("..min..")"
    label.TextColor3 = self.Theme.TextColor
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = sliderFrame

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1,0,0,6)
    bar.Position = UDim2.new(0,0,1,-10)
    bar.BackgroundColor3 = self.Theme.ToggleInactive
    bar.Parent = sliderFrame

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(0,0,1,0)
    fill.Position = UDim2.new(0,0,0,0)
    fill.BackgroundColor3 = self.Theme.Accent
    fill.Parent = bar

    local uicorner = Instance.new("UICorner", bar)
    uicorner.CornerRadius = UDim.new(0,3)
    local uicorner2 = Instance.new("UICorner", fill)
    uicorner2.CornerRadius = UDim.new(0,3)

    local dragging = false
    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
        end
    end)
    bar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local mouseX = math.clamp(input.Position.X - bar.AbsolutePosition.X,0,bar.AbsoluteSize.X)
            fill.Size = UDim2.new(mouseX/bar.AbsoluteSize.X,0,1,0)
            local value = math.floor(min + (max-min)*(mouseX/bar.AbsoluteSize.X))
            label.Text = name.." ("..value..")"
            if callback then callback(value) end
        end
    end)
end

-- Dropdown
function Library:CreateDropdown(section, name, options, callback)
    local dropdownFrame = Instance.new("Frame")
    dropdownFrame.Size = UDim2.new(1,0,0,30)
    dropdownFrame.Position = UDim2.new(0,0,0,130)
    dropdownFrame.BackgroundTransparency = 1
    dropdownFrame.Parent = section

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1,0,1,0)
    label.BackgroundColor3 = self.Theme.SectionColor
    label.Text = name
    label.TextColor3 = self.Theme.TextColor
    label.Parent = dropdownFrame

    local corner = Instance.new("UICorner", label)
    corner.CornerRadius = UDim.new(0,4)

    local open = false
    local optionFrame = Instance.new("Frame")
    optionFrame.Size = UDim2.new(1,0,0,#options*25)
    optionFrame.Position = UDim2.new(0,0,1,0)
    optionFrame.BackgroundColor3 = self.Theme.SectionColor
    optionFrame.Visible = false
    optionFrame.Parent = dropdownFrame

    local corner2 = Instance.new("UICorner", optionFrame)
    corner2.CornerRadius = UDim.new(0,4)

    for i,opt in ipairs(options) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1,0,0,25)
        btn.Position = UDim2.new(0,0,0,(i-1)*25)
        btn.Text = opt
        btn.TextColor3 = self.Theme.TextColor
        btn.BackgroundTransparency = 1
        btn.Parent = optionFrame

        btn.MouseButton1Click:Connect(function()
            label.Text = name.." ("..opt..")"
            optionFrame.Visible = false
            open = false
            if callback then callback(opt) end
        end)
    end

    label.MouseButton1Click:Connect(function()
        open = not open
        optionFrame.Visible = open
    end)
end

return Library
