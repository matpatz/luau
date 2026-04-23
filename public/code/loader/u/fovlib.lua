local cloneref = cloneref or function(i: Instance) return i; end;
local executor = identifyexecutor and identifyexecutor() or "Unknown"
local hui = gethui and gethui() or cloneref(game:GetService("CoreGui")["RobloxGui"])

local GS: GuiService = cloneref(game:GetService("GuiService"));
local Players: Players = cloneref(game:GetService("Players"));
local UIS = cloneref(game:GetService("UserInputService"));

local plr = Players.LocalPlayer;

local code = function(n: string): string
    if crypt and crypt.base64encode then
        return crypt.base64encode(n);
    end;
    return n;
end;

local salt = function(n: string): string
    local mid = math.floor(#n / 2)

    local first = n:sub(1, mid)
    local second = n:sub(mid + 1)

    local rand = tostring(math.random(1e4, 1e6))

    return first .. rand .. second
end

local get_id = loadstring(game:HttpGet("https://raw.githubusercontent.com/sneekygoober/sneeky-s-fov-lib/refs/heads/main/get_id.luau"))();

local SG = loadstring(game:HttpGet("https://raw.githubusercontent.com/sneekygoober/sneeky-s-notifications/refs/heads/main/unrestricted_main.luau"))();
local Drawlib = loadstring(game:HttpGet("https://github.com/matpatz/luau/raw/main/public/code/loader/u/drawlib"))();
local info = loadstring(game:HttpGet("https://raw.githubusercontent.com/sneekygoober/sneeky-s-fov-lib/refs/heads/main/info.luau"))();

local discord = "https://discord.gg/" .. info.discord_link;
local key = code(info.ggKey);

if executor:match("Xeno", 1) or executor:match("Solara", 1) then
    SG["error"](executor .. " is not compatible with the silent aim!\nSwitch executors!");
    coroutine.yield();
    return function() return; end;
end;

return function(fov, func, center)
    SG["info"]("Loading UI...");

    if getgenv()[key] then
        if getgenv()[key]["draw_instance"] and getgenv()[key]["connections"] and getgenv()[key]["p_instance"] then
            getgenv()[key]["draw_instance"]:terminate();
            for _, v in next, getgenv()[key]["connections"] do v:Disconnect(); end;
            table.clear(getgenv()[key]["connections"]);
            getgenv()[key]["p_instance"]:Destroy();
            table.clear(getgenv()[key]);
            getgenv()[key] = nil;
        else
            plr:Kick("Don't tamper with that getgenv key. Discord: " .. discord);
        end;
    end;

    if not Drawlib or not Drawlib.new then
        error("Drawlib failed to load");
    end;

    fov = tonumber(fov) or 100;

    local draw = Drawlib.new(fov, func, center);
    local enabled = true;

    local menuKey = getgenv().menuKey or Enum.KeyCode.RightControl;
    local fovKey = getgenv().fovKey or Enum.KeyCode.Delete;

    local setMenu = false;
    local setFov = false;

    local gui = Instance.new("ScreenGui", hui);
    gui.Name = salt(code(gui:GetDebugId()));

    local menu = Instance.new("CanvasGroup", gui)
    menu.Name = code(menu:GetDebugId());
    menu.AnchorPoint = Vector2.new(0.5, 0.5);
    menu.Position = UDim2.new(0.5, 0, 0.5, 0);
    menu.Size = UDim2.new(0, 260, 0, 200);
    menu.BackgroundColor3 = Color3.fromRGB(25, 25, 25);
    menu.BorderMode = Enum.BorderMode.Outline;
    menu.BorderColor3 = Color3.fromRGB(50, 25, 25);
    menu.BorderSizePixel = 3;
    menu.Active = true;
    menu.Draggable = true;
    menu.ClipsDescendants = true;

    local ext = Instance.new("ImageButton", gui)
    ext.Name = code(ext:GetDebugId());
    ext.AnchorPoint = Vector2.new(0, 0.5);
    ext.Position = UDim2.new(0, 0, 0.5, 0);
    ext.Size = UDim2.new(0, 32, 0, 32);
    ext.BackgroundTransparency = 1;
    ext.Image = get_id("close");
    ext.Visible = GS.MenuIsOpen;

    local top = Instance.new("Frame", menu)
    top.Name = code(top:GetDebugId());
    top.Size = UDim2.new(1, 0, 0, 36);
    top.BackgroundTransparency = 1;

    local drag = Instance.new("TextLabel", top);
    drag.Name = code(drag:GetDebugId());
    drag.AnchorPoint = Vector2.new(0.5, 0.5);
    drag.Position = UDim2.new(0.5, 0, 0.5, 0);
    drag.Size = UDim2.new(0.55, 0, 1, 0);
    drag.BackgroundTransparency = 1;
    drag.TextScaled = true;
    drag.TextColor3 = Color3.new(1, 1, 1);
    drag.Text = "HOLD TO DRAG";

    local logo = Instance.new("ImageButton", top)
    logo.Name = code(logo:GetDebugId());
    logo.Size = UDim2.new(0, 32, 0, 32);
    logo.BackgroundTransparency = 1;
    logo.Image = get_id("logo");

    local int = Instance.new("ImageButton", top)
    int.Name = code(int:GetDebugId());
    int.AnchorPoint = Vector2.new(1, 0);
    int.Position = UDim2.new(1, 0, 0, 0);
    int.Size = UDim2.new(0, 32, 0, 32);
    int.BackgroundTransparency = 1;
    int.Image = get_id("close");

    local toggle = Instance.new("TextButton", menu);
    toggle.Name = code(toggle:GetDebugId());
    toggle.Position = UDim2.new(0, 8, 0, 44);
    toggle.Size = UDim2.new(1, -16, 0, 36);
    toggle.BackgroundColor3 = enabled and Color3.new(0, 1, 0) or Color3.new(1, 0, 0);
    toggle.TextScaled = true;
    toggle.Text = enabled and "FOV Enabled" or "FOV Disabled";

    local div = Instance.new("Frame", menu);
    div.Name = code(div:GetDebugId());
    div.Position = UDim2.new(0, 8, 0, 88);
    div.Size = UDim2.new(1, -16, 0, 1);
    div.BackgroundColor3 = Color3.fromRGB(60, 60, 60);
    div.BorderSizePixel = 0;

    local menuLabel = Instance.new("TextLabel", menu);
    menuLabel.Name = code(menuLabel:GetDebugId());
    menuLabel.Position = UDim2.new(0, 8, 0, 96);
    menuLabel.Size = UDim2.new(0, 120, 0, 28);
    menuLabel.BackgroundTransparency = 1;
    menuLabel.TextColor3 = Color3.fromRGB(200, 200, 200);
    menuLabel.TextScaled = true;
    menuLabel.Text = "Toggle Menu:";
    menuLabel.TextXAlignment = Enum.TextXAlignment.Left;

    local menuInput = Instance.new("TextButton", menu);
    menuInput.Name = code(menuInput:GetDebugId());
    menuInput.Position = UDim2.new(0, 136, 0, 96);
    menuInput.Size = UDim2.new(1, -144, 0, 28);
    menuInput.BackgroundColor3 = Color3.fromRGB(40, 40, 40);
    menuInput.BorderSizePixel = 1;
    menuInput.BorderColor3 = Color3.fromRGB(80, 80, 80);
    menuInput.TextColor3 = Color3.new(1, 1, 1);
    menuInput.TextScaled = true;
    menuInput.Text = menuKey.Name;

    local fovLabel = Instance.new("TextLabel", menu);
    fovLabel.Name = code(fovLabel:GetDebugId());
    fovLabel.Position = UDim2.new(0, 8, 0, 132);
    fovLabel.Size = UDim2.new(0, 120, 0, 28);
    fovLabel.BackgroundTransparency = 1;
    fovLabel.TextColor3 = Color3.fromRGB(200, 200, 200);
    fovLabel.TextScaled = true;
    fovLabel.Text = "Toggle FOV:";
    fovLabel.TextXAlignment = Enum.TextXAlignment.Left;

    local fovInput = Instance.new("TextButton", menu);
    fovInput.Name = code(fovInput:GetDebugId());
    fovInput.Position = UDim2.new(0, 136, 0, 132);
    fovInput.Size = UDim2.new(1, -144, 0, 28);
    fovInput.BackgroundColor3 = Color3.fromRGB(40, 40, 40);
    fovInput.BorderSizePixel = 1;
    fovInput.BorderColor3 = Color3.fromRGB(80, 80, 80);
    fovInput.TextColor3 = Color3.new(1, 1, 1);
    fovInput.TextScaled = true;
    fovInput.Text = fovKey.Name;

    local reset = function()
        setMenu = false;
        setFov = false;
        menuInput.Text = menuKey.Name;
        menuInput.BackgroundColor3 = Color3.fromRGB(40, 40, 40);
        fovInput.Text = fovKey.Name;
        fovInput.BackgroundColor3 = Color3.fromRGB(40, 40, 40);
    end;

    local link = function()
        if setclipboard then
            setclipboard(discord);
            SG["info"]("Copied Discord link");
        end;
    end;

    local toggleFov = function()
        enabled = not enabled;
        toggle.BackgroundColor3 = enabled and Color3.new(0, 1, 0) or Color3.new(1, 0, 0);
        toggle.Text = enabled and "FOV Enabled" or "FOV Disabled";
        if enabled then draw:start() else draw:stop() end;
    end;

    local extUpdate = function()
        ext.Visible = GS.MenuIsOpen and not menu.Visible;
    end;

    local menuVis = function()
        menu.Visible = not menu.Visible;
        extUpdate();
    end;

    getgenv()[key] = {
        draw_instance = draw,
        connections = {
            GS.MenuOpened:Connect(extUpdate),
            GS.MenuClosed:Connect(extUpdate),

            ext.MouseButton1Up:Connect(menuVis),
            toggle.MouseButton1Up:Connect(toggleFov),
            logo.MouseButton1Up:Connect(link),
            int.MouseButton1Up:Connect(menuVis),

            menuInput.MouseButton1Up:Connect(function()
                reset();
                setMenu = true;
                menuInput.Text = "...";
            end),

            fovInput.MouseButton1Up:Connect(function()
                reset();
                setFov = true;
                fovInput.Text = "...";
            end),

            UIS.InputBegan:Connect(function(i, gp)
                if gp or i.UserInputType ~= Enum.UserInputType.Keyboard then return end;

                if setMenu then
                    menuKey = i.KeyCode;
                    getgenv().menuKey = menuKey;
                    reset();
                    return;
                end;

                if setFov then
                    fovKey = i.KeyCode;
                    getgenv().fovKey = fovKey;
                    reset();
                    return;
                end;

                if i.KeyCode == menuKey then
                    menuVis();
                elseif i.KeyCode == fovKey then
                    toggleFov();
                end;
            end)
        },
        p_instance = gui
    };

    draw:start();
end;
