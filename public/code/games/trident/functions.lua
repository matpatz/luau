function identify(child)
    if not child or not child.Parent then return "Unknown" end
    local model = child.Parent

    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("MeshPart") then
            if part.MeshId == "rbxassetid://12939036056" then
                if part.Color == Color3.fromRGB(72,72,72) then
                    return "Stone"
                elseif part.Color == Color3.fromRGB(199,172,120) then
                    return "Iron"
                elseif part.Color == Color3.fromRGB(248,248,248) then
                    return "Nitrate"
                end
            end

            if part.Name:find("Trunk") or part.Name:find("Leaves") or part.Name:find("Cacti") then
                return "Tree / Cacti"
            end

            if part.MeshId == "rbxassetid://94451148966574" then
                return "Cardboard"
            end

            if part.MeshId == "rbxassetid://13856404606" then
                return "Metal"
            end

            if part.MeshId == "rbxassetid://13895291313" then
                return "Safe"
            end
        end

        if part:IsA("UnionOperation") then
            if part.Name:find("Prim") then
                return "Gasoline"
            end
            if part.Name:find("flip") then -- ill update later fr
                return "Truck"
            end
        end
    end

    if model:FindFirstChild("Frame") and model:FindFirstChild("Seat") then
        return "ATV"
    end

    return "Unknown"
end

print(identify(workspace:GetChildren()[399].default))
