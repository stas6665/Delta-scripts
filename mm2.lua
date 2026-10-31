local Fluent = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/main.lua"))()

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

_G.CollectedCoins = _G.CollectedCoins or {}
_G.DetectedMurdererName = nil

_G.AutoFarmCoins = false
_G.FarmUnderground = false
_G.FlingMurderer = false
_G.AvoidMurderer = false
_G.FarmSpeed = 25
_G.SafeDistance = 45

_G.CoinsESP = false
_G.MurderESP = false
_G.SheriffESP = false

local noclipConnection = nil
local function findCoinContainer()
for _, child in ipairs(Workspace:GetChildren()) do
if child:FindFirstChild("CoinContainer") then
return child.CoinContainer
end
end
return nil
end

local function checkRoundActive()
local container = findCoinContainer()
if container then
local coin = container:FindFirstChild("CoinVisual", true)
if coin then
return true
end
end
if ReplicatedStorage:FindFirstChild("MatchToLog") then
return true
end
return false
end

local function isBagFull()
local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
if playerGui then
local mainGui = playerGui:FindFirstChild("MainGUI")
if mainGui then
local gameFolder = mainGui:FindFirstChild("Game")
local coinBags = gameFolder and gameFolder:FindFirstChild("CoinBags")
local coin = coinBags and coinBags:FindFirstChild("Coin")
local fullBagIcon = coin and coin:FindFirstChild("FullBagIcon")
if fullBagIcon and fullBagIcon.Visible == true then
return true
end
end
end
return false
end

local function toggleNoClip(enable)
if enable then
if not noclipConnection then
noclipConnection = RunService.Stepped:Connect(function()
if LocalPlayer.Character then
for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
if part:IsA("BasePart") and part.CanCollide then
part.CanCollide = false
end
end
end
end)
end
else
if noclipConnection then
noclipConnection:Disconnect()
noclipConnection = nil
end
end
end

local function toggleAnimations(enable)
local character = LocalPlayer.Character
local humanoid = character and character:FindFirstChildOfClass("Humanoid")
if humanoid then
local animator = humanoid:FindFirstChildOfClass("Animator")
if animator then
for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
track:AdjustSpeed(enable and 1 or 0)
end
end
end
end
local function getMurderer()
if _G.DetectedMurdererName then
local p = Players:FindFirstChild(_G.DetectedMurdererName)
if p and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then return p end
end
local logFolder = ReplicatedStorage:FindFirstChild("MatchToLog") or ReplicatedStorage:FindFirstChild("PreRoundLog")
if logFolder then
local mData = logFolder:FindFirstChild("Murder") or logFolder:FindFirstChild("Murderer")
if mData and mData:IsA("StringValue") and mData.Value ~= "" then
local p = Players:FindFirstChild(mData.Value)
if p and p.Character then _G.DetectedMurdererName = p.Name return p end
end
end
for _, p in ipairs(Players:GetPlayers()) do
if p.Character and (p.Character:FindFirstChild("Knife") or (p:FindFirstChild("Backpack") and p.Backpack:FindFirstChild("Knife"))) then
_G.DetectedMurdererName = p.Name
return p
end
end
return nil
end

local function getSheriff()
for _, p in ipairs(Players:GetPlayers()) do
if p.Character and (p.Character:FindFirstChild("Gun") or (p:FindFirstChild("Backpack") and p.Backpack:FindFirstChild("Gun"))) then
return p
end
end
return nil
end

_G.FindCoinContainer = findCoinContainer
_G.IsBagFull = isBagFull
_G.ToggleNoClip = toggleNoClip
_G.ToggleAnimations = toggleAnimations
_G.GetMurderer = getMurderer
_G.GetSheriff = getSheriff

local function getClosestCoin()
local coinContainer = _G.FindCoinContainer()
if not coinContainer then return nil end
local character = LocalPlayer.Character
local myRoot = character and character:FindFirstChild("HumanoidRootPart")
if not myRoot then return nil end

local murderer = _G.GetMurderer() local mudRoot = murderer and murderer.Character and murderer.Character:FindFirstChild("HumanoidRootPart") local closestTarget = nil local shortestDistance = math.huge for _, obj in ipairs(coinContainer:GetDescendants()) do if obj:IsA("BasePart") and obj.Name == "CoinVisual" then local targetCFrame = obj.CFrame if _G.AvoidMurderer and mudRoot then local distanceToMurderer = (targetCFrame.Position - mudRoot.Position).Magnitude if distanceToMurderer < _G.SafeDistance then continue end end local distance = (myRoot.Position - targetCFrame.Position).Magnitude if distance < shortestDistance then shortestDistance = distance closestTarget = obj end end end return closestTarget 

end

Workspace.DescendantRemoving:Connect(function(descendant)
local container = _G.FindCoinContainer()
if container and descendant == container then
_G.DetectedMurdererName = nil
end
end)
local function applyHighlight(object, name, color, enabled)
if not object then return end
local existing = object:FindFirstChild(name)
if enabled then
if not existing then
local hl = Instance.new("Highlight")
hl.Name = name
hl.FillColor = color
hl.OutlineColor = Color3.fromRGB(255, 255, 255)
hl.FillTransparency = 0.25
hl.OutlineTransparency = 0
hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
hl.Enabled = true
hl.Parent = object
else
existing.Enabled = true
existing.FillColor = color
end
else
if existing then existing:Destroy() end
end
end

local function clearGlobalESP(espName)
for _, descendant in ipairs(Workspace:GetDescendants()) do
if descendant:IsA("Highlight") and descendant.Name == espName then
descendant:Destroy()
end
end
end

task.spawn(function()
while true do
task.wait(0.3)
local container = _G.FindCoinContainer()
if _G.CoinsESP then
if container then
for _, obj in ipairs(container:GetDescendants()) do
if obj.Name == "CoinVisual" and obj:IsA("BasePart") then
applyHighlight(obj, "CoinESP", Color3.fromRGB(255, 110, 0), true)
end
end
end
else
clearGlobalESP("CoinESP")
end

local mud = _G.GetMurderer() if _G.MurderESP and mud and mud.Character then applyHighlight(mud.Character, "MurderESP", Color3.fromRGB(255, 0, 0), true) else clearGlobalESP("MurderESP") end local shr = _G.GetSheriff() if _G.SheriffESP and shr and shr.Character then applyHighlight(shr.Character, "SheriffESP", Color3.fromRGB(0, 120, 255), true) else clearGlobalESP("SheriffESP") end end 

end)
local function flingTarget(targetPlayer)
local character = LocalPlayer.Character
local targetChar = targetPlayer.Character
local myRoot = character and character:FindFirstChild("HumanoidRootPart")
local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
if myRoot and targetRoot and targetRoot.Parent then
local oldCFrame = myRoot.CFrame
_G.ToggleNoClip(false)
local bavg = Instance.new("BodyAngularVelocity")
bavg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
bavg.AngularVelocity = Vector3.new(0, 95000, 0)
bavg.Parent = myRoot
myRoot.CFrame = targetRoot.CFrame
task.wait(0.15)
bavg:Destroy()
myRoot.Velocity = Vector3.new(0, 0, 0)
myRoot.RotVelocity = Vector3.new(0, 0, 0)
myRoot.CFrame = oldCFrame
_G.ToggleNoClip(_G.AutoFarmCoins)
end
end

local function escapeFromMurderer(myRoot, mudRoot)
if not mudRoot or not myRoot then return end
local vector = (myRoot.Position - mudRoot.Position)
local direction = vector.Magnitude > 0 and vector.Unit or Vector3.new(0, 1, 0)
local escapePosition = myRoot.Position + (direction * 35)
myRoot.CFrame = CFrame.new(escapePosition)
task.wait(0.1)
end

task.spawn(function()
while true do
task.wait(0.05)
local character = LocalPlayer.Character
local myRoot = character and character:FindFirstChild("HumanoidRootPart")
local hum = character and character:FindFirstChildOfClass("Humanoid")

local inRound = checkRoundActive() if _G.AutoFarmCoins and inRound and hum and hum.Health > 0 and myRoot then local murderer = _G.GetMurderer() local mudRoot = murderer and murderer.Character and murderer.Character:FindFirstChild("HumanoidRootPart") if _G.AvoidMurderer and mudRoot then local currentDistance = (myRoot.Position - mudRoot.Position).Magnitude if currentDistance < _G.SafeDistance then escapeFromMurderer(myRoot, mudRoot) end end if _G.IsBagFull() and _G.FlingMurderer then _G.ToggleAnimations(true) local m = _G.GetMurderer() if m then flingTarget(m) task.wait(1) else _G.ToggleNoClip(false) end elseif not _G.IsBagFull() then _G.ToggleNoClip(true) _G.ToggleAnimations(not _G.FarmUnderground) local touchPart = getClosestCoin() if touchPart and touchPart.Parent then local targetCFrame = touchPart.CFrame if _G.FarmUnderground then targetCFrame = CFrame.new(targetCFrame.Position) * CFrame.new(0, -4.5, 0) end local distance = (myRoot.Position - targetCFrame.Position).Magnitude local duration = distance / _G.FarmSpeed local tween = TweenService:Create(myRoot, TweenInfo.new(duration, Enum.EasingStyle.Linear), {CFrame = targetCFrame}) tween:Play() local tweenStruct = false local connection connection = tween.Completed:Connect(function() tweenStruct = true connection:Disconnect() end) local elapsed = 0 while not tweenStruct and touchPart.Parent and elapsed < duration + 0.5 do task.wait(0.05) elapsed = elapsed + 0.05 local liveMurderer = _G.GetMurderer() local liveMudRoot = liveMurderer and liveMurderer.Character and liveMurderer.Character:FindFirstChild("HumanoidRootPart") if _G.AvoidMurderer and liveMudRoot then local distToMud = (myRoot.Position - liveMudRoot.Position).Magnitude if distToMud < _G.SafeDistance then tween:Cancel() escapeFromMurderer(myRoot, liveMudRoot) break end end end local collectTimeout = 0 while touchPart.Parent and collectTimeout < 0.3 and _G.AutoFarmCoins do task.wait(0.05) collectTimeout = collectTimeout + 0.05 end task.wait(0.02) end else _G.ToggleAnimations(true) _G.ToggleNoClip(false) end else _G.ToggleAnimations(true) _G.ToggleNoClip(false) end end 

end)

local Window = Fluent:CreateWindow({
Title = "MM2 Premium Hack",
SubTitle = "v3.0 Ultra Fixed",
TabWidth = 160,
Size = UDim2.fromOffset(580, 460),
Acrylic = false,
Theme = "Dark",
MinimizeKey = Enum.KeyCode.LeftControl
})

local FarmingTab = Window:AddTab({ Title = "Farming", Icon = "coins" })
local VisualsTab = Window:AddTab({ Title = "Visuals", Icon = "eye" })

FarmingTab:AddToggle("AutoFarmToggle", { Title = "Auto Farm Coins", Default = false, Callback = function(Value) _G.AutoFarmCoins = Value end })
FarmingTab:AddToggle("AvoidMurdererToggle", { Title = "Avoid the Murderer", Default = false, Callback = function(Value) _G.AvoidMurderer = Value end })
FarmingTab:AddToggle("FarmUndergroundToggle", { Title = "Farm Underground (Safe)", Default = false, Callback = function(Value) _G.FarmUnderground = Value end })
FarmingTab:AddToggle("FlingMurdererToggle", { Title = "Fling Murderer when Full", Default = false, Callback = function(Value) _G.FlingMurderer = Value end })

FarmingTab:AddButton({ Title = "Farm Speed -", Callback = function() _G.FarmSpeed = math.max(15, _G.FarmSpeed - 2) Fluent:Notify({ Title = "Speed", Content = tostring(_G.FarmSpeed), Duration = 1 }) end })
FarmingTab:AddButton({ Title = "Farm Speed +", Callback = function() _G.FarmSpeed = math.min(45, _G.FarmSpeed + 2) Fluent:Notify({ Title = "Speed", Content = tostring(_G.FarmSpeed), Duration = 1 }) end })

FarmingTab:AddButton({ Title = "Safe Distance -", Callback = function() _G.SafeDistance = math.max(15, _G.SafeDistance - 5) Fluent:Notify({ Title = "Safe Distance", Content = tostring(_G.SafeDistance) .. " studs", Duration = 1 }) end })
FarmingTab:AddButton({ Title = "Safe Distance +", Callback = function() _G.SafeDistance = math.min(100, _G.SafeDistance + 5) Fluent:Notify({ Title = "Safe Distance", Content = tostring(_G.SafeDistance) .. " studs", Duration = 1 }) end })

VisualsTab:AddToggle("CoinsESPToggle", { Title = "ESP Coins (Orange)", Default = false, Callback = function(Value) _G.CoinsESP = Value end })
VisualsTab:AddToggle("MurderESPToggle", { Title = "ESP Murderer (Red)", Default = false, Callback = function(Value) _G.MurderESP = Value end })
VisualsTab:AddToggle("SheriffESPToggle", { Title = "ESP Sheriff (Blue)", Default = false, Callback = function(Value) _G.SheriffESP = Value end })

Window:SelectTab(1)
Fluent:Notify({ Title = "MM2 Script", Content = "Loaded successfully! Optimized for CoinVisual.", Duration = 5 })

