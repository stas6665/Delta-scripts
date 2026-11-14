-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local enabled = false
local farmSpeed = 16
local MIN_SPEED = 1
local MAX_SPEED = 40
local isMinimized = false
local isSettingsOpen = false
local rainbowActive = false
local aimbotActive = false
local shootButtonActive = false
local autoGrabGunActive = false
local killAllButtonActive = false
local flyActive = false
local flySpeed = 50

local jumpPowerActive = false
local customJumpPower = 50
local walkSpeedActive = false
local customWalkSpeed = 16
local infiniteJumpActive = false

local espMurdererActive = false
local espSheriffActive = false
local espInnocentsActive = false
local espUserActive = false
local outlineActive = false

local activeSliderType = nil
local activeInputObject = nil
local draggingMain = false
local draggingShoot = false
local draggingKillAll = false
local dragStart, startPos

local currentThemeColor = Color3.fromRGB(145, 30, 45)
local lastActiveTab = "Farming"

local oldGui = playerGui:FindFirstChild("MM2Hub")
if oldGui then oldGui:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "MM2Hub"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local connections = {}

local VisualInventory = {
    Knives = {
        {
            Name = "Gingerscythe",
            MeshId = "rbxassetid://1234567890",
            TextureId = "rbxassetid://0987654321"
        },
        {
            Name = "Batwing",
            MeshId = "rbxassetid://1111222233",
            TextureId = "rbxassetid://3332221111"
        }
    },
    Guns = {
        {
            Name = "Harvester",
            MeshId = "rbxassetid://4444555566",
            TextureId = "rbxassetid://6655443322"
        },
        {
            Name = "Luger",
            MeshId = "rbxassetid://7777888899",
            TextureId = "rbxassetid://9988776655"
        }
    }
}

local EquippedItems = {
    Knife = nil,
    Gun = nil
}

local characterConnection = nil
local function setupCharacterListener(char)
    if characterConnection then characterConnection:Disconnect() end
    characterConnection = char.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            task.wait(0.1)
            local handle = child:FindFirstChild("Handle")
            if not handle then return end
            local mesh = handle:FindFirstChildOfClass("SpecialMesh") or handle:FindFirstChildOfClass("MeshPart")
            if not mesh then return end

            local toolLower = child.Name:lower()
            local targetData = nil

            if toolLower:find("knife") or child.Name == "DefaultKnife" then
                targetData = EquippedItems.Knife
            elseif toolLower:find("gun") or child.Name == "Revolver" or child.Name == "Sheriff" then
                targetData = EquippedItems.Gun
            end

            if targetData then
                if mesh:IsA("SpecialMesh") then
                    mesh.MeshId = targetData.MeshId
                    mesh.TextureId = targetData.TextureId
                elseif mesh:IsA("MeshPart") then
                    pcall(function()
                        mesh.MeshId = targetData.MeshId
                        mesh.TextureID = targetData.TextureId
                    end)
                end
            end
        end
    end)
end

if player.Character then
    setupCharacterListener(player.Character)
end
table.insert(connections, player.CharacterAdded:Connect(function(newChar)
    setupCharacterListener(newChar)
end))

local redDot = Instance.new("Frame")
redDot.Size = UDim2.fromOffset(6, 6)
redDot.AnchorPoint = Vector2.new(0.5, 0.5)
redDot.Position = UDim2.new(0.5, 0, 0.5, 0)
redDot.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
redDot.BorderSizePixel = 0
redDot.Visible = false
redDot.Parent = gui

Instance.new("UICorner", redDot).CornerRadius = UDim.new(1, 0)

local dotStroke = Instance.new("UIStroke")
dotStroke.Color = Color3.fromRGB(0, 0, 0)
dotStroke.Thickness = 1
dotStroke.Parent = redDot

local shootFloatingBtn = Instance.new("TextButton")
shootFloatingBtn.Size = UDim2.fromOffset(130, 60)
shootFloatingBtn.Position = UDim2.new(0.8, -65, 0.7, -30)
shootFloatingBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 22)
shootFloatingBtn.Text = "Shoot Murderer"
shootFloatingBtn.TextColor3 = Color3.new(1, 1, 1)
shootFloatingBtn.TextSize = 12
shootFloatingBtn.Font = Enum.Font.GothamBold
shootFloatingBtn.Visible = false
shootFloatingBtn.Active = true
shootFloatingBtn.Parent = gui

Instance.new("UICorner", shootFloatingBtn).CornerRadius = UDim.new(0, 8)

local shootBtnStroke = Instance.new("UIStroke")
shootBtnStroke.Color = Color3.fromRGB(200, 35, 45)
shootBtnStroke.Thickness = 2
shootBtnStroke.Parent = shootFloatingBtn

local killAllFloatingBtn = Instance.new("TextButton")
killAllFloatingBtn.Size = UDim2.fromOffset(130, 60)
killAllFloatingBtn.Position = UDim2.new(0.8, -65, 0.5, -30)
killAllFloatingBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
killAllFloatingBtn.Text = "Kill All"
killAllFloatingBtn.TextColor3 = Color3.new(1, 1, 1)
killAllFloatingBtn.TextSize = 14
killAllFloatingBtn.Font = Enum.Font.GothamBold
killAllFloatingBtn.Visible = false
killAllFloatingBtn.Active = true
killAllFloatingBtn.Parent = gui

Instance.new("UICorner", killAllFloatingBtn).CornerRadius = UDim.new(0, 8)

local killAllStroke = Instance.new("UIStroke")
killAllStroke.Color = Color3.fromRGB(255, 0, 0)
killAllStroke.Thickness = 3
killAllStroke.Parent = killAllFloatingBtn

local main = Instance.new("Frame")
main.Size = UDim2.fromOffset(400, 300)
main.Position = UDim2.new(0.5, -200, 0.5, -150)
main.BackgroundColor3 = Color3.fromRGB(18, 18, 21)
main.BorderSizePixel = 0
main.Parent = gui

Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)

local outline = Instance.new("UIStroke")
outline.Color = Color3.fromRGB(145, 25, 40)
outline.Thickness = 1.5
outline.Parent = main

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -105, 0, 35)
title.Position = UDim2.fromOffset(15, 5)
title.BackgroundTransparency = 1
title.Text = "MM2 HUB"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextSize = 20
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Active = true
title.Parent = main

local settingsBtn = Instance.new("TextButton")
settingsBtn.Size = UDim2.fromOffset(25, 25)
settingsBtn.Position = UDim2.new(1, -85, 0, 10)
settingsBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
settingsBtn.TextColor3 = Color3.new(1, 1, 1)
settingsBtn.TextSize = 14
settingsBtn.Font = Enum.Font.GothamBold
settingsBtn.Text = "Set"
settingsBtn.Parent = main
Instance.new("UICorner", settingsBtn).CornerRadius = UDim.new(0, 6)

local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size = UDim2.fromOffset(25, 25)
minimizeBtn.Position = UDim2.new(1, -55, 0, 10)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(145, 30, 45)
minimizeBtn.TextColor3 = Color3.new(1, 1, 1)
minimizeBtn.TextSize = 14
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.Text = "-"
minimizeBtn.Parent = main
Instance.new("UICorner", minimizeBtn).CornerRadius = UDim.new(0, 6)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromOffset(25, 25)
closeBtn.Position = UDim2.new(1, -25, 0, 10)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.TextSize = 14
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Text = "X"
closeBtn.Parent = main
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

local contentHolder = Instance.new("Frame")
contentHolder.Size = UDim2.new(1, 0, 1, -40)
contentHolder.Position = UDim2.fromOffset(0, 40)
contentHolder.BackgroundTransparency = 1
contentHolder.Parent = main

table.insert(connections, minimizeBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    contentHolder.Visible = not isMinimized
    local targetSize = isMinimized and UDim2.fromOffset(400, 45) or UDim2.fromOffset(400, 300)
    minimizeBtn.Text = isMinimized and "+" or "-"
    TweenService:Create(main, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = targetSize }):Play()
end))

local tabHolder = Instance.new("Frame")
tabHolder.Size = UDim2.fromOffset(90, 240)
tabHolder.Position = UDim2.fromOffset(10, 10)
tabHolder.BackgroundTransparency = 1
tabHolder.Parent = contentHolder

local tabFarming = Instance.new("TextButton")
tabFarming.Size = UDim2.fromOffset(90, 26)
tabFarming.Position = UDim2.fromOffset(0, 0)
tabFarming.BackgroundColor3 = Color3.fromRGB(145, 30, 45)
tabFarming.TextColor3 = Color3.new(1, 1, 1)
tabFarming.TextSize = 10
tabFarming.Font = Enum.Font.GothamBold
tabFarming.Text = "Farming"
tabFarming.Parent = tabHolder
Instance.new("UICorner", tabFarming).CornerRadius = UDim.new(0, 6)

local tabFling = Instance.new("TextButton")
tabFling.Size = UDim2.fromOffset(90, 26)
tabFling.Position = UDim2.fromOffset(0, 30)
tabFling.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
tabFling.TextColor3 = Color3.fromRGB(170, 170, 170)
tabFling.TextSize = 10
tabFling.Font = Enum.Font.GothamBold
tabFling.Text = "Fling"
tabFling.Parent = tabHolder
Instance.new("UICorner", tabFling).CornerRadius = UDim.new(0, 6)

local tabSheriff = Instance.new("TextButton")
tabSheriff.Size = UDim2.fromOffset(90, 26)
tabSheriff.Position = UDim2.fromOffset(0, 60)
tabSheriff.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
tabSheriff.TextColor3 = Color3.fromRGB(170, 170, 170)
tabSheriff.TextSize = 10
tabSheriff.Font = Enum.Font.GothamBold
tabSheriff.Text = "Sheriff"
tabSheriff.Parent = tabHolder
Instance.new("UICorner", tabSheriff).CornerRadius = UDim.new(0, 6)

local tabMurder = Instance.new("TextButton")
tabMurder.Size = UDim2.fromOffset(90, 26)
tabMurder.Position = UDim2.fromOffset(0, 90)
tabMurder.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
tabMurder.TextColor3 = Color3.fromRGB(170, 170, 170)
tabMurder.TextSize = 10
tabMurder.Font = Enum.Font.GothamBold
tabMurder.Text = "Murderer"
tabMurder.Parent = tabHolder
Instance.new("UICorner", tabMurder).CornerRadius = UDim.new(0, 6)

local tabPlayer = Instance.new("TextButton")
tabPlayer.Size = UDim2.fromOffset(90, 26)
tabPlayer.Position = UDim2.fromOffset(0, 120)
tabPlayer.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
tabPlayer.TextColor3 = Color3.fromRGB(170, 170, 170)
tabPlayer.TextSize = 10
tabPlayer.Font = Enum.Font.GothamBold
tabPlayer.Text = "Player"
tabPlayer.Parent = tabHolder
Instance.new("UICorner", tabPlayer).CornerRadius = UDim.new(0, 6)

local tabESP = Instance.new("TextButton")
tabESP.Size = UDim2.fromOffset(90, 26)
tabESP.Position = UDim2.fromOffset(0, 150)
tabESP.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
tabESP.TextColor3 = Color3.fromRGB(170, 170, 170)
tabESP.TextSize = 10
tabESP.Font = Enum.Font.GothamBold
tabESP.Text = "ESP"
tabESP.Parent = tabHolder
Instance.new("UICorner", tabESP).CornerRadius = UDim.new(0, 6)

local tabGodly = Instance.new("TextButton")
tabGodly.Size = UDim2.fromOffset(90, 26)
tabGodly.Position = UDim2.fromOffset(0, 180)
tabGodly.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
tabGodly.TextColor3 = Color3.fromRGB(170, 170, 170)
tabGodly.TextSize = 9
tabGodly.Font = Enum.Font.GothamBold
tabGodly.Text = "Godly Spawner"
tabGodly.Parent = tabHolder
Instance.new("UICorner", tabGodly).CornerRadius = UDim.new(0, 6)

local line = Instance.new("Frame")
line.Size = UDim2.new(0, 1, 1, -20)
line.Position = UDim2.fromOffset(110, 10)
line.BackgroundColor3 = Color3.fromRGB(100, 30, 40)
line.BorderSizePixel = 0
line.Parent = contentHolder

local panelHolder = Instance.new("Frame")
panelHolder.Size = UDim2.new(1, -125, 1, -20)
panelHolder.Position = UDim2.fromOffset(120, 10)
panelHolder.BackgroundTransparency = 1
panelHolder.Parent = contentHolder

local farmContainer = Instance.new("Frame")
farmContainer.Size = UDim2.new(1, 0, 1, 0)
farmContainer.BackgroundTransparency = 1
farmContainer.Visible = true
farmContainer.Parent = panelHolder
local farmLayout = Instance.new("UIListLayout")
farmLayout.SortOrder = Enum.SortOrder.LayoutOrder
farmLayout.Padding = UDim.new(0, 10)
farmLayout.Parent = farmContainer

local flingContainer = Instance.new("Frame")
flingContainer.Size = UDim2.new(1, 0, 1, 0)
flingContainer.BackgroundTransparency = 1
flingContainer.Visible = false
flingContainer.Parent = panelHolder
local flingLayout = Instance.new("UIListLayout")
flingLayout.SortOrder = Enum.SortOrder.LayoutOrder
flingLayout.Padding = UDim.new(0, 10)
flingLayout.Parent = flingContainer

local sheriffContainer = Instance.new("ScrollingFrame")
sheriffContainer.Size = UDim2.new(1, 0, 1, 0)
sheriffContainer.BackgroundTransparency = 1
sheriffContainer.Visible = false
sheriffContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
sheriffContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
sheriffContainer.ScrollBarThickness = 4
sheriffContainer.Parent = panelHolder
local sheriffLayout = Instance.new("UIListLayout")
sheriffLayout.SortOrder = Enum.SortOrder.LayoutOrder
sheriffLayout.Padding = UDim.new(0, 10)
sheriffLayout.Parent = sheriffContainer

local murderContainer = Instance.new("ScrollingFrame")
murderContainer.Size = UDim2.new(1, 0, 1, 0)
murderContainer.BackgroundTransparency = 1
murderContainer.Visible = false
murderContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
murderContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
murderContainer.ScrollBarThickness = 4
murderContainer.Parent = panelHolder
local murderLayout = Instance.new("UIListLayout")
murderLayout.SortOrder = Enum.SortOrder.LayoutOrder
murderLayout.Padding = UDim.new(0, 10)
murderLayout.Parent = murderContainer

local playerContainer = Instance.new("ScrollingFrame")
playerContainer.Size = UDim2.new(1, 0, 1, 0)
playerContainer.BackgroundTransparency = 1
playerContainer.Visible = false
playerContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
playerContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
playerContainer.ScrollBarThickness = 4
playerContainer.Parent = panelHolder
local playerLayout = Instance.new("UIListLayout")
playerLayout.SortOrder = Enum.SortOrder.LayoutOrder
playerLayout.Padding = UDim.new(0, 10)
playerLayout.Parent = playerContainer

local espContainer = Instance.new("ScrollingFrame")
espContainer.Size = UDim2.new(1, 0, 1, 0)
espContainer.BackgroundTransparency = 1
espContainer.Visible = false
espContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
espContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
espContainer.ScrollBarThickness = 4
espContainer.Parent = panelHolder
local espLayout = Instance.new("UIListLayout")
espLayout.SortOrder = Enum.SortOrder.LayoutOrder
espLayout.Padding = UDim.new(0, 10)
espLayout.Parent = espContainer

local godlyContainer = Instance.new("ScrollingFrame")
godlyContainer.Size = UDim2.new(1, 0, 1, 0)
godlyContainer.BackgroundTransparency = 1
godlyContainer.Visible = false
godlyContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
godlyContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
godlyContainer.ScrollBarThickness = 4
godlyContainer.Parent = panelHolder
local godlyLayout = Instance.new("UIListLayout")
godlyLayout.SortOrder = Enum.SortOrder.LayoutOrder
godlyLayout.Padding = UDim.new(0, 10)
godlyLayout.Parent = godlyContainer

local settingsContainer = Instance.new("ScrollingFrame")
settingsContainer.Size = UDim2.new(1, 0, 1, 0)
settingsContainer.BackgroundTransparency = 1
settingsContainer.Visible = false
settingsContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
settingsContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
settingsContainer.ScrollBarThickness = 4
settingsContainer.Parent = panelHolder
local settingsLayout = Instance.new("UIListLayout")
settingsLayout.SortOrder = Enum.SortOrder.LayoutOrder
settingsLayout.Padding = UDim.new(0, 10)
settingsLayout.Parent = settingsContainer

local transFill = Instance.new("Frame")
transFill.Name = "TransFillCheck"
transFill.Size = UDim2.new(0, 0, 1, 0)
transFill.BackgroundColor3 = Color3.fromRGB(150, 30, 45)
transFill.BorderSizePixel = 0
Instance.new("UICorner", transFill).CornerRadius = UDim.new(1, 0)

local function applyTransparency(transparency)
    for _, descendant in ipairs(gui:GetDescendants()) do
        if descendant:IsA("GuiObject") and descendant ~= main and descendant ~= redDot and descendant ~= shootFloatingBtn and descendant ~= killAllFloatingBtn then
            if descendant:GetAttribute("OriginalBackgroundTransparency") == nil then
                descendant:SetAttribute("OriginalBackgroundTransparency", descendant.BackgroundTransparency)
            end
            if descendant:IsA("TextLabel") or descendant:IsA("TextButton") then
                if descendant:GetAttribute("OriginalTextTransparency") == nil then
                    descendant:SetAttribute("OriginalTextTransparency", descendant.TextTransparency)
                end
            end

            local origBg = descendant:GetAttribute("OriginalBackgroundTransparency") or 0  
            descendant.BackgroundTransparency = origBg + (1 - origBg) * transparency  
              
            if descendant:IsA("TextLabel") or descendant:IsA("TextButton") then  
                local origText = descendant:GetAttribute("OriginalTextTransparency") or 0  
                descendant.TextTransparency = origText + (1 - origText) * transparency  
            end  
        end  
    end  
    main.BackgroundTransparency = transparency
end

local function updateActiveTabVisuals(tabName)
    tabFarming.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
    tabFarming.TextColor3 = Color3.fromRGB(170, 170, 170)
    tabFling.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
    tabFling.TextColor3 = Color3.fromRGB(170, 170, 170)
    tabSheriff.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
    tabSheriff.TextColor3 = Color3.fromRGB(170, 170, 170)
    tabMurder.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
    tabMurder.TextColor3 = Color3.fromRGB(170, 170, 170)
    tabPlayer.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
    tabPlayer.TextColor3 = Color3.fromRGB(170, 170, 170)
    tabESP.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
    tabESP.TextColor3 = Color3.fromRGB(170, 170, 170)
    tabGodly.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
    tabGodly.TextColor3 = Color3.fromRGB(170, 170, 170)

    local activeBtn = (tabName == "Farming" and tabFarming)  
        or (tabName == "Fling" and tabFling)  
        or (tabName == "Sheriff" and tabSheriff)  
        or (tabName == "Murderer" and tabMurder)  
        or (tabName == "Player" and tabPlayer)  
        or (tabName == "ESP" and tabESP)  
        or tabGodly

    activeBtn.BackgroundColor3 = rainbowActive and Color3.fromHSV(tick() % 5 / 5, 1, 1) or currentThemeColor  
    activeBtn.TextColor3 = Color3.new(1, 1, 1)
end

table.insert(connections, settingsBtn.MouseButton1Click:Connect(function()
    isSettingsOpen = not isSettingsOpen
    farmContainer.Visible = false
    flingContainer.Visible = false
    sheriffContainer.Visible = false
    murderContainer.Visible = false
    playerContainer.Visible = false
    espContainer.Visible = false
    godlyContainer.Visible = false
    settingsContainer.Visible = isSettingsOpen

    if isSettingsOpen then  
        settingsBtn.BackgroundColor3 = currentThemeColor  
        tabFarming.BackgroundColor3 = Color3.fromRGB(45, 45, 50)  
        tabFling.BackgroundColor3 = Color3.fromRGB(45, 45, 50)  
        tabSheriff.BackgroundColor3 = Color3.fromRGB(45, 45, 50)  
        tabMurder.BackgroundColor3 = Color3.fromRGB(45, 45, 50)  
        tabPlayer.BackgroundColor3 = Color3.fromRGB(45, 45, 50)  
        tabESP.BackgroundColor3 = Color3.fromRGB(45, 45, 50)  
        tabGodly.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
    else  
        settingsBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 50)  
        farmContainer.Visible = (lastActiveTab == "Farming")  
        flingContainer.Visible = (lastActiveTab == "Fling")  
        sheriffContainer.Visible = (lastActiveTab == "Sheriff")  
        murderContainer.Visible = (lastActiveTab == "Murderer")  
        playerContainer.Visible = (lastActiveTab == "Player")  
        espContainer.Visible = (lastActiveTab == "ESP")  
        godlyContainer.Visible = (lastActiveTab == "Godly")
        updateActiveTabVisuals(lastActiveTab)  
    end
end))

local label = Instance.new("TextLabel")
label.Size = UDim2.new(1, 0, 0, 20)
label.BackgroundTransparency = 1
label.Text = "Auto Farm Candy"
label.TextColor3 = Color3.new(1, 1, 1)
label.TextSize = 14
label.Font = Enum.Font.GothamSemibold
label.TextXAlignment = Enum.TextXAlignment.Left
label.LayoutOrder = 1
label.Parent = farmContainer

local toggle = Instance.new("TextButton")
toggle.Size = UDim2.fromOffset(48, 25)
toggle.BackgroundColor3 = Color3.fromRGB(55, 55, 60)
toggle.Text = ""
toggle.AutoButtonColor = false
toggle.LayoutOrder = 2
toggle.Parent = farmContainer
Instance.new("UICorner", toggle).CornerRadius = UDim.new(1, 0)

local toggleKnob = Instance.new("Frame")
toggleKnob.Size = UDim2.fromOffset(19, 19)
toggleKnob.Position = UDim2.fromOffset(3, 3)
toggleKnob.BackgroundColor3 = Color3.new(1, 1, 1)
toggleKnob.Parent = toggle
Instance.new("UICorner", toggleKnob).CornerRadius = UDim.new(1, 0)

local speedTitle = Instance.new("TextLabel")
speedTitle.Size = UDim2.new(1, 0, 0, 20)
speedTitle.BackgroundTransparency = 1
speedTitle.Text = "Speed: " .. farmSpeed .. " studs/s"
speedTitle.TextColor3 = Color3.fromRGB(230, 230, 230)
speedTitle.TextSize = 12
speedTitle.Font = Enum.Font.GothamSemibold
speedTitle.TextXAlignment = Enum.TextXAlignment.Left
speedTitle.LayoutOrder = 3
speedTitle.Parent = farmContainer

local sliderWrapper = Instance.new("TextButton")
sliderWrapper.Size = UDim2.new(1, 0, 0, 24)
sliderWrapper.BackgroundTransparency = 1
sliderWrapper.Text = ""
sliderWrapper.AutoButtonColor = false
sliderWrapper.LayoutOrder = 4
sliderWrapper.Parent = farmContainer

local slider = Instance.new("Frame")
slider.Size = UDim2.new(1, 0, 0, 7)
slider.AnchorPoint = Vector2.new(0, 0.5)
slider.Position = UDim2.new(0, 0, 0.5, 0)
slider.BackgroundColor3 = Color3.fromRGB(55, 55, 60)
slider.BorderSizePixel = 0
slider.Parent = sliderWrapper
Instance.new("UICorner", slider).CornerRadius = UDim.new(1, 0)

local initialPosition = (farmSpeed - MIN_SPEED) / (MAX_SPEED - MIN_SPEED)
local fill = Instance.new("Frame")
fill.Size = UDim2.new(initialPosition, 0, 1, 0)
fill.BackgroundColor3 = Color3.fromRGB(150, 30, 45)
fill.BorderSizePixel = 0
fill.Parent = slider
Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

local sliderKnob = Instance.new("Frame")
sliderKnob.Size = UDim2.fromOffset(15, 15)
sliderKnob.AnchorPoint = Vector2.new(0.5, 0.5)
sliderKnob.Position = UDim2.new(initialPosition, 0, 0.5, 0)
sliderKnob.BackgroundColor3 = Color3.fromRGB(245, 245, 245)
sliderKnob.BorderSizePixel = 0
sliderKnob.Parent = slider
Instance.new("UICorner", sliderKnob).CornerRadius = UDim.new(1, 0)

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, 0, 0, 20)
status.BackgroundTransparency = 1
status.Text = "Status: OFF"
status.TextColor3 = Color3.fromRGB(170, 170, 170)
status.TextSize = 12
status.Font = Enum.Font.Gotham
status.TextXAlignment = Enum.TextXAlignment.Left
status.LayoutOrder = 5
status.Parent = farmContainer

local function updateSlider(inputX)
    local width = slider.AbsoluteSize.X
    if width <= 0 then return end
    local relativeX = math.clamp(inputX - slider.AbsolutePosition.X, 0, width)
    local percent = relativeX / width
    farmSpeed = math.clamp(math.floor(MIN_SPEED + percent * (MAX_SPEED - MIN_SPEED) + 0.5), MIN_SPEED, MAX_SPEED)
    local position = (farmSpeed - MIN_SPEED) / (MAX_SPEED - MIN_SPEED)
    fill.Size = UDim2.new(position, 0, 1, 0)
    sliderKnob.Position = UDim2.new(position, 0, 0.5, 0)
    speedTitle.Text = "Speed: " .. farmSpeed .. " studs/s"
end

table.insert(connections, sliderWrapper.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        activeSliderType = "FarmSpeed"
        activeInputObject = input
        updateSlider(input.Position.X)
    end
end))

table.insert(connections, toggle.MouseButton1Click:Connect(function()
    enabled = not enabled
    TweenService:Create(toggle, TweenInfo.new(0.2), { BackgroundColor3 = enabled and currentThemeColor or Color3.fromRGB(55, 55, 60) }):Play()
    TweenService:Create(toggleKnob, TweenInfo.new(0.2), { Position = enabled and UDim2.fromOffset(26, 3) or UDim2.fromOffset(3, 3) }):Play()
    status.Text = enabled and "Status: ON" or "Status: OFF"

    if not enabled then
        local char = player.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end
end))

local flingHeader = Instance.new("TextLabel")
flingHeader.Size = UDim2.new(1, 0, 0, 20)
flingHeader.BackgroundTransparency = 1
flingHeader.Text = "Combined Solid Fling"
flingHeader.TextColor3 = Color3.fromRGB(230, 230, 230)
flingHeader.TextSize = 13
flingHeader.Font = Enum.Font.GothamBold
flingHeader.TextXAlignment = Enum.TextXAlignment.Left
flingHeader.LayoutOrder = 1
flingHeader.Parent = flingContainer

local murderButton = Instance.new("TextButton")
murderButton.Size = UDim2.new(1, 0, 0, 35)
murderButton.BackgroundColor3 = Color3.fromRGB(145, 30, 45)
murderButton.TextColor3 = Color3.new(1, 1, 1)
murderButton.TextSize = 12
murderButton.Font = Enum.Font.GothamBold
murderButton.Text = "Fling Murder"
murderButton.AutoButtonColor = true
murderButton.LayoutOrder = 2
murderButton.Parent = flingContainer
Instance.new("UICorner", murderButton).CornerRadius = UDim.new(0, 8)

local sheriffButton = Instance.new("TextButton")
sheriffButton.Size = UDim2.new(1, 0, 0, 35)
sheriffButton.BackgroundColor3 = Color3.fromRGB(30, 95, 145)
sheriffButton.TextColor3 = Color3.new(1, 1, 1)
sheriffButton.TextSize = 12
sheriffButton.Font = Enum.Font.GothamBold
sheriffButton.Text = "Fling Sheriff"
sheriffButton.AutoButtonColor = true
sheriffButton.LayoutOrder = 3
sheriffButton.Parent = flingContainer
Instance.new("UICorner", sheriffButton).CornerRadius = UDim.new(0, 8)

local function flingTargetPlayer(targetPlayer)
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root or not targetPlayer or not targetPlayer.Character then return end
    
    local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    local targetHumanoid = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
    if not targetRoot or not targetHumanoid or targetHumanoid.Health <= 0 then return end

    local startTime = tick()
    local connection
    connection = RunService.RenderStepped:Connect(function()
        if not char or not root or not targetRoot or tick() - startTime > 1.5 then
            if connection then connection:Disconnect() end
            root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            return
        end

        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end

        root.CFrame = targetRoot.CFrame * CFrame.new(math.sin(tick() * 50) * 2, 0, math.cos(tick() * 50) * 2)
        root.AssemblyLinearVelocity = Vector3.new(30000, 30000, 30000)
        root.AssemblyAngularVelocity = Vector3.new(99999, 99999, 99999)
    end)
end

local function findSheriff()
    local targetPlayer = nil
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player then
            local bp = p:FindFirstChild("Backpack")
            local char = p.Character
            if (bp and (bp:FindFirstChild("Gun") or bp:FindFirstChild("Revolver"))) or (char and (char:FindFirstChild("Gun") or char:FindFirstChild("Revolver"))) then
                targetPlayer = p
                break
            end
        end
    end
    return targetPlayer
end

local function findMurderer()
    local targetPlayer = nil
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player then
            local bp = p:FindFirstChild("Backpack")
            local char = p.Character
            if (bp and bp:FindFirstChild("Knife")) or (char and char:FindFirstChild("Knife")) then
                targetPlayer = p
                break
            end
        end
    end
    return targetPlayer
end

table.insert(connections, murderButton.MouseButton1Click:Connect(function()
    local murderer = findMurderer()
    if murderer then
        flingTargetPlayer(murderer)
    end
end))

table.insert(connections, sheriffButton.MouseButton1Click:Connect(function()
    local sheriff = findSheriff()
    if sheriff then
        flingTargetPlayer(sheriff)
    end
end))

local function createToggle(parent, text, callback)
    local layoutOrder = parent:FindFirstChildOfClass("UIListLayout") and #parent:GetChildren() or 1
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 30)
    container.BackgroundTransparency = 1
    container.LayoutOrder = layoutOrder
    container.Parent = parent

    local lbl = Instance.new("TextLabel")  
    lbl.Size = UDim2.new(1, -60, 1, 0)  
    lbl.BackgroundTransparency = 1  
    lbl.Text = text  
    lbl.TextColor3 = Color3.new(1, 1, 1)  
    lbl.TextSize = 12  
    lbl.Font = Enum.Font.GothamSemibold  
    lbl.TextXAlignment = Enum.TextXAlignment.Left  
    lbl.Parent = container  

    local tgl = Instance.new("TextButton")  
    tgl.Size = UDim2.fromOffset(48, 25)  
    tgl.AnchorPoint = Vector2.new(1, 0.5)  
    tgl.Position = UDim2.new(1, 0, 0.5, 0)  
    tgl.BackgroundColor3 = Color3.fromRGB(55, 55, 60)  
    tgl.Text = ""  
    tgl.AutoButtonColor = false  
    tgl.Parent = container  
    Instance.new("UICorner", tgl).CornerRadius = UDim.new(1, 0)  

    local knob = Instance.new("Frame")  
    knob.Size = UDim2.fromOffset(19, 19)  
    knob.Position = UDim2.fromOffset(3, 3)  
    knob.BackgroundColor3 = Color3.new(1, 1, 1)  
    knob.Parent = tgl  
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)  

    local state = false  
    table.insert(connections, tgl.MouseButton1Click:Connect(function()  
        state = not state  
        TweenService:Create(tgl, TweenInfo.new(0.2), { BackgroundColor3 = state and currentThemeColor or Color3.fromRGB(55, 55, 60) }):Play()  
        TweenService:Create(knob, TweenInfo.new(0.2), { Position = state and UDim2.fromOffset(26, 3) or UDim2.fromOffset(3, 3) }):Play()  
        callback(state)  
    end))
end

local godlyHeader = Instance.new("TextLabel")
godlyHeader.Size = UDim2.new(1, 0, 0, 20)
godlyHeader.BackgroundTransparency = 1
godlyHeader.Text = "--- KNIVES ---"
godlyHeader.TextColor3 = Color3.fromRGB(255, 200, 0)
godlyHeader.TextSize = 12
godlyHeader.Font = Enum.Font.GothamBold
godlyHeader.TextXAlignment = Enum.TextXAlignment.Left
godlyHeader.LayoutOrder = 1
godlyHeader.Parent = godlyContainer

for _, item in ipairs(VisualInventory.Knives) do
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, 0, 0, 32)
    Btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    Btn.Text = item.Name .. " [UNEQUIPPED]"
    Btn.Font = Enum.Font.GothamSemibold
    Btn.TextSize = 11
    Btn.LayoutOrder = godlyContainer:FindFirstChildOfClass("UIListLayout") and #godlyContainer:GetChildren() or 2
    Btn.Parent = godlyContainer
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 6)

    table.insert(connections, Btn.MouseButton1Click:Connect(function()
        if EquippedItems.Knife == item then
            EquippedItems.Knife = nil
            Btn.Text = item.Name .. " [UNEQUIPPED]"
            Btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        else
            EquippedItems.Knife = item
            Btn.Text = item.Name .. " [EQUIPPED]"
            Btn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
        end
    end))
end

local gunHeader = Instance.new("TextLabel")
gunHeader.Size = UDim2.new(1, 0, 0, 25)
gunHeader.BackgroundTransparency = 1
gunHeader.Text = "--- GUNS ---"
gunHeader.TextColor3 = Color3.fromRGB(0, 170, 255)
gunHeader.TextSize = 12
gunHeader.Font = Enum.Font.GothamBold
gunHeader.TextXAlignment = Enum.TextXAlignment.Left
gunHeader.LayoutOrder = godlyContainer:FindFirstChildOfClass("UIListLayout") and #godlyContainer:GetChildren() or 10
gunHeader.Parent = godlyContainer

for _, item in ipairs(VisualInventory.Guns) do
    local TheBtn = Instance.new("TextButton")
    TheBtn.Size = UDim2.new(1, 0, 0, 32)
    TheBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    TheBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    TheBtn.Text = item.Name .. " [UNEQUIPPED]"
    TheBtn.Font = Enum.Font.GothamSemibold
    TheBtn.TextSize = 11
    TheBtn.LayoutOrder = godlyContainer:FindFirstChildOfClass("UIListLayout") and #godlyContainer:GetChildren() or 11
    TheBtn.Parent = godlyContainer
    Instance.new("UICorner", TheBtn).CornerRadius = UDim.new(0, 6)

    table.insert(connections, TheBtn.MouseButton1Click:Connect(function()
        if EquippedItems.Gun == item then
            EquippedItems.Gun = nil
            TheBtn.Text = item.Name .. " [UNEQUIPPED]"
            TheBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        else
            EquippedItems.Gun = item
            TheBtn.Text = item.Name .. " [EQUIPPED]"
            TheBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
        end
    end))
end

local sheriffHeader = Instance.new("TextLabel")
sheriffHeader.Size = UDim2.new(1, 0, 0, 20)
sheriffHeader.BackgroundTransparency = 1
sheriffHeader.Text = "Sheriff Utilities"
sheriffHeader.TextColor3 = Color3.fromRGB(230, 230, 230)
sheriffHeader.TextSize = 13
sheriffHeader.Font = Enum.Font.GothamBold
sheriffHeader.TextXAlignment = Enum.TextXAlignment.Left
sheriffHeader.LayoutOrder = 1
sheriffHeader.Parent = sheriffContainer

createToggle(sheriffContainer, "Aimbot (Auto Equip)", function(state) aimbotActive = state end)
createToggle(sheriffContainer, "Shoot Murderer Button", function(state)
    shootButtonActive = state
    shootFloatingBtn.Visible = state
end)
createToggle(sheriffContainer, "Auto Grab Gun", function(state) autoGrabGunActive = state end)

local murderHeader = Instance.new("TextLabel")
murderHeader.Size = UDim2.new(1, 0, 0, 20)
murderHeader.BackgroundTransparency = 1
murderHeader.Text = "Murderer Utilities"
murderHeader.TextColor3 = Color3.fromRGB(230, 230, 230)
murderHeader.TextSize = 13
murderHeader.Font = Enum.Font.GothamBold
murderHeader.TextXAlignment = Enum.TextXAlignment.Left
murderHeader.LayoutOrder = 1
murderHeader.Parent = murderContainer

createToggle(murderContainer, "Kill All Button", function(state)
    killAllButtonActive = state
    killAllFloatingBtn.Visible = state
end)

local playerHeader = Instance.new("TextLabel")
playerHeader.Size = UDim2.new(1, 0, 0, 20)
playerHeader.BackgroundTransparency = 1
playerHeader.Text = "Player Utilities"
playerHeader.TextColor3 = Color3.fromRGB(230, 230, 230)
playerHeader.TextSize = 13
playerHeader.Font = Enum.Font.GothamBold
playerHeader.TextXAlignment = Enum.TextXAlignment.Left
playerHeader.LayoutOrder = 1
playerHeader.Parent = playerContainer

createToggle(playerContainer, "Fly", function(state)
    flyActive = state
    if not state then
        local char = player.Character
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.PlatformStand = false
            local animateScript = char:FindFirstChild("Animate")
            if animateScript then animateScript.Enabled = true end
        end
    end
end)

createToggle(playerContainer, "Infinite Jump", function(state)
    infiniteJumpActive = state
end)

createToggle(playerContainer, "JumpPower", function(state)
    jumpPowerActive = state
    if not state then
        local char = player.Character
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        if humanoid then humanoid.JumpPower = 50 end
    end
end)

local jpTitle = Instance.new("TextLabel")
jpTitle.Size = UDim2.new(1, 0, 0, 20)
jpTitle.BackgroundTransparency = 1
jpTitle.Text = "Jump Power: 50"
jpTitle.TextColor3 = Color3.fromRGB(230, 230, 230)
jpTitle.TextSize = 11
jpTitle.Font = Enum.Font.GothamSemibold
jpTitle.TextXAlignment = Enum.TextXAlignment.Left
jpTitle.LayoutOrder = 6
jpTitle.Parent = playerContainer

local jpWrapper = Instance.new("TextButton")
jpWrapper.Size = UDim2.new(1, 0, 0, 24)
jpWrapper.BackgroundTransparency = 1
jpWrapper.Text = ""
jpWrapper.AutoButtonColor = false
jpWrapper.LayoutOrder = 7
jpWrapper.Parent = playerContainer

local jpSlider = Instance.new("Frame")
jpSlider.Size = UDim2.new(1, 0, 0, 7)
jpSlider.AnchorPoint = Vector2.new(0, 0.5)
jpSlider.Position = UDim2.new(0, 0, 0.5, 0)
jpSlider.BackgroundColor3 = Color3.fromRGB(55, 55, 60)
jpSlider.BorderSizePixel = 0
jpSlider.Parent = jpWrapper
Instance.new("UICorner", jpSlider).CornerRadius = UDim.new(1, 0)

local jpFill = Instance.new("Frame")
jpFill.Size = UDim2.new(0, 0, 1, 0)
jpFill.BackgroundColor3 = Color3.fromRGB(150, 30, 45)
jpFill.BorderSizePixel = 0
jpFill.Parent = jpSlider
Instance.new("UICorner", jpFill).CornerRadius = UDim.new(1, 0)

local jpKnob = Instance.new("Frame")
jpKnob.Size = UDim2.fromOffset(15, 15)
jpKnob.AnchorPoint = Vector2.new(0.5, 0.5)
jpKnob.Position = UDim2.new(0, 0, 0.5, 0)
jpKnob.BackgroundColor3 = Color3.fromRGB(245, 245, 245)
jpKnob.BorderSizePixel = 0
jpKnob.Parent = jpSlider
Instance.new("UICorner", jpKnob).CornerRadius = UDim.new(1, 0)

createToggle(playerContainer, "WalkSpeed", function(state)
    walkSpeedActive = state
    if not state then
        local char = player.Character
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        if humanoid then humanoid.WalkSpeed = 16 end
    end
end)

local wsTitle = Instance.new("TextLabel")
wsTitle.Size = UDim2.new(1, 0, 0, 20)
wsTitle.BackgroundTransparency = 1
wsTitle.Text = "Walk Speed: 16"
wsTitle.TextColor3 = Color3.fromRGB(230, 230, 230)
wsTitle.TextSize = 11
wsTitle.Font = Enum.Font.GothamSemibold
wsTitle.TextXAlignment = Enum.TextXAlignment.Left
wsTitle.LayoutOrder = 10
wsTitle.Parent = playerContainer

local wsWrapper = Instance.new("TextButton")
wsWrapper.Size = UDim2.new(1, 0, 0, 24)
wsWrapper.BackgroundTransparency = 1
wsWrapper.Text = ""
wsWrapper.AutoButtonColor = false
wsWrapper.LayoutOrder = 11
wsWrapper.Parent = playerContainer

local wsSlider = Instance.new("Frame")
wsSlider.Size = UDim2.new(1, 0, 0, 7)
wsSlider.AnchorPoint = Vector2.new(0, 0.5)
wsSlider.Position = UDim2.new(0, 0, 0.5, 0)
wsSlider.BackgroundColor3 = Color3.fromRGB(55, 55, 60)
wsSlider.BorderSizePixel = 0
wsSlider.Parent = wsWrapper
Instance.new("UICorner", wsSlider).CornerRadius = UDim.new(1, 0)

local wsFill = Instance.new("Frame")
wsFill.Size = UDim2.new(0, 0, 1, 0)
wsFill.BackgroundColor3 = Color3.fromRGB(150, 30, 45)
wsFill.BorderSizePixel = 0
wsFill.Parent = wsSlider
Instance.new("UICorner", wsFill).CornerRadius = UDim.new(1, 0)

local wsKnob = Instance.new("Frame")
wsKnob.Size = UDim2.fromOffset(15, 15)
wsKnob.AnchorPoint = Vector2.new(0.5, 0.5)
wsKnob.Position = UDim2.new(0, 0, 0.5, 0)
wsKnob.BackgroundColor3 = Color3.fromRGB(245, 245, 245)
wsKnob.BorderSizePixel = 0
wsKnob.Parent = wsSlider
Instance.new("UICorner", wsKnob).CornerRadius = UDim.new(1, 0)

local function updateJumpPower(inputX)
    local width = jpSlider.AbsoluteSize.X
    if width > 0 then
        local relativeX = math.clamp(inputX - jpSlider.AbsolutePosition.X, 0, width)
        local percent = relativeX / width
        local scaledPercent = percent * percent
        customJumpPower = math.clamp(math.floor(50 + scaledPercent * (900 - 50) + 0.5), 50, 900)
        jpFill.Size = UDim2.new(percent, 0, 1, 0)
        jpKnob.Position = UDim2.new(percent, 0, 0.5, 0)
        jpTitle.Text = "Jump Power: " .. customJumpPower
    end
end

local function updateWalkSpeed(inputX)
    local width = wsSlider.AbsoluteSize.X
    if width > 0 then
        local relativeX = math.clamp(inputX - wsSlider.AbsolutePosition.X, 0, width)
        local percent = relativeX / width
        local scaledPercent = percent * percent
        customWalkSpeed = math.clamp(math.floor(16 + scaledPercent * (1000 - 16) + 0.5), 16, 1000)
        wsFill.Size = UDim2.new(percent, 0, 1, 0)
        wsKnob.Position = UDim2.new(percent, 0, 0.5, 0)
        wsTitle.Text = "Walk Speed: " .. customWalkSpeed
    end
end

table.insert(connections, jpWrapper.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        activeSliderType = "JumpPower"
        activeInputObject = input
        updateJumpPower(input.Position.X)
    end
end))

table.insert(connections, wsWrapper.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        activeSliderType = "WalkSpeed"
        activeInputObject = input
        updateWalkSpeed(input.Position.X)
    end
end))

local espHeader = Instance.new("TextLabel")
espHeader.Size = UDim2.new(1, 0, 0, 20)
espHeader.BackgroundTransparency = 1
espHeader.Text = "Role ESP & Names"
espHeader.TextColor3 = Color3.fromRGB(230, 230, 230)
espHeader.TextSize = 13
espHeader.Font = Enum.Font.GothamBold
espHeader.TextXAlignment = Enum.TextXAlignment.Left
espHeader.LayoutOrder = 1
espHeader.Parent = espContainer

createToggle(espContainer, "ESP Murderer", function(state)
    espMurdererActive = state
    if not state then
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character and p ~= player then
                local hl = p.Character:FindFirstChild("MM2MurdererHL")
                if hl then hl:Destroy() end
            end
        end
    end
end)

createToggle(espContainer, "ESP Sheriff", function(state)
    espSheriffActive = state
    if not state then
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character and p ~= player then
                local hl = p.Character:FindFirstChild("MM2SheriffHL")
                if hl then hl:Destroy() end
            end
        end
    end
end)

createToggle(espContainer, "ESP Innocents", function(state)
    espInnocentsActive = state
    if not state then
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character and p ~= player then
                local hl = p.Character:FindFirstChild("MM2InnocentHL")
                if hl then hl:Destroy() end
            end
        end
    end
end)

createToggle(espContainer, "ESP User", function(state)
    espUserActive = state
    if not state then
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character and p ~= player then
                local head = p.Character:FindFirstChild("Head")
                if head then
                    local tag = head:FindFirstChild("MM2UserTag")
                    if tag then tag:Destroy() end
                end
            end
        end
    end
end)

local function clearAllHighlights()
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then
            for _, name in ipairs({"MM2MurdererHL", "MM2SheriffHL", "MM2InnocentHL"}) do
                local hl = p.Character:FindFirstChild(name)
                if hl then hl:Destroy() end
            end
            local head = p.Character:FindFirstChild("Head")
            if head then
                local tag = head:FindFirstChild("MM2UserTag")
                if tag then tag:Destroy() end
            end
        end
    end
end

local function updateRoleESP()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            local bp = p:FindFirstChild("Backpack")
            local char = p.Character
            local head = char:FindFirstChild("Head")

            local isMurderer = (bp and bp:FindFirstChild("Knife")) or (char and char:FindFirstChild("Knife"))  
            local isSheriff = (bp and (bp:FindFirstChild("Gun") or bp:FindFirstChild("Revolver"))) or (char and (char:FindFirstChild("Gun") or char:FindFirstChild("Revolver")))  
              
            local roleColor = Color3.fromRGB(30, 200, 70)  
            if isMurderer then  
                roleColor = Color3.fromRGB(220, 30, 30)  
            elseif isSheriff then  
                roleColor = Color3.fromRGB(30, 110, 220)  
            end  

            local mHl = char:FindFirstChild("MM2MurdererHL")  
            local sHl = char:FindFirstChild("MM2SheriffHL")  
            local iHl = char:FindFirstChild("MM2InnocentHL")  

            if espMurdererActive and isMurderer then  
                if not mHl then  
                    mHl = Instance.new("Highlight")  
                    mHl.Name = "MM2MurdererHL"  
                    mHl.FillTransparency = 0.4  
                    mHl.OutlineTransparency = 0  
                    mHl.FillColor = roleColor  
                    mHl.OutlineColor = Color3.fromRGB(255, 255, 255)  
                    mHl.Parent = char  
                end  
            elseif mHl then mHl:Destroy() end  

            if espSheriffActive and isSheriff then  
                if not sHl then  
                    sHl = Instance.new("Highlight")  
                    sHl.Name = "MM2SheriffHL"  
                    sHl.FillTransparency = 0.4  
                    sHl.OutlineTransparency = 0  
                    sHl.FillColor = roleColor  
                    sHl.OutlineColor = Color3.fromRGB(255, 255, 255)  
                    sHl.Parent = char  
                end  
            elseif sHl then sHl:Destroy() end  

            if espInnocentsActive and not isMurderer and not isSheriff then  
                if not iHl then  
                    iHl = Instance.new("Highlight")  
                    iHl.Name = "MM2InnocentHL"  
                    iHl.FillTransparency = 0.4  
                    iHl.OutlineTransparency = 0  
                    iHl.FillColor = roleColor  
                    iHl.OutlineColor = Color3.fromRGB(255, 255, 255)  
                    iHl.Parent = char  
                end  
            elseif iHl then iHl:Destroy() end  

            if head then  
                local tag = head:FindFirstChild("MM2UserTag")  
                if espUserActive then  
                    if not tag then  
                        tag = Instance.new("BillboardGui")  
                        tag.Name = "MM2UserTag"  
                        tag.Size = UDim2.fromOffset(200, 40)  
                        tag.StudsOffset = Vector3.new(0, 2.5, 0)  
                        tag.AlwaysOnTop = true  
                        tag.Parent = head  

                        local textLbl = Instance.new("TextLabel")  
                        textLbl.Name = "NameText"  
                        textLbl.Size = UDim2.new(1, 0, 1, 0)  
                        textLbl.BackgroundTransparency = 1  
                        textLbl.TextSize = 13  
                        textLbl.Font = Enum.Font.GothamBold  
                        textLbl.TextStrokeTransparency = 0.2  
                        textLbl.Parent = tag  
                    end  

                    local textLbl = tag:FindFirstChild("NameText")  
                    if textLbl then  
                        textLbl.Text = p.Name  
                        textLbl.TextColor3 = roleColor  
                    end  
                elseif tag then  
                    tag:Destroy()  
                end  
            end  
        end  
    end
end

local function getKnife()
    local char = player.Character
    local backpack = player:FindFirstChild("Backpack")

    if char then  
        local equippedKnife = char:FindFirstChild("Knife")  
        if equippedKnife then return equippedKnife end  
    end  
      
    if backpack then  
        local storedKnife = backpack:FindFirstChild("Knife")  
        if storedKnife and char then  
            storedKnife.Parent = char  
            return storedKnife  
        end  
    end  
    return nil
end

local function getGun()
    local char = player.Character
    local backpack = player:FindFirstChild("Backpack")

    if char then  
        local equippedGun = char:FindFirstChild("Gun") or char:FindFirstChild("Revolver")  
        if equippedGun then return equippedGun end  
    end  
      
    if backpack then  
        local storedGun = backpack:FindFirstChild("Gun") or backpack:FindFirstChild("Revolver")  
        if storedGun and char then  
            storedGun.Parent = char  
            return storedGun  
        end  
    end  
    return nil
end

table.insert(connections, killAllFloatingBtn.MouseButton1Click:Connect(function()
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")

    if root then  
        getKnife()  
        task.wait(0.05)  

        for _, p in ipairs(Players:GetPlayers()) do  
            if p ~= player and p.Character then  
                local pRoot = p.Character:FindFirstChild("HumanoidRootPart")  
                local pHumanoid = p.Character:FindFirstChildOfClass("Humanoid")  
                if pRoot and pHumanoid and pHumanoid.Health > 0 then  
                    pRoot.CFrame = root.CFrame  
                end  
            end  
        end  
          
        pcall(function()  
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)  
            task.wait(0.05)  
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)  
        end)  
    end
end))

table.insert(connections, shootFloatingBtn.MouseButton1Click:Connect(function()
    local char = player.Character
    local backpack = player:FindFirstChild("Backpack")

    if not char then return end  

    local gun = char:FindFirstChild("Gun") or char:FindFirstChild("Revolver")  
    if not gun and backpack then  
        local storedGun = backpack:FindFirstChild("Gun") or backpack:FindFirstChild("Revolver")  
        if storedGun then  
            storedGun.Parent = char  
            task.wait(0.05)  
            gun = char:FindFirstChild("Gun") or char:FindFirstChild("Revolver")  
        end  
    end  

    if not gun then return end  

    local murderer = findMurderer()  
    if murderer and murderer.Character then  
        local mRoot = murderer.Character:FindFirstChild("HumanoidRootPart") or murderer.Character:FindFirstChild("Head")  
        local root = char:FindFirstChild("HumanoidRootPart")  
          
        if mRoot and root then  
            local oldCFrame = root.CFrame  
            local targetPos = Vector3.new(mRoot.Position.X, root.Position.Y, mRoot.Position.Z)  
            root.CFrame = CFrame.new(root.Position, targetPos)  
              
            pcall(function()  
                gun:Activate()  
            end)  
              
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)  
            task.wait(0.05)  
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)  
              
            root.CFrame = oldCFrame  
        end  
    end
end))

local userInput = {
    W = false, S = false, A = false, D = false,
    Space = false, Shift = false
}

table.insert(connections, UIS.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.W then userInput.W = true end
    if input.KeyCode == Enum.KeyCode.S then userInput.S = true end
    if input.KeyCode == Enum.KeyCode.A then userInput.A = true end
    if input.KeyCode == Enum.KeyCode.D then userInput.D = true end
    if input.KeyCode == Enum.KeyCode.Space then 
        userInput.Space = true 
        if infiniteJumpActive then
            local char = player.Character
            local humanoid = char and char:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end
    if input.KeyCode == Enum.KeyCode.LeftShift then userInput.Shift = true end
end))

table.insert(connections, UIS.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.W then userInput.W = false end
    if input.KeyCode == Enum.KeyCode.S then userInput.S = false end
    if input.KeyCode == Enum.KeyCode.A then userInput.A = false end
    if input.KeyCode == Enum.KeyCode.D then userInput.D = false end
    if input.KeyCode == Enum.KeyCode.Space then userInput.Space = false end
    if input.KeyCode == Enum.KeyCode.LeftShift then userInput.Shift = false end
end))

local function isBagFull()
    local mainGui = playerGui:FindFirstChild("MainGUI")
    if not mainGui then return false end
    local gameFolder = mainGui:FindFirstChild("Game")
    if not gameFolder then return false end
    local coinBags = gameFolder:FindFirstChild("CoinBags")
    if not coinBags then return false end

    for _, container in ipairs(coinBags:GetChildren()) do
        if container:IsA("GuiObject") or container:IsA("Folder") or container:IsA("Model") then
            local fullIcon = container:FindFirstChild("FullBagIcon")
            if fullIcon and (fullIcon:IsA("GuiObject") or fullIcon:IsA("ImageLabel")) and fullIcon.Visible then
                return true
            end
        end
    end
    return false
end

local espTimer = 0
table.insert(connections, RunService.RenderStepped:Connect(function(dt)
    local cam = workspace.CurrentCamera
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")

    if enabled and root then  
        if isBagFull() then
            for _, part in ipairs(char:GetDescendants()) do  
                if part:IsA("BasePart") then  
                    part.CanCollide = true  
                end  
            end
        else
            for _, part in ipairs(char:GetDescendants()) do  
                if part:IsA("BasePart") then  
                    part.CanCollide = false  
                end    
            end  

            local allCoins = {}  

            for _, map in ipairs(workspace:GetChildren()) do  
                local coinContainer = map:FindFirstChild("CoinContainer")  
                if coinContainer then  
                    for _, coinServer in ipairs(coinContainer:GetChildren()) do  
                        if coinServer.Name == "Coin_Server" then  
                            local coinVisual = coinServer:FindFirstChild("CoinVisual")  
                            if coinVisual and coinVisual:IsA("BasePart") then  
                                local dist = (root.Position - coinVisual.Position).Magnitude  
                                table.insert(allCoins, {part = coinVisual, distance = dist})  
                            end  
                        end  
                    end  
                end  
            end  

            if #allCoins > 0 then  
                table.sort(allCoins, function(a, b)  
                    return a.distance < b.distance  
                end)  

                local nearestCoin = allCoins[1].part  
                local targetPos = nearestCoin.Position  
                local distance = allCoins[1].distance  

                if distance > 1 then  
                    local lookAtPos = Vector3.new(targetPos.X, root.Position.Y, targetPos.Z)  
                    local targetCFrame = CFrame.new(root.Position, lookAtPos)  
                    root.CFrame = root.CFrame:Lerp(targetCFrame, math.clamp((farmSpeed * dt) / distance, 0, 1))  
                    root.CFrame = root.CFrame + (targetPos - root.Position).Unit * math.min(farmSpeed * dt, distance)  
                end  
            end  
        end
    end  

    if humanoid then  
        if jumpPowerActive then  
            humanoid.JumpPower = customJumpPower  
        end  

        if walkSpeedActive then  
            humanoid.WalkSpeed = customWalkSpeed  
        end  
    end  

    if flyActive and root and humanoid then  
        humanoid.PlatformStand = true  
          
        local animateScript = char:FindFirstChild("Animate")  
        if animateScript then animateScript.Enabled = false end  
        for _, track in ipairs(humanoid:GetPlayingAnimationTracks()) do  
            track:Stop(0)  
        end  

        local moveDirection = Vector3.zero  
          
        if userInput.W then moveDirection = moveDirection + cam.CFrame.LookVector end  
        if userInput.S then moveDirection = moveDirection - cam.CFrame.LookVector end  
        if userInput.A then moveDirection = moveDirection - cam.CFrame.RightVector end  
        if userInput.D then moveDirection = moveDirection + cam.CFrame.RightVector end  
        if userInput.Space then moveDirection = moveDirection + Vector3.new(0, 1, 0) end  
        if userInput.Shift then moveDirection = moveDirection - Vector3.new(0, 1, 0) end  

        if moveDirection.Magnitude > 0 then  
            root.Velocity = moveDirection.Unit * flySpeed  
            root.CFrame = CFrame.new(root.Position, root.Position + cam.CFrame.LookVector)  
        else  
            root.Velocity = Vector3.new(0, 0.1, 0)  
        end  
    else  
        if humanoid and humanoid.PlatformStand then  
            humanoid.PlatformStand = false  
            local animateScript = char and char:FindFirstChild("Animate")  
            if animateScript then animateScript.Enabled = true end  
        end  
    end  

    if autoGrabGunActive and root then  
        local gunDrop = workspace:FindFirstChild("GunDrop")  
        if gunDrop then  
            local oldCFrame = root.CFrame  
            root.CFrame = gunDrop.CFrame  
            task.defer(function()  
                if root and root.Parent then  
                    root.CFrame = oldCFrame  
                end  
            end)  
        end  
    end  

    if espMurdererActive or espSheriffActive or espInnocentsActive or espUserActive then  
        espTimer = espTimer + dt  
        if espTimer >= 0.3 then  
            espTimer = 0  
            updateRoleESP()  
        end  
    end  

    if rainbowActive then  
        local hue = tick() % 5 / 5  
        local rainbowColor = Color3.fromHSV(hue, 1, 1)  
        if not outlineActive then  
            outline.Color = rainbowColor  
        end  
        fill.BackgroundColor3 = rainbowColor  
        if transFill then  
            transFill.BackgroundColor3 = rainbowColor  
        end  
        if not isSettingsOpen then  
            updateActiveTabVisuals(lastActiveTab)  
        end  
    end  

    if aimbotActive then  
        local gun = getGun()  
        if gun then  
            local murderer = findMurderer()  
            if murderer and murderer.Character then  
                local mRoot = murderer.Character:FindFirstChild("HumanoidRootPart") or murderer.Character:FindFirstChild("Head")  
                if mRoot then  
                    cam.CFrame = CFrame.new(cam.CFrame.Position, mRoot.Position)  
                    redDot.Visible = true  
                else  
                    redDot.Visible = false  
                end  
            else  
                redDot.Visible = false  
            end  
        else  
            redDot.Visible = false  
        end  
    else  
        redDot.Visible = false  
    end
end))

table.insert(connections, UIS.InputChanged:Connect(function(input)
    if activeInputObject and input ~= activeInputObject then return end

    if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then  
        if activeSliderType == "FarmSpeed" then  
            updateSlider(input.Position.X)  
        elseif activeSliderType == "Transparency" then  
            local transSlider = settingsContainer:FindFirstChild("TransSliderFrame")  
            local transFillCheck = transSlider and transSlider:FindFirstChild("TransFillCheck")  
            local width = transSlider and transSlider.AbsoluteSize.X or 0  
            if width > 0 and transFillCheck then  
                local relativeX = math.clamp(input.Position.X - transSlider.AbsolutePosition.X, 0, width)  
                local percent = relativeX / width  
                transFillCheck.Size = UDim2.new(percent, 0, 1, 0)  
                local knob = transSlider:FindFirstChild("TransKnob")  
                if knob then  
                    knob.Position = UDim2.new(percent, 0, 0.5, 0)  
                end  
                applyTransparency(percent * 0.7)  
            end  
        elseif activeSliderType == "JumpPower" then  
            updateJumpPower(input.Position.X)  
        elseif activeSliderType == "WalkSpeed" then  
            updateWalkSpeed(input.Position.X)  
        elseif draggingMain then  
            local delta = input.Position - dragStart  
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)  
        elseif draggingShoot then  
            local delta = input.Position - dragStart  
            shootFloatingBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)  
        elseif draggingKillAll then  
            local delta = input.Position - dragStart  
            killAllFloatingBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)  
        end  
    end
end))

table.insert(connections, UIS.InputEnded:Connect(function(input)
    if activeInputObject and input == activeInputObject then
        activeSliderType = nil
        activeInputObject = nil
        draggingMain = false
        draggingShoot = false
        draggingKillAll = false
    elseif not activeInputObject and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
        activeSliderType = nil
        draggingMain = false
        draggingShoot = false
        draggingKillAll = false
    end
end))

table.insert(connections, UIS.TextBoxFocused:Connect(function()
    activeSliderType = nil
    activeInputObject = nil
    draggingMain = false
    draggingShoot = false
    draggingKillAll = false
end))

table.insert(connections, tabFarming.MouseButton1Click:Connect(function()
    if isSettingsOpen then return end
    lastActiveTab = "Farming"
    farmContainer.Visible = true
    flingContainer.Visible = false
    sheriffContainer.Visible = false
    murderContainer.Visible = false
    playerContainer.Visible = false
    espContainer.Visible = false
    godlyContainer.Visible = false
    updateActiveTabVisuals("Farming")
end))

table.insert(connections, tabFling.MouseButton1Click:Connect(function()
    if isSettingsOpen then return end
    lastActiveTab = "Fling"
    farmContainer.Visible = false
    flingContainer.Visible = true
    sheriffContainer.Visible = false
    murderContainer.Visible = false
    playerContainer.Visible = false
    espContainer.Visible = false
    godlyContainer.Visible = false
    updateActiveTabVisuals("Fling")
end))

table.insert(connections, tabSheriff.MouseButton1Click:Connect(function()
    if isSettingsOpen then return end
    lastActiveTab = "Sheriff"
    farmContainer.Visible = false
    flingContainer.Visible = false
    sheriffContainer.Visible = true
    murderContainer.Visible = false
    playerContainer.Visible = false
    espContainer.Visible = false
    godlyContainer.Visible = false
    updateActiveTabVisuals("Sheriff")
end))

table.insert(connections, tabMurder.MouseButton1Click:Connect(function()
    if isSettingsOpen then return end
    lastActiveTab = "Murderer"
    farmContainer.Visible = false
    flingContainer.Visible = false
    sheriffContainer.Visible = false
    murderContainer.Visible = true
    playerContainer.Visible = false
    espContainer.Visible = false
    godlyContainer.Visible = false
    updateActiveTabVisuals("Murderer")
end))

table.insert(connections, tabPlayer.MouseButton1Click:Connect(function()
    if isSettingsOpen then return end
    lastActiveTab = "Player"
    farmContainer.Visible = false
    flingContainer.Visible = false
    sheriffContainer.Visible = false
    murderContainer.Visible = false
    playerContainer.Visible = true
    espContainer.Visible = false
    godlyContainer.Visible = false
    updateActiveTabVisuals("Player")
end))

table.insert(connections, tabESP.MouseButton1Click:Connect(function()
    if isSettingsOpen then return end
    lastActiveTab = "ESP"
    farmContainer.Visible = false
    flingContainer.Visible = false
    sheriffContainer.Visible = false
    murderContainer.Visible = false
    playerContainer.Visible = false
    espContainer.Visible = true
    godlyContainer.Visible = false
    updateActiveTabVisuals("ESP")
end))

table.insert(connections, tabGodly.MouseButton1Click:Connect(function()
    if isSettingsOpen then return end
    lastActiveTab = "Godly"
    farmContainer.Visible = false
    flingContainer.Visible = false
    sheriffContainer.Visible = false
    murderContainer.Visible = false
    playerContainer.Visible = false
    espContainer.Visible = false
    godlyContainer.Visible = true
    updateActiveTabVisuals("Godly")
end))

local stY = 0
local function createSettingLabel(text)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 20)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(230, 230, 230)
    lbl.TextSize = 12
    lbl.Font = Enum.Font.GothamBold
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.LayoutOrder = stY
    lbl.Parent = settingsContainer
    stY = stY + 1
end

createSettingLabel("Interface Transparency")
local transWrapper = Instance.new("TextButton")
transWrapper.Name = "TransSliderFrame"
transWrapper.Size = UDim2.new(1, 0, 0, 24)
transWrapper.BackgroundTransparency = 1
transWrapper.Text = ""
transWrapper.AutoButtonColor = false
transWrapper.LayoutOrder = stY
transWrapper.Parent = settingsContainer
stY = stY + 1

local transSlider = Instance.new("Frame")
transSlider.Size = UDim2.new(1, 0, 0, 7)
transSlider.AnchorPoint = Vector2.new(0, 0.5)
transSlider.Position = UDim2.new(0, 0, 0.5, 0)
transSlider.BackgroundColor3 = Color3.fromRGB(55, 55, 60)
transSlider.BorderSizePixel = 0
transSlider.Parent = transWrapper
Instance.new("UICorner", transSlider).CornerRadius = UDim.new(1, 0)

local initialTransPercent = main.BackgroundTransparency / 0.7
transFill.Size = UDim2.new(initialTransPercent, 0, 1, 0)
transFill.Parent = transSlider

local transKnob = Instance.new("Frame")
transKnob.Name = "TransKnob"
transKnob.Size = UDim2.fromOffset(15, 15)
transKnob.AnchorPoint = Vector2.new(0.5, 0.5)
transKnob.Position = UDim2.new(initialTransPercent, 0, 0.5, 0)
transKnob.BackgroundColor3 = Color3.fromRGB(245, 245, 245)
transKnob.BorderSizePixel = 0
transKnob.Parent = transSlider
Instance.new("UICorner", transKnob).CornerRadius = UDim.new(1, 0)

table.insert(connections, transWrapper.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        activeSliderType = "Transparency"
        activeInputObject = input
        local width = transSlider.AbsoluteSize.X
        if width > 0 then
            local relativeX = math.clamp(input.Position.X - transSlider.AbsolutePosition.X, 0, width)
            local percent = relativeX / width
            transFill.Size = UDim2.new(percent, 0, 1, 0)
            transKnob.Position = UDim2.new(percent, 0, 0.5, 0)
            applyTransparency(percent * 0.7)
        end
    end
end))

stY = stY + 1
createSettingLabel("Interface Color")

local dropdownMain = Instance.new("Frame")
dropdownMain.Size = UDim2.new(1, 0, 0, 32)
dropdownMain.BackgroundTransparency = 1
dropdownMain.LayoutOrder = stY
dropdownMain.Parent = settingsContainer
stY = stY + 1

local dropdownBtn = Instance.new("TextButton")
dropdownBtn.Size = UDim2.new(1, 0, 0, 32)
dropdownBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
dropdownBtn.Text = "  Theme: Red  ▼"
dropdownBtn.TextColor3 = Color3.new(1, 1, 1)
dropdownBtn.TextSize = 12
dropdownBtn.Font = Enum.Font.GothamBold
dropdownBtn.TextXAlignment = Enum.TextXAlignment.Left
dropdownBtn.Parent = dropdownMain
Instance.new("UICorner", dropdownBtn).CornerRadius = UDim.new(0, 6)

local dropdownList = Instance.new("Frame")
dropdownList.Size = UDim2.new(1, 0, 0, 210)
dropdownList.Position = UDim2.new(0, 0, 1, 4)
dropdownList.BackgroundColor3 = Color3.fromRGB(25, 25, 28)
dropdownList.Visible = false
dropdownList.ZIndex = 5
dropdownList.Parent = dropdownMain
Instance.new("UICorner", dropdownList).CornerRadius = UDim.new(0, 6)

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = dropdownList

local colors = {
    {Name = "Red", Color = Color3.fromRGB(145, 30, 45)},
    {Name = "Yellow", Color = Color3.fromRGB(200, 170, 30)},
    {Name = "Green", Color = Color3.fromRGB(30, 145, 60)},
    {Name = "Orange", Color = Color3.fromRGB(200, 100, 30)},
    {Name = "Blue", Color = Color3.fromRGB(30, 95, 145)},
    {Name = "Maroon", Color = Color3.fromRGB(100, 20, 40)},
    {Name = "Rainbow", Color = "Rainbow"}
}

local isOpen = false
table.insert(connections, dropdownBtn.MouseButton1Click:Connect(function()
    isOpen = not isOpen
    dropdownList.Visible = isOpen
    dropdownBtn.Text = isOpen and "  Theme: Select Color  ▲" or "  Theme: Selected  ▼"
end))

for _, colData in ipairs(colors) do
    local optBtn = Instance.new("TextButton")
    optBtn.Size = UDim2.new(1, 0, 0, 30)
    optBtn.BackgroundTransparency = 1
    optBtn.Text = "  " .. colData.Name
    optBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    optBtn.TextSize = 11
    optBtn.Font = Enum.Font.GothamSemibold
    optBtn.TextXAlignment = Enum.TextXAlignment.Left
    optBtn.ZIndex = 6
    optBtn.Parent = dropdownList

    table.insert(connections, optBtn.MouseButton1Click:Connect(function()
        isOpen = false
        dropdownList.Visible = false
        dropdownBtn.Text = "  Theme: " .. colData.Name .. "  ▼"

        if colData.Color == "Rainbow" then  
            rainbowActive = true  
        else  
            rainbowActive = false  
            currentThemeColor = colData.Color  
            if not outlineActive then  
                outline.Color = colData.Color  
            end  
            fill.BackgroundColor3 = colData.Color  
            transFill.BackgroundColor3 = colData.Color  
            updateActiveTabVisuals(lastActiveTab)  
        end  
    end))
end

createSettingLabel("White Outline Border")
local outlineToggle = Instance.new("TextButton")
outlineToggle.Size = UDim2.fromOffset(48, 25)
outlineToggle.BackgroundColor3 = Color3.fromRGB(55, 55, 60)
outlineToggle.Text = ""
outlineToggle.AutoButtonColor = false
outlineToggle.LayoutOrder = stY
outlineToggle.Parent = settingsContainer
Instance.new("UICorner", outlineToggle).CornerRadius = UDim.new(1, 0)

local outlineKnob = Instance.new("Frame")
outlineKnob.Size = UDim2.fromOffset(19, 19)
outlineKnob.Position = UDim2.fromOffset(3, 3)
outlineKnob.BackgroundColor3 = Color3.new(1, 1, 1)
outlineKnob.Parent = outlineToggle
Instance.new("UICorner", outlineKnob).CornerRadius = UDim.new(1, 0)

table.insert(connections, outlineToggle.MouseButton1Click:Connect(function()
    outlineActive = not outlineActive
    TweenService:Create(outlineToggle, TweenInfo.new(0.2), { BackgroundColor3 = outlineActive and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(55, 55, 60) }):Play()
    TweenService:Create(outlineKnob, TweenInfo.new(0.2), { Position = outlineActive and UDim2.fromOffset(26, 3) or UDim2.fromOffset(3, 3) }):Play()
    if outlineActive then
        outline.Color = Color3.fromRGB(255, 255, 255)
    else
        outline.Color = rainbowActive and Color3.fromHSV(tick() % 5 / 5, 1, 1) or currentThemeColor
    end
end))

table.insert(connections, killAllFloatingBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingKillAll = true
        activeInputObject = input
        dragStart = input.Position
        startPos = killAllFloatingBtn.Position
    end
end))

table.insert(connections, title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingMain = true
        activeInputObject = input
        dragStart = input.Position
        startPos = main.Position
    end
end))

table.insert(connections, shootFloatingBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingShoot = true
        activeInputObject = input
        dragStart = input.Position
        startPos = shootFloatingBtn.Position
    end
end))

table.insert(connections, closeBtn.MouseButton1Click:Connect(function()
    gui:Destroy()
end))

table.insert(connections, player.CharacterAdded:Connect(function(newChar)
    local humanoid = newChar:WaitForChild("Humanoid", 5)
    if humanoid then
        if jumpPowerActive then humanoid.JumpPower = customJumpPower end
        if walkSpeedActive then humanoid.WalkSpeed = customWalkSpeed end
    end
end))

table.insert(connections, gui.Destroying:Connect(function()
    for _, conn in ipairs(connections) do
        if conn and conn.Connected then
            conn:Disconnect()
        end
    end
    connections = {}

    enabled = false  
    espMurdererActive = false  
    espSheriffActive = false  
    espInnocentsActive = false  
    espUserActive = false  
    autoGrabGunActive = false  
    killAllButtonActive = false  
    flyActive = false  
    jumpPowerActive = false  
    walkSpeedActive = false  
    infiniteJumpActive = false  
      
    local char = player.Character  
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")  
    if humanoid then  
        humanoid.PlatformStand = false  
        humanoid.JumpPower = 50  
        humanoid.WalkSpeed = 16  
        local animateScript = char:FindFirstChild("Animate")  
        if animateScript then animateScript.Enabled = true end  
    end  

    if char then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end

    clearAllHighlights()  
    redDot.Visible = false  
    shootFloatingBtn.Visible = false  
    killAllFloatingBtn.Visible = false
end))
