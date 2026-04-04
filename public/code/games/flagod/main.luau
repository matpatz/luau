local rep = game:GetService("ReplicatedStorage")
local flagmod = require(rep.Packages.GameData.Flags)
local flags = rep.Packages.Knit.Services.FlagsService

local SolveRemote = FlagsService.RF.Solve

flags.RE.TriggerGameSolution.OnClientEvent:Connect(function(eventType, data)
	task.wait(tonumber(getgenv().timer))
    if eventType ~= "ShowFlag" then return end

    local imageId = data.SolutionImageId
    local difc = data.Rarity or "Cakewalk"
    local countryName

    for _, flag in ipairs(flagmod[difc] or {}) do
        if flag.ImageId == imageId then
            countryName = flag.CountryName
            break
        end
    end

    if countryName then
        SolveRemote:InvokeServer(countryName)
        print("Answered:", countryName)
        getgenv().LastAnswer = countryName
    else
        warn("failed, image Id:", imageId)
    end
end)
