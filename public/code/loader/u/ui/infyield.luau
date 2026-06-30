-- Infinite Yield UI Library - Fully Functional Rewrite
-- 2026 Compatible

local CoreGuiService = game:GetService("CoreGui")
local PlayersService = game:GetService("Players")
local TextService = game:GetService("TextService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local Library = {}
local Env = getfenv()

-- Theme system
local Theme = {
    Shade1 = Color3.fromRGB(36, 36, 37),
    Shade2 = Color3.fromRGB(46, 46, 47),
    Shade3 = Color3.fromRGB(78, 78, 79),
    Text1 = Color3.new(1, 1, 1),
    Text2 = Color3.new(0, 0, 0),
    Accent = Color3.fromRGB(150, 150, 151),
    Scroll = Color3.fromRGB(78, 78, 79),
}

local function RandomString()
    local Length = math.random(10, 20)
    local array = {}
    for Index = 1, Length do
        array[Index] = string.char(math.random(32, 126))
    end
    return table.concat(array)
end

local IyAssets = {
    ["bindsandplugins"] = "rbxassetid://5147695474",
    ["close"] = "rbxassetid://5054663650",
    ["editaliases"] = "rbxassetid://5147488658",
    ["editkeybinds"] = "rbxassetid://129697930",
    ["edittheme"] = "rbxassetid://4911962991",
    ["editwaypoints"] = "rbxassetid://5147488592",
    ["imgstudiopluginlogo"] = "rbxassetid://4113050383",
    ["logo"] = "rbxassetid://1352543873",
    ["minimize"] = "rbxassetid://2406617031",
    ["pin"] = "rbxassetid://6234691350",
    ["reference"] = "rbxassetid://3523243755",
    ["settings"] = "rbxassetid://1204397029",
}
local function GetAsset(name) return IyAssets[name] or "" end

function Library:CreateWindow(options)
    options = options or {}
    local CurrentVersion = options.Version or "6.4"
    local WindowTitle = options.Title or ("Infinite Yield FE v" .. CurrentVersion)
    local Prefix = options.Prefix or ";"

    -- State
    local Commands = {}
    local Aliases = {}
    local Keybinds = {}
    local Waypoints = {}
    local Plugins = {}
    local EventBinds = {}
    local StayOpen = false
    local SettingsOpen = false
    local Minimized = false
    local PinnedNotification = nil
    local CommandHistory = {}
    local HistoryIndex = 0
    local NotificationQueue = {}
    local CurrentNotification = nil

    -- Callbacks
    local OnCommandRun = options.OnCommandRun or function(cmd, args) end
    local OnPrefixChange = options.OnPrefixChange or function(new) end

    -- Emoji for title
    local function GetTitleEmoji()
        local md = os.date("%m %d")
        local yr = tonumber(os.date("%Y"))
        local emojiMap = {
            ["01 01"] = "🎆",
            ["10 31"] = "🎃",
            ["12 25"] = "🎄",
        }
        -- Easter calculation
        local A = math.floor(yr / 100)
        local B = math.floor((13 + 8 * A) / 25)
        local C = (15 - B + A - math.floor(A / 4)) % 30
        local D = (4 + A - math.floor(A / 4)) % 7
        local E = (19 * (yr % 19) + C) % 30
        local F = (2 * (yr % 4) + 4 * (yr % 7) + 6 * E + D) % 7
        local G = (22 + E + F)
        local easterDate
        if E == 29 and F == 6 then
            easterDate = "04 19"
        elseif E == 28 and F == 6 then
            easterDate = "04 18"
        elseif 31 < G then
            easterDate = ("04 %02d"):format(G - 31)
        else
            easterDate = ("03 %02d"):format(G)
        end
        emojiMap[easterDate] = "🥚"
        return emojiMap[md]
    end

    local emoji = GetTitleEmoji()
    local DisplayTitle = emoji and ("%s %s %s"):format(emoji, WindowTitle, emoji) or WindowTitle

    -- GUI Setup
    local ParentGui = CoreGuiService:FindFirstChild("RobloxGui") or CoreGuiService
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = RandomString()
    ScreenGui.ResetOnSpawn = false
    ScreenGui.DisplayOrder = 2147483647
    ScreenGui.Parent = ParentGui

    local ScaledHolder = Instance.new("Frame")
    ScaledHolder.Name = RandomString()
    ScaledHolder.Size = UDim2.fromScale(1, 1)
    ScaledHolder.BackgroundTransparency = 1
    ScaledHolder.Parent = ScreenGui

    -- All themed instances tracking
    local Themed = {Shade1 = {}, Shade2 = {}, Shade3 = {}, Text1 = {}, Text2 = {}, Scroll = {}}

    local function ApplyTheme()
        for _, v in pairs(Themed.Shade1) do if v and v.Parent then v.BackgroundColor3 = Theme.Shade1 end end
        for _, v in pairs(Themed.Shade2) do if v and v.Parent then v.BackgroundColor3 = Theme.Shade2 end end
        for _, v in pairs(Themed.Shade3) do if v and v.Parent then v.BackgroundColor3 = Theme.Shade3 end end
        for _, v in pairs(Themed.Text1) do if v and v.Parent then v.TextColor3 = Theme.Text1 end end
        for _, v in pairs(Themed.Text2) do if v and v.Parent then v.TextColor3 = Theme.Text2 end end
        for _, v in pairs(Themed.Scroll) do if v and v.Parent then v.ScrollBarImageColor3 = Theme.Scroll end end
    end

    local function MakeScrollFrame(props)
        local sf = Instance.new("ScrollingFrame")
        sf.BackgroundTransparency = 1
        sf.BorderSizePixel = 0
        sf.ScrollBarImageColor3 = Theme.Scroll
        sf.BottomImage = "rbxasset://textures/ui/Scroll/Scroll-middle.png"
        sf.MidImage = "rbxasset://textures/ui/Scroll/Scroll-middle.png"
        sf.TopImage = "rbxasset://textures/ui/Scroll/Scroll-middle.png"
        sf.VerticalScrollBarInset = Enum.ScrollBarInset.Always
        sf.ScrollBarThickness = 8
        sf.CanvasSize = UDim2.new(0, 0, 0, 0)
        for k, v in pairs(props or {}) do sf[k] = v end
        table.insert(Themed.Scroll, sf)
        return sf
    end

    local function MakeButton(props)
        local btn = Instance.new("TextButton")
        btn.BackgroundColor3 = Theme.Shade2
        btn.BorderSizePixel = 0
        btn.Font = Enum.Font.SourceSans
        btn.TextSize = 14
        btn.TextColor3 = Theme.Text1
        btn.AutoButtonColor = true
        for k, v in pairs(props or {}) do btn[k] = v end
        table.insert(Themed.Shade2, btn)
        table.insert(Themed.Text1, btn)
        return btn
    end

    local function MakeSmallButton(props)
        local btn = Instance.new("TextButton")
        btn.BackgroundColor3 = Theme.Shade3
        btn.BorderSizePixel = 0
        btn.Font = Enum.Font.SourceSans
        btn.TextSize = 14
        btn.TextColor3 = Theme.Text2
        btn.AutoButtonColor = true
        for k, v in pairs(props or {}) do btn[k] = v end
        table.insert(Themed.Shade3, btn)
        table.insert(Themed.Text2, btn)
        return btn
    end

    local function MakeLabel(props)
        local lbl = Instance.new("TextLabel")
        lbl.BackgroundTransparency = 1
        lbl.Font = Enum.Font.SourceSans
        lbl.TextSize = 14
        lbl.TextColor3 = Theme.Text1
        for k, v in pairs(props or {}) do lbl[k] = v end
        table.insert(Themed.Text1, lbl)
        return lbl
    end

    -- ============ MAIN HOLDER ============
    local Holder = Instance.new("Frame")
    Holder.Name = RandomString()
    Holder.Active = true
    Holder.BackgroundColor3 = Theme.Shade2
    Holder.BorderSizePixel = 0
    Holder.Position = UDim2.new(1, -250, 1, -220)
    Holder.Size = UDim2.new(0, 250, 0, 220)
    Holder.ZIndex = 10
    table.insert(Themed.Shade2, Holder)
    Holder.Parent = ScaledHolder

    -- Make draggable
    local dragging, dragInput, dragStart, startPos
    Holder.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = Holder.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    Holder.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            Holder.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)

    -- ============ TITLE BAR ============
    local TitleBar = Instance.new("Frame")
    TitleBar.Name = "TitleBar"
    TitleBar.Size = UDim2.new(0, 250, 0, 20)
    TitleBar.BackgroundColor3 = Theme.Shade1
    TitleBar.BorderSizePixel = 0
    TitleBar.ZIndex = 10
    table.insert(Themed.Shade1, TitleBar)
    TitleBar.Parent = Holder

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Name = "Title"
    TitleLabel.Size = UDim2.new(0, 195, 0, 20)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Font = Enum.Font.SourceSans
    TitleLabel.TextSize = 18
    TitleLabel.Text = DisplayTitle
    TitleLabel.TextColor3 = Theme.Text1
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.ZIndex = 10
    table.insert(Themed.Text1, TitleLabel)
    TitleLabel.Parent = TitleBar

    local SettingsBtn = Instance.new("ImageButton")
    SettingsBtn.Name = "SettingsButton"
    SettingsBtn.Size = UDim2.new(0, 20, 0, 20)
    SettingsBtn.Position = UDim2.new(0, 230, 0, 0)
    SettingsBtn.BackgroundTransparency = 1
    SettingsBtn.Image = GetAsset("settings")
    SettingsBtn.ZIndex = 10
    SettingsBtn.Parent = TitleBar

    local MinimizeBtn = Instance.new("ImageButton")
    MinimizeBtn.Name = "MinimizeButton"
    MinimizeBtn.Size = UDim2.new(0, 20, 0, 20)
    MinimizeBtn.Position = UDim2.new(0, 212, 0, 2)
    MinimizeBtn.BackgroundTransparency = 1
    MinimizeBtn.Image = GetAsset("minimize")
    MinimizeBtn.ZIndex = 10
    MinimizeBtn.Parent = TitleBar

    -- ============ COMMAND BAR ============
    local Cmdbar = Instance.new("TextBox")
    Cmdbar.Name = "Cmdbar"
    Cmdbar.BackgroundTransparency = 1
    Cmdbar.BorderSizePixel = 0
    Cmdbar.Position = UDim2.new(0, 5, 0, 20)
    Cmdbar.Size = UDim2.new(0, 240, 0, 25)
    Cmdbar.Font = Enum.Font.SourceSans
    Cmdbar.TextSize = 18
    Cmdbar.TextXAlignment = Enum.TextXAlignment.Left
    Cmdbar.TextColor3 = Theme.Text1
    Cmdbar.Text = ""
    Cmdbar.PlaceholderText = Prefix .. " Command Bar"
    Cmdbar.ZIndex = 10
    Cmdbar.ClearTextOnFocus = false
    table.insert(Themed.Text1, Cmdbar)
    Cmdbar.Parent = Holder

    -- ============ COMMAND LIST ============
    local CMDsF = MakeScrollFrame({
        Name = "CMDs",
        Position = UDim2.new(0, 5, 0, 45),
        Size = UDim2.new(0, 245, 0, 175),
        ZIndex = 10,
    })
    CMDsF.Parent = Holder

    local CmdListLayout = Instance.new("UIListLayout")
    CmdListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    CmdListLayout.Parent = CMDsF

    -- ============ DARK BACKGROUND (behind cmd list) ============
    local Dark = Instance.new("Frame")
    Dark.Name = "Dark"
    Dark.Active = true
    Dark.BackgroundColor3 = Theme.Shade1
    Dark.BorderSizePixel = 0
    Dark.Position = UDim2.new(0, 0, 0, 45)
    Dark.Size = UDim2.new(0, 250, 0, 175)
    Dark.ZIndex = 9
    table.insert(Themed.Shade1, Dark)
    Dark.Parent = Holder

    CMDsF.ZIndex = 10

    -- ============ SETTINGS PANEL ============
    local Settings = Instance.new("Frame")
    Settings.Name = "Settings"
    Settings.Active = true
    Settings.BackgroundColor3 = Theme.Shade1
    Settings.BorderSizePixel = 0
    Settings.Position = UDim2.new(0, 0, 0, 220)
    Settings.Size = UDim2.new(0, 250, 0, 175)
    Settings.Visible = false
    Settings.ZIndex = 10
    table.insert(Themed.Shade1, Settings)
    Settings.Parent = Holder

    -- Settings title
    local SettingsTitle = Instance.new("Frame")
    SettingsTitle.Size = UDim2.new(0, 250, 0, 20)
    SettingsTitle.BackgroundColor3 = Theme.Shade2
    SettingsTitle.BorderSizePixel = 0
    SettingsTitle.ZIndex = 10
    table.insert(Themed.Shade2, SettingsTitle)
    SettingsTitle.Parent = Settings

    local SettingsTitleLabel = Instance.new("TextLabel")
    SettingsTitleLabel.Size = UDim2.new(0, 220, 0, 20)
    SettingsTitleLabel.BackgroundTransparency = 1
    SettingsTitleLabel.Font = Enum.Font.SourceSans
    SettingsTitleLabel.TextSize = 14
    SettingsTitleLabel.Text = "Settings"
    SettingsTitleLabel.TextColor3 = Theme.Text1
    SettingsTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    SettingsTitleLabel.ZIndex = 10
    table.insert(Themed.Text1, SettingsTitleLabel)
    SettingsTitleLabel.Parent = SettingsTitle

    local SettingsCloseBtn = MakeSmallButton({
        Size = UDim2.new(0, 20, 0, 20),
        Position = UDim2.new(1, -20, 0, 0),
        Text = "X",
        ZIndex = 10,
    })
    SettingsCloseBtn.Parent = SettingsTitle

    local SettingsHolder = MakeScrollFrame({
        Name = "Holder",
        Size = UDim2.new(1, 0, 1, -20),
        Position = UDim2.new(0, 0, 0, 20),
        CanvasSize = UDim2.new(0, 0, 0, 235),
        ZIndex = 10,
    })
    SettingsHolder.Parent = Settings

    -- Settings: Prefix
    local PrefixLabel = MakeLabel({
        Text = "Prefix",
        Size = UDim2.new(1, -10, 0, 20),
        Position = UDim2.new(0, 5, 0, 5),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 10,
    })
    PrefixLabel.Parent = SettingsHolder

    local PrefixBox = Instance.new("TextBox")
    PrefixBox.Name = "PrefixBox"
    PrefixBox.BackgroundColor3 = Theme.Shade3
    PrefixBox.BorderSizePixel = 0
    PrefixBox.Position = UDim2.new(1, -20, 0, 5)
    PrefixBox.Size = UDim2.new(0, 20, 0, 20)
    PrefixBox.Font = Enum.Font.SourceSansBold
    PrefixBox.TextSize = 14
    PrefixBox.Text = Prefix
    PrefixBox.TextColor3 = Theme.Text2
    PrefixBox.ZIndex = 10
    table.insert(Themed.Shade3, PrefixBox)
    table.insert(Themed.Text2, PrefixBox)
    PrefixBox.Parent = SettingsHolder

    PrefixBox.FocusLost:Connect(function(enter)
        if enter and #PrefixBox.Text > 0 then
            Prefix = PrefixBox.Text
            Cmdbar.PlaceholderText = Prefix .. " Command Bar"
            OnPrefixChange(Prefix)
        else
            PrefixBox.Text = Prefix
        end
    end)

    -- Settings: Stay Open toggle
    local StayOpenLabel = MakeLabel({
        Text = "Keep Menu Open",
        Size = UDim2.new(1, -10, 0, 20),
        Position = UDim2.new(0, 5, 0, 30),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 10,
    })
    StayOpenLabel.Parent = SettingsHolder

    local StayOpenBtnBg = Instance.new("Frame")
    StayOpenBtnBg.BackgroundColor3 = Theme.Shade3
    StayOpenBtnBg.BorderSizePixel = 0
    StayOpenBtnBg.Size = UDim2.new(0, 20, 0, 20)
    StayOpenBtnBg.Position = UDim2.new(1, -20, 0, 30)
    StayOpenBtnBg.ZIndex = 10
    table.insert(Themed.Shade3, StayOpenBtnBg)
    StayOpenBtnBg.Parent = SettingsHolder

    local StayOpenToggle = Instance.new("TextButton")
    StayOpenToggle.BackgroundTransparency = 1
    StayOpenToggle.Size = UDim2.new(0, 16, 0, 16)
    StayOpenToggle.Position = UDim2.new(0, 2, 0, 2)
    StayOpenToggle.Text = ""
    StayOpenToggle.ZIndex = 10
    StayOpenToggle.Parent = StayOpenBtnBg

    local function UpdateStayOpenVisual()
        if StayOpen then
            StayOpenToggle.Text = "✓"
            StayOpenToggle.TextColor3 = Theme.Text1
        else
            StayOpenToggle.Text = ""
        end
    end

    StayOpenToggle.MouseButton1Click:Connect(function()
        StayOpen = not StayOpen
        UpdateStayOpenVisual()
    end)

    -- Helper: settings row button with icon
    local function MakeSettingsRow(name, iconAsset, yOffset, iconOffset)
        local row = Instance.new("TextButton")
        row.BackgroundColor3 = Theme.Shade2
        row.BorderSizePixel = 0
        row.Size = UDim2.new(1, -10, 0, 25)
        row.Position = UDim2.new(0, 5, 0, yOffset)
        row.Text = ""
        row.ZIndex = 10
        row.AutoButtonColor = true
        table.insert(Themed.Shade2, row)
        row.Parent = SettingsHolder

        local icon = Instance.new("ImageLabel")
        icon.Size = UDim2.new(0, 16, 0, 16)
        icon.Position = UDim2.new(0, 5, 0, 5)
        icon.BackgroundTransparency = 1
        icon.Image = iconAsset
        icon.ZIndex = 10
        if iconOffset then
            icon.ScaleType = Enum.ScaleType.Crop
            icon.ImageRectSize = Vector2.new(16, 16)
            icon.ImageRectOffset = Vector2.new(iconOffset, 0)
        end
        icon.Parent = row

        local lbl = MakeLabel({
            Text = name,
            Position = UDim2.new(0, 28, 0, 0),
            Size = UDim2.new(1, -28, 1, 0),
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 10,
        })
        lbl.Parent = row

        return row
    end

    local ColorsBtn = MakeSettingsRow("Edit Theme", GetAsset("edittheme"), 55)
    local KeybindsBtn = MakeSettingsRow("Edit Keybinds", GetAsset("editkeybinds"), 85)
    local AliasesBtn = MakeSettingsRow("Edit Aliases", GetAsset("editaliases"), 115)
    local WaypointsBtn = MakeSettingsRow("Edit/Goto Waypoints", GetAsset("editwaypoints"), 145)
    local PluginsBtn = MakeSettingsRow("Manage Plugins", GetAsset("bindsandplugins"), 175, 743)
    local EventBindsBtn = MakeSettingsRow("Edit Event Binds", GetAsset("bindsandplugins"), 205, 759)

    -- ============ TOOLTIP ============
    local Tooltip = Instance.new("Frame")
    Tooltip.Name = RandomString()
    Tooltip.Active = true
    Tooltip.BackgroundColor3 = Theme.Shade1
    Tooltip.BackgroundTransparency = 0.1
    Tooltip.BorderSizePixel = 0
    Tooltip.Size = UDim2.new(0, 200, 0, 96)
    Tooltip.Visible = false
    Tooltip.ZIndex = 100
    table.insert(Themed.Shade1, Tooltip)
    Tooltip.Parent = ScaledHolder

    local TooltipTitle = Instance.new("Frame")
    TooltipTitle.Size = UDim2.new(0, 200, 0, 20)
    TooltipTitle.BackgroundColor3 = Theme.Shade2
    TooltipTitle.BackgroundTransparency = 0.1
    TooltipTitle.BorderSizePixel = 0
    TooltipTitle.ZIndex = 100
    table.insert(Themed.Shade2, TooltipTitle)
    TooltipTitle.Parent = Tooltip

    local TooltipTitleLabel = MakeLabel({
        Size = UDim2.new(0, 190, 0, 20),
        Position = UDim2.new(0, 5, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTransparency = 0.1,
        ZIndex = 100,
    })
    TooltipTitleLabel.Parent = TooltipTitle

    local TooltipDesc = MakeLabel({
        Size = UDim2.new(0, 180, 0, 72),
        Position = UDim2.new(0, 10, 0, 18),
        TextWrapped = true,
        TextTransparency = 0.1,
        TextYAlignment = Enum.TextYAlignment.Top,
        ZIndex = 100,
    })
    TooltipDesc.Parent = Tooltip

    local function ShowTooltip(title, desc, x, y)
        TooltipTitleLabel.Text = title
        TooltipDesc.Text = desc or ""
        local textSize = TextService:GetTextSize(TooltipDesc.Text, 16, Enum.Font.SourceSans, Vector2.new(180, 1000))
        local neededHeight = math.max(96, textSize.Y + 24)
        Tooltip.Size = UDim2.new(0, 200, 0, neededHeight)
        TooltipDesc.Size = UDim2.new(0, 180, 0, neededHeight - 24)
        -- Position tooltip
        local viewportSize = workspace.CurrentCamera.ViewportSize
        local posX = math.min(x + 15, viewportSize.X - 210)
        local posY = math.max(y - neededHeight - 5, 5)
        if posY < 5 then
            posY = math.min(y + 25, viewportSize.Y - neededHeight - 5)
        end
        Tooltip.Position = UDim2.new(0, posX, 0, posY)
        Tooltip.Visible = true
    end

    local function HideTooltip()
        Tooltip.Visible = false
    end

    -- ============ NOTIFICATION ============
    local Notification = Instance.new("Frame")
    Notification.Name = RandomString()
    Notification.BackgroundColor3 = Theme.Shade1
    Notification.BorderSizePixel = 0
    Notification.Position = UDim2.new(1, -500, 1, 20)
    Notification.Size = UDim2.new(0, 250, 0, 100)
    Notification.Visible = false
    Notification.ZIndex = 50
    table.insert(Themed.Shade1, Notification)
    Notification.Parent = ScaledHolder

    local NotifTitle = Instance.new("Frame")
    NotifTitle.Size = UDim2.new(0, 250, 0, 20)
    NotifTitle.BackgroundColor3 = Theme.Shade2
    NotifTitle.BorderSizePixel = 0
    NotifTitle.ZIndex = 50
    table.insert(Themed.Shade2, NotifTitle)
    NotifTitle.Parent = Notification

    local NotifTitleLabel = MakeLabel({
        Size = UDim2.new(0, 190, 0, 20),
        Position = UDim2.new(0, 5, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 50,
    })
    NotifTitleLabel.Parent = NotifTitle

    local NotifText = MakeLabel({
        Position = UDim2.new(0, 5, 0, 25),
        Size = UDim2.new(0, 240, 0, 75),
        TextWrapped = true,
        TextYAlignment = Enum.TextYAlignment.Top,
        ZIndex = 50,
    })
    NotifText.Parent = Notification

    local NotifCloseBtn = Instance.new("TextButton")
    NotifCloseBtn.BackgroundTransparency = 1
    NotifCloseBtn.Size = UDim2.new(0, 20, 0, 20)
    NotifCloseBtn.Position = UDim2.new(1, -20, 0, 0)
    NotifCloseBtn.Text = ""
    NotifCloseBtn.ZIndex = 50
    NotifCloseBtn.Parent = NotifTitle

    local NotifCloseImg = Instance.new("ImageLabel")
    NotifCloseImg.BackgroundTransparency = 1
    NotifCloseImg.Size = UDim2.new(0, 10, 0, 10)
    NotifCloseImg.Position = UDim2.new(0, 5, 0, 5)
    NotifCloseImg.Image = GetAsset("close")
    NotifCloseImg.ZIndex = 50
    NotifCloseImg.Parent = NotifCloseBtn

    local NotifPinBtn = Instance.new("TextButton")
    NotifPinBtn.BackgroundTransparency = 1
    NotifPinBtn.Size = UDim2.new(0, 20, 0, 20)
    NotifPinBtn.Position = UDim2.new(1, -40, 0, 0)
    NotifPinBtn.Text = ""
    NotifPinBtn.ZIndex = 50
    NotifPinBtn.Parent = NotifTitle

    local NotifPinImg = Instance.new("ImageLabel")
    NotifPinImg.BackgroundTransparency = 1
    NotifPinImg.Size = UDim2.new(0, 14, 0, 14)
    NotifPinImg.Position = UDim2.new(0, 3, 0, 3)
    NotifPinImg.Image = GetAsset("pin")
    NotifPinImg.ZIndex = 50
    NotifPinImg.Parent = NotifPinBtn

    -- Notification draggable
    local notifDragging, notifDragInput, notifDragStart, notifStartPos
    NotifTitle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            notifDragging = true
            notifDragStart = input.Position
            notifStartPos = Notification.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then notifDragging = false end
            end)
        end
    end)
    NotifTitle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then notifDragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == notifDragInput and notifDragging then
            local delta = input.Position - notifDragStart
            Notification.Position = UDim2.new(
                notifStartPos.X.Scale, notifStartPos.X.Offset + delta.X,
                notifStartPos.Y.Scale, notifStartPos.Y.Offset + delta.Y
            )
        end
    end)

    local NotifDismissTime = 4
    local NotifTimer = nil

    local function DismissNotification()
        if PinnedNotification then return end
        if NotifTimer then
            NotifTimer:Disconnect()
            NotifTimer = nil
        end
        Notification.Visible = false
        CurrentNotification = nil
        -- Process queue
        if #NotificationQueue > 0 then
            local next = table.remove(NotificationQueue, 1)
            Library.Notify(next.Title, next.Text, next.Duration)
        end
    end

    NotifCloseBtn.MouseButton1Click:Connect(function()
        PinnedNotification = nil
        DismissNotification()
    end)

    NotifPinBtn.MouseButton1Click:Connect(function()
        if PinnedNotification then
            PinnedNotification = nil
            NotifPinImg.ImageTransparency = 0
            if NotifTimer then NotifTimer:Disconnect() NotifTimer = nil end
            NotifTimer = spawn(function()
                wait(NotifDismissTime)
                DismissNotification()
            end)
        else
            PinnedNotification = true
            NotifPinImg.ImageTransparency = 0.5
            if NotifTimer then NotifTimer:Disconnect() NotifTimer = nil end
        end
    end)

    function Library.Notify(title, text, duration)
        duration = duration or NotifDismissTime
        if CurrentNotification and not PinnedNotification then
            table.insert(NotificationQueue, {Title = title, Text = text, Duration = duration})
            return
        elseif CurrentNotification and PinnedNotification then
            table.insert(NotificationQueue, {Title = title, Text = text, Duration = duration})
            return
        end
        CurrentNotification = {Title = title, Text = text}
        NotifTitleLabel.Text = title or "Notification"
        NotifText.Text = text or ""
        -- Auto-size notification height
        local textSize = TextService:GetTextSize(NotifText.Text, 16, Enum.Font.SourceSans, Vector2.new(240, 1000))
        local neededHeight = math.max(60, textSize.Y + 30)
        Notification.Size = UDim2.new(0, 250, 0, neededHeight)
        NotifText.Size = UDim2.new(0, 240, 0, neededHeight - 30)
        Notification.Position = UDim2.new(1, -500, 1, 20)
        Notification.Visible = true
        PinnedNotification = nil
        NotifPinImg.ImageTransparency = 0
        -- Slide in
        local tweenIn = TweenService:Create(Notification, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
            Position = UDim2.new(1, -260, 1, -neededHeight - 10)
        })
        tweenIn:Play()
        if NotifTimer then NotifTimer:Disconnect() end
        NotifTimer = spawn(function()
            wait(duration)
            DismissNotification()
        end)
    end

    -- ============ SUB-FRAMES (Keybinds, Aliases, Waypoints, Plugins) ============
    -- These are rendered inside the Settings panel area

    local SubFrames = {}
    local function CreateSubFrame(name)
        local frame = Instance.new("Frame")
        frame.Name = name
        frame.Active = true
        frame.BackgroundColor3 = Theme.Shade1
        frame.BorderSizePixel = 0
        frame.Size = UDim2.new(0, 250, 0, 175)
        frame.Position = UDim2.new(0, 0, 0, 175)
        frame.Visible = false
        frame.ZIndex = 11
        table.insert(Themed.Shade1, frame)
        frame.Parent = Settings

        -- Title bar
        local titleBar = Instance.new("Frame")
        titleBar.Size = UDim2.new(0, 250, 0, 20)
        titleBar.BackgroundColor3 = Theme.Shade2
        titleBar.BorderSizePixel = 0
        titleBar.ZIndex = 11
        table.insert(Themed.Shade2, titleBar)
        titleBar.Parent = frame

        local titleLbl = MakeLabel({
            Text = name,
            Size = UDim2.new(0, 210, 0, 20),
            Position = UDim2.new(0, 5, 0, 0),
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 11,
        })
        titleLbl.Parent = titleBar

        local closeBtn = MakeSmallButton({
            Size = UDim2.new(0, 20, 0, 20),
            Position = UDim2.new(1, -20, 0, 0),
            Text = "X",
            ZIndex = 11,
        })
        closeBtn.Parent = titleBar

        local listFrame = MakeScrollFrame({
            Size = UDim2.new(0, 250, 0, 145),
            Position = UDim2.new(0, 0, 0, 20),
            ScrollBarThickness = 0,
            ZIndex = 11,
        })
        listFrame.Parent = frame

        local listLayout = Instance.new("UIListLayout")
        listLayout.SortOrder = Enum.SortOrder.LayoutOrder
        listLayout.Parent = listFrame

        SubFrames[name] = {
            Frame = frame,
            List = listFrame,
            Layout = listLayout,
            CloseBtn = closeBtn,
            TitleLabel = titleLbl,
        }

        closeBtn.MouseButton1Click:Connect(function()
            frame.Visible = false
        end)

        return SubFrames[name]
    end

    local KeybindsFrame = CreateSubFrame("Keybinds")
    local AliasesFrame = CreateSubFrame("Aliases")
    local WaypointsFrame = CreateSubFrame("Waypoints")
    local PluginsFrame = CreateSubFrame("Plugins")
    local EventBindsFrame = CreateSubFrame("Event Binds")

    -- Add button rows to sub-frames
    local function AddSubFrameButtons(frameData, buttons)
        local yOff = 0
        for i, btnData in ipairs(buttons) do
            local btn = MakeButton({
                Text = btnData.Text,
                Size = UDim2.new(0, btnData.Width or 40, 0, 20),
                Position = UDim2.new(0, 5 + (i - 1) * ((btnData.Width or 40) + 5), 0, 150),
                ZIndex = 11,
            })
            btn.Parent = frameData.Frame
            if btnData.Callback then
                btn.MouseButton1Click:Connect(btnData.Callback)
            end
        end
    end

    AddSubFrameButtons(KeybindsFrame, {
        {Text = "Add", Callback = function()
            Library.Notify("Keybinds", "Use the keybind editor popup to add keybinds.", 3)
        end},
        {Text = "Clear", Callback = function()
            Keybinds = {}
            RefreshKeybindsList()
            Library.Notify("Keybinds", "All keybinds cleared.", 2)
        end},
    })

    AddSubFrameButtons(AliasesFrame, {
        {Text = "Clear", Callback = function()
            Aliases = {}
            RefreshAliasesList()
            Library.Notify("Aliases", "All aliases cleared.", 2)
        end},
    })

    AddSubFrameButtons(WaypointsFrame, {
        {Text = "Part", Callback = function()
            Library.Notify("Waypoints", "Select a part in the game to save as a waypoint.", 3)
        end},
        {Text = "Clear", Callback = function()
            Waypoints = {}
            RefreshWaypointsList()
            Library.Notify("Waypoints", "All waypoints cleared.", 2)
        end},
    })

    AddSubFrameButtons(PluginsFrame, {
        {Text = "Add", Callback = function()
            Library.Notify("Plugins", "Use the plugin editor to add .iy plugin files.", 3)
        end},
        {Text = "Clear", Callback = function()
            Plugins = {}
            RefreshPluginsList()
            Library.Notify("Plugins", "All plugins cleared.", 2)
        end},
    })

    AddSubFrameButtons(EventBindsFrame, {
        {Text = "Add", Callback = function()
            Library.Notify("Event Binds", "Event binds allow binding commands to game events.", 3)
        end},
        {Text = "Clear", Callback = function()
            EventBinds = {}
            RefreshEventBindsList()
            Library.Notify("Event Binds", "All event binds cleared.", 2)
        end},
    })

    -- Hints for empty sub-frames
    local function AddHint(frameData, text)
        local hint = MakeLabel({
            Text = text,
            Size = UDim2.new(0, 200, 0, 50),
            Position = UDim2.new(0, 25, 0, 40),
            Font = Enum.Font.SourceSansItalic,
            TextSize = 16,
            TextWrapped = true,
            ZIndex = 11,
        })
        hint.Parent = frameData.Frame
        hint.Name = "Hint"
        return hint
    end

    AddHint(AliasesFrame, "Add aliases using the 'addalias' command")
    AddHint(PluginsFrame, "Add plugins using the 'addplugin' command")
    AddHint(WaypointsFrame, "Save waypoints using the 'waypoint' command")
    AddHint(KeybindsFrame, "Add keybinds using the 'bind' command")
    AddHint(EventBindsFrame, "Add event binds using the 'eventbind' command")

    -- ============ REFRESH FUNCTIONS FOR SUB-FRAMES ============
    local function ClearList(frameData)
        for _, child in pairs(frameData.List:GetChildren()) do
            if child:IsA("Frame") or child:IsA("TextButton") then
                child:Destroy()
            end
        end
        local hint = frameData.Frame:FindFirstChild("Hint")
        if hint then hint.Visible = true end
    end

    function RefreshKeybindsList()
        ClearList(KeybindsFrame)
        for i, kb in ipairs(Keybinds) do
            local hint = KeybindsFrame.Frame:FindFirstChild("Hint")
            if hint then hint.Visible = false end
            local row = Instance.new("Frame")
            row.BackgroundColor3 = Theme.Shade2
            row.BorderSizePixel = 0
            row.Size = UDim2.new(0, 250, 0, 20)
            row.ZIndex = 11
            table.insert(Themed.Shade2, row)
            row.Parent = KeybindsFrame.List

            local lbl = MakeLabel({
                Text = tostring(kb.Key) .. " > " .. tostring(kb.Command),
                Size = UDim2.new(0, 200, 0, 20),
                Position = UDim2.new(0, 5, 0, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 11,
            })
            lbl.Parent = row

            local del = MakeSmallButton({
                Text = "Delete",
                Size = UDim2.new(0, 40, 0, 20),
                Position = UDim2.new(0, 200, 0, 0),
                ZIndex = 11,
            })
            del.Parent = row
            del.MouseButton1Click:Connect(function()
                table.remove(Keybinds, i)
                RefreshKeybindsList()
            end)
        end
    end

    function RefreshAliasesList()
        ClearList(AliasesFrame)
        for alias, cmd in pairs(Aliases) do
            local hint = AliasesFrame.Frame:FindFirstChild("Hint")
            if hint then hint.Visible = false end
            local row = Instance.new("Frame")
            row.BackgroundColor3 = Theme.Shade2
            row.BorderSizePixel = 0
            row.Size = UDim2.new(0, 250, 0, 20)
            row.ZIndex = 11
            table.insert(Themed.Shade2, row)
            row.Parent = AliasesFrame.List

            local lbl = MakeLabel({
                Text = alias .. " > " .. cmd,
                Size = UDim2.new(0, 200, 0, 20),
                Position = UDim2.new(0, 5, 0, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 11,
            })
            lbl.Parent = row

            local capturedAlias = alias
            local del = MakeSmallButton({
                Text = "Delete",
                Size = UDim2.new(0, 40, 0, 20),
                Position = UDim2.new(0, 200, 0, 0),
                ZIndex = 11,
            })
            del.Parent = row
            del.MouseButton1Click:Connect(function()
                Aliases[capturedAlias] = nil
                RefreshAliasesList()
            end)
        end
    end

    function RefreshWaypointsList()
        ClearList(WaypointsFrame)
        for name, pos in pairs(Waypoints) do
            local hint = WaypointsFrame.Frame:FindFirstChild("Hint")
            if hint then hint.Visible = false end
            local row = Instance.new("Frame")
            row.BackgroundColor3 = Theme.Shade2
            row.BorderSizePixel = 0
            row.Size = UDim2.new(0, 250, 0, 20)
            row.ZIndex = 11
            table.insert(Themed.Shade2, row)
            row.Parent = WaypointsFrame.List

            local lbl = MakeLabel({
                Text = name .. " [" .. math.floor(pos.X) .. ", " .. math.floor(pos.Y) .. ", " .. math.floor(pos.Z) .. "]",
                Size = UDim2.new(0, 150, 0, 20),
                Position = UDim2.new(0, 5, 0, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 11,
            })
            lbl.Parent = row

            local capturedName = name
            local capturedPos = pos

            local gotoBtn = MakeSmallButton({
                Text = "Goto",
                Size = UDim2.new(0, 40, 0, 20),
                Position = UDim2.new(0, 155, 0, 0),
                ZIndex = 11,
            })
            gotoBtn.Parent = row
            gotoBtn.MouseButton1Click:Connect(function()
                local char = PlayersService.LocalPlayer.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    char.HumanoidRootPart.CFrame = CFrame.new(capturedPos)
                    Library.Notify("Waypoints", "Teleported to " .. capturedName, 2)
                end
            end)

            local del = MakeSmallButton({
                Text = "Delete",
                Size = UDim2.new(0, 40, 0, 20),
                Position = UDim2.new(0, 200, 0, 0),
                ZIndex = 11,
            })
            del.Parent = row
            del.MouseButton1Click:Connect(function()
                Waypoints[capturedName] = nil
                RefreshWaypointsList()
            end)
        end
    end

    function RefreshPluginsList()
        ClearList(PluginsFrame)
        for i, pluginName in ipairs(Plugins) do
            local hint = PluginsFrame.Frame:FindFirstChild("Hint")
            if hint then hint.Visible = false end
            local row = Instance.new("Frame")
            row.BackgroundColor3 = Theme.Shade2
            row.BorderSizePixel = 0
            row.Size = UDim2.new(0, 250, 0, 20)
            row.ZIndex = 11
            table.insert(Themed.Shade2, row)
            row.Parent = PluginsFrame.List

            local lbl = MakeLabel({
                Text = pluginName,
                Size = UDim2.new(0, 200, 0, 20),
                Position = UDim2.new(0, 5, 0, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 11,
            })
            lbl.Parent = row

            local del = MakeSmallButton({
                Text = "Delete",
                Size = UDim2.new(0, 40, 0, 20),
                Position = UDim2.new(0, 200, 0, 0),
                ZIndex = 11,
            })
            del.Parent = row
            del.MouseButton1Click:Connect(function()
                table.remove(Plugins, i)
                RefreshPluginsList()
            end)
        end
    end

    function RefreshEventBindsList()
        ClearList(EventBindsFrame)
        for i, eb in ipairs(EventBinds) do
            local hint = EventBindsFrame.Frame:FindFirstChild("Hint")
            if hint then hint.Visible = false end
            local row = Instance.new("Frame")
            row.BackgroundColor3 = Theme.Shade2
            row.BorderSizePixel = 0
            row.Size = UDim2.new(0, 250, 0, 20)
            row.ZIndex = 11
            table.insert(Themed.Shade2, row)
            row.Parent = EventBindsFrame.List

            local lbl = MakeLabel({
                Text = tostring(eb.Event) .. " > " .. tostring(eb.Command),
                Size = UDim2.new(0, 200, 0, 20),
                Position = UDim2.new(0, 5, 0, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 11,
            })
            lbl.Parent = row

            local del = MakeSmallButton({
                Text = "Delete",
                Size = UDim2.new(0, 40, 0, 20),
                Position = UDim2.new(0, 200, 0, 0),
                ZIndex = 11,
            })
            del.Parent = row
            del.MouseButton1Click:Connect(function()
                table.remove(EventBinds, i)
                RefreshEventBindsList()
            end)
        end
    end

    -- ============ THEME EDITOR POPUP ============
    local ThemeEditor = Instance.new("Frame")
    ThemeEditor.Name = RandomString()
    ThemeEditor.Active = true
    ThemeEditor.BackgroundTransparency = 1
    ThemeEditor.Position = UDim2.new(0.5, -150, 0, -500)
    ThemeEditor.Size = UDim2.new(0, 300, 0, 20)
    ThemeEditor.ZIndex = 60
    ThemeEditor.Parent = ScaledHolder

    local ThemeEditorTitle = Instance.new("Frame")
    ThemeEditorTitle.Size = UDim2.new(0, 300, 0, 20)
    ThemeEditorTitle.BackgroundColor3 = Theme.Shade2
    ThemeEditorTitle.BorderSizePixel = 0
    ThemeEditorTitle.ZIndex = 60
    table.insert(Themed.Shade2, ThemeEditorTitle)
    ThemeEditorTitle.Parent = ThemeEditor

    local ThemeEditorTitleLabel = MakeLabel({
        Text = "Edit Theme",
        Size = UDim2.new(0, 270, 0, 20),
        Position = UDim2.new(0, 5, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 60,
    })
    ThemeEditorTitleLabel.Parent = ThemeEditorTitle

    local ThemeEditorClose = MakeSmallButton({
        Size = UDim2.new(0, 20, 0, 20),
        Position = UDim2.new(1, -20, 0, 0),
        Text = "X",
        ZIndex = 60,
    })
    ThemeEditorClose.Parent = ThemeEditorTitle

    local ThemeEditorBg = Instance.new("Frame")
    ThemeEditorBg.Size = UDim2.new(0, 300, 0, 200)
    ThemeEditorBg.Position = UDim2.new(0, 0, 0, 20)
    ThemeEditorBg.BackgroundColor3 = Theme.Shade1
    ThemeEditorBg.BorderSizePixel = 0
    ThemeEditorBg.ZIndex = 60
    table.insert(Themed.Shade1, ThemeEditorBg)
    ThemeEditorBg.Parent = ThemeEditor

    -- Color pickers for each theme element
    local ThemeColors = {
        {Name = "Shade 1 (Dark)", Key = "Shade1", Default = Color3.fromRGB(36, 36, 37)},
        {Name = "Shade 2 (Medium)", Key = "Shade2", Default = Color3.fromRGB(46, 46, 47)},
        {Name = "Shade 3 (Light)", Key = "Shade3", Default = Color3.fromRGB(78, 78, 79)},
        {Name = "Text 1 (Primary)", Key = "Text1", Default = Color3.new(1, 1, 1)},
        {Name = "Text 2 (Secondary)", Key = "Text2", Default = Color3.new(0, 0, 0)},
        {Name = "Accent", Key = "Accent", Default = Color3.fromRGB(150, 150, 151)},
    }

    for i, colorData in ipairs(ThemeColors) do
        local y = 5 + (i - 1) * 32
        local lbl = MakeLabel({
            Text = colorData.Name,
            Size = UDim2.new(0, 180, 0, 20),
            Position = UDim2.new(0, 10, 0, y),
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 60,
        })
        lbl.Parent = ThemeEditorBg

        local preview = Instance.new("Frame")
        preview.Size = UDim2.new(0, 20, 0, 20)
        preview.Position = UDim2.new(0, 195, 0, y)
        preview.BackgroundColor3 = Theme[colorData.Key]
        preview.BorderSizePixel = 0
        preview.ZIndex = 60
        preview.Parent = ThemeEditorBg

        local colorBtn = MakeSmallButton({
            Text = "Pick",
            Size = UDim2.new(0, 40, 0, 20),
            Position = UDim2.new(0, 220, 0, y),
            ZIndex = 60,
        })
        colorBtn.Parent = ThemeEditorBg

        colorBtn.MouseButton1Click:Connect(function()
            -- Simple color cycle since we can't use Color3Picker easily
            local colors = {
                Color3.fromRGB(36, 36, 37),
                Color3.fromRGB(46, 46, 47),
                Color3.fromRGB(78, 78, 79),
                Color3.fromRGB(100, 100, 100),
                Color3.fromRGB(30, 30, 30),
                Color3.fromRGB(20, 20, 25),
                Color3.fromRGB(50, 50, 60),
                Color3.fromRGB(60, 40, 40),
                Color3.fromRGB(40, 60, 40),
                Color3.fromRGB(40, 40, 60),
                Color3.new(1, 1, 1),
                Color3.new(0, 0, 0),
                Color3.fromRGB(200, 50, 50),
                Color3.fromRGB(50, 200, 50),
                Color3.fromRGB(50, 50, 200),
                Color3.fromRGB(200, 200, 50),
                Color3.fromRGB(200, 50, 200),
                Color3.fromRGB(50, 200, 200),
            }
            local current = Theme[colorData.Key]
            local found = false
            for j, c in ipairs(colors) do
                if (c - current).Magnitude < 0.05 then
                    if j < #colors then
                        Theme[colorData.Key] = colors[j + 1]
                    else
                        Theme[colorData.Key] = colors[1]
                    end
                    found = true
                    break
                end
            end
            if not found then
                Theme[colorData.Key] = colors[1]
            end
            preview.BackgroundColor3 = Theme[colorData.Key]
            ApplyTheme()
        end)
    end

    local ResetThemeBtn = MakeButton({
        Text = "Reset to Default",
        Size = UDim2.new(0, 120, 0, 20),
        Position = UDim2.new(0, 10, 0, 175),
        ZIndex = 60,
    })
    ResetThemeBtn.Parent = ThemeEditorBg
    ResetThemeBtn.MouseButton1Click:Connect(function()
        Theme.Shade1 = Color3.fromRGB(36, 36, 37)
        Theme.Shade2 = Color3.fromRGB(46, 46, 47)
        Theme.Shade3 = Color3.fromRGB(78, 78, 79)
        Theme.Text1 = Color3.new(1, 1, 1)
        Theme.Text2 = Color3.new(0, 0, 0)
        Theme.Accent = Color3.fromRGB(150, 150, 151)
        Theme.Scroll = Color3.fromRGB(78, 78, 79)
        ApplyTheme()
        -- Update previews
        for _, child in pairs(ThemeEditorBg:GetChildren()) do
            if child:IsA("Frame") and child ~= ThemeEditorBg then
                -- Will be refreshed on next open
            end
        end
        Library.Notify("Theme", "Theme reset to default.", 2)
    end)

    ThemeEditorClose.MouseButton1Click:Connect(function()
        ThemeEditor.Position = UDim2.new(0.5, -150, 0, -500)
    end)

    -- Theme editor draggable
    local teDragging, teDragInput, teDragStart, teStartPos
    ThemeEditorTitle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            teDragging = true
            teDragStart = input.Position
            teStartPos = ThemeEditor.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then teDragging = false end
            end)
        end
    end)
    ThemeEditorTitle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then teDragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == teDragInput and teDragging then
            local delta = input.Position - teDragStart
            ThemeEditor.Position = UDim2.new(
                teStartPos.X.Scale, teStartPos.X.Offset + delta.X,
                teStartPos.Y.Scale, teStartPos.Y.Offset + delta.Y
            )
        end
    end)

    -- ============ KEYBIND EDITOR POPUP ============
    local KeybindEditor = Instance.new("Frame")
    KeybindEditor.Name = RandomString()
    KeybindEditor.Active = true
    KeybindEditor.BackgroundTransparency = 1
    KeybindEditor.Position = UDim2.new(0.5, -180, 0, -500)
    KeybindEditor.Size = UDim2.new(0, 360, 0, 20)
    KeybindEditor.ZIndex = 60
    KeybindEditor.Parent = ScaledHolder

    local KeTitleBar = Instance.new("Frame")
    KeTitleBar.Size = UDim2.new(0, 360, 0, 20)
    KeTitleBar.BackgroundColor3 = Theme.Shade2
    KeTitleBar.BorderSizePixel = 0
    KeTitleBar.ZIndex = 60
    table.insert(Themed.Shade2, KeTitleBar)
    KeTitleBar.Parent = KeybindEditor

    local KeTitleLabel = MakeLabel({
        Text = "Set Keybinds",
        Size = UDim2.new(0, 330, 0, 20),
        Position = UDim2.new(0, 5, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 60,
    })
    KeTitleLabel.Parent = KeTitleBar

    local KeClose = MakeSmallButton({
        Size = UDim2.new(0, 20, 0, 20),
        Position = UDim2.new(1, -20, 0, 0),
        Text = "X",
        ZIndex = 60,
    })
    KeClose.Parent = KeTitleBar

    local KeBg = Instance.new("Frame")
    KeBg.Size = UDim2.new(0, 360, 0, 185)
    KeBg.Position = UDim2.new(0, 0, 0, 20)
    KeBg.BackgroundColor3 = Theme.Shade1
    KeBg.BorderSizePixel = 0
    KeBg.ZIndex = 60
    table.insert(Themed.Shade1, KeBg)
    KeBg.Parent = KeybindEditor

    -- Divider
    local KeDivider = Instance.new("Frame")
    KeDivider.Size = UDim2.new(0, 2, 0, 185)
    KeDivider.Position = UDim2.new(0, 135, 0, 0)
    KeDivider.BackgroundColor3 = Theme.Shade2
    KeDivider.BorderSizePixel = 0
    KeDivider.ZIndex = 60
    table.insert(Themed.Shade2, KeDivider)
    KeDivider.Parent = KeBg

    -- Left side: key binding
    local KeDirections = MakeLabel({
        Text = "Click the button below and press a key/mouse button. Then select what you want to bind it to.",
        Size = UDim2.new(0, 115, 0, 90),
        Position = UDim2.new(0, 10, 0, 15),
        TextWrapped = true,
        TextYAlignment = Enum.TextYAlignment.Top,
        ZIndex = 60,
    })
    KeDirections.Parent = KeBg

    local BindToBtn = MakeButton({
        Text = "Click to bind",
        Size = UDim2.new(0, 115, 0, 50),
        Position = UDim2.new(0, 10, 0, 95),
        ZIndex = 60,
    })
    BindToBtn.Parent = KeBg

    local KeTriggerLabel = MakeLabel({
        Text = "Trigger:",
        Size = UDim2.new(0, 45, 0, 20),
        Position = UDim2.new(0, 10, 0, 155),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 60,
    })
    KeTriggerLabel.Parent = KeBg

    local TriggerSelect = MakeButton({
        Text = "KeyDown",
        Size = UDim2.new(0, 65, 0, 20),
        Position = UDim2.new(0, 60, 0, 155),
        ZIndex = 60,
    })
    TriggerSelect.Parent = KeBg

    local TriggerModes = {"KeyDown", "KeyUp", "KeyPressed"}
    local TriggerIndex = 1
    TriggerSelect.MouseButton1Click:Connect(function()
        TriggerIndex = TriggerIndex % #TriggerModes + 1
        TriggerSelect.Text = TriggerModes[TriggerIndex]
    end)

    -- Right side: command input
    local KeCmdLabel = MakeLabel({
        Text = "Command to run:",
        Size = UDim2.new(0, 200, 0, 20),
        Position = UDim2.new(0, 150, 0, 10),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 60,
    })
    KeCmdLabel.Parent = KeBg

    local KeCmdBox = Instance.new("TextBox")
    KeCmdBox.BackgroundColor3 = Theme.Shade2
    KeCmdBox.BorderSizePixel = 0
    KeCmdBox.Size = UDim2.new(0, 195, 0, 20)
    KeCmdBox.Position = UDim2.new(0, 150, 0, 35)
    KeCmdBox.Font = Enum.Font.SourceSans
    KeCmdBox.TextSize = 14
    KeCmdBox.PlaceholderText = "Command"
    KeCmdBox.Text = ""
    KeCmdBox.TextColor3 = Theme.Text1
    KeCmdBox.TextXAlignment = Enum.TextXAlignment.Left
    KeCmdBox.ZIndex = 60
    table.insert(Themed.Shade2, KeCmdBox)
    table.insert(Themed.Text1, KeCmdBox)
    KeCmdBox.Parent = KeBg

    local KeCmdBox2 = Instance.new("TextBox")
    KeCmdBox2.BackgroundColor3 = Theme.Shade2
    KeCmdBox2.BorderSizePixel = 0
    KeCmdBox2.Size = UDim2.new(0, 195, 0, 20)
    KeCmdBox2.Position = UDim2.new(0, 150, 0, 60)
    KeCmdBox2.Font = Enum.Font.SourceSans
    KeCmdBox2.TextSize = 14
    KeCmdBox2.PlaceholderText = "Command 2 (optional)"
    KeCmdBox2.Text = ""
    KeCmdBox2.TextColor3 = Theme.Text1
    KeCmdBox2.TextXAlignment = Enum.TextXAlignment.Left
    KeCmdBox2.ZIndex = 60
    table.insert(Themed.Shade2, KeCmdBox2)
    table.insert(Themed.Text1, KeCmdBox2)
    KeCmdBox2.Parent = KeBg

    -- Toggle option
    local KeToggleLabel = MakeLabel({
        Text = "Create Toggle",
        Size = UDim2.new(0, 170, 0, 20),
        Position = UDim2.new(0, 152, 0, 85),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 60,
    })
    KeToggleLabel.Parent = KeBg

    local KeToggleBg = Instance.new("Frame")
    KeToggleBg.BackgroundColor3 = Theme.Shade3
    KeToggleBg.BorderSizePixel = 0
    KeToggleBg.Size = UDim2.new(0, 20, 0, 20)
    KeToggleBg.Position = UDim2.new(0, 322, 0, 85)
    KeToggleBg.ZIndex = 60
    table.insert(Themed.Shade3, KeToggleBg)
    KeToggleBg.Parent = KeBg

    local KeToggleBtn = Instance.new("TextButton")
    KeToggleBtn.BackgroundTransparency = 1
    KeToggleBtn.Size = UDim2.new(0, 16, 0, 16)
    KeToggleBtn.Position = UDim2.new(0, 2, 0, 2)
    KeToggleBtn.Text = ""
    KeToggleBtn.ZIndex = 60
    KeToggleBtn.Parent = KeToggleBg

    local KeIsToggle = false
    KeToggleBtn.MouseButton1Click:Connect(function()
        KeIsToggle = not KeIsToggle
        KeToggleBtn.Text = KeIsToggle and "✓" or ""
        KeToggleBtn.TextColor3 = Theme.Text1
    end)

    -- Quick toggle options
    local KeQuickToggles = MakeScrollFrame({
        Size = UDim2.new(0, 195, 0, 50),
        Position = UDim2.new(0, 150, 0, 110),
        ScrollBarThickness = 8,
        CanvasSize = UDim2.new(0, 0, 0, 50),
        ZIndex = 60,
    })
    KeQuickToggles.Parent = KeBg

    local QuickToggleOptions = {"Click TP (Hold Key & Click)", "Click Delete (Hold Key & Click)"}
    for i, opt in ipairs(QuickToggleOptions) do
        local row = MakeButton({
            Text = "    " .. opt,
            Size = UDim2.new(0, 195, 0, 20),
            Position = UDim2.new(0, 0, 0, (i - 1) * 25),
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 60,
        })
        row.Parent = KeQuickToggles
        local addBtn = MakeSmallButton({
            Text = "Add",
            Size = UDim2.new(0, 35, 0, 20),
            Position = UDim2.new(0, 155, 0, 0),
            ZIndex = 60,
        })
        addBtn.Parent = row
    end

    -- Add button
    local KeAddBtn = MakeButton({
        Text = "Add",
        Size = UDim2.new(0, 40, 0, 20),
        Position = UDim2.new(0, 310, 0, 160),
        ZIndex = 60,
    })
    KeAddBtn.Parent = KeBg

    -- Bind capture state
    local CapturingBind = false
    local CapturedKey = nil

    BindToBtn.MouseButton1Click:Connect(function()
        CapturingBind = true
        CapturedKey = nil
        BindToBtn.Text = "Press a key..."
    end)

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if CapturingBind and not gameProcessed then
            CapturedKey = input.KeyCode.Name
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                CapturedKey = "MouseButton1"
            elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
                CapturedKey = "MouseButton2"
            elseif input.UserInputType == Enum.UserInputType.MouseButton3 then
                CapturedKey = "MouseButton3"
            end
            BindToBtn.Text = CapturedKey
            CapturingBind = false
        end
    end)

    KeAddBtn.MouseButton1Click:Connect(function()
        if not CapturedKey then
            Library.Notify("Keybinds", "Please bind a key first.", 2)
            return
        end
        local cmd1 = KeCmdBox.Text
        if #cmd1 == 0 then
            Library.Notify("Keybinds", "Please enter a command.", 2)
            return
        end
        local cmd2 = KeCmdBox2.Text
        local entry = {
            Key = CapturedKey,
            Command = cmd1,
            Command2 = #cmd2 > 0 and cmd2 or nil,
            Trigger = TriggerModes[TriggerIndex],
            Toggle = KeIsToggle,
        }
        table.insert(Keybinds, entry)
        RefreshKeybindsList()
        Library.Notify("Keybinds", "Bound " .. CapturedKey .. " to " .. cmd1, 2)
        -- Reset
        CapturedKey = nil
        BindToBtn.Text = "Click to bind"
        KeCmdBox.Text = ""
        KeCmdBox2.Text = ""
        KeIsToggle = false
        KeToggleBtn.Text = ""
    end)

    KeClose.MouseButton1Click:Connect(function()
        KeybindEditor.Position = UDim2.new(0.5, -180, 0, -500)
    end)

    -- Keybind editor draggable
    local keDragging, keDragInput, keDragStart, keStartPos
    KeTitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            keDragging = true
            keDragStart = input.Position
            keStartPos = KeybindEditor.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then keDragging = false end
            end)
        end
    end)
    KeTitleBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then keDragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == keDragInput and keDragging then
            local delta = input.Position - keDragStart
            KeybindEditor.Position = UDim2.new(
                keStartPos.X.Scale, keStartPos.X.Offset + delta.X,
                keStartPos.Y.Scale, keStartPos.Y.Offset + delta.Y
            )
        end
    end)

    -- ============ PLUGIN EDITOR POPUP ============
    local PluginEditor = Instance.new("Frame")
    PluginEditor.Name = RandomString()
    PluginEditor.Active = true
    PluginEditor.BackgroundTransparency = 1
    PluginEditor.Position = UDim2.new(0.5, -180, 0, -500)
    PluginEditor.Size = UDim2.new(0, 360, 0, 20)
    PluginEditor.ZIndex = 60
    PluginEditor.Parent = ScaledHolder

    local PeTitleBar = Instance.new("Frame")
    PeTitleBar.Size = UDim2.new(0, 360, 0, 20)
    PeTitleBar.BackgroundColor3 = Theme.Shade2
    PeTitleBar.BorderSizePixel = 0
    PeTitleBar.ZIndex = 60
    table.insert(Themed.Shade2, PeTitleBar)
    PeTitleBar.Parent = PluginEditor

    local PeTitleLabel = MakeLabel({
        Text = "Add Plugins",
        Size = UDim2.new(0, 330, 0, 20),
        Position = UDim2.new(0, 5, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 60,
    })
    PeTitleLabel.Parent = PeTitleBar

    local PeClose = MakeSmallButton({
        Size = UDim2.new(0, 20, 0, 20),
        Position = UDim2.new(1, -20, 0, 0),
        Text = "X",
        ZIndex = 60,
    })
    PeClose.Parent = PeTitleBar

    local PeBg = Instance.new("Frame")
    PeBg.Size = UDim2.new(0, 360, 0, 160)
    PeBg.Position = UDim2.new(0, 0, 0, 20)
    PeBg.BackgroundColor3 = Theme.Shade1
    PeBg.BorderSizePixel = 0
    PeBg.ZIndex = 60
    table.insert(Themed.Shade1, PeBg)
    PeBg.Parent = PluginEditor

    local PeDivider = Instance.new("Frame")
    PeDivider.Size = UDim2.new(0, 2, 0, 160)
    PeDivider.Position = UDim2.new(0, 222, 0, 0)
    PeDivider.BackgroundColor3 = Theme.Shade2
    PeDivider.BorderSizePixel = 0
    PeDivider.ZIndex = 60
    table.insert(Themed.Shade2, PeDivider)
    PeDivider.Parent = PeBg

    local PeAbout = MakeLabel({
        Text = "Plugins are .iy files and should be located in the 'workspace' folder of your exploit.",
        Size = UDim2.new(0, 187, 0, 49),
        Position = UDim2.new(0, 17, 0, 10),
        TextWrapped = true,
        TextYAlignment = Enum.TextYAlignment.Top,
        ZIndex = 60,
    })
    PeAbout.Parent = PeBg

    local PeDirections = MakeLabel({
        Text = "Type the name of the plugin file you want to add below.",
        Size = UDim2.new(0, 187, 0, 49),
        Position = UDim2.new(0, 17, 0, 60),
        TextWrapped = true,
        TextYAlignment = Enum.TextYAlignment.Top,
        ZIndex = 60,
    })
    PeDirections.Parent = PeBg

    local PeFileBox = Instance.new("TextBox")
    PeFileBox.BackgroundColor3 = Theme.Shade2
    PeFileBox.BorderSizePixel = 0
    PeFileBox.Size = UDim2.new(0, 200, 0, 50)
    PeFileBox.Position = UDim2.new(0, 10, 0, 100)
    PeFileBox.Font = Enum.Font.SourceSans
    PeFileBox.TextSize = 14
    PeFileBox.PlaceholderText = "Plugin File Name"
    PeFileBox.Text = ""
    PeFileBox.TextColor3 = Theme.Text1
    PeFileBox.ZIndex = 60
    table.insert(Themed.Shade2, PeFileBox)
    table.insert(Themed.Text1, PeFileBox)
    PeFileBox.Parent = PeBg

    local PeImg = Instance.new("ImageLabel")
    PeImg.Size = UDim2.new(0, 100, 0, 95)
    PeImg.Position = UDim2.new(0, 242, 0, 3)
    PeImg.BackgroundTransparency = 1
    PeImg.Image = GetAsset("imgstudiopluginlogo")
    PeImg.ZIndex = 60
    PeImg.Parent = PeBg

    local PeAddBtn = MakeButton({
        Text = "Add Plugin",
        Size = UDim2.new(0, 115, 0, 50),
        Position = UDim2.new(0, 235, 0, 100),
        ZIndex = 60,
    })
    PeAddBtn.Parent = PeBg

    PeAddBtn.MouseButton1Click:Connect(function()
        local name = PeFileBox.Text
        if #name > 0 then
            table.insert(Plugins, name)
            RefreshPluginsList()
            Library.Notify("Plugins", "Added plugin: " .. name, 2)
            PeFileBox.Text = ""
        else
            Library.Notify("Plugins", "Please enter a plugin file name.", 2)
        end
    end)

    PeClose.MouseButton1Click:Connect(function()
        PluginEditor.Position = UDim2.new(0.5, -180, 0, -500)
    end)

    -- Plugin editor draggable
    local peDragging, peDragInput, peDragStart, peStartPos
    PeTitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            peDragging = true
            peDragStart = input.Position
            peStartPos = PluginEditor.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then peDragging = false end
            end)
        end
    end)
    PeTitleBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then peDragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == peDragInput and peDragging then
            local delta = input.Position - peDragStart
            PluginEditor.Position = UDim2.new(
                peStartPos.X.Scale, peStartPos.X.Offset + delta.X,
                peStartPos.Y.Scale, peStartPos.Y.Offset + delta.Y
            )
        end
    end)

    -- ============ SETTINGS BUTTON LOGIC ============
    local ActiveSubFrame = nil

    local function HideAllSubFrames()
        for name, data in pairs(SubFrames) do
            data.Frame.Visible = false
        end
        ActiveSubFrame = nil
    end

    local function ToggleSubFrame(name)
        if ActiveSubFrame == name then
            HideAllSubFrames()
            return
        end
        HideAllSubFrames()
        if SubFrames[name] then
            SubFrames[name].Frame.Visible = true
            ActiveSubFrame = name
        end
    end

    SettingsBtn.MouseButton1Click:Connect(function()
        SettingsOpen = not SettingsOpen
        Settings.Visible = SettingsOpen
        if not SettingsOpen then
            HideAllSubFrames()
        end
        -- Adjust holder size
        local targetSize = SettingsOpen and UDim2.new(0, 250, 0, 395) or UDim2.new(0, 250, 0, 220)
        TweenService:Create(Holder, TweenInfo.new(0.2), {Size = targetSize}):Play()
        CMDsF.Size = SettingsOpen and UDim2.new(0, 245, 0, 175) or UDim2.new(0, 245, 0, 175)
    end)

    SettingsCloseBtn.MouseButton1Click:Connect(function()
        SettingsOpen = false
        Settings.Visible = false
        HideAllSubFrames()
        TweenService:Create(Holder, TweenInfo.new(0.2), {Size = UDim2.new(0, 250, 0, 220)}):Play()
    end)

    MinimizeBtn.MouseButton1Click:Connect(function()
        Minimized = not Minimized
        if Minimized then
            -- Hide everything except title bar
            Dark.Visible = false
            CMDsF.Visible = false
            Cmdbar.Visible = false
            Settings.Visible = false
            SettingsOpen = false
            HideAllSubFrames()
            TweenService:Create(Holder, TweenInfo.new(0.2), {Size = UDim2.new(0, 250, 0, 20)}):Play()
        else
            Dark.Visible = true
            CMDsF.Visible = true
            Cmdbar.Visible = true
            TweenService:Create(Holder, TweenInfo.new(0.2), {Size = UDim2.new(0, 250, 0, 220)}):Play()
        end
    end)

    ColorsBtn.MouseButton1Click:Connect(function()
        -- Show theme editor centered
        ThemeEditor.Position = UDim2.new(0.5, -150, 0.5, -110)
    end)

    KeybindsBtn.MouseButton1Click:Connect(function()
        ToggleSubFrame("Keybinds")
    end)

    AliasesBtn.MouseButton1Click:Connect(function()
        ToggleSubFrame("Aliases")
    end)

    WaypointsBtn.MouseButton1Click:Connect(function()
        ToggleSubFrame("Waypoints")
    end)

    PluginsBtn.MouseButton1Click:Connect(function()
        ToggleSubFrame("Plugins")
        -- Also show plugin editor
        PluginEditor.Position = UDim2.new(0.5, -180, 0.5, -90)
    end)

    EventBindsBtn.MouseButton1Click:Connect(function()
        ToggleSubFrame("Event Binds")
    end)

    -- ============ COMMAND SYSTEM ============
    local CommandButtons = {}

    local function ClearCommandList()
        for _, btn in pairs(CommandButtons) do
            if btn and btn.Parent then btn:Destroy() end
        end
        CommandButtons = {}
    end

    local function RebuildCommandList(filter)
        ClearCommandList()
        filter = filter or ""
        local filtered = {}
        for name, cmd in pairs(Commands) do
            if #filter == 0 or name:lower():find(filter:lower(), 1, true) then
                table.insert(filtered, {Name = name, Data = cmd})
            end
        end
        -- Also check aliases
        for alias, cmd in pairs(Aliases) do
            if #filter == 0 or alias:lower():find(filter:lower(), 1, true) then
                if not Commands[alias] then
                    table.insert(filtered, {Name = alias, Data = {Description = "Alias for: " .. cmd, Aliased = cmd}})
                end
            end
        end
        table.sort(filtered, function(a, b) return a.Name < b.Name end)

        CMDsF.CanvasSize = UDim2.new(0, 0, 0, #filtered * 20)

        for i, entry in ipairs(filtered) do
            local btn = Instance.new("TextButton")
            btn.BackgroundColor3 = Theme.Shade2
            btn.BorderSizePixel = 0
            btn.Size = UDim2.new(0, 240, 0, 20)
            btn.Font = Enum.Font.SourceSans
            btn.TextSize = 14
            btn.Text = entry.Name
            btn.TextColor3 = Theme.Text1
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.ZIndex = 10
            btn.LayoutOrder = i
            table.insert(Themed.Shade2, btn)
            table.insert(Themed.Text1, btn)
            btn.Parent = CMDsF
            CommandButtons[entry.Name] = btn

            -- Click to fill command bar
            btn.MouseButton1Click:Connect(function()
                Cmdbar.Text = Prefix .. entry.Name .. " "
                Cmdbar:CaptureFocus()
            end)

            -- Tooltip on hover
            btn.MouseEnter:Connect(function(x, y)
                local desc = entry.Data.Description or "No description available."
                if entry.Data.Aliased then desc = "Alias for: " .. entry.Data.Aliased end
                ShowTooltip(entry.Name, desc, x, y)
            end)
            btn.MouseLeave:Connect(function()
                HideTooltip()
            end)
        end
    end

    -- AddCommand - THE MAIN FUNCTION
    function Library:AddCommand(name, description, callback)
        Commands[name] = {
            Description = description or "",
            Callback = callback or function() end,
        }
        RebuildCommandList(Cmdbar.Text)
    end

    -- RemoveCommand
    function Library:RemoveCommand(name)
        Commands[name] = nil
        RebuildCommandList(Cmdbar.Text)
    end

    -- AddAlias (public)
    function Library:AddAlias(alias, command)
        Aliases[alias] = command
        RefreshAliasesList()
        RebuildCommandList(Cmdbar.Text)
    end

    -- RemoveAlias (public)
    function Library:RemoveAlias(alias)
        Aliases[alias] = nil
        RefreshAliasesList()
        RebuildCommandList(Cmdbar.Text)
    end

    -- AddWaypoint (public)
    function Library:AddWaypoint(name, position)
        Waypoints[name] = position
        RefreshWaypointsList()
    end

    -- RemoveWaypoint (public)
    function Library:RemoveWaypoint(name)
        Waypoints[name] = nil
        RefreshWaypointsList()
    end

    -- AddKeybind (public)
    function Library:AddKeybind(key, command, options)
        options = options or {}
        table.insert(Keybinds, {
            Key = key,
            Command = command,
            Command2 = options.Command2,
            Trigger = options.Trigger or "KeyDown",
            Toggle = options.Toggle or false,
        })
        RefreshKeybindsList()
    end

    -- AddPlugin (public)
    function Library:AddPlugin(name)
        table.insert(Plugins, name)
        RefreshPluginsList()
    end

    -- AddEventBind (public)
    function Library:AddEventBind(eventName, command)
        table.insert(EventBinds, {Event = eventName, Command = command})
        RefreshEventBindsList()
    end

    -- SetPrefix (public)
    function Library:SetPrefix(newPrefix)
        Prefix = newPrefix
        PrefixBox.Text = newPrefix
        Cmdbar.PlaceholderText = Prefix .. " Command Bar"
        OnPrefixChange(Prefix)
    end

    -- GetPrefix (public)
    function Library:GetPrefix()
        return Prefix
    end

    -- RunCommand (public)
    function Library:RunCommand(input)
        local text = input:gsub("^" .. Prefix, ""):match("^%s*(.-)%s*$")
        if not text or #text == 0 then return false end

        local parts = {}
        for part in text:gmatch("%S+") do
            table.insert(parts, part)
        end
        local cmdName = parts[1]
        local args = {}
        for i = 2, #parts do
            table.insert(args, parts[i])
        end

        -- Check aliases first
        local resolvedCmd = Aliases[cmdName] or cmdName

        -- Check if it's an alias pointing to another command
        if Aliases[cmdName] then
            local aliasParts = {}
            for part in Aliases[cmdName]:gmatch("%S+") do
                table.insert(aliasParts, part)
            end
            if #aliasParts > 0 then
                resolvedCmd = aliasParts[1]
                for i = 2, #aliasParts do
                    table.insert(args, 1, aliasParts[i])
                end
            end
        end

        if Commands[resolvedCmd] then
            local success, err = pcall(function()
                Commands[resolvedCmd].Callback(unpack(args))
            end)
            if not success then
                Library.Notify("Error", "Command '" .. resolvedCmd .. "' error: " .. tostring(err), 4)
            end
            OnCommandRun(resolvedCmd, args)
            return true
        else
            Library.Notify("Error", "Unknown command: " .. cmdName, 2)
            return false
        end
    end

    -- SetTheme (public)
    function Library:SetTheme(themeTable)
        for k, v in pairs(themeTable) do
            if Theme[k] then
                Theme[k] = v
            end
        end
        ApplyTheme()
    end

    -- GetTheme (public)
    function Library:GetTheme()
        local copy = {}
        for k, v in pairs(Theme) do
            copy[k] = v
        end
        return copy
    end

    -- Show/Hide (public)
    function Library:Show()
        Holder.Visible = true
    end

    function Library:Hide()
        Holder.Visible = false
    end

    function Library:Toggle()
        Holder.Visible = not Holder.Visible
    end

    -- GetElements (public)
    function Library:GetElements()
        return {
            Holder = Holder,
            Cmdbar = Cmdbar,
            CMDsF = CMDsF,
            Settings = Settings,
            Notification = Notification,
            Tooltip = Tooltip,
            ThemeEditor = ThemeEditor,
            KeybindEditor = KeybindEditor,
            PluginEditor = PluginEditor,
            ScreenGui = ScreenGui,
        }
    end

    -- ============ COMMAND BAR LOGIC ============
    Cmdbar:GetPropertyChangedSignal("Text"):Connect(function()
        local text = Cmdbar.Text
        -- Strip prefix for filtering
        local filter = text:gsub("^" .. Prefix, ""):match("^%s*(.-)%s*$") or ""
        -- If text starts with prefix, filter commands
        if text:sub(1, #Prefix) == Prefix then
            RebuildCommandList(filter)
        elseif #text > 0 then
            RebuildCommandList(filter)
        else
            RebuildCommandList("")
        end
    end)

    Cmdbar.FocusLost:Connect(function(enter)
        if enter then
            local text = Cmdbar.Text
            if #text > 0 then
                local ran = Library:RunCommand(text)
                if not StayOpen then
                    Cmdbar.Text = ""
                    RebuildCommandList("")
                end
                if ran then
                    table.insert(CommandHistory, text)
                    HistoryIndex = #CommandHistory + 1
                end
            end
        end
    end)

    -- Command history navigation
    Cmdbar.InputBegan:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.Up then
            if HistoryIndex > 1 then
                HistoryIndex = HistoryIndex - 1
                Cmdbar.Text = CommandHistory[HistoryIndex]
            end
        elseif input.KeyCode == Enum.KeyCode.Down then
            if HistoryIndex < #CommandHistory then
                HistoryIndex = HistoryIndex + 1
                Cmdbar.Text = CommandHistory[HistoryIndex]
            else
                HistoryIndex = #CommandHistory + 1
                Cmdbar.Text = ""
            end
        elseif input.KeyCode == Enum.KeyCode.Tab then
            -- Autocomplete
            local text = Cmdbar.Text:gsub("^" .. Prefix, ""):match("^%s*(.-)%s*$") or ""
            if #text > 0 then
                for name, _ in pairs(Commands) do
                    if name:lower():sub(1, #text) == text:lower() then
                        Cmdbar.Text = Prefix .. name .. " "
                        Cmdbar:CaptureFocus()
                        break
                    end
                end
                -- Also check aliases
                for alias, _ in pairs(Aliases) do
                    if alias:lower():sub(1, #text) == text:lower() then
                        Cmdbar.Text = Prefix .. alias .. " "
                        Cmdbar:CaptureFocus()
                        break
                    end
                end
            end
        end
    end)

    -- ============ KEYBIND EXECUTION ============
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        local keyName = input.KeyCode.Name
        if input.UserInputType == Enum.UserInputType.MouseButton1 then keyName = "MouseButton1" end
        if input.UserInputType == Enum.UserInputType.MouseButton2 then keyName = "MouseButton2" end
        if input.UserInputType == Enum.UserInputType.MouseButton3 then keyName = "MouseButton3" end

        for _, kb in ipairs(Keybinds) do
            if kb.Key == keyName and (kb.Trigger == "KeyDown" or kb.Trigger == "KeyPressed") then
                Library:RunCommand(Prefix .. kb.Command)
                if kb.Command2 then
                    Library:RunCommand(Prefix .. kb.Command2)
                end
            end
        end
    end)

    UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        local keyName = input.KeyCode.Name
        if input.UserInputType == Enum.UserInputType.MouseButton1 then keyName = "MouseButton1" end
        if input.UserInputType == Enum.UserInputType.MouseButton2 then keyName = "MouseButton2" end
        if input.UserInputType == Enum.UserInputType.MouseButton3 then keyName = "MouseButton3" end

        for _, kb in ipairs(Keybinds) do
            if kb.Key == keyName and kb.Trigger == "KeyUp" then
                Library:RunCommand(Prefix .. kb.Command)
                if kb.Command2 then
                    Library:RunCommand(Prefix .. kb.Command2)
                end
            end
        end
    end)

    -- ============ INITIAL BUILD ============
    RebuildCommandList("")
    ApplyTheme()

    -- Return the library interface
    return Library
end

return Library
