local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
_G.Fluent = Fluent

_G.CollectedCoins = _G.CollectedCoins or {}
_G.DetectedMurdererName = nil
_G.AutoFarmCoins = false
_G.FarmUnderground = false
_G.FlingMurderer = false
_G.AvoidMurderer = false
_G.AutoGrabGun = false
_G.FarmSpeed = 25
_G.SafeDistance = 45
_G.CoinsESP = false
_G.MurderESP = false
_G.SheriffESP = false
_G.InnocentESP = false
_G.HeroESP = false

_G.Window = _G.Fluent:CreateWindow({
Title = "MM2 Premium Hack",
SubTitle = "v3.5 Ultimate Edition",
TabWidth = 160,
Size = UDim2.fromOffset(580, 460),
Acrylic = false,
Theme = "Dark",
MinimizeKey = Enum.KeyCode.LeftControl
})

_G.FarmingTab = _G.Window:AddTab({ Title = "Farming", Icon = "coin" })
_G.CombatTab = _G.Window:AddTab({ Title = "Combat", Icon = "swords" })
_G.FlingTab = _G.Window:AddTab({ Title = "Fling Tools", Icon = "zap" })
_G.VisualsTab = _G.Window:AddTab({ Title = "Visuals", Icon = "eye" })

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

_G.FindCoinContainer = function()
for _, child in ipairs(Workspace:GetChildren()) do
local container = child:FindFirstChild("CoinContainer") or child:FindFirstChild("coinContainer")
if container then
return container
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

if coinBags then
local normalBag = coinBags:FindFirstChild("Coin")
if normalBag and normalBag.Visible == true then
local fullIcon = normalBag:FindFirstChild("FullBagIcon")
if fullIcon and fullIcon.Visible == true then
return true
end
end

local container = coinBags:FindFirstChild("Container")
if container then
local candyBag = container:FindFirstChild("Candy")
if candyBag and candyBag.Visible == true then
local fullIcon = candyBag:FindFirstChild("FullBagIcon")
if fullIcon and fullIcon.Visible == true then
return true
end
end
end

end
return false

end

_G.CurrentHeroName = _G.CurrentHeroName or nil

task.spawn(function()
local lastDroppedGun = nil
while task.wait(0.1) do
local droppedGun = Workspace:FindFirstChild("GunDrop", true)

if droppedGun then
lastDroppedGun = droppedGun
else
if lastDroppedGun then
task.wait(0.1)
for _, p in ipairs(Players:GetPlayers()) do
local playerData = p:FindFirstChild("PlayerData") or (ReplicatedStorage:FindFirstChild("PlayerData") and ReplicatedStorage.PlayerData:FindFirstChild(p.Name))
local isRoleSheriff = playerData and playerData:FindFirstChild("Role") and playerData.Role.Value == "Sheriff"

if not isRoleSheriff and ((p:FindFirstChild("Backpack") and p.Backpack:FindFirstChild("Gun")) or (p.Character and p.Character:FindFirstChild("Gun"))) then
_G.CurrentHeroName = p.Name
break
end
end
lastDroppedGun = nil
end
end

if not _G.CheckRoundActive() then
_G.CurrentHeroName = nil
end

end

end)

local function getRole(player)
if not player then return "Innocent" end

if player:FindFirstChild("Backpack") and player.Backpack:FindFirstChild("Knife") then return "Murderer" end
if player.Character and player.Character:FindFirstChild("Knife") then return "Murderer" end

local playerData = player:FindFirstChild("PlayerData") or (ReplicatedStorage:FindFirstChild("PlayerData") and ReplicatedStorage.PlayerData:FindFirstChild(player.Name))
if playerData and playerData:FindFirstChild("Role") then
if playerData.Role.Value == "Sheriff" then
return "Sheriff"
elseif playerData.Role.Value == "Murderer" then
return "Murderer"
end
end

if _G.CurrentHeroName and player.Name == _G.CurrentHeroName then
return "Hero"
end

local hasGun = (player:FindFirstChild("Backpack") and player.Backpack:FindFirstChild("Gun")) or (player.Character and player.Character:FindFirstChild("Gun"))
if hasGun and not hasGun:FindFirstChild("Innocent") then
return "Sheriff"
end

return "Innocent"

end

_G.GetMurderer = function()
for _, p in ipairs(Players:GetPlayers()) do
if getRole(p) == "Murderer" then
_G.DetectedMurdererName = p.Name
return p
end
end
return nil
end

_G.GetSheriff = function()
for _, p in ipairs(Players:GetPlayers()) do
if getRole(p) == "Sheriff" then return p end
end
return nil
end

_G.GetHero = function()
for _, p in ipairs(Players:GetPlayers()) do
if getRole(p) == "Hero" then return p end
end
return nil
end
Workspace.DescendantRemoving:Connect(function(descendant)
local container = _G.FindCoinContainer()
if container and descendant == container then
_G.DetectedMurdererName = nil
_G.CurrentHeroName = nil
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
if descendant:IsA("Highlight") and descendant.Name == espName then descendant:Destroy() end
end
end

task.spawn(function()
while true do
task.wait(0.3)
if not _G.FindCoinContainer then continue end

local container = _G.FindCoinContainer()
if _G.CoinsESP and container then
for _, obj in ipairs(container:GetDescendants()) do
if obj.Name == "CoinVisual" and obj:IsA("BasePart") then
applyHighlight(obj, "CoinESP", Color3.fromRGB(255, 110, 0), true)
end
end
else
clearGlobalESP("CoinESP")
end

local droppedGun = Workspace:FindFirstChild("GunDrop", true)
if droppedGun then
applyHighlight(droppedGun, "GunDropESP", Color3.fromRGB(0, 255, 255), _G.SheriffESP)
else
clearGlobalESP("GunDropESP")
end

for _, p in ipairs(Players:GetPlayers()) do
if p ~= LocalPlayer and p.Character then
local role = getRole(p)

if role == "Murderer" then
if p.Character:FindFirstChild("SheriffESP") then p.Character.SheriffESP:Destroy() end
if p.Character:FindFirstChild("InnocentHighlight") then p.Character.InnocentHighlight:Destroy() end
if p.Character:FindFirstChild("HeroHighlight") then p.Character.HeroHighlight:Destroy() end
applyHighlight(p.Character, "MurderESP", Color3.fromRGB(255, 0, 0), _G.MurderESP)

elseif role == "Sheriff" then if p.Character:FindFirstChild("MurderESP") then p.Character.MurderESP:Destroy() end if p.Character:FindFirstChild("InnocentHighlight") then p.Character.InnocentHighlight:Destroy() end if p.Character:FindFirstChild("HeroHighlight") then p.Character.HeroHighlight:Destroy() end applyHighlight(p.Character, "SheriffESP", Color3.fromRGB(0, 120, 255), _G.SheriffESP) elseif role == "Hero" then if p.Character:FindFirstChild("MurderESP") then p.Character.MurderESP:Destroy() end if p.Character:FindFirstChild("SheriffESP") then p.Character.SheriffESP:Destroy() end if p.Character:FindFirstChild("InnocentHighlight") then p.Character.InnocentHighlight:Destroy() end applyHighlight(p.Character, "HeroHighlight", Color3.fromRGB(255, 255, 0), _G.HeroESP) elseif role == "Innocent" then if p.Character:FindFirstChild("MurderESP") then p.Character.MurderESP:Destroy() end if p.Character:FindFirstChild("SheriffESP") then p.Character.SheriffESP:Destroy() end if p.Character:FindFirstChild("HeroHighlight") then p.Character.HeroHighlight:Destroy() end applyHighlight(p.Character, "InnocentHighlight", Color3.fromRGB(0, 255, 0), _G.InnocentESP) end 

end

end

if not _G.SheriffESP then clearGlobalESP("SheriffESP") end
if not _G.MurderESP then clearGlobalESP("MurderESP") end
if not _G.InnocentESP then clearGlobalESP("InnocentHighlight") end
if not _G.HeroESP then clearGlobalESP("HeroHighlight") end

end

end)

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

local function smoothTween(targetPosition)
local character = LocalPlayer.Character
local myRoot = character and character:FindFirstChild("HumanoidRootPart")
if not myRoot then return end

local distance = (myRoot.Position - targetPosition).Magnitude
if distance < 1 then
myRoot.CFrame = CFrame.new(targetPosition)
return
end

local speed = math.max(15, _G.FarmSpeed)
local duration = distance / speed

local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)
local tween = TweenService:Create(myRoot, tweenInfo, {CFrame = CFrame.new(targetPosition)})

tween:Play()
tween.Completed:Wait()

end

local function flingTarget(targetPlayer)
if not targetPlayer or not targetPlayer.Character then return end
local character = LocalPlayer.Character
local myRoot = character and character:FindFirstChild("HumanoidRootPart")
local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
local targetHum = targetPlayer.Character:FindFirstChildOfClass("Humanoid")

if myRoot and targetRoot and targetRoot.Parent then
local oldCFrame = myRoot.CFrame
_G.ToggleNoClip(true)

local bavg = Instance.new("BodyAngularVelocity")
bavg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
bavg.AngularVelocity = Vector3.new(0, 200000, 0)
bavg.Parent = myRoot

local startTime = tick()
local heartbeatConnection

heartbeatConnection = RunService.Heartbeat:Connect(function()
if targetRoot and targetRoot.Parent and (tick() - startTime < 2.0) then
myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, -0.5, 0)
targetRoot.AssemblyLinearVelocity = Vector3.new(math.random(-5000, 5000), -10000, math.random(-5000, 5000))
myRoot.AssemblyLinearVelocity = Vector3.new(0, -5000, 0)

if targetHum then targetHum:ChangeState(Enum.HumanoidStateType.Ragdoll) end
else
if heartbeatConnection then heartbeatConnection:Disconnect() heartbeatConnection = nil end
end

end)

while tick() - startTime < 2.0 and targetRoot and targetRoot.Parent do task.wait(0.05) end
if heartbeatConnection then heartbeatConnection:Disconnect() end

bavg:Destroy()
myRoot.AssemblyLinearVelocity = Vector3.new(0,0,0)
myRoot.AssemblyAngularVelocity = Vector3.new(0,0,0)
myRoot.CFrame = oldCFrame

end

end

local function escapeFromMurderer(myRoot, mudRoot)
if not mudRoot or not myRoot then return end
local vector = (myRoot.Position - mudRoot.Position)
local direction = vector.Magnitude > 0 and vector.Unit or Vector3.new(0, 1, 0)
local targetPosition = myRoot.Position + (direction * 35)
myRoot.CFrame = CFrame.new(targetPosition.X, mudRoot.Position.Y, targetPosition.Z)
task.wait(0.1)
end

local function getBestCoin()
if not _G.FindCoinContainer or not _G.GetMurderer then return nil end
local coinContainer = _G.FindCoinContainer()
if not coinContainer then return nil end

local character = LocalPlayer.Character
local myRoot = character and character:FindFirstChild("HumanoidRootPart")
if not myRoot then return nil end

local murderer = _G.GetMurderer()
local mudRoot = murderer and murderer.Character and murderer.Character:FindFirstChild("HumanoidRootPart")

local closestTarget = nil
local shortestDistance = math.huge

for _, obj in ipairs(coinContainer:GetDescendants()) do
if obj:IsA("BasePart") and obj.Name == "CoinVisual" then
local coinPos = obj.Position

if _G.AvoidMurderer and mudRoot then
if (coinPos - mudRoot.Position).Magnitude < _G.SafeDistance then
continue
end
end

local dist = (myRoot.Position - coinPos).Magnitude
if dist < shortestDistance then
shortestDistance = dist
closestTarget = obj
end

end

end

return closestTarget

end
task.spawn(function()
while true do
task.wait(0.05)
if not _G.CheckRoundActive or not _G.IsBagFull then continue end

local character = LocalPlayer.Character
local myRoot = character and character:FindFirstChild("HumanoidRootPart")
local hum = character and character:FindFirstChildOfClass("Humanoid")

if _G.CheckRoundActive() and hum and hum.Health > 0 and myRoot then
local droppedGun = Workspace:FindFirstChild("GunDrop", true)

if _G.AutoGrabGun and droppedGun and droppedGun:IsA("BasePart") then
smoothTween(Vector3.new(droppedGun.Position.X, myRoot.Position.Y, droppedGun.Position.Z))
task.wait(0.1)
elseif _G.AutoFarmCoins then
local murderer = _G.GetMurderer()
local mudRoot = murderer and murderer.Character and murderer.Character:FindFirstChild("HumanoidRootPart")

if not _G.IsBagFull() and _G.AvoidMurderer and mudRoot and (myRoot.Position - mudRoot.Position).Magnitude < _G.SafeDistance then escapeFromMurderer(myRoot, mudRoot) end if _G.IsBagFull() then if _G.FlingMurderer then if murderer and murderer.Character and murderer.Character:FindFirstChild("HumanoidRootPart") then toggleAnimations(true) flingTarget(murderer) task.wait(0.5) else myRoot.AssemblyLinearVelocity = Vector3.new(0,0,0) myRoot.AssemblyAngularVelocity = Vector3.new(0,0,0) if _G.FarmUnderground then myRoot.CFrame = CFrame.new(myRoot.Position.X, -50, myRoot.Position.Z) end task.wait(0.2) end else _G.ToggleNoClip(false) toggleAnimations(true) myRoot.AssemblyLinearVelocity = Vector3.new(0,0,0) myRoot.AssemblyAngularVelocity = Vector3.new(0,0,0) task.wait(0.5) end else _G.ToggleNoClip(true) if _G.FarmUnderground == true then toggleAnimations(false) else toggleAnimations(true) end local touchPart = getBestCoin() if touchPart and touchPart.Parent then local coinPos = touchPart.Position local targetPos if _G.FarmUnderground == true then targetPos = Vector3.new(coinPos.X, -50, coinPos.Z) if touchPart:IsA("BasePart") then touchPart.Size = Vector3.new(touchPart.Size.X, 10, touchPart.Size.Z) touchPart.CanCollide = false end else targetPos = Vector3.new(coinPos.X, coinPos.Y, coinPos.Z) end smoothTween(targetPos) else myRoot.AssemblyLinearVelocity = Vector3.new(0,0,0) myRoot.AssemblyAngularVelocity = Vector3.new(0,0,0) end end 

end

else
toggleAnimations(true)
_G.ToggleNoClip(false)
end

end

end)

if _G.FarmingTab and _G.CombatTab and _G.FlingTab and _G.VisualsTab and _G.Fluent then
_G.FarmingTab:AddToggle("AutoFarmToggle", { Title = "Auto Farm Coins", Default = false, Callback = function(Value) _G.AutoFarmCoins = Value end })
_G.FarmingTab:AddToggle("AvoidMurdererToggle", { Title = "Avoid the Murderer", Default = false, Callback = function(Value) _G.AvoidMurderer = Value end })
_G.FarmingTab:AddToggle("FarmUndergroundToggle", { Title = "Farm Underground (Safe)", Default = false, Callback = function(Value) _G.FarmUnderground = Value end })
_G.FarmingTab:AddToggle("FlingMurdererToggle", { Title = "Fling Murderer when Full", Default = false, Callback = function(Value) _G.FlingMurderer = Value end })

_G.FarmingTab:AddButton({ Title = "Farm Speed -", Callback = function() _G.FarmSpeed = math.max(10, _G.FarmSpeed - 5) _G.Fluent:Notify({ Title = "Speed", Content = tostring(_G.FarmSpeed), Duration = 1 }) end })
_G.FarmingTab:AddButton({ Title = "Farm Speed +", Callback = function() _G.FarmSpeed = math.min(150, _G.FarmSpeed + 5) _G.Fluent:Notify({ Title = "Speed", Content = tostring(_G.FarmSpeed), Duration = 1 }) end })
_G.FarmingTab:AddButton({ Title = "Safe Distance -", Callback = function() _G.SafeDistance = math.max(15, _G.SafeDistance - 5) _G.Fluent:Notify({ Title = "Safe Distance", Content = tostring(_G.SafeDistance) .. " studs", Duration = 1 }) end })
_G.FarmingTab:AddButton({ Title = "Safe Distance +", Callback = function() _G.SafeDistance = math.min(100, _G.SafeDistance + 5) _G.Fluent:Notify({ Title = "Safe Distance", Content = tostring(_G.SafeDistance) .. " studs", Duration = 1 }) end })

_G.CombatTab:AddToggle("AutoGrabGunToggle", { Title = "Auto Grab Gun", Default = false, Callback = function(Value) _G.AutoGrabGun = Value end })

_G.FlingTab:AddButton({ Title = "Fling Murderer", Callback = function() local target = _G.GetMurderer() if target then flingTarget(target) else _G.Fluent:Notify({ Title = "Fling", Content = "Murderer not found", Duration = 3 }) end end })
_G.FlingTab:AddButton({ Title = "Fling Sheriff", Callback = function() local target = _G.GetSheriff() if target then flingTarget(target) else _G.Fluent:Notify({ Title = "Fling", Content = "Sheriff not found", Duration = 3 }) end end })
_G.FlingTab:AddButton({ Title = "Fling Hero", Callback = function() local target = _G.GetHero() if target then flingTarget(target) else _G.Fluent:Notify({ Title = "Fling", Content = "Hero not found", Duration = 3 }) end end })

_G.VisualsTab:AddToggle("CoinsESPToggle", { Title = "ESP Candy/Coins (Orange)", Default = false, Callback = function(Value) _G.CoinsESP = Value end })
_G.VisualsTab:AddToggle("MurderESPToggle", { Title = "ESP Murderer (Red)", Default = false, Callback = function(Value) _G.MurderESP = Value end })
_G.VisualsTab:AddToggle("SheriffESPToggle", { Title = "ESP Sheriff (Blue)", Default = false, Callback = function(Value) _G.SheriffESP = Value end })
_G.VisualsTab:AddToggle("InnocentESPToggle", { Title = "ESP Innocents (Green)", Default = false, Callback = function(Value) _G.InnocentESP = Value end })
_G.VisualsTab:AddToggle("HeroESPToggle", { Title = "ESP Hero (Yellow)", Default = false, Callback = function(Value) _G.HeroESP = Value end })

_G.Window:SelectTab(1)
_G.Fluent:Notify({ Title = "MM2 Menu", Content = "Interface successfully connected to all modules!", Duration = 5 })

end

