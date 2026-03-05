local time = tick(); local sunc, failed, tcount = 0, 0, 0
local tests = {}

local function rname()
    return tostring(math.random(1e8, 1e9))
end

local function sendTest(item, result, extra, emsg)
    local output; tcount += 1

    if result == true then
        output = " "
        sunc += 1
    elseif result == false then
        output = " "
        failed += 1
    elseif result == "unfinished" then
        output = " "
    else
        output = "~~~"
    end

    if extra == nil then extra = false; emsg = "-" end

    local out = ""
    if extra == false then
        out = output .. " " .. tostring(item)
    else
        out = "\t" .. " | " .. tostring(emsg) .. " | "
    end

    print(out)
end

local function sendSpecial(item, result, extra, emsg)
  print(item, result)
end

local function checkcall()
    local passed = checkcaller() == true
    sendTest("checkcaller", passed)
end; table.insert(tests, { name = "checkcaller", fn = checkcall })

local function clonef()
    local orignal = function() print("...") end; local clone = clonefunction(orignal)
    local passed = getfenv(orignal) ~= clone
    sendTest("clonefunction", passed)
end; table.insert(tests, { name = "clonefunction", fn = clonef })

local function getfhash()
    local function check(hash)
        return #hash == 96 and hash:match("^[0-9a-fA-F]+$") ~= nil
    end
    local function p()
        if 1 == 1 then a = "" end
    end

    local passed; local hash = getfunctionhash(check)
    passed = check(hash) == true and getfunctionhash(p) ~= hash
    sendTest("getfunctionhash", passed)
end; table.insert(tests, { name = "getfunctionhash", fn = getfhash })

local hf_oldp
local function hookf()
    hf_oldp = hookfunction(math.random, function(...) return 23 end)
    local passed = (math.random() == 23)
    sendTest("hookfunction", passed)
end; table.insert(tests, { name = "hookfunction", fn = hookf })

local function restoref()
    restorefunction(math.random)
    local passed = type(math.random()) == "number" and math.random() ~= 23
    sendTest("restorefunction", passed)
end; table.insert(tests, { name = "restorefunction", fn = restoref })

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
end; table.insert(tests, { name = "hookmetamethod", fn = hookmeta })

local c_closure = newcclosure(function() return "C" end)
local function newc()
    local function l_closure() return "L" end
    local passed = iscclosure(l_closure) == false and iscclosure(c_closure) == true
    sendTest("newcclosure", passed)
end; table.insert(tests, { name = "iscclosure", fn = newc })

local function is_exec()
    local passed = isexecutorclosure(c_closure) == true and isexecutorclosure(print) == false
    sendTest("isexecutorclosure", passed)
end; table.insert(tests, { name = "isexecutorclosure", fn = is_exec })

local function is_l()
    local lclosure = function() return "L" end
    local passed = islclosure(lclosure) == true and iscclosure(lclosure) == false
    sendTest("islclosure", passed)
end; table.insert(tests, { name = "islclosure", fn = is_l })

local function is()
    local passed = funcy(true) == false
    sendTest("funcy", passed)
end; table.insert(tests, { name = "notreal", fn = is })

local function ls()
    local passed = loadstring("return math.pi")() == math.pi
    sendTest("loadstring", passed)
end; table.insert(tests, {name = "loadstring", fn = ls})

local sc = {}
for _, item in pairs(game:GetDescendants()) do
  table.insert(sc, {int = item, class = item.ClassName})
end

local cf = {}
local function sccheck(...)
  local classes = {...}
  for _, class in ipairs(classes) do
    for _, item in ipairs(sc) do
      if item.class == class then
        table.insert(cf, item)
      end
    end
  end
  return cf
end

local function dummy()
  local s = "wong tong"
  string.split(s, " ")
end

local function _debug()
  local function _getconstant()
    local passed = type(debug.getproto(dummy)) == "function"
    sendTest("debug.getconstants", passed)
  end; table.insert(tests, {name = "debug.getconstant", fn = _getconstant})

  local function _getconstants()
    local passed = true
    local expected = {"string", "split", "foo bar", " "}
    local constants = debug.getconstants(dummy)
    for _, constant in ipairs(constants) do
      local found = false
      for _, item in pairs(expected) do
        if tostring(constant):find(item) then
          found = true
        end
      end
      if not found then
        passed = false
      end
    end
    sendTest("debug.getconstants", passed)
  end; table.insert(tests, {name = "debug.getconstants", fn = _getconstants})

  local function _getproto()
    local passed = true
    sendTest("debug.getproto", passed)
  end; table.insert(tests, {name = "debug.getproto", fn = _getproto})

  local function _getprotos()
    local passed = true
    sendTest("debug.getprotos", passed)
  end; table.insert(tests, {name = "debug.getprotos", fn = _getprotos})

  local function _getstack()
    local passed = true
    sendTest("debug.getstack", passed)
  end; table.insert(tests, {name = "debug.getstack", fn = _getstack})

  local function _setstack()
    local passed = true
    sendTest("debug.setstack", passed)
  end; table.insert(tests, {name = "debug.setstack", fn = _setstack})

  local function _getupvalue()
    local passed = true
    sendTest("debug.getupvalue", passed)
  end; table.insert(tests, {name = "debug.getupvalue", fn = _getupvalue})

  local function _setupvalue()
    local passed = true
    sendTest("debug.setupvalue", passed)
  end; table.insert(tests, {name = "debug.setupvalue", fn = _setupvalue})

  local function _getupvalues()
    local passed = true
    sendTest("debug.getupvalues", passed)
  end; table.insert(tests, {name = "debug.getupvalues", fn = _getupvalues})
end; _debug()

local function garscripts()
  local ltest = sccheck("LocalScript", "Script", "ModuleScript")
  local ctest = getscripts()
end; table.insert(tests, {name = "getscripts", fn = garscripts})

local function grscripts()
  local passed = sccheck("LocalScript", "Script") ~= nil
end; table.insert(tests, {name = "getrunningsripts", fn = grscripts})

local function grmodules()
  local passed = sccheck("Modules") ~= nil
end; table.insert(tests, {name = "getrunningmodules", fn = grmodules})

local searchable = {}

local function _oth()
  local function get_og_thread(...)
    local og_thread = oth.get_original_thread()
    local passed = og_thread and true or false
    sendTest("oth.get_original_thread", passed)
  end; table.insert(searchable, { name = "oth.get_original_thread", fn = get_og_thread})

  local function oth_hook()
    local ogp = oth.hook(math.random, function(...) return 75 end)
    local passed = math.random() == 75
    sendSpecial("oth.hook", passed)
  end; table.insert(searchable, { name = "oth.hook", fn = oth_hook })
end; _oth()

for _, test in pairs(tests) do
    local success, err = pcall(test.fn)
    if not success then
        if err:find("attempt to call a nil value") then
            err = test.name .. " function does not exist"
        end
        sendTest(test.name, false, true, err)
    end
end

getgenv().search = function(search)
    for _, item in pairs(searchable) do
        if item.name == search then return item.fn() end
    end
    for _, item in pairs(tests) do
        if item.name == search then return item.fn() end
    end
    return "Sorry, but this functions test are yet to be implemented. Feel free to request the functions support"
end

print(string.format(
    "Completed the tests with a success rate of %.2f%% (%d/%d; Failed: %d) within %.2f seconds\n\n%s",
    (sunc / tcount) * 100,
    sunc,
    tcount,
    failed,
    tick() - time,
    string.rep("\t", 4) .. "View 'https://docs.sunc.su' for more accurate and detailed results."
))

local gui = Instance.new("ScreenGui")
gui.Name = rname()
gui.Parent = gethui() or game.CoreGui

local button = Instance.new("TextButton", gui)
button.Name = rname()
button.Text = "Load Extra?"
button.AnchorPoint = Vector2.new(0.5, 0.5); button.Position = UDim2.fromScale(0.75, 0.5)
button.Size = UDim2.fromScale(0.1, 0.05)
Instance.new("UICorner", button).CornerRadius = UDim.new(0.2, 0)

button.Activated:Connect(function()
    loadstring(game:HttpGet("https://website-iota-ivory-12.vercel.app/code/scripts/unc/sunc/extra.luau"))()
end)
