local time = tick(); local sunc, failed, tcount = 0, 0, 0
local tests = {} -- used to run all functions, and search anything extra

local function rname()
    return tostring(math.random(1e9, 1e9))
end

local function sendTest(item, result)
    local output; tcount += 1

    if result == true then
        output = "✅"
        sunc += 1
    elseif result == false then
        output = "❌"
        failed += 1
    elseif result == "unfinished" then
        output = "🥀"
    else
        output = "‍🤷‍♂️"
    end

    print(output, item)
end

local function checkcall()
    local passed = checkcaller() == true
    sendTest("checkcaller", passed)
end; table.insert(tests, checkcall)

local function clonef()
    local orignal = function() print("...") end; local clone = clonefunction(orignal)

    local passed = getfenv(orignal) ~= clone
    sendTest("clonefunction", passed)
end; table.insert(tests, clonef)

local function getfhash()
    local function check(hash)
        return #hash == 96 and hash:match("^[0-9a-fA-F]+$") ~= nil
    end
    local function p()
        if 1 == 1 then a = "" end
    end

    local passed; local hash = getfunctionhash(check)
    passed = check(hash) == true and getfunctionhash(p) ~= hash -- [2] = stupid

    sendTest("getfunctionhash", passed)
end; table.insert(tests, getfhash)

local hf_oldp
local function hookf()
    hf_oldp = hookfunction(math.random, function(...)
        return 23
    end)

    local passed = (math.random() == 23)
    sendTest("hookfunction", passed)
end; table.insert(tests, hookf)

-- actually supposed to be ninth but without fixing the hook animation breaks so i just put it here
local function restoref()
    restorefunction(math.random)

    local passed = type(math.random()) == "number" and math.random() ~= 23
    sendTest("restorefunction", passed)
end; table.insert(tests, restoref)


local function hookmeta()
    local old
    old = hookmetamethod(game, "__index", newcclosure(function(self, key)
        if key == "WalkSpeed" then
            return 7
        end

        return old(self, key)
    end))

    local passed = game:GetService("Players")["LocalPlayer"]["Character"]["Humanoid"].WalkSpeed == 7

    sendTest("hookmetamethod", passed)
end; table.insert(tests, hookmeta)

local c_closure = newcclosure(function()
    return "C"
end)
local function newc()
    local function l_closure()
        return "L"
    end

    local passed = iscclosure(l_closure) == false and iscclosure(c_closure) == true

    sendTest("newcclosure", passed)
end; table.insert(tests, newc)

local function is_c()
    local passed = islclosure(c_closure) == true and not iscclosure(sendTest)

    sendTest("islclosure", passed)
end; table.insert(tests, is_c)

local function is_exec()

    local passed = isexecutorclosure(c_closure) == true and isexecutorclosure(print) == false

    sendTest("isexecutorclosure", passed)
end; table.insert(tests, is_exec)

local function is_l()
    local lclosure = (function()
        return "L"
    end)

    local passed = islclosure(lclosure) == true and c_closure == false 
    sendTest("islclosure", passed)
end; table.insert(tests, is_l)

for _, item in pairs(tests) do -- runs everything!
    item()
end

print(string.format(
    "Completed the tests with a success rate of %.2f%% (%d/%d; Failed: %d) within %.2f seconds\n\n%s",
    (sunc / tcount) * 100, --success rate
    sunc,
    tcount,
    failed,
    tick() - time,
    string.rep(" ", 13) .. "View 'https://docs.sunc.su' for more accurate and detailed results."
))

-- way to scan an individual function for extra information, possibly not including in sunc

local gui = Instance.new("ScreenGui", game:GetService("CoreGui")["RobloxGui"])
gui.Name = rname()

local button = Instance.new("TextButton", gui)
button.Name = rname()
button.Text = "Load Extra?"
button.AnchorPoint = Vector2.new(0.5, 0.5); button.Position = UDim2.fromScale(0.75, 0.5)
button.Size = UDim2.fromScale(0.1, 0.05)
Instance.new("UICorner", button).CornerRadius = UDim.new(0.2, 0)

button.Activated:Connect(function()
	loadstib
end)
