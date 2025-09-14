local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local localPlayer = Players.LocalPlayer

print("Starting trade calculator...")

-- Check if services exist
if not ReplicatedStorage then
    warn("ReplicatedStorage not found!")
    return
end

print("ReplicatedStorage found")

-- Wait for the necessary modules to load
local Fsys = ReplicatedStorage:WaitForChild("Fsys", 10)
if not Fsys then
    warn("Fsys module not found!")
    return
end

print("Fsys found, requiring...")

local success, load_func = pcall(function()
    return require(Fsys).load
end)

if not success or not load_func then
    warn("Failed to load Fsys or get load function: " .. tostring(load_func))
    return
end

print("Load function obtained")

local ClientData, ItemDB

-- Try to load ClientData
local cd_success, cd_result = pcall(function()
    return load_func("ClientData")
end)

if cd_success then
    ClientData = cd_result
    print("ClientData loaded successfully")
else
    warn("Failed to load ClientData: " .. tostring(cd_result))
    return
end

-- Try to load ItemDB
local idb_success, idb_result = pcall(function()
    return load_func("ItemDB")
end)

if idb_success then
    ItemDB = idb_result
    print("ItemDB loaded successfully")
else
    warn("Failed to load ItemDB: " .. tostring(idb_result))
    return
end

-- Simple hardcoded value database (you can replace this with your JSON data)
local value_db = {
    ["Hedgehog"] = {
        name = "Hedgehog",
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
    ["African Wild Dog"] = {
        name = "African Wild Dog",
        rvalue = 44.5,
        nvalue = 180.0,
        mvalue = 732.0,
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
        ["mvalue - fly&ride"] = 732.0
    },
    ["Dalmatian"] = {
        name = "Dalmatian",
        rvalue = 29.0,
        nvalue = 119.0,
        mvalue = 485.0,
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
        ["mvalue - fly&ride"] = 485.0
    },
    ["Shadow Dragon"] = {
        name = "Shadow Dragon",
        rvalue = 100,
        nvalue = 400,
        mvalue = 1600,
        ["rvalue - nopotion"] = 95,
        ["rvalue - ride"] = 98,
        ["rvalue - fly"] = 98,
        ["rvalue - fly&ride"] = 100,
        ["nvalue - nopotion"] = 380,
        ["nvalue - ride"] = 390,
        ["nvalue - fly"] = 390,
        ["nvalue - fly&ride"] = 400,
        ["mvalue - nopotion"] = 1500,
        ["mvalue - ride"] = 1550,
        ["mvalue - fly"] = 1550,
        ["mvalue - fly&ride"] = 1600
    }
}

print("Value database loaded with " .. tostring(#value_db) .. " entries")

-- Main function to log pet information and calculate values
local function logTradeItems()
    print("Running logTradeItems function...")
    
    -- Check if ClientData exists and has get function
    if not ClientData then
        warn("ClientData is nil!")
        return
    end
    
    if not ClientData.get then
        warn("ClientData.get function not found!")
        return
    end
    
    local trade_state
    local get_success, get_result = pcall(function()
        return ClientData.get("trade")
    end)
    
    if get_success then
        trade_state = get_result
    else
        warn("Failed to get trade state: " .. tostring(get_result))
        return
    end
    
    if not trade_state then
        warn("No active trade found!")
        return
    end
    
    print("Trade state found")

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

    -- Calculate totals with extensive error checking
    local function getItemValue(item)
        if not item then
            print("Item is nil")
            return 0
        end
        
        if not item.category or not item.kind then
            print("Item missing category or kind")
            return 0
        end
        
        if not ItemDB then
            warn("ItemDB is nil!")
            return 0
        end
        
        if not ItemDB[item.category] then
            print("Category not found in ItemDB: " .. tostring(item.category))
            return 0
        end
        
        local data = ItemDB[item.category][item.kind]
        local name = data and (data.name or item.kind) or "Unknown item"
        
        print("Looking for pet: " .. tostring(name))
        
        local value_data = value_db[name]
        
        if not value_data then
            print("No value data found for: " .. tostring(name))
            return 0
        end

        local item_value = 0
        if value_data.value then
            item_value = tonumber(value_data.value) or 0
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
            item_value = tonumber(value_data[key]) or tonumber(value_data[base_key]) or 0
            print("Using key: " .. key .. " = " .. item_value)
        end
        return item_value
    end

    local my_total = 0
    print("=== Your Offer Items ===")
    if my_offer and my_offer.items then
        for i, item in ipairs(my_offer.items) do
            print("Processing item " .. i)
            local data = ItemDB[item.category] and ItemDB[item.category][item.kind]
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
    else
        print("No items in your offer")
    end

    local partner_total = 0
    print("=== Their Offer Items ===")
    if partner_offer and partner_offer.items then
        for i, item in ipairs(partner_offer.items) do
            print("Processing partner item " .. i)
            local data = ItemDB[item.category] and ItemDB[item.category][item.kind]
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
    else
        print("No items in their offer")
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
    local gui_success, gui_error = pcall(function()
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

        local textLabel = Instance.new("TextLabel")
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.Position = UDim2.new(0, 0, 0, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.TextColor3 = Color3.new(1, 1, 1)
        textLabel.Text = string.format("You: %.1f\nOther: %.1f\n%s", my_total, partner_total, result_str)
        textLabel.TextSize = 14
        textLabel.Font = Enum.Font.SourceSans
        textLabel.TextWrapped = true
        textLabel.Parent = frame

        print("GUI created successfully!")
    end)
    
    if not gui_success then
        warn("Failed to create GUI: " .. tostring(gui_error))
    end
end

-- Execute the function with extensive error handling
print("About to run trade calculator...")
spawn(function()
    wait(2) -- Longer delay to ensure everything is loaded
    local success, error_msg = pcall(logTradeItems)
    if not success then
        warn("Error running trade calculator: " .. tostring(error_msg))
        print("Debug info:")
        print("ClientData exists:", ClientData ~= nil)
        print("ItemDB exists:", ItemDB ~= nil)
        print("localPlayer exists:", localPlayer ~= nil)
    else
        print("Trade calculator ran successfully!")
    end
end)
