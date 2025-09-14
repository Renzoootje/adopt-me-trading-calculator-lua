local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local localPlayer = Players.LocalPlayer

-- Wait for the necessary modules to load
local Fsys = require(ReplicatedStorage:WaitForChild("Fsys"))
local load = Fsys.load

local ClientData = load("ClientData")
local ItemDB = load("ItemDB")

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

    -- Fetch the JSON value database
    local json_url = "https://raw.githubusercontent.com/Renzoootje/adopt-me-trading-calculator-lua/refs/heads/main/test"
    local value_db = {}
    local name_to_data = {}
    local success, response = pcall(function()
        return HttpService:GetAsync(json_url)
    end)
    if success then
        local decode_success, db = pcall(function()
            return HttpService:JSONDecode(response)
        end)
        if decode_success then
            value_db = db
            for id, data in pairs(value_db) do
                if data.name then
                    name_to_data[data.name] = data
                end
            end
        else
            warn("Failed to decode JSON: " .. tostring(db))
        end
    else
        warn("Failed to fetch JSON: " .. tostring(response))
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
        
        print(prefix .. name)
        my_total = my_total + getItemValue(item)
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
        
        print(prefix .. name)
        partner_total = partner_total + getItemValue(item)
    end

    local diff = partner_total - my_total
    local label = ""
    local result_str = ""
    if diff > 0 then
        label = "WIN"
        result_str = string.format("%s: %+.1f", label, diff)
    elseif diff < 0 then
        label = "LOSS"
        result_str = string.format("%s: %+.1f", label, diff)
    else
        result_str = "FAIR: 0"
    end

    print(string.format("You: %.1f Other: %.1f, %s", my_total, partner_total, result_str))

    -- Create ScreenGui
    local gui = Instance.new("ScreenGui")
    gui.Name = "TradeValueGui"
    gui.Parent = localPlayer:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 200, 0, 100)
    frame.Position = UDim2.new(0.5, -100, 0.5, -50)
    frame.BackgroundColor3 = Color3.new(0, 0, 0)
    frame.BackgroundTransparency = 0.5
    frame.Parent = gui

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, -20)
    textLabel.Position = UDim2.new(0, 0, 0, 20)
    textLabel.BackgroundTransparency = 1
    textLabel.TextColor3 = Color3.new(1, 1, 1)
    textLabel.Text = string.format("You: %.1f\nOther: %.1f\n%s", my_total, partner_total, result_str)
    textLabel.TextSize = 14
    textLabel.Font = Enum.Font.SourceSans
    textLabel.Parent = frame

    -- Minimize button
    local minButton = Instance.new("TextButton")
    minButton.Size = UDim2.new(0, 20, 0, 20)
    minButton.Position = UDim2.new(1, -20, 0, 0)
    minButton.Text = "-"
    minButton.BackgroundColor3 = Color3.new(1, 0, 0)
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
            frame.Size = UDim2.new(0, 200, 0, 20)
            textLabel.Visible = false
            minButton.Text = "+"
            minimized = true
        end
    end)

    -- Make frame draggable
    local dragging
    local dragInput
    local dragStart
    local startPos

    local function update(input)
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
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
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)
end

-- Execute the function
logTradeItems()
