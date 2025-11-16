function identify(child, sleepCheck, weaponCheck)
    if not child then return "Unknown" end

    local model = child:IsA("Model") and child or child.Parent
    if not model then return "Unknown" end

    for _, part in ipairs(model:GetDescendants()) do
        
        if part:IsA("Folder") and part.Name == "Armor" then
            local char = part.Parent
            if not char then return "Player" end

            local head = char:FindFirstChild("Head")
            if not head then return "Player" end
            
            local nameTag = head:FindFirstChild("Nametag")
            nameTag = nameTag and nameTag:FindFirstChild("tag")
            local user = nameTag and nameTag.Text or "Player"

            if sleepCheck and not head:FindFirstChild("face") then -- fire we know
                return "Sleeper " .. user
            end

            if weaponCheck then
                local hand = char:FindFirstChild("HandModel")
                local tool = hand and hand:GetChildren()[1] and hand:GetChildren()[1].Name or "Unarmed"
                return user .. " " .. tool
            end

            return user
        end

        if part:IsA("MeshPart") then
            if part.MeshId == "rbxassetid://12939036056" then
                if part.Color == Color3.fromRGB(72,72,72) then return "Stone" end
                if part.Color == Color3.fromRGB(199,172,120) then return "Iron" end
                if part.Color == Color3.fromRGB(248,248,248) then return "Nitrate" end
            end

            if part.Name:find("Trunk") or part.Name:find("Leaves") or part.Name:find("Cacti") then return "Tree / Cacti" end
            if part.MeshId == "rbxassetid://86433652951149" then return "Vending" end
            if part.MeshId == "rbxassetid://18507721359" then return "Salvage" end
            if part.MeshId == "rbxassetid://94451148966574" then return "Cardboard" end
            if part.MeshId == "rbxassetid://13856404606" then return "Metal" end
            if part.MeshId == "rbxassetid://13895291313" then return "Safe" end
        end

        if part:IsA("UnionOperation") then
            if part.Name:find("Body") then return "TC" end -- might be mistaken for a car or sum
            if part.Name:find("Prim") then return "Gasoline" end
            if part.Name:find("flip") then return "Car" end
        end
    end

    return "Unknown"
end

--print(identify(workspace:GetChildren()[349], false, false))
