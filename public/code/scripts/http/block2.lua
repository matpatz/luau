-- block all Http functions safely
local mt = getrawmetatable(game)
setreadonly(mt,false)

local oldIndex = mt.__index
local oldNamecall = mt.__namecall

mt.__index = newcclosure(function(self,key)
    if self == game and (key == "HttpGet" or key == "HttpGetAsync" or key == "HttpPost" or key == "HttpPostAsync") then
        warn("Blocked attempt to access "..key)
        return function(...) return nil end
    end
    return oldIndex(self,key)
end)

mt.__namecall = newcclosure(function(self,...)
    local method = getnamecallmethod()
    if self == game and (method == "HttpGet" or method == "HttpGetAsync" or method == "HttpPost" or method == "HttpPostAsync") then
        warn("Blocked attempt to call "..method)
        return nil
    end
    return oldNamecall(self,...)
end)

setreadonly(mt,true)

print("HTTP spying blocked successfully")
