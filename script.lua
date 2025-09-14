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

-- Value database with the structure you provided
local value_db = {
    ["0"] = {
        image = "/images/pets/Hedgehog.png", 
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
        image = "/images/pets/African Wild Dog.png", 
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
    -- Add more pets here following the same pattern
}

-- Create a lookup table by pet name for easier access
local value_db_by_name = {}
for id, data in pairs(value_db) do
    value_db_by_name[data.name] = data
end

-- Function to calculate trade values and update GUI
local function calculateTradeValues()
    local trade_state = ClientData.get("trade")
    
    if not trade_state then
        -- Remove GUI if no trade is active
        local existingGui = localPlayer.PlayerGui:FindFirstChild("TradeValueGui")
        if existingGui then
            existingGui:Destroy()
        end
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

    -- Calculate item value based on properties
    local function getItemValue(item)
        if not item or not item.category or not item.kind then
            return 0
        end
        
        local data = ItemDB[item.category] and ItemDB[item.category][item.kind]
        if not data then
            return 0
        end
        
        local name = data.name or item.kind
        local value_data = value_db_by_name[name]
        
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
    for _, item in ipairs(my_offer.items or {}) do
        my_total = my_total + getItemValue(item)
    end

    local partner_total = 0
    for _, item in ipairs(partner_offer.items or {}) do
        partner_total = partner_total + getItemValue(item)
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

    -- Create or update GUI
    local gui = localPlayer.PlayerGui:FindFirstChild("TradeValueGui")
    if not gui then
        gui = Instance.new("ScreenGui")
        gui.Name = "TradeValueGui"
        gui.ResetOnSpawn = false
        gui.Parent = localPlayer.PlayerGui

        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, 200, 0, 100)
        frame.Position = UDim2.new(0.9, -100, 0, 0)
        frame.BackgroundColor3 = Color3.new(0, 0, 0)
        frame.BackgroundTransparency = 0.3
        frame.BorderSizePixel = 0
        frame.Parent = gui

        local textLabel = Instance.new("TextLabel")
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.TextColor3 = Color3.new(1, 1, 1)
        textLabel.TextSize = 14
        textLabel.Font = Enum.Font.SourceSans
        textLabel.TextWrapped = true
        textLabel.Parent = frame
    end

    -- Update the text
    local textLabel = gui:FindFirstChild("Frame"):FindFirstChild("TextLabel")
    if textLabel then
        textLabel.Text = string.format("You: %.1f\nOther: %.1f\n%s", my_total, partner_total, result_str)
    end
end

-- Set up continuous checking
local running = true
spawn(function()
    while running do
        local success, err = pcall(calculateTradeValues)
        if not success then
            warn("Error in calculateTradeValues: " .. tostring(err))
        end
        wait(1) -- Check every second
    end
end)

-- Clean up when the script is stopped
game:GetService("UserInputService").WindowFocusReleased:Connect(function()
    running = false
    local gui = localPlayer.PlayerGui:FindFirstChild("TradeValueGui")
    if gui then
        gui:Destroy()
    end
end)
