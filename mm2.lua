local Fluent = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/main.lua"))()

_G.Fluent = Fluent
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

_G.Window = _G.Fluent:CreateWindow({
Title = "MM2 Premium Hack",
SubTitle = "v3.3 Split Edition",
TabWidth = 160,
Size = UDim2.fromOffset(580, 460),
Acrylic = false,
Theme = "Dark",
MinimizeKey = Enum.KeyCode.LeftControl
})

_G.FarmingTab = _G.Window:AddTab({ Title = "Farming", Icon = "coins" })
_G.VisualsTab = _G.Window:AddTab({ Title = "Visuals", Icon = "eye" })
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

_G.FindCoinContainer = function()
for _, child in ipairs(Workspace:GetChildren()) do
if child:FindFirstChild("CoinContainer") then
return child.CoinContainer
end
end
return nil
end

_G.CheckRoundActive = function()
local container = _G.FindCoinContainer()
if container then
local coin = container:FindFirstChild("CoinVisual", true)
if coin then return true end
end
if ReplicatedStorage:FindFirstChild("MatchToLog") then return true end
return false
end

_G.IsBagFull = function()
local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
local mainGui = playerGui and playerGui:FindFirstChild("MainGUI")
local gameFolder = mainGui and mainGui:FindFirstChild("Game")
local coinBags = gameFolder and gameFolder:FindFirstChild("CoinBags")

if coinBags then local targetBags = {} for _, child in ipairs(coinBags:GetChildren()) do if child:IsA("Frame") then table.insert(targetBags, child) end end local container = coinBags:FindFirstChild("Container") if container then for _, child in ipairs(container:GetChildren()) do if child:IsA("Frame") then table.insert(targetBags, child) end end end for _, bag in ipairs(targetBags) do if bag.Visible == true then local fullIcon = bag:FindFirstChild("FullBagIcon") if fullIcon and fullIcon.Visible == true then return true end end end end return false 

end

_G.GetMurderer = function()
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

_G.GetSheriff = function()
for _, p in ipairs(Players:GetPlayers()) do
if p.Character and (p.Character:FindFirstChild("Gun") or (p:FindFirstChild("Backpack") and p.Backpack:FindFirstChild("Gun"))) then return p end
end
return nil
end

Workspace.DescendantRemoving:Connect(function(descendant)
local container = _G.FindCoinContainer()
if container and descendant == container then _G.DetectedMurdererName = nil end
end)
local Workspace = game:GetService("Workspace")

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
if descendant:IsA("Highlight") and descendant.Name == espName then descendant:Destroy() end
end
end

task.spawn(function()
while true do
task.wait(0.3)
if not _G.FindCoinContainer then continue end

local container = _G.FindCoinContainer() if _G.CoinsESP and container then for _, obj in ipairs(container:GetDescendants()) do if obj.Name == "CoinVisual" and obj:IsA("BasePart") then applyHighlight(obj, "CoinESP", Color3.fromRGB(255, 110, 0), true) end end else clearGlobalESP("CoinESP") end local mud = _G.GetMurderer and _G.GetMurderer() if _G.MurderESP and mud and mud.Character then applyHighlight(mud.Character, "MurderESP", Color3.fromRGB(255, 0, 0), true) else clearGlobalESP("MurderESP") end local shr = _G.GetSheriff and _G.GetSheriff() if _G.SheriffESP and shr and shr.Character then applyHighlight(shr.Character, "SheriffESP", Color3.fromRGB(0, 120, 255), true) else clearGlobalESP("SheriffESP") end end 

end)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local noclipConnection = nil
_G.ToggleNoClip = function(enable)
if enable then
if not noclipConnection then
noclipConnection = RunService.Stepped:Connect(function()
if LocalPlayer.Character then
for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end
end
end
end)
end
else
if noclipConnection then noclipConnection:Disconnect() noclipConnection = nil end
end
end

local function toggleAnimations(enable)
local character = LocalPlayer.Character
local humanoid = character and character:FindFirstChildOfClass("Humanoid")
local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
if animator then
for _, track in ipairs(animator:GetPlayingAnimationTracks()) do track:AdjustSpeed(enable and 1 or 0) end
end
end

local function getClosestCoin()
if not _G.FindCoinContainer or not _G.GetMurderer then return nil end
local coinContainer = _G.FindCoinContainer()
if not coinContainer then return nil end
local character = LocalPlayer.Character
local myRoot = character and character:FindFirstChild("HumanoidRootPart")
if not myRoot then return nil end

local murderer = _G.GetMurderer() local mudRoot = murderer and murderer.Character and murderer.Character:FindFirstChild("HumanoidRootPart") local closestTarget, shortestDistance = nil, math.huge for _, obj in ipairs(coinContainer:GetDescendants()) do if obj:IsA("BasePart") and obj.Name == "CoinVisual" then local targetCFrame = obj.CFrame if _G.AvoidMurderer and mudRoot then if (targetCFrame.Position - mudRoot.Position).Magnitude < _G.SafeDistance then continue end end local distance = (myRoot.Position - targetCFrame.Position).Magnitude if distance < shortestDistance then shortestDistance = distance; closestTarget = obj end end end return closestTarget 

end

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
myRoot.Velocity, myRoot.RotVelocity = Vector3.new(0,0,0), Vector3.new(0,0,0)
myRoot.CFrame = oldCFrame
_G.ToggleNoClip(_G.AutoFarmCoins)
end
end

local function escapeFromMurderer(myRoot, mudRoot)
if not mudRoot or not myRoot then return end
local vector = (myRoot.Position - mudRoot.Position)
local direction = vector.Magnitude > 0 and vector.Unit or Vector3.new(0, 1, 0)
myRoot.CFrame = CFrame.new(myRoot.Position + (direction * 35).X, mudRoot.Position.Y, myRoot.Position + (direction * 35).Z)
task.wait(0.1)
end
task.spawn(function()
while true do
task.wait(0.01)
if not _G.CheckRoundActive or not _G.IsBagFull then continue end

local character = LocalPlayer.Character local myRoot = character and character:FindFirstChild("HumanoidRootPart") local hum = character and character:FindFirstChildOfClass("Humanoid") if _G.AutoFarmCoins and _G.CheckRoundActive() and hum and hum.Health > 0 and myRoot then local murderer = _G.GetMurderer() local mudRoot = murderer and murderer.Character and murderer.Character:FindFirstChild("HumanoidRootPart") if _G.AvoidMurderer and mudRoot and (myRoot.Position - mudRoot.Position).Magnitude < _G.SafeDistance then escapeFromMurderer(myRoot, mudRoot) end if _G.IsBagFull() then toggleAnimations(true) _G.ToggleNoClip(false) if _G.FlingMurderer and murderer then flingTarget(murderer) task.wait(1) else myRoot.Velocity = Vector3.new(0,0,0) task.wait(0.5) end else _G.ToggleNoClip(true) toggleAnimations(not _G.FarmUnderground) local touchPart = getClosestCoin() if touchPart and touchPart.Parent then local coinPos = touchPart.Position local targetPos if _G.FarmUnderground then local horizontalDist = Vector2.new(myRoot.Position.X - coinPos.X, myRoot.Position.Z - coinPos.Z).Magnitude if horizontalDist < 1.2 then targetPos = coinPos else targetPos = Vector3.new(coinPos.X, coinPos.Y - 2.8, coinPos.Z) end else targetPos = coinPos if myRoot.Position.Y > coinPos.Y + 2 then targetPos = Vector3.new(targetPos.X, coinPos.Y, targetPos.Z) end end if (myRoot.Position - targetPos).Magnitude > 0.2 then myRoot.Velocity = Vector3.new(0,0,0) local moveDirection = (targetPos - myRoot.Position).Unit local nextPosition = myRoot.Position + moveDirection * (_G.FarmSpeed / 100) if _G.FarmUnderground then myRoot.CFrame = CFrame.new(nextPosition) * CFrame.Angles(math.rad(-90), 0, 0) else myRoot.CFrame = CFrame.new(nextPosition, Vector3.new(targetPos.X, myRoot.Position.Y, targetPos.Z)) end end end end else toggleAnimations(true) _G.ToggleNoClip(false) end end 

end)

if _G.FarmingTab and _G.VisualsTab and _G.Fluent then
_G.FarmingTab:AddToggle("AutoFarmToggle", { Title = "Auto Farm Coins", Default = false, Callback = function(Value) _G.AutoFarmCoins = Value end })
_G.FarmingTab:AddToggle("AvoidMurdererToggle", { Title = "Avoid the Murderer", Default = false, Callback = function(Value) _G.AvoidMurderer = Value end })
_G.FarmingTab:AddToggle("FarmUndergroundToggle", { Title = "Farm Underground (Safe)", Default = false, Callback = function(Value) _G.FarmUnderground = Value end })
_G.FarmingTab:AddToggle("FlingMurdererToggle", { Title = "Fling Murderer when Full", Default = false, Callback = function(Value) _G.FlingMurderer = Value end })

_G.FarmingTab:AddButton({ Title = "Farm Speed -", Callback = function() _G.FarmSpeed = math.max(15, _G.FarmSpeed - 2) _G.Fluent:Notify({ Title = "Speed", Content = tostring(_G.FarmSpeed), Duration = 1 }) end }) _G.FarmingTab:AddButton({ Title = "Farm Speed +", Callback = function() _G.FarmSpeed = math.min(45, _G.FarmSpeed + 2) _G.Fluent:Notify({ Title = "Speed", Content = tostring(_G.FarmSpeed), Duration = 1 }) end }) _G.FarmingTab:AddButton({ Title = "Safe Distance -", Callback = function() _G.SafeDistance = math.max(15, _G.SafeDistance - 5) _G.Fluent:Notify({ Title = "Safe Distance", Content = tostring(_G.SafeDistance) .. " studs", Duration = 1 }) end }) _G.FarmingTab:AddButton({ Title = "Safe Distance +", Callback = function() _G.SafeDistance = math.min(100, _G.SafeDistance + 5) _G.Fluent:Notify({ Title = "Safe Distance", Content = tostring(_G.SafeDistance) .. " studs", Duration = 1 }) end }) _G.VisualsTab:AddToggle("CoinsESPToggle", { Title = "ESP Coins (Orange)", Default = false, Callback = function(Value) _G.CoinsESP = Value end }) _G.VisualsTab:AddToggle("MurderESPToggle", { Title = "ESP Murderer (Red)", Default = false, Callback = function(Value) _G.MurderESP = Value end }) _G.VisualsTab:AddToggle("SheriffESPToggle", { Title = "ESP Sheriff (Blue)", Default = false, Callback = function(Value) _G.SheriffESP = Value end }) _G.Window:SelectTab(1) _G.Fluent:Notify({ Title = "MM2 Menu", Content = "Interface successfully connected to all modules!", Duration = 5 }) 

end

