local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

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
_G.FarmSpeed = 25

_G.CoinsESP = false
_G.MurderESP = false
_G.SheriffESP = false

local noclipConnection = nil
local function findCoinContainer()
local normal = Workspace:FindFirstChild("Normal")
if normal then return normal:FindFirstChild("CoinContainer") end
return nil
end

local function getHitboxPart(coinObj)
return coinObj:FindFirstChild("CoinVisual") or coinObj:FindFirstChild("TouchInterest") and coinObj or coinObj
end

local function isBagFull()
local playerData = LocalPlayer:FindFirstChild("PlayerData")
if playerData then
local coinsValue = playerData:FindFirstChild("Coins")
if coinsValue and coinsValue.Value >= 50 then return true end
end
return false
end

local function getCoinCount()
local playerData = LocalPlayer:FindFirstChild("PlayerData")
if playerData then
local coinsValue = playerData:FindFirstChild("Coins")
return coinsValue and coinsValue.Value or 0
end
return 0
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
_G.GetHitboxPart = getHitboxPart
_G.IsBagFull = isBagFull
_G.GetCoinCount = getCoinCount
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

local closestCoin = nil local shortestDistance = math.huge for _, obj in ipairs(coinContainer:GetDescendants()) do if obj.Name == "Coin_Server" and obj.Parent then local touchPart = _G.GetHitboxPart(obj) if touchPart and (touchPart:IsA("Model") or touchPart:IsA("BasePart")) then local coinCFrame = touchPart:GetPivot() local distance = (myRoot.Position - coinCFrame.Position).Magnitude if distance < shortestDistance then shortestDistance = distance closestCoin = obj end end end end return closestCoin 

end

Workspace.DescendantRemoving:Connect(function(descendant)
local container = _G.FindCoinContainer()
if container and descendant == container then
_G.DetectedMurdererName = nil
end
end)

local function applyHighlight(object, name, color, enabled)
if object then
local existing = object:FindFirstChild(name)
if enabled then
if not existing then
local hl = Instance.new("Highlight")
hl.Name = name
hl.FillColor = color
hl.OutlineColor = Color3.fromRGB(255, 255, 255)
hl.FillTransparency = 0.4
hl.OutlineTransparency = 0.2
hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
hl.Enabled = true
hl.Parent = object
else
existing.Enabled = true
end
else
if existing then
existing.Enabled = false
end
end
end
end

task.spawn(function()
while true do
task.wait(0.5)
local container = _G.FindCoinContainer()
if container then
for _, obj in ipairs(container:GetDescendants()) do
if obj.Name == "Coin_Server" then
local visual = obj:FindFirstChild("CoinVisual", true) or obj
if visual and (visual:IsA("Model") or visual:IsA("BasePart")) then
applyHighlight(visual, "CoinESP", Color3.fromRGB(255, 130, 0), _G.CoinsESP)
end
end
end
end
local mud = _G.GetMurderer()
if mud and mud.Character then
applyHighlight(mud.Character, "MurderESP", Color3.fromRGB(255, 0, 0), _G.MurderESP)
end
local shr = _G.GetSheriff()
if shr and shr.Character then
applyHighlight(shr.Character, "SheriffESP", Color3.fromRGB(0, 120, 255), _G.SheriffESP)
end
end
end)
local function flingTarget(targetPlayer)
local character = LocalPlayer.Character
local targetChar = targetPlayer.Character
local myRoot = character and character:FindFirstChild("HumanoidRootPart")
local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")

if myRoot and targetRoot and targetRoot.Parent then local oldCFrame = myRoot.CFrame _G.ToggleNoClip(false) local bavg = Instance.new("BodyAngularVelocity") bavg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge) bavg.AngularVelocity = Vector3.new(0, 95000, 0) bavg.Parent = myRoot myRoot.CFrame = targetRoot.CFrame task.wait(0.15) bavg:Destroy() myRoot.Velocity = Vector3.new(0, 0, 0) myRoot.RotVelocity = Vector3.new(0, 0, 0) myRoot.CFrame = oldCFrame _G.ToggleNoClip(_G.AutoFarmCoins) end 

end

task.spawn(function()
while true do
task.wait(0.05)

if _G.AutoFarmCoins then if _G.IsBagFull() and _G.FlingMurderer then _G.ToggleAnimations(true) local m = _G.GetMurderer() if m then flingTarget(m) task.wait(1) else _G.ToggleNoClip(false) end elseif not _G.IsBagFull() then _G.ToggleNoClip(true) _G.ToggleAnimations(not _G.FarmUnderground) local coin = getClosestCoin() local character = LocalPlayer.Character local myRoot = character and character:FindFirstChild("HumanoidRootPart") if coin and myRoot then local touchPart = _G.GetHitboxPart(coin) if touchPart and (touchPart:IsA("Model") or touchPart:IsA("BasePart")) then local targetCFrame = touchPart:GetPivot() if _G.FarmUnderground then targetCFrame = CFrame.new(targetCFrame.Position) * CFrame.new(0, -3.2, 0) * CFrame.Angles(math.rad(-90), 0, 0) end local startCount = _G.GetCoinCount() local distance = (myRoot.Position - targetCFrame.Position).Magnitude local duration = distance / _G.FarmSpeed local tween = TweenService:Create(myRoot, TweenInfo.new(duration, Enum.EasingStyle.Linear), {CFrame = targetCFrame}) tween:Play() local coinRemoved = false local connection connection = coin.AncestryChanged:Connect(function() if not coin.Parent or not coin:IsDescendantOf(game) then tween:Cancel() coinRemoved = true connection:Disconnect() end end) tween.Completed:Wait() if connection.Connected then connection:Disconnect() end if not coinRemoved then local timeout = 0 while coin.Parent and touchPart.Parent and timeout < 0.4 do if _G.GetCoinCount() > startCount then break end task.wait(0.02) timeout = timeout + 0.02 end end end end else _G.ToggleAnimations(true) _G.ToggleNoClip(false) end else _G.ToggleAnimations(true) _G.ToggleNoClip(false) end end 

end)
local Window = Fluent:CreateWindow({
Title = "MM2 Premium Hack",
SubTitle = "v2.0 Fixed & Stable",
TabWidth = 160,
Size = UDim2.fromOffset(580, 460),
Acrylic = false,
Theme = "Dark",
MinimizeKey = Enum.KeyCode.LeftControl
})

local FarmingTab = Window:AddTab({ Title = "Farming", Icon = "candy" })
local VisualsTab = Window:AddTab({ Title = "Visuals", Icon = "eye" })

FarmingTab:AddToggle("AutoFarmToggle", {
Title = "Auto Farm Coins",
Default = false,
Callback = function(Value) _G.AutoFarmCoins = Value end
})
FarmingTab:AddToggle("FarmUndergroundToggle", {
Title = "Farm Underground (Safe)",
Default = false,
Callback = function(Value) _G.FarmUnderground = Value end
})
FarmingTab:AddToggle("FlingMurdererToggle", {
Title = "Fling Murderer when Full",
Default = false,
Callback = function(Value) _G.FlingMurderer = Value end
})

FarmingTab:AddButton({
Title = "Farm Speed -",
Callback = function()
_G.FarmSpeed = math.max(15, _G.FarmSpeed - 2)
Fluent:Notify({ Title = "Speed", Content = tostring(_G.FarmSpeed), Duration = 1 })
end
})
FarmingTab:AddButton({
Title = "Farm Speed +",
Callback = function()
_G.FarmSpeed = math.min(45, _G.FarmSpeed + 2)
Fluent:Notify({ Title = "Speed", Content = tostring(_G.FarmSpeed), Duration = 1 })
end
})

VisualsTab:AddToggle("CoinsESPToggle", {
Title = "ESP Coins (Orange)",
Default = false,
Callback = function(Value) _G.CoinsESP = Value end
})
VisualsTab:AddToggle("MurderESPToggle", {
Title = "ESP Murderer (Red)",
Default = false,
Callback = function(Value) _G.MurderESP = Value end
})
VisualsTab:AddToggle("SheriffESPToggle", {
Title = "ESP Sheriff (Blue)",
Default = false,
Callback = function(Value) _G.SheriffESP = Value end
})

Window:SelectTab(1)
Fluent:Notify({
Title = "MM2 Script",
Content = "Loaded Successfully!",
Duration = 5
})

