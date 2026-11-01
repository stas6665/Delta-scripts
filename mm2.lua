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

local OriginalKnifeData = nil
local OriginalGunData = nil

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
_G.SkinsTab = _G.Window:AddTab({ Title = "Skin Changer", Icon = "shirt" })

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
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

if coinBags then local normalBag = coinBags:FindFirstChild("Coin") if normalBag and normalBag.Visible == true then local fullIcon = normalBag:FindFirstChild("FullBagIcon") if fullIcon and fullIcon.Visible == true then return true end end local container = coinBags:FindFirstChild("Container") if container then local candyBag = container:FindFirstChild("Candy") if candyBag and candyBag.Visible == true then local fullIcon = candyBag:FindFirstChild("FullBagIcon") if fullIcon and fullIcon.Visible == true then return true end end end end return false 

end
_G.CurrentHeroName = _G.CurrentHeroName or nil

task.spawn(function()
local lastDroppedGun = nil
while task.wait(0.1) do
local droppedGun = Workspace:FindFirstChild("GunDrop", true)

if droppedGun then lastDroppedGun = droppedGun else if lastDroppedGun then task.wait(0.1) for _, p in ipairs(Players:GetPlayers()) do local playerData = p:FindFirstChild("PlayerData") or (ReplicatedStorage:FindFirstChild("PlayerData") and ReplicatedStorage.PlayerData:FindFirstChild(p.Name)) local isRoleSheriff = playerData and playerData:FindFirstChild("Role") and playerData.Role.Value == "Sheriff" if not isRoleSheriff and ((p:FindFirstChild("Backpack") and p.Backpack:FindFirstChild("Gun")) or (p.Character and p.Character:FindFirstChild("Gun"))) then _G.CurrentHeroName = p.Name break end end lastDroppedGun = nil end end if not _G.CheckRoundActive() then _G.CurrentHeroName = nil end end 

end)

local function getRole(player)
if not player then return "Innocent" end

if player:FindFirstChild("Backpack") and player.Backpack:FindFirstChild("Knife") then return "Murderer" end if player.Character and player.Character:FindFirstChild("Knife") then return "Murderer" end local playerData = player:FindFirstChild("PlayerData") or (ReplicatedStorage:FindFirstChild("PlayerData") and ReplicatedStorage.PlayerData:FindFirstChild(player.Name)) if playerData and playerData:FindFirstChild("Role") then if playerData.Role.Value == "Sheriff" then return "Sheriff" elseif playerData.Role.Value == "Murderer" then return "Murderer" end end if _G.CurrentHeroName and player.Name == _G.CurrentHeroName then return "Hero" end local hasGun = (player:FindFirstChild("Backpack") and player.Backpack:FindFirstChild("Gun")) or (player.Character and player.Character:FindFirstChild("Gun")) if hasGun and not hasGun:FindFirstChild("Innocent") then return "Sheriff" end return "Innocent" 

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

local container = _G.FindCoinContainer() if _G.CoinsESP and container then for _, obj in ipairs(container:GetDescendants()) do if obj.Name == "CoinVisual" and obj:IsA("BasePart") then applyHighlight(obj, "CoinESP", Color3.fromRGB(255, 110, 0), true) end end else clearGlobalESP("CoinESP") end local droppedGun = Workspace:FindFirstChild("GunDrop", true) if droppedGun then applyHighlight(droppedGun, "GunDropESP", Color3.fromRGB(0, 255, 255), _G.SheriffESP) else clearGlobalESP("GunDropESP") end for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer and p.Character then local role = getRole(p) if role == "Murderer" then if p.Character:FindFirstChild("SheriffESP") then p.Character.SheriffESP:Destroy() end if p.Character:FindFirstChild("InnocentHighlight") then p.Character.InnocentHighlight:Destroy() end if p.Character:FindFirstChild("HeroHighlight") then p.Character.HeroHighlight:Destroy() end applyHighlight(p.Character, "MurderESP", Color3.fromRGB(255, 0, 0), _G.MurderESP) elseif role == "Sheriff" then if p.Character:FindFirstChild("MurderESP") then p.Character.MurderESP:Destroy() end if p.Character:FindFirstChild("InnocentHighlight") then p.Character.InnocentHighlight:Destroy() end if p.Character:FindFirstChild("HeroHighlight") then p.Character.HeroHighlight:Destroy() end applyHighlight(p.Character, "SheriffESP", Color3.fromRGB(0, 120, 255), _G.SheriffESP) elseif role == "Hero" then if p.Character:FindFirstChild("MurderESP") then p.Character.MurderESP:Destroy() end if p.Character:FindFirstChild("SheriffESP") then p.Character.SheriffESP:Destroy() end if p.Character:FindFirstChild("InnocentHighlight") then p.Character.InnocentHighlight:Destroy() end applyHighlight(p.Character, "HeroHighlight", Color3.fromRGB(255, 255, 0), _G.HeroESP) elseif role == "Innocent" then if p.Character:FindFirstChild("MurderESP") then p.Character.MurderESP:Destroy() end if p.Character:FindFirstChild("SheriffESP") then p.Character.SheriffESP:Destroy() end if p.Character:FindFirstChild("HeroHighlight") then p.Character.HeroHighlight:Destroy() end applyHighlight(p.Character, "InnocentHighlight", Color3.fromRGB(0, 255, 0), _G.InnocentESP) end end end if not _G.SheriffESP then clearGlobalESP("SheriffESP") end if not _G.MurderESP then clearGlobalESP("MurderESP") end if not _G.InnocentESP then clearGlobalESP("InnocentHighlight") end if not _G.HeroESP then clearGlobalESP("HeroHighlight") end end 

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
_G.VisualSkinChanger = false
_G.SelectedKnifeSkin = "Default"
_G.SelectedGunSkin = "Default"

local KnifeDatabase = {
["Nik's Scythe"] = {Mesh = "rbxassetid://4746142714", Texture = "rbxassetid://4746144078", Sound = "rbxassetid://2428812423", Image = "rbxassetid://4746145290"},
["Traveler's Axe"] = {Mesh = "rbxassetid://15132208037", Texture = "rbxassetid://15132208359", Sound = "rbxassetid://9114223191", Image = "rbxassetid://15132209110"},
["Celestial"] = {Mesh = "rbxassetid://15545595511", Texture = "rbxassetid://15545595708", Sound = "rbxassetid://9117912443", Image = "rbxassetid://15545596120"},
["Vampire's Axe"] = {Mesh = "rbxassetid://15132230485", Texture = "rbxassetid://15132230752", Sound = "rbxassetid://1445037042", Image = "rbxassetid://15132231120"},
["Emberscythe"] = {Mesh = "rbxassetid://15545511022", Texture = "rbxassetid://15545511394", Sound = "rbxassetid://9117912443", Image = "rbxassetid://15545512005"},
["Icebreaker"] = {Mesh = "rbxassetid://6116239103", Texture = "rbxassetid://6116239420", Sound = "rbxassetid://6116244221", Image = "rbxassetid://6116245088"},
["Batwing"] = {Mesh = "rbxassetid://1203074311", Texture = "rbxassetid://1203074495", Sound = "rbxassetid://1364506385", Image = "rbxassetid://1203074611"},
["Elderwood Scythe"]={Mesh = "rbxassetid://4273837965", Texture = "rbxassetid://4273838274", Sound = "rbxassetid://4273841102", Image = "rbxassetid://4273842105"},
["Hallowscythe"] = {Mesh = "rbxassetid://5822365376", Texture = "rbxassetid://5822365702", Sound = "rbxassetid://5822369201", Image = "rbxassetid://5822369905"},
["Logchopper"] = {Mesh = "rbxassetid://2611384074", Texture = "rbxassetid://2611384351", Sound = "rbxassetid://1445037042", Image = "rbxassetid://2611385110"}
}

local GunDatabase = {
["Gingerscope"] = {Mesh = "rbxassetid://15623048512", Texture = "rbxassetid://15623048895", Sound = "rbxassetid://15623055210", Image = "rbxassetid://15623056005"},
["Emberbow"] = {Mesh = "rbxassetid://15545648110", Texture = "rbxassetid://15545648505", Sound = "rbxassetid://15545691033", Image = "rbxassetid://15545649110"},
["Harvester"] = {Mesh = "rbxassetid://7653024844", Texture = "rbxassetid://7653025110", Sound = "rbxassetid://7653031022", Image = "rbxassetid://7653026005"},
["Icepiercer"] = {Mesh = "rbxassetid://11689230552", Texture = "rbxassetid://11689230894", Sound = "rbxassetid://11689240112", Image = "rbxassetid://11689231508"}
}

local function saveOriginalSpecs(tool, isKnife)
local meshPart = tool:FindFirstChildOfClass("MeshPart") or tool:FindFirstChild("Handle")
local sound = tool:FindFirstChildOfClass("Sound")
if meshPart then
local data = {
MeshId = meshPart:IsA("MeshPart") and meshPart.MeshId or (meshPart:FindFirstChildOfClass("SpecialMesh") and meshPart:FindFirstChildOfClass("SpecialMesh").MeshId),
TextureId = meshPart:IsA("MeshPart") and meshPart.TextureID or (meshPart:FindFirstChildOfClass("SpecialMesh") and meshPart:FindFirstChildOfClass("SpecialMesh").TextureId),
SoundId = sound and sound.SoundId or ""
}
if isKnife then OriginalKnifeData = data else OriginalGunData = data end
end
end

task.spawn(function()
while task.wait(0.1) do
if _G.VisualSkinChanger and LocalPlayer.Character then
local knife = LocalPlayer.Character:FindFirstChild("Knife") or LocalPlayer:FindFirstChild("Backpack"):FindFirstChild("Knife")
if knife then
if not OriginalKnifeData then saveOriginalSpecs(knife, true) end
local data = (_G.SelectedKnifeSkin == "Default") and OriginalKnifeData or KnifeDatabase[_G.SelectedKnifeSkin]
if data then
for _, child in ipairs(knife:GetDescendants()) do
if child:IsA("MeshPart") then
child.MeshId = data.MeshId or data.Mesh
child.TextureID = data.TextureId or data.Texture
elseif child:IsA("SpecialMesh") then
child.MeshId = data.MeshId or data.Mesh
child.TextureId = data.TextureId or data.Texture
elseif child:IsA("Sound") then
child.SoundId = data.SoundId or data.Sound
end
end
end
end

local gun = LocalPlayer.Character:FindFirstChild("Gun") or LocalPlayer:FindFirstChild("Backpack"):FindFirstChild("Gun") if gun then if not OriginalGunData then saveOriginalSpecs(gun, false) end local data = (_G.SelectedGunSkin == "Default") and OriginalGunData or GunDatabase[_G.SelectedGunSkin] if data then for _, child in ipairs(gun:GetDescendants()) do if child:IsA("MeshPart") then child.MeshId = data.MeshId or data.Mesh child.TextureID = data.TextureId or data.Texture elseif child:IsA("SpecialMesh") then child.MeshId = data.MeshId or data.Mesh child.TextureId = data.TextureId or data.Texture elseif child:IsA("Sound") then child.SoundId = data.SoundId or data.Sound end end end end end end 

end)
local function smoothTween(targetCFrame)
local character = LocalPlayer.Character
local myRoot = character and character:FindFirstChild("HumanoidRootPart")
if not myRoot then return end

myRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0) myRoot.AssemblyAngularVelocity = Vector3.new(0, 0, 0) local distance = (myRoot.Position - targetCFrame.Position).Magnitude local duration = distance / math.max(10, _G.FarmSpeed) local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut) local tween = TweenService:Create(myRoot, tweenInfo, {CFrame = targetCFrame}) tween:Play() tween.Completed:Wait() 

end

Workspace.DescendantAdded:Connect(function(descendant)
if _G.VisualSkinChanger and descendant:IsA("Sound") then
if descendant.Name == "Shoot" or descendant.Name == "GunShoot" or descendant.SoundId == "rbxassetid://138090544" then
if _G.SelectedGunSkin ~= "Default" then
local data = GunDatabase[_G.SelectedGunSkin]
if data then descendant.SoundId = data.Sound end
end
elseif descendant.Name == "Slash" or descendant.Name == "KnifeSlash" then
if _G.SelectedKnifeSkin ~= "Default" then
local data = KnifeDatabase[_G.SelectedKnifeSkin]
if data then descendant.SoundId = data.Sound end
end
end
end
end)

local function flingTarget(targetPlayer)
if not targetPlayer or not targetPlayer.Character then return end
local character = LocalPlayer.Character
local myRoot = character and character:FindFirstChild("HumanoidRootPart")
local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
local targetHum = targetPlayer.Character:FindFirstChildOfClass("Humanoid")

if myRoot and targetRoot and targetRoot.Parent then local oldCFrame = myRoot.CFrame _G.ToggleNoClip(true) local bavg = Instance.new("BodyAngularVelocity") bavg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge) bavg.AngularVelocity = Vector3.new(0, 200000, 0) bavg.Parent = myRoot local startTime = tick() local heartbeatConnection heartbeatConnection = RunService.Heartbeat:Connect(function() if targetRoot and targetRoot.Parent and (tick() - startTime < 2.0) then myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, -0.5, 0) targetRoot.AssemblyLinearVelocity = Vector3.new(math.random(-5000, 5000), -10000, math.random(-5000, 5000)) myRoot.AssemblyLinearVelocity = Vector3.new(0, -5000, 0) if targetHum then targetHum:ChangeState(Enum.HumanoidStateType.Ragdoll) end else if heartbeatConnection then heartbeatConnection:Disconnect() heartbeatConnection = nil end end end) while tick() - startTime < 2.0 and targetRoot and targetRoot.Parent do task.wait(0.05) end if heartbeatConnection then heartbeatConnection:Disconnect() end bavg:Destroy() myRoot.AssemblyLinearVelocity = Vector3.new(0,0,0) myRoot.AssemblyAngularVelocity = Vector3.new(0,0,0) myRoot.CFrame = oldCFrame end 

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

local murderer = _G.GetMurderer() local mudRoot = murderer and murderer.Character and murderer.Character:FindFirstChild("HumanoidRootPart") local closestTarget = nil local shortestDistance = math.huge local nearbyRadius = 25 local coins = {} for _, obj in ipairs(coinContainer:GetDescendants()) do if obj:IsA("BasePart") and obj.Name == "CoinVisual" then local targetCFrame = obj.CFrame if _G.AvoidMurderer and mudRoot then if (targetCFrame.Position - mudRoot.Position).Magnitude < _G.SafeDistance then continue end end local dist = (myRoot.Position - targetCFrame.Position).Magnitude table.insert(coins, {obj = obj, dist = dist}) end end for _, coinData in ipairs(coins) do if coinData.dist < nearbyRadius and coinData.dist < shortestDistance then shortestDistance = coinData.dist closestTarget = coinData.obj end end if not closestTarget then for _, coinData in ipairs(coins) do if coinData.dist < shortestDistance then shortestDistance = coinData.dist closestTarget = coinData.obj end end end return closestTarget 

end

local function emulateInventoryUI()
local pGui = LocalPlayer:FindFirstChild("PlayerGui")
local mainGui = pGui and pGui:FindFirstChild("MainGUI")
local invGui = mainGui and mainGui:FindFirstChild("Inventory")
local mainPanel = invGui and invGui:FindFirstChild("Main")
local itemsContainer = mainPanel and mainPanel:FindFirstChild("Items")
local scrollingFrame = itemsContainer and itemsContainer:FindFirstChild("ScrollingFrame")

if scrollingFrame then for name, data in pairs(KnifeDatabase) do if not scrollingFrame:FindFirstChild("Visual_" .. name) then local template = scrollingFrame:FindFirstChildOfClass("TextButton") or scrollingFrame:FindFirstChildOfClass("ImageButton") if template then local clone = template:Clone() clone.Name = "Visual_" .. name clone.Visible = true local container = clone:FindFirstChild("Container") local label = container and container:FindFirstChild("ItemName") or clone:FindFirstChildOfClass("TextLabel") if label then label.Text = name end local img = container and container:FindFirstChild("ItemImage") or clone:FindFirstChildOfClass("ImageLabel") if img then img.Image = data.Image end clone.MouseButton1Click:Connect(function() if _G.VisualSkinChanger then _G.SelectedKnifeSkin = name _G.Fluent:Notify({ Title = "Inventory Changer", Content = "Equipped Status: " .. name, Duration = 2 }) end end) clone.Parent = scrollingFrame end end end for name, data in pairs(GunDatabase) do if not scrollingFrame:FindFirstChild("Visual_" .. name) then local template = scrollingFrame:FindFirstChildOfClass("TextButton") or scrollingFrame:FindFirstChildOfClass("ImageButton") if template then local clone = template:Clone() clone.Name = "Visual_" .. name clone.Visible = true local container = clone:FindFirstChild("Container") local label = container and container:FindFirstChild("ItemName") or clone:FindFirstChildOfClass("TextLabel") if label then label.Text = name end local img = container and container:FindFirstChild("ItemImage") or clone:FindFirstChildOfClass("ImageLabel") if img then img.Image = data.Image end clone.MouseButton1Click:Connect(function() if _G.VisualSkinChanger then _G.SelectedGunSkin = name _G.Fluent:Notify({ Title = "Inventory Changer", Content = "Equipped Status: " .. name, Duration = 2 }) end end) clone.Parent = scrollingFrame end end end end 

end

task.spawn(function()
while task.wait(2) do
if _G.VisualSkinChanger then pcall(emulateInventoryUI) end
end
end)

task.spawn(function()
while true do
task.wait(0.01)
if not _G.CheckRoundActive or not _G.IsBagFull then continue end

local character = LocalPlayer.Character local myRoot = character and character:FindFirstChild("HumanoidRootPart") local hum = character and character:FindFirstChildOfClass("Humanoid") if _G.CheckRoundActive() and hum and hum.Health > 0 and myRoot then local droppedGun = Workspace:FindFirstChild("GunDrop", true) if _G.AutoGrabGun and droppedGun and droppedGun:IsA("BasePart") then smoothTween(CFrame.new(droppedGun.Position.X, myRoot.Position.Y, droppedGun.Position.Z) * CFrame.Angles(math.rad(90), 0, 0)) task.wait(0.1) elseif _G.AutoFarmCoins then local murderer = _G.GetMurderer() local mudRoot = murderer and murderer.Character and murderer.Character:FindFirstChild("HumanoidRootPart") if not _G.IsBagFull() and _G.AvoidMurderer and mudRoot and (myRoot.Position - mudRoot.Position).Magnitude < _G.SafeDistance then escapeFromMurderer(myRoot, mudRoot) end if _G.IsBagFull() then if _G.FlingMurderer then if murderer and murderer.Character and murderer.Character:FindFirstChild("HumanoidRootPart") then toggleAnimations(true) flingTarget(murderer) task.wait(0.5) else myRoot.AssemblyLinearVelocity = Vector3.new(0,0,0) myRoot.AssemblyAngularVelocity = Vector3.new(0,0,0) if _G.FarmUnderground then myRoot.CFrame = CFrame.new(myRoot.Position.X, -50, myRoot.Position.Z) * CFrame.Angles(math.rad(90), 0, 0) end task.wait(0.2) end else _G.ToggleNoClip(false) toggleAnimations(true) myRoot.AssemblyLinearVelocity = Vector3.new(0,0,0) myRoot.AssemblyAngularVelocity = Vector3.new(0,0,0) task.wait(0.5) end else _G.ToggleNoClip(true) if _G.FarmUnderground == true then toggleAnimations(false) else toggleAnimations(true) end local touchPart = getBestCoin() if touchPart and touchPart.Parent then local coinPos = touchPart.Position local targetCFrame if _G.FarmUnderground == true then targetCFrame = CFrame.new(coinPos.X, coinPos.Y - 4, coinPos.Z) * CFrame.Angles(math.rad(90), 0, 0) if touchPart:IsA("BasePart") then touchPart.Size = Vector3.new(touchPart.Size.X, 10, touchPart.Size.Z) touchPart.CanCollide = false end else targetCFrame = CFrame.new(coinPos) end smoothTween(targetCFrame) end end end else toggleAnimations(true) _G.ToggleNoClip(false) end end 

end)
if _G.FarmingTab and _G.CombatTab and _G.FlingTab and _G.VisualsTab and _G.Fluent then
_G.FarmingTab:AddToggle("AutoFarmToggle", { Title = "Auto Farm Coins", Default = false, Callback = function(Value) _G.AutoFarmCoins = Value end })
_G.FarmingTab:AddToggle("AvoidMurdererToggle", { Title = "Avoid the Murderer", Default = false, Callback = function(Value) _G.AvoidMurderer = Value end })
_G.FarmingTab:AddToggle("FarmUndergroundToggle", { Title = "Farm Underground (Safe)", Default = false, Callback = function(Value) _G.FarmUnderground = Value end })
_G.FarmingTab:AddToggle("FlingMurdererToggle", { Title = "Fling Murderer when Full", Default = false, Callback = function(Value) _G.FlingMurderer = Value end })

_G.FarmingTab:AddButton({ Title = "Farm Speed -", Callback = function() _G.FarmSpeed = math.max(10, _G.FarmSpeed - 5) _G.Fluent:Notify({ Title = "Speed", Content = tostring(_G.FarmSpeed), Duration = 1 }) end }) _G.FarmingTab:AddButton({ Title = "Farm Speed +", Callback = function() _G.FarmSpeed = math.min(150, _G.FarmSpeed + 5) _G.Fluent:Notify({ Title = "Speed", Content = tostring(_G.FarmSpeed), Duration = 1 }) end }) _G.FarmingTab:AddButton({ Title = "Safe Distance -", Callback = function() _G.SafeDistance = math.max(15, _G.SafeDistance - 5) _G.Fluent:Notify({ Title = "Safe Distance", Content = tostring(_G.SafeDistance) .. " studs", Duration = 1 }) end }) _G.FarmingTab:AddButton({ Title = "Safe Distance +", Callback = function() _G.SafeDistance = math.min(100, _G.SafeDistance + 5) _G.Fluent:Notify({ Title = "Safe Distance", Content = tostring(_G.SafeDistance) .. " studs", Duration = 1 }) end }) _G.CombatTab:AddToggle("AutoGrabGunToggle", { Title = "Auto Grab Gun", Default = false, Callback = function(Value) _G.AutoGrabGun = Value end }) _G.FlingTab:AddButton({ Title = "Fling Murderer", Callback = function() local target = _G.GetMurderer() if target then flingTarget(target) else _G.Fluent:Notify({ Title = "Fling", Content = "Murderer not found", Duration = 3 }) end end }) _G.FlingTab:AddButton({ Title = "Fling Sheriff", Callback = function() local target = _G.GetSheriff() if target then flingTarget(target) else _G.Fluent:Notify({ Title = "Fling", Content = "Sheriff not found", Duration = 3 }) end end }) _G.FlingTab:AddButton({ Title = "Fling Hero", Callback = function() local target = _G.GetHero() if target then flingTarget(target) else _G.Fluent:Notify({ Title = "Fling", Content = "Hero not found", Duration = 3 }) end end }) _G.SkinsTab:AddToggle("SkinChangerToggle", { Title = "Enable Visual Godly", Default = false, Callback = function(Value) _G.VisualSkinChanger = Value end }) _G.SkinsTab:AddDropdown("KnifeDropdown", { Title = "Select Visual Knife", Values = {"Default", "Nik's Scythe", "Traveler's Axe", "Celestial", "Vampire's Axe", "Emberscythe", "Icebreaker", "Batwing", "Elderwood Scythe", "Hallowscythe", "Logchopper"}, Default = "Default", Callback = function(Value) _G.SelectedKnifeSkin = Value _G.Fluent:Notify({ Title = "Skin Changer", Content = "Equipped Status: " .. Value, Duration = 2 }) end }) _G.SkinsTab:AddDropdown("GunDropdown", { Title = "Select Visual Gun", Values = {"Default", "Gingerscope", "Emberbow", "Harvester", "Icepiercer"}, Default = "Default", Callback = function(Value) _G.SelectedGunSkin = Value _G.Fluent:Notify({ Title = "Skin Changer", Content = "Equipped Status: " .. Value, Duration = 2 }) end }) _G.VisualsTab:AddToggle("CoinsESPToggle", { Title = "ESP Candy/Coins (Orange)", Default = false, Callback = function(Value) _G.CoinsESP = Value end }) _G.VisualsTab:AddToggle("MurderESPToggle", { Title = "ESP Murderer (Red)", Default = false, Callback = function(Value) _G.MurderESP = Value end }) _G.VisualsTab:AddToggle("SheriffESPToggle", { Title = "ESP Sheriff (Blue)", Default = false, Callback = function(Value) _G.SheriffESP = Value end }) _G.VisualsTab:AddToggle("InnocentESPToggle", { Title = "ESP Innocents (Green)", Default = false, Callback = function(Value) _G.InnocentESP = Value end }) _G.VisualsTab:AddToggle("HeroESPToggle", { Title = "ESP Hero (Yellow)", Default = false, Callback = function(Value) _G.HeroESP = Value end }) _G.Window:SelectTab(1) _G.Fluent:Notify({ Title = "MM2 Menu", Content = "Interface successfully connected to all modules!", Duration = 5 }) 

end

