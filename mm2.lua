local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local fallbackItems = {
    Raygun = {
        ItemName = "Raygun",
        Image = "rbxthumb://type=Asset&w=150&h=150&id=139431943195380",
        ItemType = "Gun",
        Rarity = "Godly",
        ItemID = 139431943195380,
        Event = "Halloween",
        Year = "2025"
    },
    Gingerscope = {
        ItemName = "Gingerscope",
        Image = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=250&height=250&assetId=15666596216",
        ItemType = "Gun",
        Rarity = "Ancient",
        ItemID = 15666469505,
        Event = "Christmas",
        Year = "2023",
        FX = true
    }
}

local syncDb = nil
local itemModule = nil
local mainGui = nil
local gameGui = nil
local gameNewItem = nil
local pendingQueue = {}
local hookedButtons = {}

local function trim(str)
    return tostring(str or ""):match("^%s*(.-)%s*$")
end

local function initGameRefs()
    if not syncDb then
        pcall(function()
            local dbFolder = ReplicatedStorage:FindFirstChild("Database")
            local syncMod = dbFolder and dbFolder:FindFirstChild("Sync")
            if syncMod then
                syncDb = require(syncMod)
            end
        end)
    end

    if not itemModule then
        pcall(function()
            local modsFolder = ReplicatedStorage:FindFirstChild("Modules")
            local itemMod = modsFolder and modsFolder:FindFirstChild("ItemModule")
            if itemMod then
                itemModule = require(itemMod)
            end
        end)
    end

    if not mainGui then
        mainGui = playerGui:FindFirstChild("MainGUI")
    end

    if mainGui and not gameGui then
        gameGui = mainGui:FindFirstChild("Game")
    end

    if gameGui and not gameNewItem then
        gameNewItem = gameGui:FindFirstChild("NewItem")
    end
end

local function findExactItemInTable(tbl, exactName)
    if type(tbl) ~= "table" then return nil, nil end
    if type(tbl[exactName]) == "table" then
        return exactName, tbl[exactName]
    end
    for k, v in pairs(tbl) do
        if type(v) == "table" and v.ItemName == exactName then
            return tostring(k), v
        end
    end
    return nil, nil
end

local function resolveExactItem(rawName)
    local exactName = trim(rawName)
    if exactName == "" then
        return nil, nil, nil, "Enter exact item name"
    end

    initGameRefs()

    if type(syncDb) == "table" then
        local key, info = findExactItemInTable(syncDb.Item, exactName)
        if key and info then
            return key, "Item", info, nil
        end

        key, info = findExactItemInTable(syncDb.Weapons, exactName)
        if key and info then
            return key, "Weapons", info, nil
        end

        for catName, catTable in pairs(syncDb) do
            if type(catTable) == "table" and catName ~= "Item" and catName ~= "Weapons" and catName ~= "Rarities" then
                key, info = findExactItemInTable(catTable, exactName)
                if key and info and type(info) == "table" and (info.ItemName or info.Image or info.Rarity) then
                    return key, catName, info, nil
                end
            end
        end
    end

    local key, info = findExactItemInTable(fallbackItems, exactName)
    if key and info then
        return key, "Weapons", info, nil
    end

    return nil, nil, nil, "Item not found"
end

local function hasFxEnabled(info, itemName)
    if itemName == "Gingerscope" or (info and info.ItemName == "Gingerscope") then
        return true
    end
    if not info then return false end
    return info.FX == true or info.HasFX == true or info.Effect == true
end

local function shouldShowEventBg(info, itemName, eventType)
    if eventType == "Halloween" then
        if itemName == "Raygun" or (info and info.ItemName == "Raygun") then
            return true
        end
    elseif eventType == "Christmas" then
        if itemName == "Gingerscope" or (info and info.ItemName == "Gingerscope") then
            return false
        end
    end
    return true
end

local function isYearObject(obj)
    if not obj:IsA("TextLabel") then return false end
    if obj.Name == "TagName" then return false end
    local lowerName = string.lower(obj.Name)
    if lowerName == "year" or lowerName == "year2" or string.find(lowerName, "year", 1, true) then
        return true
    end
    local txt = trim(obj.Text)
    if string.match(txt, "^20%d%d$") then
        return true
    end
    return false
end

local function applySingleYear(card, info, activeEventName)
    if not card then return end
    local itemYear = (info and info.Year) and tostring(info.Year) or ""
    local canShow = (activeEventName == "Halloween" or activeEventName == "Christmas") and itemYear ~= ""

    local chosen = nil
    if canShow then
        local tags = card:FindFirstChild("Tags")
        local activeFrame = tags and tags:FindFirstChild(activeEventName)
        if activeFrame then
            local primaryYear = activeFrame:FindFirstChild("Year", true)
            if primaryYear and isYearObject(primaryYear) then
                chosen = primaryYear
            else
                for _, obj in ipairs(activeFrame:GetDescendants()) do
                    if isYearObject(obj) then
                        chosen = obj
                        break
                    end
                end
            end
        end
        if not chosen then
            for _, obj in ipairs(card:GetDescendants()) do
                if isYearObject(obj) then
                    chosen = obj
                    break
                end
            end
        end
    end

    for _, obj in ipairs(card:GetDescendants()) do
        if isYearObject(obj) then
            if canShow and obj == chosen then
                obj.Text = itemYear
                obj.Visible = true
            else
                obj.Text = ""
                obj.Visible = false
            end
        end
    end
end

local function applyEventFrame(eventFrame, info, itemName, eventType, active)
    if not eventFrame then return end
    eventFrame.Visible = active

    local bg = eventFrame:FindFirstChild("BG")
    if bg then
        bg.Visible = active and shouldShowEventBg(info, itemName, eventType)
    end
end

local function enableFxOnCard(card, showFx)
    if not card then return end
    for _, desc in ipairs(card:GetDescendants()) do
        if desc.Name == "FX" and desc:IsA("GuiObject") then
            desc.Visible = showFx
            local img = desc:FindFirstChild("ImageLabel")
            if img and img:IsA("GuiObject") then
                img.Visible = showFx
            end
        end
    end
end

local function applyTags(card, info, itemName)
    if not card then return end
    local eventName = info and info.Event
    local showFx = hasFxEnabled(info, itemName)

    enableFxOnCard(card, showFx)

    local tags = card:FindFirstChild("Tags")
    if tags then
        local hallowFrame = tags:FindFirstChild("Halloween")
        local xmasFrame = tags:FindFirstChild("Christmas")
        local chromaFrame = tags:FindFirstChild("Chroma")

        if chromaFrame then
            chromaFrame.Visible = (info and info.Chroma == true) or false
        end

        applyEventFrame(hallowFrame, info, itemName, "Halloween", eventName == "Halloween")
        applyEventFrame(xmasFrame, info, itemName, "Christmas", eventName == "Christmas")
    end

    applySingleYear(card, info, eventName)
end

local function fillCardVisuals(card, info, itemName)
    if not card or not info then return end
    if type(itemModule) == "table" and itemModule.DisplayItem then
        pcall(function()
            itemModule.DisplayItem(card, info)
        end)
    end

    local displayName = tostring(info.ItemName or itemName or "")
    local iconAsset = info.Image and tostring(info.Image) or ""

    for _, desc in ipairs(card:GetDescendants()) do
        if desc:IsA("ImageLabel") or desc:IsA("ImageButton") then
            if iconAsset ~= "" and (desc.Name == "Icon" or desc.Name == "ItemIcon" or desc.Name == "Image" or desc:FindFirstAncestor("Tags") == nil) then
                if desc.Image == "" or desc.Name == "Icon" or desc.Name == "ItemIcon" or desc.Name == "Image" then
                    desc.Image = iconAsset
                end
            end
        elseif desc:IsA("TextLabel") then
            if desc.Name == "ItemName" or desc.Name == "TitleName" or desc.Name == "NameLabel" then
                desc.Text = displayName
            end
        end
    end

    applyTags(card, info, itemName)
end

local function getAncestryPath(instance)
    local parts = {}
    local current = instance
    while current and current ~= game do
        table.insert(parts, 1, string.lower(current.Name))
        current = current.Parent
    end
    return table.concat(parts, "/")
end

local function hasRarity(info)
    local r = info and tostring(info.Rarity or "") or ""
    r = string.lower(trim(r))
    return r ~= "" and r ~= "none" and r ~= "default" and r ~= "common"
end

local function scoreContainerForItem(container, info)
    local path = getAncestryPath(container)
    local score = 0

    local itemType = info and string.lower(tostring(info.ItemType or "")) or ""
    local eventName = info and string.lower(tostring(info.Event or "")) or ""
    local rarityPresent = hasRarity(info)

    if string.find(path, "weapons", 1, true) then
        score += 10
    end

    if itemType == "gun" or itemType == "knife" then
        if string.find(path, "pet", 1, true) or string.find(path, "emote", 1, true) or string.find(path, "effect", 1, true) or string.find(path, "radio", 1, true) then
            score -= 25
        end
    end

    if eventName == "halloween" then
        if string.find(path, "halloween", 1, true) then
            score += 40
        else
            score -= 20
        end
        if string.find(path, "christmas", 1, true) or string.find(path, "classic", 1, true) then
            score -= 30
        end
    elseif eventName == "christmas" then
        if string.find(path, "christmas", 1, true) then
            score += 40
        else
            score -= 20
        end
        if string.find(path, "halloween", 1, true) or string.find(path, "classic", 1, true) then
            score -= 30
        end
    else
        if string.find(path, "halloween", 1, true) or string.find(path, "christmas", 1, true) or string.find(path, "holiday", 1, true) then
            score -= 35
        end
        if not rarityPresent then
            if string.find(path, "classic", 1, true) then
                score += 40
            elseif string.find(path, "current", 1, true) then
                score -= 10
            end
        else
            if string.find(path, "classic", 1, true) then
                score -= 35
            end
        end
    end

    return score
end

local function collectWeaponContainers()
    local allContainers = {}

    local tradeGui = playerGui:FindFirstChild("TradeGUI")
    local tradeItems = tradeGui and tradeGui:FindFirstChild("Container") and tradeGui.Container:FindFirstChild("Items")
    if tradeItems then
        for _, child in ipairs(tradeItems:GetChildren()) do
            local cat = child:FindFirstChild("Weapons")
            if cat then
                for _, desc in ipairs(cat:GetDescendants()) do
                    if desc.Name == "Container" then
                        table.insert(allContainers, desc)
                    end
                end
            end
        end
    end

    if mainGui then
        local invRoot = mainGui:FindFirstChild("Inventory")
        if invRoot then
            for _, desc in ipairs(invRoot:GetDescendants()) do
                if desc.Name == "Container" then
                    local path = string.lower(getAncestryPath(desc))
                    if string.find(path, "weapon", 1, true) or string.find(path, "gun", 1, true) then
                        table.insert(allContainers, desc)
                    end
                end
            end
        end
    end

    return allContainers
end

local function findWeaponCardTemplate(allContainers)
    for _, cont in ipairs(allContainers) do
        for _, child in ipairs(cont:GetChildren()) do
            if child:IsA("GuiObject") and child.Name == "NewItem" then
                return child
            end
        end
    end

    for _, cont in ipairs(allContainers) do
        for _, child in ipairs(cont:GetChildren()) do
            if child:IsA("GuiObject") and not child:IsA("UILayout") and not child:IsA("UIPadding") then
                return child
            end
        end
    end

    return nil
end

local function addCardToContainers(info, itemName)
    local allContainers = collectWeaponContainers()
    local fallbackTemplate = findWeaponCardTemplate(allContainers)
    if not fallbackTemplate then return end

    local bestScore = -math.huge
    for _, cont in ipairs(allContainers) do
        local s = scoreContainerForItem(cont, info)
        if s > bestScore then
            bestScore = s
        end
    end

    local targetContainers = {}
    for _, cont in ipairs(allContainers) do
        if scoreContainerForItem(cont, info) == bestScore then
            table.insert(targetContainers, cont)
        end
    end

    for _, cont in ipairs(targetContainers) do
        local localTemplate = cont:FindFirstChild("NewItem")
        local template = (localTemplate and localTemplate:IsA("GuiObject")) and localTemplate or fallbackTemplate
        if template and template:IsA("GuiObject") then
            local clone = template:Clone()
            clone.Name = "NewItem"
            clone.Visible = true
            fillCardVisuals(clone, info, itemName)
            clone.Parent = cont
        end
    end
end

local function playNativeInventoryAnimation(popupFrame)
    if type(itemModule) ~= "table" or not itemModule.AnimateItemIconIntoInventory then return end
    if not gameGui then return end
    local dock = gameGui:FindFirstChild("Dock")
    local invDock = dock and dock:FindFirstChild("Inventory")
    local cont = popupFrame and popupFrame:FindFirstChild("Container")
    local card = cont and cont:FindFirstChild("NewItem")
    local cardCont = card and card:FindFirstChild("Container")
    local icon = cardCont and cardCont:FindFirstChild("Icon")
    if icon and invDock then
        pcall(function()
            itemModule.AnimateItemIconIntoInventory(icon, invDock, gameGui)
        end)
    end
end

local function getActivePopup()
    if gameNewItem and gameNewItem:IsA("GuiObject") then
        return gameNewItem
    end
    local cp = playerGui:FindFirstChild("CrossPlatform")
    local cpPopup = cp and cp:FindFirstChild("NewItem")
    if cpPopup and cpPopup:IsA("GuiObject") then
        return cpPopup
    end
    return nil
end

local function hookClaimButton(popup)
    if not popup then return end
    for _, desc in ipairs(popup:GetDescendants()) do
        if desc:IsA("GuiButton") and desc.Name == "Claim" and not hookedButtons[desc] then
            hookedButtons[desc] = true
            desc.MouseButton1Click:Connect(function()
                local entry = table.remove(pendingQueue, 1)
                playNativeInventoryAnimation(popup)
                popup.Visible = false
                pcall(function()
                    local blur = Lighting:FindFirstChild("NewItemBlur")
                    if blur then
                        blur.Enabled = false
                    end
                end)
                if entry then
                    addCardToContainers(entry.Info, entry.Name)
                end
                if #pendingQueue > 0 then
                    local nextEntry = pendingQueue[1]
                    local cont = popup:FindFirstChild("Container")
                    local card = cont and cont:FindFirstChild("NewItem")
                    if card then
                        fillCardVisuals(card, nextEntry.Info, nextEntry.Name)
                    end
                    popup.Visible = true
                    local claimObj = cont and cont:FindFirstChild("Claim")
                    if claimObj and claimObj:IsA("TextButton") then
                        claimObj.Text = (#pendingQueue > 1) and ("Claim (1/" .. #pendingQueue .. ")") or "Claim"
                    end
                end
            end)
        end
    end
end

local function openPopupForItem(itemKey, category, info)
    initGameRefs()
    local popup = getActivePopup()
    if not popup then
        return false, "NewItem popup not found"
    end

    hookClaimButton(popup)

    local inSync = type(syncDb) == "table" and type(syncDb[category]) == "table" and syncDb[category][itemKey] ~= nil
    if inSync and typeof(_G.NewItem) == "function" then
        local okCall = pcall(function()
            _G.NewItem(itemKey, "You Got...", nil, category)
        end)
        if okCall then
            task.delay(0.03, function()
                local cont = popup:FindFirstChild("Container")
                local card = cont and cont:FindFirstChild("NewItem")
                if card then
                    fillCardVisuals(card, info, itemKey)
                end
            end)
            return true, "Spawned: " .. tostring(info.ItemName or itemKey)
        end
    end

    popup.Visible = true
    pcall(function()
        local blur = Lighting:FindFirstChild("NewItemBlur")
        if blur then
            blur.Enabled = true
        end
    end)

    local cont = popup:FindFirstChild("Container")
    if cont and cont:IsA("GuiObject") then
        cont.Visible = true
        local title = cont:FindFirstChild("Title")
        if title and title:IsA("TextLabel") then
            title.Text = "You Got..."
        end
        local claimObj = cont:FindFirstChild("Claim")
        if claimObj and claimObj:IsA("TextButton") then
            claimObj.Text = (#pendingQueue > 1) and ("Claim (1/" .. #pendingQueue .. ")") or "Claim"
        end
    end

    local card = cont and cont:FindFirstChild("NewItem")
    if card and card:IsA("GuiObject") then
        card.Visible = true
        fillCardVisuals(card, info, itemKey)
    end

    return true, "Spawned: " .. tostring(info.ItemName or itemKey)
end

local function spawnItemPopup(rawName)
    local itemKey, category, info, errMsg = resolveExactItem(rawName)
    if not itemKey or not info then
        return false, errMsg or "Enter exact item name"
    end

    table.insert(pendingQueue, {
        Name = itemKey,
        Info = info
    })

    return openPopupForItem(itemKey, category, info)
end

local oldGui = playerGui:FindFirstChild("GodlySpawnerGUI")
if oldGui then
    oldGui:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GodlySpawnerGUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 999
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 224, 0, 126)
mainFrame.Position = UDim2.new(0.5, -112, 0.22, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 14)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 8)
mainCorner.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(170, 35, 55)
mainStroke.Thickness = 1.5
mainStroke.Parent = mainFrame

local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.new(1, 0, 0, 28)
topBar.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
topBar.BorderSizePixel = 0
topBar.Parent = mainFrame

local topCorner = Instance.new("UICorner")
topCorner.CornerRadius = UDim.new(0, 8)
topCorner.Parent = topBar

local topFix = Instance.new("Frame")
topFix.Size = UDim2.new(1, 0, 0, 8)
topFix.Position = UDim2.new(0, 0, 1, -8)
topFix.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
topFix.BorderSizePixel = 0
topFix.Parent = topBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -56, 1, 0)
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "godly spawner"
titleLabel.TextColor3 = Color3.fromRGB(245, 245, 245)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 13
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = topBar

local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 22, 0, 22)
minBtn.Position = UDim2.new(1, -48, 0.5, -11)
minBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
minBtn.Text = "-"
minBtn.TextColor3 = Color3.fromRGB(235, 235, 235)
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 14
minBtn.BorderSizePixel = 0
minBtn.Parent = topBar

local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(0, 5)
minCorner.Parent = minBtn

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 22, 0, 22)
closeBtn.Position = UDim2.new(1, -24, 0.5, -11)
closeBtn.BackgroundColor3 = Color3.fromRGB(150, 30, 45)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 12
closeBtn.BorderSizePixel = 0
closeBtn.Parent = topBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 5)
closeCorner.Parent = closeBtn

local bodyFrame = Instance.new("Frame")
bodyFrame.Name = "Body"
bodyFrame.Size = UDim2.new(1, 0, 1, -28)
bodyFrame.Position = UDim2.new(0, 0, 0, 28)
bodyFrame.BackgroundTransparency = 1
bodyFrame.Parent = mainFrame

local nameBox = Instance.new("TextBox")
nameBox.Name = "ItemInput"
nameBox.Size = UDim2.new(1, -20, 0, 32)
nameBox.Position = UDim2.new(0, 10, 0, 8)
nameBox.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
nameBox.BorderSizePixel = 0
nameBox.PlaceholderText = "Enter exact item name"
nameBox.PlaceholderColor3 = Color3.fromRGB(130, 130, 140)
nameBox.Text = ""
nameBox.TextColor3 = Color3.fromRGB(255, 255, 255)
nameBox.Font = Enum.Font.Gotham
nameBox.TextSize = 13
nameBox.ClearTextOnFocus = false
nameBox.Parent = bodyFrame

local boxCorner = Instance.new("UICorner")
boxCorner.CornerRadius = UDim.new(0, 6)
boxCorner.Parent = nameBox

local boxStroke = Instance.new("UIStroke")
boxStroke.Color = Color3.fromRGB(65, 65, 75)
boxStroke.Thickness = 1
boxStroke.Parent = nameBox

local spawnBtn = Instance.new("TextButton")
spawnBtn.Name = "SpawnButton"
spawnBtn.Size = UDim2.new(1, -20, 0, 32)
spawnBtn.Position = UDim2.new(0, 10, 0, 46)
spawnBtn.BackgroundColor3 = Color3.fromRGB(170, 35, 55)
spawnBtn.BorderSizePixel = 0
spawnBtn.Text = "Spawn"
spawnBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
spawnBtn.Font = Enum.Font.GothamBold
spawnBtn.TextSize = 13
spawnBtn.Parent = bodyFrame

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 6)
btnCorner.Parent = spawnBtn

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 16)
statusLabel.Position = UDim2.new(0, 10, 0, 80)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Enter exact item name"
statusLabel.TextColor3 = Color3.fromRGB(160, 160, 170)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 11
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = bodyFrame

local dragging = false
local dragStart = Vector2.zero
local startPos = UDim2.zero

topBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
    end
end)

topBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

local minimized = false
minBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    bodyFrame.Visible = not minimized
    topFix.Visible = not minimized
    minBtn.Text = minimized and "+" or "-"
    mainFrame.Size = minimized and UDim2.new(0, 224, 0, 28) or UDim2.new(0, 224, 0, 126)
end)

closeBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

spawnBtn.MouseButton1Click:Connect(function()
    local ok, msg = spawnItemPopup(nameBox.Text)
    statusLabel.Text = msg
    statusLabel.TextColor3 = ok and Color3.fromRGB(110, 220, 130) or Color3.fromRGB(240, 100, 100)
end)

pcall(function()
    initGameRefs()
    hookClaimButton(getActivePopup())
end)
