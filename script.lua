local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local localPlayer = Players.LocalPlayer

print("Starting trade calculator...")

-- Function to safely require modules with error handling
local function safeRequire(module)
    local success, result = pcall(function()
        return require(module)
    end)
    if success then
        return result
    else
        warn("Failed to require " .. module.Name .. ": " .. result)
        return nil
    end
end

-- Wait for and require Fsys
local Fsys = ReplicatedStorage:WaitForChild("Fsys")
if not Fsys then
    warn("Fsys not found!")
    return
end

local FsysModule = safeRequire(Fsys)
if not FsysModule then
    return
end

-- Check if Fsys has a load function
if type(FsysModule.load) ~= "function" then
    warn("Fsys.load is not a function!")
    return
end

-- Load ClientData and ItemDB
local ClientData = FsysModule.load("ClientData")
local ItemDB = FsysModule.load("ItemDB")

if not ClientData or not ItemDB then
    warn("Failed to load ClientData or ItemDB!")
    return
end

-- Check if ClientData has a get function
if type(ClientData.get) ~= "function" then
    warn("ClientData.get is not a function!")
    return
end

-- Simple hardcoded value database
local value_db = {
    ["Hedgehog"] = {
        rvalue = 42.5,
        nvalue = 176.0,
        mvalue = 725.0,
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
        ["mvalue - fly&ride"] = 725.0
    },
    -- Add more pets as needed
}

-- Main function to log pet information and calculate values
local function logTradeItems()
    print("Attempting to get trade state...")
    local trade_state = ClientData.get("trade")
    
    if not trade_state then
        warn("No active trade found!")
        return
    end

    print("Trade state found successfully")

    local my_offer, partner_offer
    if localPlayer == trade_state.sender then
        my_offer = trade_state.sender_offer
        partner_offer = trade_state.recipient_offer
        print("You are the sender")
    else
        my_offer = trade_state.recipient_offer
        partner_offer = trade_state.sender_offer
        print("You are the recipient")
    end

    -- Calculate totals
    local function getItemValue(item)
        if not item or not item.category or not item.kind then
            return 0
        end
        
        local data = ItemDB[item.category] and ItemDB[item.category][item.kind]
        if not data then
            return 0
        end
        
        local name = data.name or item.kind
        local value_data = value_db[name]
        
        if not value_data then
            return 0
        end

        local base_key = "rvalue" -- Regular value by default
        if item.properties then
            if item.properties.mega_neon then
                base_key = "mvalue"
            elseif item.properties.neon then
                base_key = "nvalue"
            end
        end

        local suffix = " - nopotion"
        if item.properties then
            if item.properties.flyable and item.properties.rideable then
                suffix = " - fly&ride"
            elseif item.properties.flyable then
                suffix = " - fly"
            elseif item.properties.rideable then
                suffix = " - ride"
            end
        end

        local key = base_key .. suffix
        return value_data[key] or value_data[base_key] or 0
    end

    local my_total = 0
    print("=== Your Offer Items ===")
    for _, item in ipairs(my_offer.items or {}) do
        local data = ItemDB[item.category] and ItemDB[item.category][item.kind]
        local name = data and (data.name or item.kind) or "Unknown"
        
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
    print("=== Their Offer Items ===")
    for _, item in ipairs(partner_offer.items or {}) do
        local data = ItemDB[item.category] and ItemDB[item.category][item.kind]
        local name = data and (data.name or item.kind) or "Unknown"
        
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
    local result_str = ""
    if diff > 0 then
        result_str = string.format("WIN: +%.1f", diff)
    elseif diff < 0 then
        result_str = string.format("LOSS: %.1f", diff)
    else
        result_str = "FAIR: 0"
    end

    print(string.format("=== RESULTS ==="))
    print(string.format("You: %.1f", my_total))
    print(string.format("Other: %.1f", partner_total))
    print(result_str)

    -- Create simple GUI
    local existingGui = localPlayer.PlayerGui:FindFirstChild("TradeValueGui")
    if existingGui then
        existingGui:Destroy()
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "TradeValueGui"
    gui.ResetOnSpawn = false
    gui.Parent = localPlayer.PlayerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 200, 0, 100)
    frame.Position = UDim2.new(0.5, -100, 0.1, 0)
    frame.BackgroundColor3 = Color3.new(0, 0, 0)
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0
    frame.Parent = gui

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.TextColor3 = Color3.new(1, 1, 1)
    textLabel.Text = string.format("You: %.1f\nOther: %.1f\n%s", my_total, partner_total, result_str)
    textLabel.TextSize = 14
    textLabel.Font = Enum.Font.SourceSans
    textLabel.TextWrapped = true
    textLabel.Parent = frame
end

-- Wait a bit for the game to load, then run the calculator
wait(5)
logTradeItems()
