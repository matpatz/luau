local HttpService = game:GetService("HttpService")

local _RequestAsync = HttpService.RequestAsync
local _PostAsync = HttpService.PostAsync

local mt = getrawmetatable(game)
setreadonly(mt, false)

local oldIndex = mt.__index
mt.__index = newcclosure(function(self, key)
    -- intercept property access like HttpService.RequestAsync
    if self == HttpService then
        if key == "RequestAsync" then
            return function(params)
                -- safe: only log, do not modify or obfuscate
                if params then
                    print("[HttpService] RequestAsync called. Body (len):", (type(params.Body) == "string") and #params.Body or tostring(params.Body))
                else
                    print("[HttpService] RequestAsync called with nil params")
                end
                return _RequestAsync(HttpService, params)
            end
        elseif key == "PostAsync" then
            return function(url, body, ...)
                print("[HttpService] PostAsync called. url:", tostring(url), "body (len):", (type(body) == "string") and #body or tostring(body))
                return _PostAsync(HttpService, url, body, ...)
            end
        end
    end

    -- fall back to original __index behavior (function or table)
    if type(oldIndex) == "function" then
        return oldIndex(self, key)
    else
        return oldIndex[key]
    end
end)

local oldNamecall = mt.__namecall
mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    if self == HttpService and (method == "RequestAsync" or method == "PostAsync") then
        local args = {...}
        if method == "RequestAsync" and args[1] then
            print("[HttpService:namecall] RequestAsync body length:", (type(args[1].Body) == "string") and #args[1].Body or tostring(args[1].Body))
        elseif method == "PostAsync" then
            print("[HttpService:namecall] PostAsync body length:", (type(args[2]) == "string") and #args[2] or tostring(args[2]))
        end
        -- call original with proper self and unpacked args
        return (method == "RequestAsync" and _RequestAsync or _PostAsync)(self, table.unpack(args))
    end
    return oldNamecall(self, ...)
end)

setreadonly(mt, true)
