local rep = game:GetService("ReplicatedStorage")
local FlagsModule = require(rep.Packages.GameData.Flags)
local FlagsService = rep.Packages.Knit.Services.FlagsService

local SolveRemote = FlagsService.RF.Solve
local TriggerEvent = FlagsService.RE.TriggerGameSolution

TriggerEvent.OnClientEvent:Connect(function(eventType, data)
    if eventType ~= "ShowFlag" then return end

    local imageId = data.SolutionImageId
    local difc = data.Rarity or "Cakewalk"
    local countryName

    for _, flag in ipairs(FlagsModule[difc] or {}) do
        if flag.ImageId == imageId then
            countryName = flag.CountryName
            break
        end
    end

    if countryName then
        SolveRemote:InvokeServer(countryName)
        print("Answered:", countryName)
    else
        warn("failed, image Id:", imageId)
    end
end)
