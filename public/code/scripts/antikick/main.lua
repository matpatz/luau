-- Reignx (goofy) code

--[[
	WARNING: Heads up! This script has not been verified by ScriptBlox. Use at your own risk!
]]
local getgenv, getnamecallmethod, hookmetamethod, hookfunction, newcclosure, checkcaller, lower, gsub, match =
    getgenv, getnamecallmethod, hookmetamethod, hookfunction, newcclosure, checkcaller, string.lower, string.gsub, string.match

if getgenv().Xemon_Protection then
    return
end

local cloneref = cloneref or function(...) return ... end
local clonefunction = clonefunction or function(...) return ... end

local Players = cloneref(game:GetService("Players"))
local LocalPlayer = cloneref(Players.LocalPlayer)
local StarterGui = cloneref(game:GetService("StarterGui"))
local SetCore = clonefunction(StarterGui.SetCore)
local FindFirstChild = clonefunction(game.FindFirstChild)

local CompareInstances = (CompareInstances and function(Instance1, Instance2)
    if typeof(Instance1) == "Instance" and typeof(Instance2) == "Instance" then
        return CompareInstances(Instance1, Instance2)
    end
end) or function(Instance1, Instance2)
    return typeof(Instance1) == "Instance" and typeof(Instance2) == "Instance"
end

local CanCastToSTDString = function(...)
    return pcall(FindFirstChild, game, ...)
end

getgenv().Xemon_Protection = {
    Enabled = true,
    SendNotifications = false,
    CheckCaller = false
}

local OldNamecall
OldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(...)
    local self, message = ...
    local method = getnamecallmethod()
    local isCallerValid = true
    if Xemon_Protection.CheckCaller then
        local success, result = pcall(checkcaller)
        isCallerValid = success and result or true
    end
    if (isCallerValid or not Xemon_Protection.CheckCaller)
        and CompareInstances(self, LocalPlayer)
        and gsub(method, "^%l", string.upper) == "Kick"
        and Xemon_Protection.Enabled then
        if CanCastToSTDString(message) then
            return
        end
    end
    return OldNamecall(...)
end))

local OldFunction
OldFunction = hookfunction(LocalPlayer.Kick, function(...)
    local self, message = ...
    local isCallerValid = true
    if Xemon_Protection.CheckCaller then
        local success, result = pcall(checkcaller)
        isCallerValid = success and result or true
    end
    if (isCallerValid or not Xemon_Protection.CheckCaller)
        and CompareInstances(self, LocalPlayer)
        and Xemon_Protection.Enabled then
        if CanCastToSTDString(message) then
            return
        end
    end
    return OldFunction(...)
end)

