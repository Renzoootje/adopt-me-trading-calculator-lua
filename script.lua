local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

-- Wait for the necessary modules to load
local Fsys = require(ReplicatedStorage:WaitForChild("Fsys"))
local load = Fsys.load

local ClientData = load("ClientData")
local ItemDB = load("ItemDB")

-- Main function to log pet information
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

-- Execute the function
logTradeItems()
