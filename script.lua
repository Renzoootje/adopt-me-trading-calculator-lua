local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local localPlayer = Players.LocalPlayer

-- Wait for the necessary modules to load
local Fsys = require(ReplicatedStorage:WaitForChild("Fsys"))
local load = Fsys.load

local ClientData = load("ClientData")
local ItemDB = load("ItemDB")

-- Hardcoded value database
local value_db = {
    ["0"] = {
        rvalue = 42.5,
        nvalue = 176.0,
        mvalue = 725.0,
        status = "Ready",
        ["rvalue - nopotion"] = 42.0,
        ["rvalue - ride"] = 42.0,
        ["rvalue - fly"] = 42.0,
        ["rvalue - fly&ride"] = 42.5,
        ["nvalue - nopotion"] = 181.0,
        ["nvalue - ride"] = 177.0,
        ["nvalue - fly"] = 177.0,
        ["nvalue - fly&ride"] = 176.0,
        ["mvalue - nopotion"] = 755.0,
        ["mvalue - ride"] = 739.0,
        ["mvalue - fly"] = 739.0,
        ["mvalue - fly&ride"] = 725.0,
        ["fly&ride?"] = "true",
        rarity = "ultra rare",
        type = "pets",
        categoryd = "Classy",
        categoryn = "Classy",
        categorym = "Classy",
        name = "Hedgehog",
        score = 1,
        id = "0"
    },
    ["1"] = {
        rvalue = 44.5,
        nvalue = 180.0,
        mvalue = 732.0,
        status = "Ready",
        ["rvalue - nopotion"] = 44.5,
        ["rvalue - ride"] = 45.0,
        ["rvalue - fly"] = 45.0,
        ["rvalue - fly&ride"] = 45.5,
        ["nvalue - nopotion"] = 179.0,
        ["nvalue - ride"] = 179.5,
        ["nvalue - fly"] = 179.5,
        ["nvalue - fly&ride"] = 180.0,
        ["mvalue - nopotion"] = 742.0,
        ["mvalue - ride"] = 731.0,
        ["mvalue - fly"] = 731.0,
        ["mvalue - fly&ride"] = 732.0,
        ["fly&ride?"] = "false",
        rarity = "ultra rare",
        type = "pets",
        categoryd = "Exotic",
        categoryn = "Exotic",
        categorym = "Exotic",
        name = "African Wild Dog",
        score = 2,
        id = "1"
    },
    ["2"] = {
        rvalue = 29.0,
        nvalue = 119.0,
        mvalue = 485.0,
        status = "Ready",
        ["rvalue - nopotion"] = 28.5,
        ["rvalue - ride"] = 28.5,
        ["rvalue - fly"] = 28.5,
        ["rvalue - fly&ride"] = 29.0,
        ["nvalue - nopotion"] = 121.0,
        ["nvalue - ride"] = 118.5,
        ["nvalue - fly"] = 118.5,
        ["nvalue - fly&ride"] = 119.0,
        ["mvalue - nopotion"] = 515.0,
        ["mvalue - ride"] = 493.0,
        ["mvalue - fly"] = 493.0,
        ["mvalue - fly&ride"] = 485.0,
        ["fly&ride?"] = "true",
        rarity = "ultra rare",
        type = "pets",
        categoryd = "Classy",
        categoryn = "Classy",
        categorym = "Classy",
        name = "Dalmatian",
        score = 3,
        id = "2"
    }
}

-- Create name-to-data lookup table
local name_to_data = {}
for id, data in pairs(value_db) do
    if data.name then
        name_to_data[data.name] = data
    end
end

-- Main function to log pet information and calculate values
local function logTradeItems()
    local trade_state = ClientData.get("trade")
    if not trade_state then
        warn("No active trade found!")
        return
    end

    local my_offer, partner_offer
    if localPlayer == trade_state.sender then
        my_offer = trade_state.sender_offer
        partner_offer = trade_state.recipient_offer
    else
        my_offer = trade_state.recipient_offer
        partner_offer = trade_state.sender_offer
    end

    -- Calculate totals
    local function getItemValue(item)
        local data = ItemDB[item.category][item.kind]
        local name = data and (data.name or item.kind) or "Unknown item"
        local value_data = name_to_data[name]
        if not value_data then
            return 0
        end

        local item_value = 0
        if value_data.value then
            item_value = value_data.value
        else
            -- Assume pet
            local base_key = "rvalue"
            local has_properties = item.properties or {}
            if has_properties.mega_neon then
                base_key = "mvalue"
            elseif has_properties.neon then
                base_key = "nvalue"
            end

            local suffix = " - nopotion"
            if has_properties.flyable and has_properties.rideable then
                suffix = " - fly&ride"
            elseif has_properties.flyable then
                suffix = " - fly"
            elseif has_properties.rideable then
                suffix = " - ride"
            end

            local key = base_key .. suffix
            item_value = value_data[key] or value_data[base_key] or 0
        end
        return item_value
    end

    local my_total = 0
    print("Your Offer Items:")
    for _, item in ipairs(my_offer.items or {}) do
        local data = ItemDB[item.category][item.kind]
        local name = data and (data.name or item.kind) or "Unknown item"
        
        local prefix = ""
        if item.properties then
            if item.properties.mega_neon then
                prefix = "Mega Neon "
            elseif item.properties.neon then
                prefix = "Neon "
            end
            if item.properties.flyable then
                prefix = prefix .. "Fly "
            end
            if item.properties.rideable then
                prefix = prefix .. "Ride "
            end
        end
        
        local item_value = getItemValue(item)
        print(prefix .. name .. " - Value: " .. item_value)
        my_total = my_total + item_value
    end

    local partner_total = 0
    print("Their Offer Items:")
    for _, item in ipairs(partner_offer.items or {}) do
        local data = ItemDB[item.category][item.kind]
        local name = data and (data.name or item.kind) or "Unknown item"
        
        local prefix = ""
        if item.properties then
            if item.properties.mega_neon then
                prefix = "Mega Neon "
            elseif item.properties.neon then
                prefix = "Neon "
            end
            if item.properties.flyable then
                prefix = prefix .. "Fly "
            end
            if item.properties.rideable then
                prefix = prefix .. "Ride "
            end
        end
        
        local item_value = getItemValue(item)
        print(prefix .. name .. " - Value: " .. item_value)
        partner_total = partner_total + item_value
    end

    local diff = partner_total - my_total
    local label = ""
    local result_str = ""
    if diff > 0 then
        label = "WIN"
        result_str = string.format("%s: +%.1f", label, diff)
    elseif diff < 0 then
        label = "LOSS"
        result_str = string.format("%s: %.1f", label, diff)
    else
        result_str = "FAIR: 0"
    end

    print(string.format("You: %.1f Other: %.1f, %s", my_total, partner_total, result_str))

    -- Remove existing GUI if it exists
    local existingGui = localPlayer.PlayerGui:FindFirstChild("TradeValueGui")
    if existingGui then
        existingGui:Destroy()
    end

    -- Create ScreenGui
    local gui = Instance.new("ScreenGui")
    gui.Name = "TradeValueGui"
    gui.ResetOnSpawn = false
    gui.Parent = localPlayer.PlayerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 200, 0, 100)
    frame.Position = UDim2.new(0.5, -100, 0.5, -50)
    frame.BackgroundColor3 = Color3.new(0, 0, 0)
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0
    frame.Parent = gui

    -- Add a border for better visibility
    local border = Instance.new("UIStroke")
    border.Color = Color3.new(1, 1, 1)
    border.Thickness = 1
    border.Parent = frame

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, -25)
    textLabel.Position = UDim2.new(0, 0, 0, 25)
    textLabel.BackgroundTransparency = 1
    textLabel.TextColor3 = Color3.new(1, 1, 1)
    textLabel.Text = string.format("You: %.1f\nOther: %.1f\n%s", my_total, partner_total, result_str)
    textLabel.TextSize = 14
    textLabel.Font = Enum.Font.SourceSans
    textLabel.TextWrapped = true
    textLabel.Parent = frame

    -- Title label
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -25, 0, 25)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextColor3 = Color3.new(1, 1, 1)
    titleLabel.Text = "Trade Calculator"
    titleLabel.TextSize = 12
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.Parent = frame

    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 25, 0, 25)
    closeButton.Position = UDim2.new(1, -25, 0, 0)
    closeButton.Text = "X"
    closeButton.BackgroundColor3 = Color3.new(1, 0, 0)
    closeButton.TextColor3 = Color3.new(1, 1, 1)
    closeButton.BorderSizePixel = 0
    closeButton.Parent = frame

    closeButton.MouseButton1Click:Connect(function()
        gui:Destroy()
    end)

    -- Minimize button
    local minButton = Instance.new("TextButton")
    minButton.Size = UDim2.new(0, 25, 0, 25)
    minButton.Position = UDim2.new(1, -50, 0, 0)
    minButton.Text = "-"
    minButton.BackgroundColor3 = Color3.new(0.5, 0.5, 0.5)
    minButton.TextColor3 = Color3.new(1, 1, 1)
    minButton.BorderSizePixel = 0
    minButton.Parent = frame

    local originalSize = frame.Size
    local minimized = false
    minButton.MouseButton1Click:Connect(function()
        if minimized then
            frame.Size = originalSize
            textLabel.Visible = true
            minButton.Text = "-"
            minimized = false
        else
            originalSize = frame.Size
            frame.Size = UDim2.new(0, 200, 0, 25)
            textLabel.Visible = false
            minButton.Text = "+"
            minimized = true
        end
    end)

    -- Make frame draggable
    local dragging = false
    local dragInput = nil
    local dragStart = nil
    local startPos = nil

    local function update(input)
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)

    print("Trade calculator GUI created successfully!")
end

-- Execute the function with better error handling
spawn(function()
    wait(1) -- Small delay to ensure everything is loaded
    local success, error_msg = pcall(logTradeItems)
    if not success then
        warn("Error running trade calculator: " .. tostring(error_msg))
    end
end)
