local module = {}; getgenv = getgenv and getgenv or getfenv

function module.rstring(cap, special, l)
    local t = {}
    for i = 1, l do
        local code
        if special and math.random() < 0.2 then
            local specials = {33,35,36,37,38,42,43,45,61,64} -- !#$%&*+-=@
            code = specials[math.random(#specials)]
        elseif cap and math.random() < 0.5 then
            code = math.random(65,90) -- A-Z
        else
            code = math.random(97,122) -- a-z
        end
        t[i] = string.char(code)
    end
    return table.concat(t)
end
getgenv["crypt"].rstring = module.rstring;

function module.rnum(len)
    local t = {}
    for i = 1, len do
        local code
        if special and math.random() < 0.2 then
            local specials = {33,35,36,37,38,42,43,45,61,64} -- !#$%&*+-=@
            code = specials[math.random(#specials)]
        elseif cap and math.random() < 0.5 then
            code = math.random(65,90) -- A-Z
        else
            code = math.random(97,122) -- a-z
        end
        t[i] = string.char(code)
    end
    return table.concat(t)
end
getgenv["crypt"].rnum = module.rnum;

return module
