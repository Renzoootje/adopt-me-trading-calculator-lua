local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local localPlayer = Players.LocalPlayer
local StarterGui = game:GetService("StarterGui")

-- Wait for the necessary modules to load
local Fsys = require(ReplicatedStorage:WaitForChild("Fsys"))
local load = Fsys.load

local ClientData = load("ClientData")
local ItemDB = load("ItemDB")

-- Hardcoded pet values database (from provided JSON-like structure)
local petValues = {}

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
        return 0  -- Default to 0 if no value data found, to avoid nil errors
    end
    
    local prefixType = "rvalue"  -- Default regular
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
    local value = valueData[valueKey] or 0  -- Default to 0 if key not found, to avoid nil errors
    
    return value
end

-- Main function to calculate and display trade values
local function displayTradeValues()
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
    
    -- Create ScreenGui if not exists
    local screenGui = localPlayer:WaitForChild("PlayerGui"):FindFirstChild("TradeValueGui")
    if not screenGui then
        screenGui = Instance.new("ScreenGui")
        screenGui.Name = "TradeValueGui"
        screenGui.Parent = localPlayer:WaitForChild("PlayerGui")
        screenGui.ResetOnSpawn = false
    end
    
    -- Clear existing children
    for _, child in ipairs(screenGui:GetChildren()) do
        child:Destroy()
    end
    
    -- Main Frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 300, 0, 200)
    mainFrame.Position = UDim2.new(0.5, -150, 0.5, -100)
    mainFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    mainFrame.ClipsDescendants = true
    
    -- Add corner rounding
    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0, 10)
    uiCorner.Parent = mainFrame
    
    -- Title Bar for dragging and minimizing
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 30)
    titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    titleBar.Parent = mainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 10)
    titleCorner.Parent = titleBar
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -60, 1, 0)
    titleLabel.Position = UDim2.new(0, 10, 0, 0)
    titleLabel.Text = "Trade Values"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextSize = 16
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.Parent = titleBar
    
    -- Minimize Button
    local minimizeButton = Instance.new("TextButton")
    minimizeButton.Size = UDim2.new(0, 30, 0, 30)
    minimizeButton.Position = UDim2.new(1, -60, 0, 0)
    minimizeButton.Text = "-"
    minimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    minimizeButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    minimizeButton.Parent = titleBar
    
    local minCorner = Instance.new("UICorner")
    minCorner.CornerRadius = UDim.new(0, 5)
    minCorner.Parent = minimizeButton
    
    -- Close Button
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -30, 0, 0)
    closeButton.Text = "X"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeButton.Parent = titleBar
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 5)
    closeCorner.Parent = closeButton
    
    -- Content Frame
    local contentFrame = Instance.new("Frame")
    contentFrame.Size = UDim2.new(1, 0, 1, -30)
    contentFrame.Position = UDim2.new(0, 0, 0, 30)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = mainFrame
    
    -- Display Labels
    local myValueLabel = Instance.new("TextLabel")
    myValueLabel.Size = UDim2.new(1, 0, 0, 30)
    myValueLabel.Position = UDim2.new(0, 0, 0, 10)
    myValueLabel.Text = "Your Value: " .. string.format("%.1f", myTotalValue)
    myValueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    myValueLabel.BackgroundTransparency = 1
    myValueLabel.TextSize = 14
    myValueLabel.Font = Enum.Font.SourceSans
    myValueLabel.Parent = contentFrame
    
    local theirValueLabel = Instance.new("TextLabel")
    theirValueLabel.Size = UDim2.new(1, 0, 0, 30)
    theirValueLabel.Position = UDim2.new(0, 0, 0, 40)
    theirValueLabel.Text = "Their Value: " .. string.format("%.1f", theirTotalValue)
    theirValueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    theirValueLabel.BackgroundTransparency = 1
    theirValueLabel.TextSize = 14
    theirValueLabel.Font = Enum.Font.SourceSans
    theirValueLabel.Parent = contentFrame
    
    local diffLabel = Instance.new("TextLabel")
    diffLabel.Size = UDim2.new(1, 0, 0, 30)
    diffLabel.Position = UDim2.new(0, 0, 0, 70)
    diffLabel.Text = "Difference: " .. string.format("%.1f", difference)
    diffLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    diffLabel.BackgroundTransparency = 1
    diffLabel.TextSize = 14
    diffLabel.Font = Enum.Font.SourceSans
    diffLabel.Parent = contentFrame
    
    local resultLabel = Instance.new("TextLabel")
    resultLabel.Size = UDim2.new(1, 0, 0, 30)
    resultLabel.Position = UDim2.new(0, 0, 0, 100)
    resultLabel.Text = "Result: " .. result
    resultLabel.TextColor3 = (result == "WIN") and Color3.fromRGB(0, 255, 0) or (result == "LOSS") and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(255, 255, 0)
    resultLabel.BackgroundTransparency = 1
    resultLabel.TextSize = 16
    resultLabel.Font = Enum.Font.SourceSansBold
    resultLabel.Parent = contentFrame
    
    -- Minimize functionality
    local minimized = false
    minimizeButton.MouseButton1Click:Connect(function()
        minimized = not minimized
        contentFrame.Visible = not minimized
        mainFrame.Size = minimized and UDim2.new(0, 300, 0, 30) or UDim2.new(0, 300, 0, 200)
        minimizeButton.Text = minimized and "+" or "-"
    end)
    
    -- Close functionality
    closeButton.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)
    
    -- Draggable functionality
    local dragging
    local dragInput
    local dragStart
    local startPos
    
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    titleBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- Original console logging function
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

-- Execute both functions
displayTradeValues()
logTradeItems()
