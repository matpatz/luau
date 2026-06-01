local services = loadstring(game:HttpGet(
    "https://website-iota-ivory-12.vercel.app/code/loader/u/vars.lua"
))()

local _game = services["marketplace"]:GetProductInfo(game.PlaceId).Name

local Rayfield = loadstring(game:HttpGet(
    "https://website-iota-ivory-12.vercel.app/code/loader/u/ui/rayfield.lua"
))()

local window = Rayfield:CreateWindow({
    Name = _game,
    LoadingTitle = "fah you",
    LoadingSubtitle = "subtitle",
})

local tabs = {
    main = window:CreateTab("Main", 4483362458),
    settings = window:CreateTab("Settings", 4483362458),
}

local connections = {
    communication = {},
    table = {},
    gameplay = {},
}

local states = {
    runtime = {},

    values = {
		Autoclick = false,
		AutoLuckyDrop = false,

		Cps = 1,
        Delay = 0.1,

        communication = Instance.new("BindableEvent"),
    },
}

local responses = {}

local function SetValue(obj, key, value)
    obj[key] = value
    states.values.communication:Fire({
        Object = obj,
        Key = key,
        Value = value,
    })
end

local function addConnection(category, name, connection)
    if category[name] then
        pcall(function()
            if typeof(category[name]) == "RBXScriptConnection" then
                category[name]:Disconnect()
            else
                task.cancel(category[name])
            end
        end)
    end

    category[name] = connection
    states.runtime[name] = true
end

local function removeConnection(category, name)
    if not category[name] then return end

    pcall(function()
        if typeof(category[name]) == "RBXScriptConnection" then
            category[name]:Disconnect()
        else
            task.cancel(category[name])
        end
    end)

    category[name] = nil
    states.runtime[name] = false
end

tabs.main:CreateSlider({
    Name = "Click Delay",
    Range = {0, 1},
    Increment = 0.05,
    CurrentValue = 0.1,
    Callback = function(value)
        SetValue(states.values, "Delay", value)
    end,
})

tabs.main:CreateInput({
   Name = "Click Value",
   CurrentValue = 1,
   PlaceholderText = "Cps",
   RemoveTextAfterFocusLost = false,
   Callback = function(value)
		SetValue(states.values, "Cps", tonumber(value))
   end,
})

tabs.main:CreateToggle({
    Name = "Autoclicker",
    CurrentValue = false,
    Callback = function(value)
        SetValue(states.values, "Autoclick", value)
    end,
})

tabs.main:CreateDivider()

tabs.main:CreateToggle({
    Name = "Auto Open Luckydrop",
    CurrentValue = false,
    Callback = function(value)
        SetValue(states.values, "AutoLuckyDrop", value)
    end,
})

task.spawn(function()
	while true do
		if states.values.Autoclick then
			services.rep.Remotes.ClickBrainrot:FireServer(states.values.Cps)
			task.wait(states.values.Delay)
		else
			task.wait(0.1)
		end
	end
end)

local LuckyDrop = services["rep"].Remotes.LuckyDrop
LuckyDrop.OnClientEvent:Connect(function(data)
    if states.values.AutoLuckyDrop then
        local token = data.ServerCpsLockToken
        
        services["rep"].Remotes.LuckyDropCompleted:FireServer(token)
    end
end)
