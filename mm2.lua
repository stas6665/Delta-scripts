local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
Name = "MM2 Hub",
LoadingTitle = "Loading...",
LoadingSubtitle = "by User",
ConfigurationSaving = { Enabled = false },
KeySystem = false,
})

local FarmingTab = Window:CreateTab("Farming", 4483362458)
local FlingTab = Window:CreateTab("Fling", 4483362458)
local CombatTab = Window:CreateTab("Combat", 4483362458)
local SkinsTab = Window:CreateTab("Skins", 4483362458)
local VisualsTab = Window:CreateTab("Visuals", 4483362458)

local autoFarmCandy = false
local flingMurderOnFull = false
local killAllWhenFull = false
local antiFlingEnabled = false
local autoGrabGunEnabled = false
local farmSpeed = 25

local espPlayersEnabled = false
local espCoinsEnabled = false

local activeTween = nil
local activeFarmRoutine = nil
local currentFarmSession = 0
local isFlingingActive = false

local autoShootGui = nil
local autoShootButtonEnabled = false

local selectedWeaponType = "Gun"
local activeSkinName = "Default"

local skinDatabase = {
["Default"] = {MeshId = "", TextureId = ""},

["GingerScope"] = {
MeshId = "rbxassetid://15622152775",
TextureId = "rbxassetid://15622152865"
},
["Celestial"] = {
MeshId = "rbxassetid://14013441230",
TextureId = "rbxassetid://14013441315"
},
["Emberbow"] = {
MeshId = "rbxassetid://15622157077",
TextureId = "rbxassetid://15622157144"
},
["Combain"] = {
MeshId = "rbxassetid://13812499120",
TextureId = "rbxassetid://13812499245"
},
["Evergun"] = {
MeshId = "rbxassetid://15622157077",
TextureId = "rbxassetid://15622157144"
},
["Laser Gun"] = {
MeshId = "rbxassetid://460652273",
TextureId = "rbxassetid://460652303"
},
["Luger"] = {
MeshId = "rbxassetid://460652516",
TextureId = "rbxassetid://460652545"
},
["Corrupt Knife"] = {
MeshId = "rbxassetid://460651877",
TextureId = "rbxassetid://460651900"
}
}

local function createAutoShootGui()
if autoShootGui then return end

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local playerGui = player:FindFirstChild("PlayerGui")

if playerGui then
autoShootGui = Instance.new("ScreenGui")
autoShootGui.Name = "MM2AutoShootGui"
autoShootGui.ResetOnSpawn = false

local btn = Instance.new("TextButton") btn.Name = "ShootButton" btn.Size = UDim2.new(0, 220, 0, 50) btn.Position = UDim2.new(0.5, -110, 0.8, 0) btn.BackgroundColor3 = Color3.fromRGB(220, 40, 40) btn.TextColor3 = Color3.fromRGB(255, 255, 255) btn.TextSize = 18 btn.Font = Enum.Font.SourceSansBold btn.Text = "SHOOT MURDER" btn.Parent = autoShootGui local corner = Instance.new("UICorner") corner.CornerRadius = UDim.new(0, 6) corner.Parent = btn local stroke = Instance.new("UIStroke") stroke.Color = Color3.fromRGB(255, 255, 255) stroke.Thickness = 2.5 stroke.Parent = btn local dragging, dragInput, dragStart, startPos btn.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true dragStart = input.Position startPos = btn.Position input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end) end end) btn.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end end) UserInputService.InputChanged:Connect(function(input) if input == dragInput and dragging then local delta = input.Position - dragStart btn.Position = UDim2.new( startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y ) end end) btn.MouseButton1Click:Connect(function() local success, err = pcall(function() local char = player.Character local backpack = player:FindFirstChild("Backpack") local gun = (backpack and backpack:FindFirstChild("Gun")) or (char and char:FindFirstChild("Gun")) if not gun then return end if gun.Parent == backpack then gun.Parent = char end local targetChar = nil for _, p in ipairs(Players:GetPlayers()) do if p ~= player and p.Character then local pBackpack = p:FindFirstChild("Backpack") local pChar = p.Character local isKnife = (pBackpack and pBackpack:FindFirstChild("Knife")) or pChar:FindFirstChild("Knife") if isKnife and pChar:FindFirstChild("HumanoidRootPart") then targetChar = pChar break end end end if targetChar and targetChar:FindFirstChild("HumanoidRootPart") then local targetRoot = targetChar.HumanoidRootPart gun:Activate() task.wait(0.05) local args = { [1] = 1, [2] = targetRoot.Position, [3] = "AH" } gun:FindFirstChild("RemoteEvent"):FireServer(unpack(args)) end end) if not success then warn("AutoShoot Error:", err) end end) autoShootGui.Parent = playerGui 

end
end

local function removeAutoShootGui()
if autoShootGui then
autoShootGui:Destroy()
autoShootGui = nil
end
end

local function executeFlingOnTarget(targetType)
task.spawn(function()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local character = player.Character

if not character or not character:FindFirstChild("HumanoidRootPart") then return end local root = character.HumanoidRootPart local originalCFrame = root.CFrame local targetRoot = nil local targetChar = nil for _, p in ipairs(Players:GetPlayers()) do if p ~= player and p.Character then local backpack = p:FindFirstChild("Backpack") local char = p.Character local isKnife = (backpack and backpack:FindFirstChild("Knife")) or char:FindFirstChild("Knife") local isGun = (backpack and backpack:FindFirstChild("Gun")) or char:FindFirstChild("Gun") if targetType == "Murder" and isKnife then if char:FindFirstChild("HumanoidRootPart") then targetChar = char targetRoot = char.HumanoidRootPart break end elseif targetType == "Sheriff" and isGun then if char:FindFirstChild("HumanoidRootPart") then targetChar = char targetRoot = char.HumanoidRootPart break end end end end if targetRoot and targetChar then isFlingingActive = true local startTime = tick() for _, part in ipairs(character:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide = false end end local connection connection = RunService.RenderStepped:Connect(function() if not character or not character:FindFirstChild("HumanoidRootPart") or not targetRoot or not targetRoot.Parent then if connection then connection:Disconnect() end isFlingingActive = false return end for _, part in ipairs(targetChar:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide = true end end local randomOffset = CFrame.new(math.random(-4, 4), math.random(-2, 2), math.random(-4, 4)) root.CFrame = targetRoot.CFrame * randomOffset root.AssemblyLinearVelocity = Vector3.new(500000, 500000, 500000) root.AssemblyAngularVelocity = Vector3.new(99999, 99999, 99999) targetRoot.AssemblyLinearVelocity = Vector3.new(math.random(-50000, 50000), -500000, math.random(-50000, 50000)) if tick() - startTime > 2 then if connection then connection:Disconnect() end root.AssemblyLinearVelocity = Vector3.new(0, 0, 0) root.AssemblyAngularVelocity = Vector3.new(0, 0, 0) root.CFrame = originalCFrame isFlingingActive = false end end) end 

end)
end

local function applySkinToTool(tool)
if not tool then return end

local handle = tool:FindFirstChild("Handle") or tool:FindFirstChildOfClass("BasePart")
if not handle then return end

local skinData = skinDatabase[activeSkinName]
if not skinData then return end

local mesh = handle:FindFirstChildOfClass("SpecialMesh")
if not mesh then
mesh = Instance.new("SpecialMesh")
mesh.Parent = handle
end

if skinData.MeshId ~= "" then
mesh.MeshId = skinData.MeshId
end
if skinData.TextureId ~= "" then
mesh.TextureId = skinData.TextureId
end

local oldHighlight = handle:FindFirstChild("SkinGlow")
if oldHighlight then oldHighlight:Destroy() end

if activeSkinName == "GingerScope" and tool:IsA("Tool") then
local glow = Instance.new("SelectionBox")
glow.Name = "SkinGlow"
glow.Color3 = Color3.fromRGB(255, 140, 0)
glow.LineThickness = 0.03
glow.Adornee = handle
glow.Parent = handle

tool.Activated:Connect(function() pcall(function() local originalSound = handle:FindFirstChild("FireSound") or handle:FindFirstChildOfClass("Sound") if originalSound then originalSound:Play() end end) end) 

end
end

FarmingTab:CreateToggle({
Name = "Auto Farm Candy",
CurrentValue = false,
Flag = "AutoFarmCandyToggle",
Callback = function(Value)
autoFarmCandy = Value
currentFarmSession = currentFarmSession + 1
local mySessionId = currentFarmSession

if autoFarmCandy then activeFarmRoutine = task.spawn(function() local Players = game:GetService("Players") local Workspace = game:GetService("Workspace") local player = Players.LocalPlayer while autoFarmCandy and (currentFarmSession == mySessionId) do local success, err = pcall(function() local reachedLimit = false local playerGui = player:FindFirstChild("PlayerGui") local mainGui = playerGui and playerGui:FindFirstChild("MainGUI") local gameFrame = mainGui and mainGui:FindFirstChild("Game") local coinBags = gameFrame and gameFrame:FindFirstChild("CoinBags") if coinBags then local bagCandy = coinBags:FindFirstChild("Candy") local bagCoin = coinBags:FindFirstChild("Coin") if bagCandy and bagCandy:FindFirstChild("FullBagIcon") and bagCandy.FullBagIcon:IsA("GuiObject") and bagCandy.FullBagIcon.Visible then reachedLimit = true elseif bagCoin then local emptyIcon = bagCoin:FindFirstChild("EmptyBagIcon") if emptyIcon and emptyIcon:FindFirstChild("FullBagIcon") and emptyIcon.FullBagIcon.Visible then reachedLimit = true elseif bagCoin:FindFirstChild("FullBagIcon") and bagCoin.FullBagIcon:IsA("GuiObject") and bagCoin.FullBagIcon.Visible then reachedLimit = true end end end if reachedLimit then autoFarmCandy = false currentFarmSession = currentFarmSession + 1 local character = player.Character local backpack = player:FindFirstChild("Backpack") local isLocalMurderer = (backpack and backpack:FindFirstChild("Knife")) or (character and character:FindFirstChild("Knife")) if killAllWhenFull and isLocalMurderer then local root = character and character:FindFirstChild("HumanoidRootPart") if root then local originalCFrame = root.CFrame local knife = (backpack and backpack:FindFirstChild("Knife")) or (character and character:FindFirstChild("Knife")) if knife then knife.Parent = character end for _, p in ipairs(Players:GetPlayers()) do if p ~= player and p.Character then local targetChar = p.Character local targetRoot = targetChar:FindFirstChild("HumanoidRootPart") local targetHum = targetChar:FindFirstChild("Humanoid") if targetRoot and targetHum and targetHum.Health > 0 then root.CFrame = targetRoot.CFrame task.wait(0.03) if knife then pcall(function() knife:Activate() end) end end end end task.wait(0.1) root.CFrame = originalCFrame end elseif flingMurderOnFull then executeFlingOnTarget("Murder") end return end if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then local character = player.Character local root = character.HumanoidRootPart local availableCoins = {} local map = Workspace:FindFirstChild("Map") if map then local container = map:FindFirstChild("CoinContainer") if container then for _, cm in ipairs(container:GetChildren()) do if cm.Name == "Coin_Server" then local visual = cm:FindFirstChild("CoinVisual") if visual and visual:IsA("BasePart") then table.insert(availableCoins, visual) end end end end end table.sort(availableCoins, function(a, b) return (root.Position - a.Position).Magnitude < (root.Position - b.Position).Magnitude end) if #availableCoins > 0 then for _, targetCoin in ipairs(availableCoins) do if not autoFarmCandy or (currentFarmSession ~= mySessionId) then break end if targetCoin and targetCoin.Parent and targetCoin.Parent.Parent then local currentRotation = root.CFrame - root.CFrame.Position local targetPos = targetCoin.Position root.Anchored = true local distance = (root.Position - targetPos).Magnitude local selectedSpeed = math.clamp(farmSpeed, 1, 33) local travelTime = distance / selectedSpeed local startTime = tick() local startPos = root.Position while autoFarmCandy and (currentFarmSession == mySessionId) do local elapsed = tick() - startTime local alpha = math.clamp(elapsed / travelTime, 0, 1) if not targetCoin or not targetCoin.Parent or not targetCoin.Parent.Parent then break end local currentPos = startPos + (targetPos - startPos) * alpha root.CFrame = currentRotation + currentPos if map then local container = map:FindFirstChild("CoinContainer") if container then for _, cm in ipairs(container:GetChildren()) do if cm.Name == "Coin_Server" and autoFarmCandy and (currentFarmSession == mySessionId) then local visual = cm:FindFirstChild("CoinVisual") if visual and visual:IsA("BasePart") and visual.Parent and visual.Parent.Parent then if (root.Position - visual.Position).Magnitude <= 5 then root.CFrame = currentRotation + visual.Position task.wait(0.2) end end end end end end if alpha >= 1 then break end task.wait(0.01) end if autoFarmCandy and (currentFarmSession == mySessionId) then root.CFrame = currentRotation + targetPos task.wait(0.2) end end end else task.wait(0.2) end end end) if not success then warn("AutoFarm Error:", err) end task.wait(0.01) end pcall(function() if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then player.Character.HumanoidRootPart.Anchored = false end end) if currentFarmSession == mySessionId then activeFarmRoutine = nil end end) end 

end,
})

FarmingTab:CreateSlider({
Name = "Farm Speed (Studs/s)",
Range = {1, 33},
Increment = 1,
Suffix = "s/s",
CurrentValue = 25,
Flag = "FarmSpeedSlider",
Callback = function(Value)
farmSpeed = Value
end,
})

FarmingTab:CreateToggle({
Name = "Anti-Fling Protection",
CurrentValue = false,
Flag = "AntiFlingToggle",
Callback = function(Value)
antiFlingEnabled = Value
if not antiFlingEnabled then
pcall(function()
local Players = game:GetService("Players")
local player = Players.LocalPlayer
for _, p in ipairs(Players:GetPlayers()) do
if p ~= player and p.Character then
for _, part in ipairs(p.Character:GetDescendants()) do
if part:IsA("BasePart") then
part.CanCollide = true
end
end
end
end
end)
end
end,
})

FarmingTab:CreateToggle({
Name = "Auto Grab Gun",
CurrentValue = false,
Flag = "AutoGrabGunToggle",
Callback = function(Value)
autoGrabGunEnabled = Value
if autoGrabGunEnabled then
task.spawn(function()
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

while autoGrabGunEnabled do pcall(function() local gunDrop = Workspace:FindFirstChild("GunDrop") if gunDrop and player.Character then local backpack = player:FindFirstChild("Backpack") local hasGun = (backpack and backpack:FindFirstChild("Gun")) or player.Character:FindFirstChild("Gun") if not hasGun then local handle = gunDrop:FindFirstChild("Handle") or gunDrop:FindFirstChild("Part") or gunDrop if handle and handle:IsA("BasePart") then local character = player.Character local hrp = character:FindFirstChild("HumanoidRootPart") local originalCFrame = hrp and hrp.CFrame if hrp then hrp.CFrame = handle.CFrame task.wait(0.2) if originalCFrame then hrp.CFrame = originalCFrame end end end end end end) task.wait(0.4) end end) end 

end,
})

FarmingTab:CreateToggle({
Name = "Fling Murder When Full",
CurrentValue = false,
Flag = "FlingMurderWhenFullToggle",
Callback = function(Value)
flingMurderOnFull = Value
end,
})

FarmingTab:CreateToggle({
Name = "Kill All When Full (If Murder)",
CurrentValue = false,
Flag = "KillAllWhenFullToggle",
Callback = function(Value)
killAllWhenFull = Value
end,
})

CombatTab:CreateToggle({
Name = "Auto Shoot Button",
CurrentValue = false,
Flag = "AutoShootButtonToggle",
Callback = function(Value)
autoShootButtonEnabled = Value
if autoShootButtonEnabled then
createAutoShootGui()
else
removeAutoShootGui()
end
end,
})

FlingTab:CreateButton({
Name = "Fling Murder",
Callback = function()
executeFlingOnTarget("Murder")
end,
})

FlingTab:CreateButton({
Name = "Fling Sheriff / Hero",
Callback = function()
executeFlingOnTarget("Sheriff")
end,
})

SkinsTab:CreateDropdown({
Name = "Select Weapon Slot",
Options = {"Knife", "Gun"},
CurrentOption = "Gun",
Flag = "SkinSlotDropdown",
Callback = function(Option)
selectedWeaponType = Option
end,
})

SkinsTab:CreateDropdown({
Name = "Select Skin",
Options = {"Default", "GingerScope", "Celestial", "Emberbow", "Combain", "Evergun", "Laser Gun", "Luger", "Corrupt Knife"},
CurrentOption = "Default",
Flag = "SkinNameDropdown",
Callback = function(Option)
activeSkinName = Option
end,
})

SkinsTab:CreateButton({
Name = "Apply & Equip Skin",
Callback = function()
pcall(function()
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local character = player.Character
local backpack = player:FindFirstChild("Backpack")

local targetTool = (character and character:FindFirstChild(selectedWeaponType)) or (backpack and backpack:FindFirstChild(selectedWeaponType)) if targetTool then applySkinToTool(targetTool) end end) 

end,
})

task.spawn(function()
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local function scanAndApply()
pcall(function()
local character = player.Character
local backpack = player:FindFirstChild("Backpack")

if character then for _, item in ipairs(character:GetChildren()) do if (item:IsA("Tool") or item:IsA("Model")) and (item.Name == selectedWeaponType or item.Name:find(selectedWeaponType)) then applySkinToTool(item) end end end if backpack then for _, item in ipairs(backpack:GetChildren()) do if item:IsA("Tool") and item.Name == selectedWeaponType then applySkinToTool(item) end end end end) 

end

task.spawn(function()
while true do
scanAndApply()
task.wait(0.5)
end
end)

local function setupCharacter(char)
if not char then return end
char.ChildAdded:Connect(function(child)
task.wait(0.05)
scanAndApply()
end)

local backpack = player:FindFirstChild("Backpack") if backpack then backpack.ChildAdded:Connect(function(child) task.wait(0.05) scanAndApply() end) end 

end

if player.Character then setupCharacter(player.Character) end
player.CharacterAdded:Connect(setupCharacter)
end)

task.spawn(function()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

RunService.Stepped:Connect(function()
if not antiFlingEnabled or isFlingingActive then return end

pcall(function() local character = player.Character if character then local root = character:FindFirstChild("HumanoidRootPart") if root then if root.AssemblyLinearVelocity.Magnitude > 75 then root.AssemblyLinearVelocity = Vector3.new(0, 0, 0) root.AssemblyAngularVelocity = Vector3.new(0, 0, 0) end for _, p in ipairs(Players:GetPlayers()) do if p ~= player and p.Character then for _, part in ipairs(p.Character:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide = false end end end end end end end) 

end)
end)

VisualsTab:CreateToggle({
Name = "Player ESP (Role Colors)",
CurrentValue = false,
Flag = "PlayerESPToggle",
Callback = function(Value)
espPlayersEnabled = Value
if espPlayersEnabled then
task.spawn(function()
local Players = game:GetService("Players")
local player = Players.LocalPlayer

while espPlayersEnabled do pcall(function() for _, p in ipairs(Players:GetPlayers()) do if p ~= player and p.Character then local char = p.Character local highlight = char:FindFirstChild("ESPHighlight") if not highlight then highlight = Instance.new("Highlight") highlight.Name = "ESPHighlight" highlight.FillTransparency = 0.5 highlight.OutlineTransparency = 0 highlight.OutlineColor = Color3.fromRGB(255, 255, 255) highlight.Parent = char end local backpack = p:FindFirstChild("Backpack") local isMurderer = (backpack and backpack:FindFirstChild("Knife")) or char:FindFirstChild("Knife") local hasGun = (backpack and backpack:FindFirstChild("Gun")) or char:FindFirstChild("Gun") if isMurderer then highlight.FillColor = Color3.fromRGB(255, 0, 0) elseif hasGun then highlight.FillColor = Color3.fromRGB(0, 100, 255) else highlight.FillColor = Color3.fromRGB(0, 255, 0) end end end end) task.wait(0.5) end for _, p in ipairs(Players:GetPlayers()) do if p.Character and p.Character:FindFirstChild("ESPHighlight") then p.Character.ESPHighlight:Destroy() end end end) end 

end,
})

VisualsTab:CreateToggle({
Name = "Coins / Candy ESP",
CurrentValue = false,
Flag = "CoinsESPToggle",
Callback = function(Value)
espCoinsEnabled = Value
if espCoinsEnabled then
task.spawn(function()
local Workspace = game:GetService("Workspace")

while espCoinsEnabled do pcall(function() local map = Workspace:FindFirstChild("Map") if map then local container = map:FindFirstChild("CoinContainer") if container then for _, coinModel in ipairs(container:GetChildren()) do if coinModel.Name == "Coin_Server" then local coinVisual = coinModel:FindFirstChild("CoinVisual") if coinVisual and coinVisual:IsA("BasePart") then if not coinVisual:FindFirstChild("CoinHighlight") then local highlight = Instance.new("Highlight") highlight.Name = "CoinHighlight" highlight.FillColor = Color3.fromRGB(255, 215, 0) highlight.OutlineColor = Color3.fromRGB(255, 255, 255) highlight.FillTransparency = 0.4 highlight.Parent = coinVisual end end end end end end end) task.wait(1) end local map = Workspace:FindFirstChild("Map") if map then local container = map:FindFirstChild("CoinContainer") if container then for _, coinModel in ipairs(container:GetChildren()) do local coinVisual = coinModel:FindFirstChild("CoinVisual") if coinVisual and coinVisual:FindFirstChild("CoinHighlight") then coinVisual.CoinHighlight:Destroy() end end end end end) end 

end,
})

