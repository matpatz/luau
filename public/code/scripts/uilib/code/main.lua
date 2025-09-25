local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local Library = {}
Library.__index = Library

function Library:CreateWindow(config)
    config = config or {}
    local title = config.Title or "Window"
    local size = config.Size or UDim2.new(0, 520, 0, 320)
    local tabsEnabled = (config.TabsEnabled ~= false)

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "e" .. math.random(1e9, 2e9)
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = game.CoreGui

    local Frame = Instance.new("Frame")
    Frame.Size = size
    Frame.Position = UDim2.new(0.3, 0, 0.2, 0)
    Frame.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
    Frame.Active = true
    Frame.Draggable = true
    Frame.Parent = ScreenGui
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 8)

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Text = title
    TitleLabel.Size = UDim2.new(1, -40, 0, 30)
    TitleLabel.Position = UDim2.new(0, 10, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextSize = 18
    TitleLabel.Parent = Frame

    local CloseButton = Instance.new("TextButton")
    CloseButton.Text = "X"
    CloseButton.Size = UDim2.new(0, 30, 0, 30)
    CloseButton.Position = UDim2.new(1, -30, 0, 0)
    CloseButton.BackgroundTransparency = 1
    CloseButton.TextColor3 = Color3.fromRGB(255, 50, 50)
    CloseButton.Font = Enum.Font.Gotham
    CloseButton.TextSize = 18
    CloseButton.Parent = Frame
    CloseButton.MouseButton1Click:Connect(function()
        TweenService:Create(Frame, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
        task.wait(0.3)
        ScreenGui:Destroy()
    end)

    local TabBar
    local Tabs = {}
    local ActiveTab

    if tabsEnabled then
        TabBar = Instance.new("Frame")
        TabBar.Size = UDim2.new(1, 0, 0, 30)
        TabBar.Position = UDim2.new(0, 0, 0, 30)
        TabBar.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        TabBar.BorderSizePixel = 0
        TabBar.Parent = Frame
    end

    local WindowObj = {
        Frame = Frame,
        TabsEnabled = tabsEnabled,
        Tabs = Tabs,
        ActiveTab = ActiveTab
    }
    setmetatable(WindowObj, Library)

    function WindowObj:AddTab(name)
        if not tabsEnabled then
            warn("Tabs disabled in config")
            return
        end

        local Button = Instance.new("TextButton")
        Button.Size = UDim2.new(0, 120, 1, 0)
        Button.Text = name
        Button.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
        Button.TextColor3 = Color3.fromRGB(255, 255, 255)
        Button.Font = Enum.Font.GothamBold
        Button.TextSize = 14
        Button.Parent = TabBar

        local Container = Instance.new("Frame")
        Container.Size = UDim2.new(1, -20, 1, tabsEnabled and -70 or -40)
        Container.Position = UDim2.new(0, 10, 0, tabsEnabled and 70 or 40)
        Container.BackgroundTransparency = 1
        Container.Visible = false
        Container.Parent = Frame

        Button.MouseButton1Click:Connect(function()
            if WindowObj.ActiveTab then
                WindowObj.ActiveTab.Container.Visible = false
            end
            Container.Visible = true
            WindowObj.ActiveTab = {Name = name, Container = Container}
        end)

        table.insert(WindowObj.Tabs, {Name = name, Button = Button, Container = Container})
        if not WindowObj.ActiveTab then
            Container.Visible = true
            WindowObj.ActiveTab = {Name = name, Container = Container}
        end
        return Container
    end

    if not tabsEnabled then
        local Container = Instance.new("Frame")
        Container.Size = UDim2.new(1, -20, 1, -40)
        Container.Position = UDim2.new(0, 10, 0, 40)
        Container.BackgroundTransparency = 1
        Container.Visible = true
        Container.Parent = Frame
        WindowObj.MainContainer = Container
    end

    return WindowObj
end

return Library
