local ssignal = (RBXScriptSignal)
local function expect(got, expected, care_about_value, arg_num, message)
    expt = typeof(expected)
  
    arg_num = arg_num or 1
    if not message then
        message = "expected " .. expt .. " at #" .. arg_num .. " got " .. typeof(got)
    end

    if not care_about_value then
        assert(typeof(got) == expt, message)
    else -- run some more checks
        message = "expected " .. expected .. " at #" .. arg_num .. " got " .. typeof(got) -- wrong values
    
        assert(typeof(got) == expected, message)
        --assert(typeof(got) == expt, message) -- to keep og or not ... idk
    end
end
