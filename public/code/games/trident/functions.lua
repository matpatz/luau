local v, functions = loadstring(game:HttpGet("https://website-iota-ivory-12.vercel.app/code/loader/u/vars.lua"))(), loadstring(game:HttpGet("https://website-iota-ivory-12.vercel.app/code/game/trident/functions.lua"))()

getgenv().lp = {
    ignore = workspace.Const.Ignore,
    top = workspace.Const.Ignore.LocalCharacter.Top,
    middle = workspace.Const.Ignore.LocalCharacter.Middle,
    bottom = workspace.Const.Ignore.LocalCharacter.Bottom,
    tcp = v.player.TCP,
    orignal = v.rep.Shared.entities.Player.Model,
    gc = {
        projectiles = {},
        classes = nil,
        entitys = nil,
        recoil = nil,
        sendtcp = nil,
        isgrounded = nil,
        character = nil,
        equippeditem = nil,
        camera = nil
    }
}

for i,v in pairs(getgc(true)) do
    if type(v) == "table" then
        if type(rawget(v, "Camera")) == "table" and rawget(v.Camera, "type") == "Camera" then
            lp.gc.classes = v
        end
        if type(rawget(v, "updateCharacter")) == "function" then
            lp.gc.character = v
        end
        if type(v) == 'table' and rawget(v, "SetMaxRelativeLookExtentsY") then
            lp.gc.camera = v
        end
    end
    if type(v) == "function" then
        local name = getinfo(v).name
        if name == "GetEntityFromPart" then
            lp.gc.entitylist = v
        end
        if name == "createProjectile" then
            table.insert(trident.gc.createProjectile, v)
        end
        if name == "Recoil" and not rawget(getfenv(v), "script") then
            lp.gc.recoil = v
        end
        if name == "IsGrounded" then
            lp.gc.isgrounded = v
        end
        if name == "GetEquippedItem" then
            lp.gc.equippeditem = v
        end
        if name == "GetCFrame" and getinfo(v).short_src:lower():find("camera") then
            lp.gc.getcamcframe = v
        end
    end
    --if lp.gc.entitylist and lp.gc.classes then break end
end

function identify(model)
    if model:FindFirstChild("Armor") or model:FindFirstChild("HumanoidRootPart") then
        return "alive " .. model
    end
end

function check(r, p) local r = p:GetRoleInGroup(r) or "" for _, bad in ipairs(roles) do if r:find(bad) then p:Kick("detected → "..r) end end end
