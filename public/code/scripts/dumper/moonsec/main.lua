local output = ""
local captured = {}
local count = 0

-- Safe file writing
local function write(file, data)
    if writefile then
        local success, err = pcall(writefile, file, data)
        return success
    end
    return false
end

local function fmt(tbl, indent, seen)
    indent = indent or 0
    seen = seen or {}
    
    if seen[tbl] then return "\"<cycle>\"" end
    if indent > 10 then return "\"<too deep>\"" end
    
    seen[tbl] = true
    local spacing = string.rep("  ", indent)
    local result = "{"
    local first = true
    
    for k, v in pairs(tbl) do
        if first then
            first = false
        else
            result = result .. ","
        end
        
        result = result .. "\n" .. spacing .. "  "
        
        if type(k) == "string" and k:match("^[%a_][%a%d_]*$") then
            result = result .. k .. " = "
        else
            result = result .. "[" .. tostring(k) .. "] = "
        end
        
        if type(v) == "table" then
            result = result .. fmt(v, indent + 1, seen)
        elseif type(v) == "string" then
            result = result .. string.format("%q", v)
        else
            result = result .. tostring(v)
        end
    end
    
    if not first then
        result = result .. "\n" .. spacing
    end
    result = result .. "}"
    
    seen[tbl] = nil
    return result
end

do
    local og_unpack = unpack or table.unpack
    
    getfenv(0).unpack = function(...)
        local args = {...}
        local t = args[1]
        
        if type(t) == "table" then
            count = count + 1
            local success, formatted = pcall(fmt, t)
            
            if success then
                output = output .. string.format("\n-- Table #%d --\n%s\n", count, formatted)
                table.insert(captured, {
                    table = t,
                    size = #t,
                    elementCount = 0
                })
                
                local count = 0
                for _ in pairs(t) do count = count + 1 end
                captured[#captured].elementCount = count
                
                print("Table #" .. count .. " | Array size: " .. #t .. " | Elements: " .. count)
            end
        end
        
        return og_unpack(...)
    end
    
    local og_load = loadstring or load
    getfenv(0).loadstring = function(code, ...)
        if type(code) == "string" then
            if code:find("return function") and code:find("local d=") then -- every obf used return function, and local d= is probbaly random
                print("it can really be any executor but idk we did load so yay")
            end
            
            if #code > 10000 then
                print("MASSIVE file : " .. #code .. " chars")
            end
            
            if code:find("\\x%x%x") then
                print("hex") -- i think base64 ngl
            end
        end
        return og_load(code, ...)
    end
end

-- Save function
local function save()
    if #captured == 0 then
        print("[INFO] No tables captured yet")
        return false
    end
    
    local filename = "table_dump_" .. os.time() .. ".txt"
    local header = string.format([[
TABLE CAPTURE RESULTS : 
Time: %s
Total Tables: %d
Capture Count: %d

]],
    os.date("%Y-%m-%d %H:%M:%S"),
    #captured,
    count)

    local content = header .. output
    
    local saved = write(filename, content)
    local copied = setclipboard(content) -- every mf has setclipboard
    
    if saved then
        print("saved to: " .. filename)
    end
    
    if copied then
        print("check your clipboard")
    end
    
    print(#captured .. " tables total")
    return true
end

task.spawn(function()
    for i = 1, 6 do
        task.wait(5)
        
        if #captured > 0 then
            print("found " .. #captured .. " tables, saving..")
            save()
            break
        elseif i == 3 then
            print("waiting (not likely)")
        end
    end
end)

getfenv(0).saveCapture = save
getfenv(0).clearCapture = function()
    output = ""
    captured = {}
    count = 0
    print("cleared")
end

if table.unpack and table.unpack ~= unpack then
    local og_table_unpack = table.unpacks
    local success = pcall(function()
        table.unpack = function(t, i, j)
            if type(t) == "table" then
                count = count + 1
                local success, formatted = pcall(fmt, t)
                if success then
                    output = output .. string.format("\n-- Table.unpack #%d --\n%s\n", count, formatted)
                    table.insert(captured, t)
                    print("unpack #" .. count .. " | Size: " .. #t)
                end
            end
            return og_table_unpack(t, i, j)
        end
    end)
end

loadstring(readfile("message.txt"))()
