local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local localPlayer = Players.LocalPlayer

-- Wait for Fsys module
local Fsys = ReplicatedStorage:WaitForChild("Fsys", 10) -- Timeout after 10 seconds
if not Fsys then
    warn("Fsys module not found in ReplicatedStorage")
    return
end

-- Get the load function
local load = require(Fsys)
if not load then
    warn("Failed to get load function from Fsys")
    return
end

-- Load ClientData and ItemDB with error handling
local ClientData = load("ClientData")
if not ClientData then
    warn("Failed to load ClientData module")
    return
end

local ItemDB = load("ItemDB")
if not ItemDB then
    warn("Failed to load ItemDB module")
    return
end

-- Hardcoded JSON data (Paste your full JSON here without outer array brackets)
local values_data = {
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
        ["fly&ride?"] = "\"false\"",
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
        image = "/images/pets/Dalmatian.png",
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
        ["fly&ride?"] = "\"true\"",
        rarity = "ultra rare",
        type = "pets",
        categoryd = "Classy",
        categoryn = "Classy",
        categorym = "Classy",
        name = "Dalmatian",
        score = 3,
        id = "2"
    },
    ["3"] = {
        image = "/images/pets/Pelican.png",
        rvalue = 26.5,
        nvalue = 109.0,
        mvalue = 444.0,
        status = "Ready",
        ["rvalue - nopotion"] = 26.5,
        ["rvalue - ride"] = 27.0,
        ["rvalue - fly"] = 27.0,
        ["rvalue - fly&ride"] = 27.5,
        ["nvalue - nopotion"] = 108.0,
        ["nvalue - ride"] = 108.5,
        ["nvalue - fly"] = 108.5,
        ["nvalue - fly&ride"] = 109.0,
        ["mvalue - nopotion"] = 454.0,
        ["mvalue - ride"] = 443.0,
        ["mvalue - fly"] = 443.0,
        ["mvalue - fly&ride"] = 444.0,
        ["fly&ride?"] = "\"false\"",
        rarity = "ultra rare",
        type = "pets",
        categoryd = "Exotic",
        categoryn = "Exotic",
        categorym = "Exotic",
        name = "Pelican",
        score = 4,
        id = "3"
    },
    ["2535"] = {
        image = "/images/pets/Emberlight.png",
        rvalue = 10.5,
        nvalue = 49.0,
        mvalue = 220,
        status = "Ready",
        ["rvalue - nopotion"] = 10.5,
        ["rvalue - ride"] = 11.0,
        ["rvalue - fly"] = 11.0,
        ["rvalue - fly&ride"] = 11.5,
        ["nvalue - nopotion"] = 48.0,
        ["nvalue - ride"] = 48.5,
        ["nvalue - fly"] = 48.5,
        ["nvalue - fly&ride"] = 49.0,
        ["mvalue - nopotion"] = 218.0,
        ["mvalue - ride"] = 219.0,
        ["mvalue - fly"] = 219.0,
        ["mvalue - fly&ride"] = 220,
        ["fly&ride?"] = "\"false\"",
        rarity = "legendary",
        type = "pets",
        categoryd = nil,
        categoryn = nil,
        categorym = nil,
        name = "Emberlight",
        score = 46,
        id = "2535"
    }
    -- Paste additional JSON entries here as needed
}

-- Create a map from name to data
local name_to_data = {}
for _, data in pairs(values_data) do
    if data.name then
        name_to_data[data.name] = data
    end
end

-- Function to calculate total value of an offer
local function calculate_total(offer)
    if not offer or not offer.items then
        return 0
    end
    local total = 0
    for _, item in ipairs(offer.items) do
        local item_data = ItemDB[item.category] and ItemDB[item.category][item.kind]
        local item_name = item_data and (item_data.name or item.kind) or "Unknown"
        local data = name_to_data[item_name]
        if data then
            local value = 0
            if item.category == "pets" then
                local base = "rvalue"
                if item.properties and item.properties.mega_neon then
                    base = "mvalue"
                elseif item.properties and item.properties.neon then
                    base = "nvalue"
                end
                local suffix = " - nopotion"
                if item.properties and item.properties.flyable and item.properties.rideable then
                    suffix = " - fly&ride"
                elseif item.properties and item.properties.flyable then
                    suffix = " - fly"
                elseif item.properties and item.properties.rideable then
                    suffix = " - ride"
                end
                local key = base .. suffix
                value = data[key] or 0
            else
                value = data.value or 0
            end
            total = total + value
        end
    end
    return total
end

-- Main loop to update UI
RunService.Heartbeat:Connect(function()
    local trade_state = ClientData.get and ClientData.get("trade")
    if not trade_state then return end

    local trade_app
    repeat
        trade_app = localPlayer.PlayerGui:FindFirstChild("TradeApp")
        if not trade_app then
            wait(1)
        end
    until trade_app

    local my_offer, partner_offer
    if localPlayer == trade_state.sender then
        my_offer = trade_state.sender_offer
        partner_offer = trade_state.recipient_offer
    else
        my_offer = trade_state.recipient_offer
        partner_offer = trade_state.sender_offer
    end

    local my_total = calculate_total(my_offer)
    local partner_total = calculate_total(partner_offer)
    local diff = my_total - partner_total

    local neg_frame = trade_app.Frame:FindFirstChild("NegotiationFrame")
    if not neg_frame then return end

    -- Update user's label
    local you_frame = neg_frame.Header:FindFirstChild("YouFrame")
    if you_frame then
        local you_label = you_frame:FindFirstChild("NameLabel")
        if you_label then
            you_label.Text = "You (" .. string.format("%.2f", my_total) .. ")"
        end
    end

    -- Update partner's label
    local partner_frame = neg_frame.Header:FindFirstChild("PartnerFrame")
    if partner_frame then
        local partner_label = partner_frame:FindFirstChild("NameLabel")
        if partner_label then
            partner_label.Text = "Partner (" .. string.format("%.2f", partner_total) .. ")"
        end
    end

    -- Update difference in Body.NameLabel
    local body = neg_frame:FindFirstChild("Body")
    if body then
        local body_label = body:FindFirstChild("TextLabel")
        if body_label then
            if diff > 0 then
                -- Overpaying, red
                body_label.Text = string.format("%.2f", diff)
                body_label.TextColor3 = Color3.new(1, 0, 0)  -- Red
            elseif diff < 0 then
                -- Underpaying, green
                body_label.Text = string.format("%.2f", math.abs(diff))
                body_label.TextColor3 = Color3.new(0, 1, 0)  -- Green
            else
                body_label.Text = "0"
                body_label.TextColor3 = Color3.new(1, 1, 1)  -- White
            end
        end
    end
end)
