-- Simple Drawing UI Library
local DrawingUI = {}
DrawingUI.Elements = {}

-- Utility function to check if mouse is over a rectangle
local function isMouseOver(pos, size)
    local mouse = game:GetService("UserInputService"):GetMouseLocation()
    return mouse.X >= pos.X and mouse.X <= pos.X + size.X
       and mouse.Y >= pos.Y and mouse.Y <= pos.Y + size.Y
end

-- Base function to create a button
function DrawingUI:CreateButton(props)
    local button = Drawing.new("Square")
    button.Size = Vector2.new(150, 30)
    button.Position = props.Position or Vector2.new(100, 100)
    button.Color = Color3.fromRGB(50, 50, 50)
    button.Filled = true
    button.Transparency = 1
    button.Visible = true

    local text = Drawing.new("Text")
    text.Text = props.Name or "Button"
    text.Size = 20
    text.Position = button.Position + Vector2.new(5, 5)
    text.Color = Color3.fromRGB(255, 255, 255)
    text.Visible = true

    -- store element
    table.insert(self.Elements, {Button = button, Text = text, Callback = props.Callback})

    -- click handler
    task.spawn(function()
        while true do
            task.wait()
            if isMouseOver(button.Position, button.Size) and game:GetService("UserInputService"):IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
                pcall(props.Callback)
                task.wait(0.3) -- debounce
            end
        end
    end)

    return button
end

-- Toggle
function DrawingUI:CreateToggle(props)
    local toggleBox = Drawing.new("Square")
    toggleBox.Size = Vector2.new(20, 20)
    toggleBox.Position = props.Position or Vector2.new(100, 100)
    toggleBox.Color = Color3.fromRGB(100, 100, 100)
    toggleBox.Filled = true
    toggleBox.Visible = true

    local text = Drawing.new("Text")
    text.Text = props.Name or "Toggle"
    text.Position = toggleBox.Position + Vector2.new(30, 0)
    text.Size = 20
    text.Color = Color3.fromRGB(255, 255, 255)
    text.Visible = true

    local state = props.CurrentValue or false

    local function updateColor()
        toggleBox.Color = state and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(100, 100, 100)
    end
    updateColor()

    task.spawn(function()
        while true do
            task.wait()
            if isMouseOver(toggleBox.Position, toggleBox.Size) and game:GetService("UserInputService"):IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
                state = not state
                updateColor()
                pcall(props.Callback, state)
                task.wait(0.3)
            end
        end
    end)

    return {Box = toggleBox, Text = text, GetState = function() return state end}
end

-- Dropdown
function DrawingUI:CreateDropdown(props)
    local box = Drawing.new("Square")
    box.Size = Vector2.new(150, 30)
    box.Position = props.Position or Vector2.new(100, 100)
    box.Color = Color3.fromRGB(50, 50, 50)
    box.Filled = true
    box.Visible = true

    local text = Drawing.new("Text")
    text.Text = props.CurrentOption and props.CurrentOption[1] or "Select"
    text.Position = box.Position + Vector2.new(5, 5)
    text.Size = 20
    text.Color = Color3.fromRGB(255, 255, 255)
    text.Visible = true

    local open = false
    local items = {}
    local itemHeight = 25

    local function toggleDropdown()
        open = not open
        for _, it in ipairs(items) do
            it.Visible = open
        end
    end

    -- click main box to toggle
    task.spawn(function()
        while true do
            task.wait()
            if isMouseOver(box.Position, box.Size) and game:GetService("UserInputService"):IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
                toggleDropdown()
                task.wait(0.3)
            end
        end
    end)

    -- create items
    for i, option in ipairs(props.Options or {}) do
        local item = Drawing.new("Text")
        item.Text = option
        item.Position = box.Position + Vector2.new(5, box.Size.Y + (i - 1) * itemHeight)
        item.Size = 20
        item.Color = Color3.fromRGB(255, 255, 255)
        item.Visible = false
        table.insert(items, item)

        task.spawn(function()
            while true do
                task.wait()
                if open and isMouseOver(item.Position, Vector2.new(140, itemHeight)) and game:GetService("UserInputService"):IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
                    text.Text = option
                    open = false
                    for _, it in ipairs(items) do it.Visible = false end
                    pcall(props.Callback, option)
                    task.wait(0.3)
                end
            end
        end)
    end

    return {Box = box, Text = text, Items = items}
end

-- Example usage
local UI = DrawingUI

-- Button
UI:CreateButton({
    Name = "Redeem Codes",
    Callback = function()
        print("Redeem clicked")
    end
})

-- Toggle
UI:CreateToggle({
    Name = "Start Match",
    CurrentValue = false,
    Callback = function(state)
        print("Toggle state:", state)
    end
})

-- Dropdown
UI:CreateDropdown({
    Name = "Difficulty",
    Options = {"Easy", "Medium", "Hard"},
    CurrentOption = {"Medium"},
    Callback = function(option)
        print("Selected:", option)
    end
})
