-- Load the library
local Library = loadstring(game:HttpGet("https://website-iota-ivory-12.vercel.app/code/scripts/uilib/main.lua"))()

-- Create a window
local Window = Library.new("My Awesome UI")

-- Create tabs
local MainTab = Window:CreateTab("Main")
local VisualsTab = Window:CreateTab("Visuals")

-- Add sections to tabs
local PlayerSection = Window:CreateSection(MainTab, "Player Options")
local ESPSection = Window:CreateSection(VisualsTab, "ESP Options")

-- Add toggles
Window:CreateToggle(PlayerSection, "Fly", function(value)
    print("Fly toggled:", value)
end)

Window:CreateToggle(ESPSection, "Player ESP", function(value)
    print("Player ESP:", value)
end)

-- Add buttons
Window:CreateButton(PlayerSection, "Reset Character", function()
    game.Players.LocalPlayer.Character:BreakJoints()
end)

-- Add sliders
Window:CreateSlider(PlayerSection, "WalkSpeed", 16, 100, function(val)
    game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = val
end)

-- Add dropdowns
Window:CreateDropdown(PlayerSection, "Select Tool", {"Sword","Gun","Pickaxe"}, function(opt)
    print("Selected tool:", opt)
end)
