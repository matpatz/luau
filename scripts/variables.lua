do
    for _, service in ipairs(game:GetChildren()) do
        if pcall(function() return service:IsA("Service") end) then
            localName = service.Name:gsub("%s", "")
            _G[localName] = service
            _G[localName] = service 
        end
    end
end
