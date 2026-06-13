local services = loadstring(game:HttpGet(
    "https://website-iota-ivory-12.vercel.app/code/loader/u/vars.lua"
))()

local Heartbeat = services["rs"].Heartbeat
local RenderStepped = services["rs"].RenderStepped

local Connections = {
    Communication = {
        Bindable = Instance.new("BindableEvent")
    },
    Table = {},
    Gameplay = {},
}

local States = {
    Runtime = {},

    Values = {
		AreWeBeingRanInAnActor = is_parallel(),

        LocalPlayer = {
            IsGrounded = nil,
			SetSprintBlocked = nil,
            CanShoot = nil,
            Character = nil,
            EquippedItem = nil,
            Camera = nil
        },

        Game = {
            Global = {},
            NEXT = {},
            Classes = {},
			
			RangedWeaponClient = {},
				-- CreateProjictle
				-- PlayerReload
				-- ProjictileSpeed
				-- PlayerAim
            Recoil = nil,
			SetSwaySpeed = nil,
            SendTcp = nil,
            TCP = nil,

			Lighting = {
				DefaultAmbient = services["lighting"].Ambient,
				DefaultOutdoorAmbient = services["lighting"].OutdoorAmbient,
				DefaultBrightness = services["lighting"].Brightness
			},
			Workspace = {
				Terrian = {
					WaterWaveSize = workspace.Terrain.WaterWaveSize
				},
				EntityList = {},
			}
        }
    }
}

local _localplayer = States.Values.LocalPlayer
local _game = States.Values.Game

local Values = {}

setmetatable(Values, {
    __index = States.Values,

    __newindex = function(self, key, value)
        rawset(States.Values, key, value)

        if key == "LocalPlayer" then
            _localplayer = value
        elseif key == "Game" then
            _game = value
        end
    end
})

States.Values = Values

local function SetValue(Obj, Key, Value, Notify)
    Obj[Key] = Value

    if Notify then
        Connections.Communication.Bindable:Fire({
            Object = Obj,
            Key = Key,
            Value = Value,
        })
    end
end

local function AddConnection(Category, Name, Connection)
    if Category[Name] then
        pcall(function()
            if typeof(Category[Name]) == "RBXScriptConnection" then
                Category[Name]:Disconnect()
            else
                task.cancel(Category[Name])
            end
        end)
    end

    Category[Name] = Connection
    States.Runtime[Name] = true
end

local function RemoveConnection(Category, Name)
    if not Category[Name] then return end

    pcall(function()
        if typeof(Category[Name]) == "RBXScriptConnection" then
            Category[Name]:Disconnect()
        else
            task.cancel(Category[Name])
        end
    end)

    Category[Name] = nil
    States.Runtime[Name] = false
end

if States.Values.AreWeBeingRanInAnActor then
	SetValue(_game, "Global", getsenv(services["player"].PlayerScripts.Client.Client)._G) -- Scripts.Client = Actor .Client = LocalScript
	SetValue(_game, "NEXT", _game.Global.NEXT)
	SetValue(_game, "Classes", _game.Global.classes)

	SetValue(_game, "RangedWeaponClient", _game.Classes.RangedWeaponClient)
	SetValue(_game, "Recoil", _game.Classes.Recoil)
	SetValue(_game, "SetSwaySpeed", _game.Classes.SetSwaySpeed)
	SetValue(_game, "TCP", services["player"].TCP)

	SetValue(_localplayer, "Character", _game.Classes.Character)
	SetValue(_localplayer, "IsGrounded", _localplayer.Character.IsGrounded) -- function
	SetValue(_localplayer, "SetSprintBlocked", _localplayer.Character.SetSprintBlocked) -- function
	SetValue(_localplayer, "Camera", _game.Classes.Camera)
else
	task.spawn(error("Run via Actor for more functions, thanks!", 2))
end

local Library, ThemeManager, SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/Library.lua"))(),loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/addons/ThemeManager.lua"))(),loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/addons/SaveManager.lua"))()

local Options, Toggles = Library.Options
Library.ForceCheckbox, Library.ShowToggleFrameInKeybinds = false, true

local Window = Library:CreateWindow({
    Title = "mspaint",
    Footer = "version: v1",
    Icon = 95816097006870,
    NotifySide = "Right",
    ShowCustomCursor = false,
})

local Tabs = {
    Combat = Window:AddTab("Combat", "swords"),
    Visuals = Window:AddTab("Visuals", "eye"),
    Misc = Window:AddTab("Misc", "settings"),
    Config = Window:AddTab("Ui Settings", "settings"),
}

local Tabboxes = {
    Combat = Tabs.Combat:AddLeftTabbox(),
    Misc = Tabs.Misc:AddLeftTabbox(),
}

local SilentTab = Tabboxes.Combat:AddTab("Silent Aim")

SilentTab:AddToggle("silentaim", {
    Text = "Silent Aim",
    Default = false,
    Callback = function(Value) end
})

SilentTab:AddSlider("silentaimdistance", {
    Text = "Distance",
    Default = 1,
    Min = 1,
    Max = 2000,
    Rounding = 1,
    Callback = function(Value) end
})

local AimbotTab = Tabboxes.Combat:AddTab("Aimbot")

AimbotTab:AddToggle("aimbot", {
    Text = "Aimbot",
    Default = false,
    Callback = function(Value) end
})

AimbotTab:AddSlider("aimbotsmoothing", {
    Text = "Smoothing Amount",
    Default = 1,
    Min = 0,
    Max = 10,
    Rounding = 1,
    Callback = function(Value) end
})

AimbotTab:AddSlider("aimbotdistance", {
    Text = "Aimbot Distance",
    Default = 100,
    Min = 0,
    Max = 1000,
    Rounding = 0,
    Callback = function(Value) end
})

local WeaponMods = Tabs.Combat:AddLeftGroupbox("Weapon Mods")

WeaponMods:AddDivider()

WeaponMods:AddToggle("norecoil", {
    Text = "No Recoil",
    Default = false,
    Callback = function(Value)
        local Camera = _game.Classes.Camera
        if Value then
            AddConnection(Connections.Gameplay, "NoRecoil", nil)

            _game.OldRecoil = hookfunction(_localplayer.Camera.Recoil, function(...)
				return
			end)
        elseif isfunctionhooked(_game.OldRecoil) then
			restorefunction(_game.OldRecoil)
			_game.OldRecoil = nil
        end
    end
})

WeaponMods:AddDivider()

WeaponMods:AddToggle("nospread", {
    Text = "No Spread",
    Default = false,
    Callback = function(Value) end
})

WeaponMods:AddDivider()

WeaponMods:AddToggle("instahit", {
    Text = "Insta Hit",
    Default = false,
    Callback = function(Value) end
})

WeaponMods:AddDivider()

WeaponMods:AddToggle("setswayspeed", {
    Text = "No Weapon Sway",
    Default = false,
    Callback = function(Value) end
})

WeaponMods:AddDivider()

local Hitbox = Tabs.Combat:AddRightGroupbox("Hitbox")

Hitbox:AddToggle("hitboxexpander", {
    Text = "Hitbox Expander",
    Default = false,
    Callback = function(Value) end
})

Hitbox:AddSlider("hitboxsize", {
    Text = "Size",
    Min = 2,
    Max = 10,
    Default = 4,
    Callback = function(Value) end
})


local PlayerEsp = Tabs.Visuals:AddLeftGroupbox("Player Esp")

PlayerEsp:AddToggle("playeresp", {
    Text = "Enable",
    Default = false,
    Callback = function(Value) end
})

PlayerEsp:AddDropdown("playerespsettings", {
	Multi = true,
    Values = {"Box", "Name", "Held Item", "Tracer", "Health", "Distance", "Chams", "Health Bar", "Team Color"},
    Default = "Distance",
    Callback = function(Value) end
})

PlayerEsp:AddDivider()

PlayerEsp:AddToggle("aic", {
    Text = "Ai Check",
    Default = false,
    Callback = function(Value) end
})

PlayerEsp:AddToggle("src", {
    Text = "Sleeper",
    Default = false,
    Callback = function(Value) end
})

PlayerEsp:AddDivider()

PlayerEsp:AddLabel("Esp Color"):AddColorPicker("ec", {
    Default = Color3.new(1, 1, 1),
    Title = "Esp Color",
    Callback = function(Value) end
})

local Chameleon = Tabs.Visuals:AddLeftGroupbox("Chams")

Chameleon:AddToggle("armchams", {
    Text = "Arm Chams",
    Default = false,
    Callback = function(Value) end
})

Chameleon:AddToggle("weaponchams", {
    Text = "Weapon Chams",
    Default = false,
    Callback = function(Value) end
})

local Bullet = Tabs.Visuals:AddLeftGroupbox("Bullet")

Bullet:AddToggle("bullettracer", {
    Text = "Bullet Tracer",
    Default = false,
    Callback = function(Value) end
})

local VehicleEsp = Tabs.Visuals:AddRightGroupbox("Vehicle")

VehicleEsp:AddDropdown("vehicletype", {
    Values = {"ATV", "Boat", "Heli", "Pickup"},
    Default = "ATV",
    Text = "Vehicle",
    Callback = function(Value) end
})

VehicleEsp:AddToggle("vehicleesp", {
    Text = "Vehicle Esp",
    Default = false,
    Callback = function(Value) end
})

local Crosshair = Tabs.Visuals:AddRightGroupbox("Crosshair")

Crosshair:AddDropdown("crosshairshape", {
    Values = {"Circle", "Lines"},
    Default = "Circle",
    Text = "Shape",
    Callback = function(Value) end
})

Crosshair:AddToggle("crosshairenabled", {
    Text = "Enable",
    Default = false,
    Callback = function(Value) end
})

Crosshair:AddSlider("crosshairsize", {
    Text = "Crosshair Size",
    Default = 50,
    Min = 10,
    Max = 300,
    Rounding = 0,
    Callback = function(Value) end
})

local DefaultAmbient = _game.Lighting.DefaultAmbient
local DefaultOutdoorAmbient = _game.Lighting.OutdoorAmbient
local DefaultBrightness = _game.Lighting.Brightness

local Ambient = Tabs.Visuals:AddRightGroupbox("Ambient")

Ambient:AddToggle("ambient", {
    Text = "Enable",
    Default = false,
    Callback = function(Value)
        if Value then
            AddConnection(Connections.Gameplay, "Ambient", game:GetService("RunService").RenderStepped:Connect(function()
                services["lighting"].Ambient = Options.ambientcolor.Value
                services["lighting"].OutdoorAmbient = Options.outdoorambient.Value
                services["lighting"].Brightness = Options.ambientbrightness.Value
            end))
        else
            RemoveConnection(Connections.Gameplay, "Ambient")
            services["lighting"].Ambient = DefaultAmbient
            services["lighting"].OutdoorAmbient = DefaultOutdoorAmbient
            services["lighting"].Brightness = DefaultBrightness
        end
    end
})

Ambient:AddLabel("Ambient Color"):AddColorPicker("ambientcolor", {
    Default = Color3.fromRGB(0, 0, 0),
    Title = "Ambient Color",
    Callback = function(Value)
        if Toggles.ambient.Value then
            services["lighting"].Ambient = Value
        end
    end
})

Ambient:AddLabel("Outdoor Ambient"):AddColorPicker("outdoorambient", {
    Default = Color3.fromRGB(70, 70, 70),
    Title = "Outdoor Ambient",
    Callback = function(Value)
        if Toggles.ambient.Value then
            services["lighting"].OutdoorAmbient = Value
        end
    end
})

Ambient:AddSlider("ambientbrightness", {
    Text = "Brightness",
    Default = 1,
    Min = 0,
    Max = 10,
    Rounding = 1,
    Callback = function(Value)
        if Toggles.ambient.Value then
            services["lighting"].Brightness = Value
        end
    end
})

local Terrain = Tabs.Visuals:AddRightGroupbox("Terrain")

Terrain:AddToggle("reducewater", {
    Text = "No Waves",
    Default = false,
    Callback = function(Value)
		workspace.Terrain.WaterWaveSize = Value and 0 or _game.Workspace.WaterWaveSize
	end
})

local MovementTab = Tabboxes.Misc:AddTab("Movement")

local KeyList = loadstring(game:HttpGet("https://website-iota-ivory-12.vercel.app/code/loader/u/keys.lua"))()
local function InputKeys(Keys, Delay)
    Delay = Delay or 0
    for _, v in ipairs(Keys) do
        if keypress then
            keypress(KeyList[v])
        else
            services["vim"]:SendKeyEvent(true, Enum.KeyCode[v], false, game)
            task.wait(0.05)
            services["vim"]:SendKeyEvent(false, Enum.KeyCode[v], false, game)
        end
        if Delay and Delay > 0 then
            task.wait(Delay)
        end
    end
end

local function FarJump()
	local keys = {Keys["C"], Keys["Space"]}
	InputKeys(keys, 0.02)
end

MovementTab:AddToggle("autoslidejump", {
    Text = "Auto Slide Jump",
    Default = false,
    Callback = function(Value)
        if Value then
            AddConnection(Connections.Gameplay, "AutoSlideJump", Heartbeat:Connect(function()
                if _localplayer.IsGrounded() then
                    FarJump()
                end
            end))
        else
            RemoveConnection(Connections.Gameplay, "AutoSlideJump")
        end
    end
})

MovementTab:AddButton("Slide Jump", function() 
	FarJump()
end)

MovementTab:AddDivider()

MovementTab:AddToggle("walkspeed", {
    Text = "Walkspeed",
    Default = false,
    Callback = function(Value) end
})

MovementTab:AddSlider("movementspeed", {
    Text = "Movement Speed",
    Default = 20,
    Min = 2,
    Max = 20,
    Rounding = 0,
    Callback = function(Value) end
})

MovementTab:AddDivider()

MovementTab:AddToggle("alwaysgrounded", {
    Text = "Always Grounded",
    Default = false,
    Callback = function(Value) end
})

MovementTab:AddToggle("antisprintblock", {
    Text = "Anti Sprint Block",
    Default = false,
    Callback = function(Value) end
})

local ExploitsTab = Tabboxes.Misc:AddTab("Misc")

ExploitsTab:AddToggle("longneck", {
    Text = "Long Neck",
    Default = false,
    Callback = function(Value) end
})

ExploitsTab:AddDivider()

ExploitsTab:AddToggle("freecam", {
    Text = "Freecam",
    Default = false,
    Callback = function(Value) end
})

ExploitsTab:AddSlider("freecamspeed", {
    Text = "Freecam Speed",
    Default = 50,
    Min = 10,
    Max = 300,
    Rounding = 0,
    Callback = function(Value) end
})

ExploitsTab:AddDivider()

ExploitsTab:AddSlider("camerafov", {
    Text = "Camera Fov",
    Default = 70,
    Min = 10,
    Max = 120,
    Rounding = 0,
    Callback = function(Value) end
})

local VehicleMisc = Tabs.Misc:AddRightGroupbox("Vehicle")

VehicleMisc:AddToggle("vehiclefly", {
    Text = "Fly",
    Default = false,
    Callback = function(Value) end
})

VehicleMisc:AddSlider("vehicleflyspeed", {
    Text = "Speed Amount",
    Default = 50,
    Min = 10,
    Max = 300,
    Rounding = 0,
    Callback = function(Value) end
})

VehicleMisc:AddDivider()

VehicleMisc:AddToggle("vehiclespeed", {
    Text = "Vehicle Speed",
    Default = false,
    Callback = function(Value) end
})

VehicleMisc:AddSlider("vehiclespeedamount", {
    Default = 50,
    Min = 10,
    Max = 300,
    Rounding = 0,
    Callback = function(Value) end
})

-- Ui Settings

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:BuildConfigSection(Tabs.Config)
ThemeManager:ApplyToTab(Tabs.Config)

local Gui = Tabs.Config:AddRightGroupbox("Gui")

Gui:AddButton("Unload Gui", function()
    Library:Unload()
end)

MenuGroup:AddLabel("Menu bind")
	:AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })

SaveManager:LoadAutoloadConfig()
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })

ThemeManager:SetFolder("trident")
SaveManager:SetFolder("trident/Configs")
