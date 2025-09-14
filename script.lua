local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local localPlayer = Players.LocalPlayer
local StarterGui = game:GetService("StarterGui")

-- Wait for the necessary modules to load
local Fsys = require(ReplicatedStorage:WaitForChild("Fsys"))
local load = Fsys.load

local ClientData = load("ClientData")  -- If this causes issues, try: local ClientData = require(game.ReplicatedStorage.ClientModules.Core.ClientData)
local ItemDB = load("ItemDB")

-- Hardcoded pet values database (from provided JSON-like structure)
local petValues = {
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
    -- (Other pets omitted for brevity; add the full list as needed)
}

-- Function to get the value of a single item
local function getItemValue(item)
    local data = ItemDB[item.category][item.kind]
    local name = data and (data.name or item.kind) or "Unknown item"
    
    -- Find the pet in petValues by name
    local valueData = nil
    for _, pet in pairs(petValues) do
        if pet.name == name then
            valueData = pet
            break
        end
    end
    
    if not valueData then
        return 0
    end
    
    local prefixType = "rvalue"
    if item.properties then
        if item.properties.mega_neon then
            prefixType = "mvalue"
        elseif item.properties.neon then
            prefixType = "nvalue"
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
    
    local valueKey = prefixType .. suffix
    local value = valueData[valueKey] or 0
    
    return value
end

-- Main function to calculate and display trade values
local function displayTradeValues()
    -- Fixed: Use .get_data() instead of .get, and access trade under player data
    local playerData = ClientData.get_data()[localPlayer.Name]
    local trade_state = playerData.trade
    
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
    local myTotalValue = 0
    for _, item in ipairs(my_offer.items or {}) do
        myTotalValue = myTotalValue + getItemValue(item)
    end
    
    local theirTotalValue = 0
    for _, item in ipairs(partner_offer.items or {}) do
        theirTotalValue = theirTotalValue + getItemValue(item)
    end
    
    local difference = theirTotalValue - myTotalValue  -- Positive means you gain, negative means you lose
    local result = (difference > 0) and "WIN" or (difference < 0) and "LOSS" or "EVEN"
    
    -- (The rest of the GUI creation code remains unchanged; omitted for brevity)
end

-- Original console logging function (unchanged)
local function logTradeItems()
    -- Fixed: Same change as above for consistency
    local playerData = ClientData.get_data()[localPlayer.Name]
    local trade_state = playerData.trade
    
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
    end

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
    end
end

-- Execute both functions
displayTradeValues()
logTradeItems()
