local Fluent = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
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
Title = "MM2 Premium Hub",
SubTitle = "v5.1 Split Part 1",
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
_G.CasesTab = _G.Window:AddTab({ Title = "Cases", Icon = "package" })

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

_G.FindCoinContainer = function()
for _, child in ipairs(Workspace:GetChildren()) do
local container = child:FindFirstChild("CoinContainer") or child:FindFirstChild("coinContainer")
if container then return container end
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

local function getRole(player)
if not player then return "Innocent" end
if player:FindFirstChild("Backpack") and player.Backpack:FindFirstChild("Knife") then return "Murderer" end
if player.Character and player.Character:FindFirstChild("Knife") then return "Murderer" end

local playerData = player:FindFirstChild("PlayerData") or (ReplicatedStorage:FindFirstChild("PlayerData") and ReplicatedStorage.PlayerData:FindFirstChild(player.Name)) if playerData and playerData:FindFirstChild("Role") then if playerData.Role.Value == "Sheriff" then return "Sheriff" elseif playerData.Role.Value == "Murderer" then return "Murderer" end end if _G.CurrentHeroName and player.Name == _G.CurrentHeroName then return "Hero" end local hasGun = (player:FindFirstChild("Backpack") and player.Backpack:FindFirstChild("Gun")) or (player.Character and player.Character:FindFirstChild("Gun")) if hasGun and not hasGun:FindFirstChild("Innocent") then return "Sheriff" end return "Innocent" 

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
["Gingerscope"] = {Mesh = "rbxassetid://15682855140", Texture = "rbxassetid://15682857038", Sound = "rbxassetid://98146868591104", Image = "rbxassetid://15666596216"},
["Emberbow"] = {Mesh = "rbxassetid://15545648110", Texture = "rbxassetid://15545648505", Sound = "rbxassetid://15545691033", Image = "rbxassetid://15545649110"},
["Harvester"] = {Mesh = "rbxassetid://7653024844", Texture = "rbxassetid://7653025110", Sound = "rbxassetid://7653031022", Image = "rbxassetid://7653026005"},
["Icepiercer"] = {Mesh = "rbxassetid://11689230552", Texture = "rbxassetid://11689230894", Sound = "rbxassetid://11689240112", Image = "rbxassetid://11689231508"}
}

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

local function flingTarget(targetPlayer)
if not targetPlayer or not targetPlayer.Character then return end
local character = LocalPlayer.Character
local myRoot = character and character:FindFirstChild("HumanoidRootPart")
local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
local targetHum = targetPlayer.Character:FindFirstChildOfClass("Humanoid")

if myRoot and targetRoot and targetRoot.Parent then local oldCFrame = myRoot.CFrame _G.ToggleNoClip(true) local bavg = Instance.new("BodyAngularVelocity") bavg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge) bavg.AngularVelocity = Vector3.new(0, 200000, 0) bavg.Parent = myRoot local startTime = tick() local heartbeatConnection heartbeatConnection = RunService.Heartbeat:Connect(function() if targetRoot and targetRoot.Parent and (tick() - startTime < 2.0) then myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, -0.5, 0) targetRoot.AssemblyLinearVelocity = Vector3.new(math.random(-5000, 5000), -10000, math.random(-5000, 5000)) myRoot.AssemblyLinearVelocity = Vector3.new(0, -5000, 0) if targetHum then targetHum:ChangeState(Enum.HumanoidStateType.Ragdoll) end else if heartbeatConnection then heartbeatConnection:Disconnect() heartbeatConnection = nil end end end) while tick() - startTime < 2.0 and targetRoot and targetRoot.Parent do task.wait(0.05) end if heartbeatConnection then heartbeatConnection:Disconnect() end bavg:Destroy() myRoot.AssemblyLinearVelocity = Vector3.new(0,0,0) myRoot.AssemblyAngularVelocity = Vector3.new(0,0,0) myRoot.CFrame = oldCFrame end 

end

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
_G.VisualSkinChanger = false
_G.SelectedKnifeSkin = "Default"
_G.SelectedGunSkin = "Default"

local cachedAnimationTracks = {}
local function applyCustomAnimation(humanoid, animationId)
if not humanoid or not humanoid:FindFirstChildOfClass("Animator") then return end
local animator = humanoid:FindFirstChildOfClass("Animator")

if not cachedAnimationTracks[animationId] then local anim = Instance.new("Animation") anim.AnimationId = animationId local success, track = pcall(function() return animator:LoadAnimation(anim) end) if success and track then cachedAnimationTracks[animationId] = track end end local track = cachedAnimationTracks[animationId] if track and not track.IsPlaying then track:Play() end 

end

local function saveOriginalSpecs(tool, isKnife)
local meshPart = tool:FindFirstChild("Handle") or tool:FindFirstChildOfClass("MeshPart") or tool:FindFirstChildOfClass("BasePart")
local sound = tool:FindFirstChildOfClass("Sound")
if meshPart then
local data = {
MeshId = meshPart:IsA("MeshPart") and meshPart.MeshId or (meshPart:FindFirstChildOfClass("SpecialMesh") and meshPart:FindFirstChildOfClass("SpecialMesh").MeshId or ""),
TextureId = meshPart:IsA("MeshPart") and meshPart.TextureID or (meshPart:FindFirstChildOfClass("SpecialMesh") and meshPart:FindFirstChildOfClass("SpecialMesh").TextureId or ""),
SoundId = sound and sound.SoundId or ""
}
if isKnife then OriginalKnifeData = data else OriginalGunData = data end
end
end

local function emulateInventoryUI()
local pGui = LocalPlayer:FindFirstChild("PlayerGui")
local mainGui = pGui and pGui:FindFirstChild("MainGUI")
local invGui = mainGui and mainGui:FindFirstChild("Inventory")
local mainPanel = invGui and invGui:FindFirstChild("Main")
local itemsContainer = mainPanel and mainPanel:FindFirstChild("Items")
local scrollingFrame = itemsContainer and itemsContainer:FindFirstChild("ScrollingFrame")

if scrollingFrame then for name, data in pairs(KnifeDatabase) do if not scrollingFrame:FindFirstChild("Visual_" .. name) then local template = scrollingFrame:FindFirstChildOfClass("TextButton") or scrollingFrame:FindFirstChildOfClass("ImageButton") if template then local clone = template:Clone() clone.Name = "Visual_" .. name clone.Visible = true local container = clone:FindFirstChild("Container") local label = container and container:FindFirstChild("ItemName") or clone:FindFirstChildOfClass("TextLabel") if label then label.Text = name end local img = container and container:FindFirstChild("ItemImage") or clone:FindFirstChild("ItemImage") if img then img.Image = data.Image end clone.MouseButton1Click:Connect(function() if _G.VisualSkinChanger then _G.SelectedKnifeSkin = name _G.Fluent:Notify({ Title = "Inventory", Content = "Equipped: " .. name, Duration = 2 }) end end) clone.Parent = scrollingFrame end end end for name, data in pairs(GunDatabase) do if not scrollingFrame:FindFirstChild("Visual_" .. name) then local template = scrollingFrame:FindFirstChildOfClass("TextButton") or scrollingFrame:FindFirstChildOfClass("ImageButton") if template then local clone = template:Clone() clone.Name = "Visual_" .. name clone.Visible = true local container = clone:FindFirstChild("Container") local label = container and container:FindFirstChild("ItemName") or clone:FindFirstChildOfClass("TextLabel") if label then label.Text = name end local img = container and container:FindFirstChild("ItemImage") or clone:FindFirstChild("ItemImage") if img then img.Image = data.Image end clone.MouseButton1Click:Connect(function() if _G.VisualSkinChanger then _G.SelectedGunSkin = name _G.Fluent:Notify({ Title = "Inventory", Content = "Equipped: " .. name, Duration = 2 }) end end) clone.Parent = scrollingFrame end end end end 

end

task.spawn(function()
while task.wait(2) do
if _G.VisualSkinChanger then pcall(emulateInventoryUI) end
end
end)

task.spawn(function()
while task.wait(0.1) do
if _G.VisualSkinChanger and LocalPlayer.Character then
local backpack = LocalPlayer:FindFirstChild("Backpack")
local knife = LocalPlayer.Character:FindFirstChild("Knife") or (backpack and backpack:FindFirstChild("Knife"))
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

local gun = LocalPlayer.Character:FindFirstChild("Gun") or (backpack and backpack:FindFirstChild("Gun")) if gun then if not OriginalGunData then saveOriginalSpecs(gun, false) end local data = (_G.SelectedGunSkin == "Default") and OriginalGunData or GunDatabase[_G.SelectedGunSkin] if data then for _, child in ipairs(gun:GetDescendants()) do if child:IsA("MeshPart") then child.MeshId = data.MeshId or data.Mesh child.TextureID = data.TextureId or data.Texture elseif child:IsA("SpecialMesh") then child.MeshId = data.MeshId or data.Mesh child.TextureId = data.TextureId or data.Texture elseif child:IsA("Sound") then child.SoundId = data.SoundId or data.Sound end end if _G.SelectedGunSkin == "Gingerscope" then local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid") if humanoid then applyCustomAnimation(humanoid, "rbxassetid://15684227091") end end end end end end 

end)

local function smoothTween(targetPosition)
local character = LocalPlayer.Character
local myRoot = character and character:FindFirstChild("HumanoidRootPart")
if not myRoot then return end

local distance = (myRoot.Position - targetPosition).Magnitude if distance < 1 then myRoot.CFrame = CFrame.new(targetPosition) return end local speed = math.max(15, _G.FarmSpeed) local duration = distance / speed local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut) local tween = TweenService:Create(myRoot, tweenInfo, {CFrame = CFrame.new(targetPosition)}) tween:Play() tween.Completed:Wait() 

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

local character = LocalPlayer.Character local myRoot = character and character:FindFirstChild("HumanoidRootPart") if not myRoot then return nil end local murderer = _G.GetMurderer() local mudRoot = murderer and murderer.Character and murderer.Character:FindFirstChild("HumanoidRootPart") local closestTarget = nil local shortestDistance = math.huge for _, obj in ipairs(coinContainer:GetDescendants()) do if obj:IsA("BasePart") and obj.Name == "CoinVisual" then local coinPos = obj.Position if _G.AvoidMurderer and mudRoot then if (coinPos - mudRoot.Position).Magnitude < _G.SafeDistance then continue end end local dist = (myRoot.Position - coinPos).Magnitude if dist < shortestDistance then shortestDistance = dist closestTarget = obj end end end return closestTarget 

end

task.spawn(function()
while true do
task.wait(0.05)
if not _G.CheckRoundActive or not _G.IsBagFull then continue end

local character = LocalPlayer.Character local myRoot = character and character:FindFirstChild("HumanoidRootPart") local hum = character and character:FindFirstChildOfClass("Humanoid") if _G.CheckRoundActive() and hum and hum.Health > 0 and myRoot then local droppedGun = Workspace:FindFirstChild("GunDrop", true) if _G.AutoGrabGun and droppedGun and droppedGun:IsA("BasePart") then smoothTween(Vector3.new(droppedGun.Position.X, myRoot.Position.Y, droppedGun.Position.Z)) task.wait(0.1) elseif _G.AutoFarmCoins then local murderer = _G.GetMurderer() local mudRoot = murderer and murderer.Character and murderer.Character:FindFirstChild("HumanoidRootPart") if not _G.IsBagFull() and _G.AvoidMurderer and mudRoot and (myRoot.Position - mudRoot.Position).Magnitude < _G.SafeDistance then escapeFromMurderer(myRoot, mudRoot) end if _G.IsBagFull() then if _G.FlingMurderer then if murderer and murderer.Character and murderer.Character:FindFirstChild("HumanoidRootPart") then flingTarget(murderer) task.wait(0.5) else myRoot.AssemblyLinearVelocity = Vector3.new(0,0,0) myRoot.AssemblyAngularVelocity = Vector3.new(0,0,0) if _G.FarmUnderground then myRoot.CFrame = CFrame.new(myRoot.Position.X, -50, myRoot.Position.Z) end task.wait(0.2) end else _G.ToggleNoClip(false) myRoot.AssemblyLinearVelocity = Vector3.new(0,0,0) myRoot.AssemblyAngularVelocity = Vector3.new(0,0,0) task.wait(0.5) end else _G.ToggleNoClip(true) local touchPart = getBestCoin() if touchPart and touchPart.Parent then local coinPos = touchPart.Position local targetPos if _G.FarmUnderground == true then targetPos = Vector3.new(coinPos.X, -50, coinPos.Z) if touchPart:IsA("BasePart") then touchPart.Size = Vector3.new(touchPart.Size.X, 10, touchPart.Size.Z) touchPart.CanCollide = false end else targetPos = Vector3.new(coinPos.X, coinPos.Y, coinPos.Z) end smoothTween(targetPos) end end end else _G.ToggleNoClip(false) end end 

end)

local function showGodlyRewardScreen(wonSkinName, isGun)
local playerGui = LocalPlayer:WaitForChild("PlayerGui")
if playerGui:FindFirstChild("MM2RewardGui") then playerGui.MM2RewardGui:Destroy() end

local rewardGui = Instance.new("ScreenGui") rewardGui.Name = "MM2RewardGui" rewardGui.IgnoreGuiInset = true rewardGui.ResetOnSpawn = false rewardGui.Parent = playerGui local bg = Instance.new("Frame") bg.Size = UDim2.new(1, 0, 1, 0) bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0) bg.BackgroundTransparency = 0.5 bg.BorderSizePixel = 0 bg.Parent = rewardGui local card = Instance.new("Frame") card.Size = UDim2.new(0, 320, 0, 390) card.Position = UDim2.new(0.5, -160, 0.5, -195) card.BackgroundColor3 = Color3.fromRGB(24, 24, 30) card.BorderSizePixel = 0 card.Parent = rewardGui local cCorner = Instance.new("UICorner") cCorner.CornerRadius = UDim.new(0, 8) cCorner.Parent = card local stroke = Instance.new("UIStroke") stroke.Color = Color3.fromRGB(70, 70, 85) stroke.Thickness = 2 stroke.Parent = card local topTitle = Instance.new("TextLabel") topTitle.Size = UDim2.new(1, 0, 0, 35) topTitle.Position = UDim2.new(0, 0, 0, 12) topTitle.BackgroundTransparency = 1 topTitle.Text = "You Got..." topTitle.TextColor3 = Color3.fromRGB(240, 240, 240) topTitle.TextSize = 20 topTitle.Font = Enum.Font.GothamBold topTitle.Parent = card local imagePreview = Instance.new("ImageLabel") imagePreview.Size = UDim2.new(0, 240, 0, 160) imagePreview.Position = UDim2.new(0.5, -120, 0, 55) imagePreview.BackgroundTransparency = 1 local itemData = isGun and GunDatabase[wonSkinName] or KnifeDatabase[wonSkinName] imagePreview.Image = itemData and itemData.Image or "" imagePreview.ScaleType = Enum.ScaleType.Fit imagePreview.Parent = card local purpleBar = Instance.new("Frame") purpleBar.Size = UDim2.new(1, -24, 0, 50) purpleBar.Position = UDim2.new(0, 12, 0, 230) purpleBar.BackgroundColor3 = Color3.fromRGB(130, 20, 235) purpleBar.BorderSizePixel = 0 purpleBar.Parent = card local pCorner = Instance.new("UICorner") pCorner.CornerRadius = UDim.new(0, 6) pCorner.Parent = purpleBar local nameLabel = Instance.new("TextLabel") nameLabel.Size = UDim2.new(1, 0, 1, 0) nameLabel.BackgroundTransparency = 1 nameLabel.Text = wonSkinName nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255) nameLabel.TextSize = 20 nameLabel.Font = Enum.Font.GothamBold nameLabel.Parent = purpleBar local claimBtn = Instance.new("TextButton") claimBtn.Size = UDim2.new(1, -24, 0, 48) claimBtn.Position = UDim2.new(0, 12, 1, -65) claimBtn.BackgroundColor3 = Color3.fromRGB(30, 144, 255) claimBtn.Text = "Claim" claimBtn.TextColor3 = Color3.fromRGB(255, 255, 255) claimBtn.TextSize = 18 claimBtn.Font = Enum.Font.GothamBold claimBtn.Parent = card local bCorner = Instance.new("UICorner") bCorner.CornerRadius = UDim.new(0, 6) bCorner.Parent = claimBtn claimBtn.MouseButton1Click:Connect(function() if isGun then _G.SelectedGunSkin = wonSkinName else _G.SelectedKnifeSkin = wonSkinName end rewardGui:Destroy() _G.Fluent:Notify({ Title = "Success!", Content = wonSkinName .. " added to inventory and equipped!", Duration = 3 }) end) 

end

local function playCaseOpeningRoulette(wonSkinName, isGun)
local playerGui = LocalPlayer:WaitForChild("PlayerGui")
if playerGui:FindFirstChild("MM2RouletteGui") then playerGui.MM2RouletteGui:Destroy() end

local rouletteGui = Instance.new("ScreenGui") rouletteGui.Name = "MM2RouletteGui" rouletteGui.IgnoreGuiInset = true rouletteGui.ResetOnSpawn = false rouletteGui.Parent = playerGui local bg = Instance.new("Frame") bg.Size = UDim2.new(1, 0, 1, 0) bg.BackgroundColor3 = Color3.fromRGB(10, 10, 15) bg.BackgroundTransparency = 0.3 bg.BorderSizePixel = 0 bg.Parent = rouletteGui local container = Instance.new("Frame") container.Size = UDim2.new(0, 600, 0, 160) container.Position = UDim2.new(0.5, -300, 0.5, -80) container.BackgroundColor3 = Color3.fromRGB(25, 25, 32) container.BorderSizePixel = 0 container.ClipsDescendants = true container.Parent = rouletteGui local corner = Instance.new("UICorner") corner.CornerRadius = UDim.new(0, 8) corner.Parent = container local stroke = Instance.new("UIStroke") stroke.Color = Color3.fromRGB(70, 70, 90) stroke.Thickness = 2 stroke.Parent = container local scrollingStrip = Instance.new("ScrollingFrame") scrollingStrip.Size = UDim2.new(1, 0, 1, 0) scrollingStrip.BackgroundTransparency = 1 scrollingStrip.BorderSizePixel = 0 scrollingStrip.CanvasSize = UDim2.new(0, 5000, 0, 160) scrollingStrip.ScrollBarThickness = 0 scrollingStrip.ScrollingEnabled = false scrollingStrip.Parent = container local listLayout = Instance.new("UIListLayout") listLayout.FillDirection = Enum.FillDirection.Horizontal listLayout.SortOrder = Enum.SortOrder.LayoutOrder listLayout.Padding = UDim.new(0, 6) listLayout.Parent = scrollingStrip local allSkinsPool = {} for k, _ in pairs(KnifeDatabase) do table.insert(allSkinsPool, {Name = k}) end for k, _ in pairs(GunDatabase) do table.insert(allSkinsPool, {Name = k}) end local generatedCards = {} for i = 1, 40 do local randData = allSkinsPool[math.random(1, #allSkinsPool)] if i == 28 then randData = {Name = wonSkinName} -- Гарантоване випадіння потрібного скіна end table.insert(generatedCards, randData) end for index, data in ipairs(generatedCards) do local card = Instance.new("Frame") card.Size = UDim2.new(0, 130, 0, 140) card.BackgroundColor3 = Color3.fromRGB(35, 35, 45) card.BorderSizePixel = 0 card.LayoutOrder = index card.Parent = scrollingStrip local cCorner = Instance.new("UICorner") cCorner.CornerRadius = UDim.new(0, 6) cCorner.Parent = card local label = Instance.new("TextLabel") label.Size = UDim2.new(1, -10, 0, 35) label.Position = UDim2.new(0, 5, 1, -40) label.BackgroundTransparency = 1 label.Text = data.Name label.TextColor3 = Color3.fromRGB(255, 255, 255) label.TextSize = 12 label.Font = Enum.Font.GothamBold label.TextWrapped = true label.Parent = card end local centerLine = Instance.new("Frame") centerLine.Size = UDim2.new(0, 4, 1, 0) centerLine.Position = UDim2.new(0.5, -2, 0, 0) centerLine.BackgroundColor3 = Color3.fromRGB(255, 200, 0) centerLine.BorderSizePixel = 0 centerLine.ZIndex = 10 centerLine.Parent = container local clickSound = Instance.new("Sound") clickSound.SoundId = "rbxassetid://9114223191" clickSound.Volume = 0.5 clickSound.Parent = rouletteGui local targetCanvasPos = Vector2.new(3672 - (600 / 2) + 65, 0) local tweenInfo = TweenInfo.new(4.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out) local tween = TweenService:Create(scrollingStrip, tweenInfo, {CanvasPosition = targetCanvasPos}) tween:Play() task.spawn(function() local lastX = -1 while tween.PlaybackState == Enum.PlaybackState.Playing do task.wait(0.05) local currentX = math.floor(scrollingStrip.CanvasPosition.X / 136) if currentX ~= lastX then lastX = currentX pcall(function() clickSound:Play() end) end end end) tween.Completed:Wait() task.wait(0.3) rouletteGui:Destroy() showGodlyRewardScreen(wonSkinName, isGun) 

end

if _G.FarmingTab and _G.CombatTab and _G.FlingTab and _G.VisualsTab and _G.CasesTab and _G.Fluent then
_G.FarmingTab:AddToggle("AutoFarmToggle", { Title = "Auto Farm Coins", Default = false, Callback = function(Value) _G.AutoFarmCoins = Value end })
_G.FarmingTab:AddToggle("AvoidMurdererToggle", { Title = "Avoid the Murderer", Default = false, Callback = function(Value) _G.AvoidMurderer = Value end })
_G.FarmingTab:AddToggle("FarmUndergroundToggle", { Title = "Farm Underground (Safe)", Default = false, Callback = function(Value) _G.FarmUnderground = Value end })
_G.FarmingTab:AddToggle("FlingMurdererToggle", { Title = "Fling Murderer when Full", Default = false, Callback = function(Value) _G.FlingMurderer = Value end })

_G.FarmingTab:AddButton({ Title = "Farm Speed -", Callback = function() _G.FarmSpeed = math.max(10, _G.FarmSpeed - 5) _G.Fluent:Notify({ Title = "Speed", Content = tostring(_G.FarmSpeed), Duration = 1 }) end }) _G.FarmingTab:AddButton({ Title = "Farm Speed +", Callback = function() _G.FarmSpeed = math.min(150, _G.FarmSpeed + 5) _G.Fluent:Notify({ Title = "Speed", Content = tostring(_G.FarmSpeed), Duration = 1 }) end }) _G.FarmingTab:AddButton({ Title = "Safe Distance -", Callback = function() _G.SafeDistance = math.max(15, _G.SafeDistance - 5) _G.Fluent:Notify({ Title = "Safe Distance", Content = tostring(_G.SafeDistance) .. " studs", Duration = 1 }) end }) _G.FarmingTab:AddButton({ Title = "Safe Distance +", Callback = function() _G.SafeDistance = math.min(100, _G.SafeDistance + 5) _G.Fluent:Notify({ Title = "Safe Distance", Content = tostring(_G.SafeDistance) .. " studs", Duration = 1 }) end }) _G.CombatTab:AddToggle("AutoGrabGunToggle", { Title = "Auto Grab Gun", Default = false, Callback = function(Value) _G.AutoGrabGun = Value end }) _G.FlingTab:AddButton({ Title = "Fling Murderer", Callback = function() local target = _G.GetMurderer() if target then flingTarget(target) else _G.Fluent:Notify({ Title = "Fling", Content = "Murderer not found", Duration = 3 }) end end }) _G.FlingTab:AddButton({ Title = "Fling Sheriff", Callback = function() local target = _G.GetSheriff() if target then flingTarget(target) else _G.Fluent:Notify({ Title = "Fling", Content = "Sheriff not found", Duration = 3 }) end end }) _G.FlingTab:AddButton({ Title = "Fling Hero", Callback = function() local target = _G.GetHero() if target then flingTarget(target) else _G.Fluent:Notify({ Title = "Fling", Content = "Hero not found", Duration = 3 }) end end }) _G.SkinsTab:AddToggle("SkinChangerToggle", { Title = "Enable Visual Godly", Default = false, Callback = function(Value) _G.VisualSkinChanger = Value end }) _G.SkinsTab:AddDropdown("KnifeDropdown", { Title = "Select Visual Knife", Values = {"Default", "Nik's Scythe", "Traveler's Axe", "Celestial", "Vampire's Axe", "Emberscythe", "Icebreaker", "Batwing", "Elderwood Scythe", "Hallowscythe", "Logchopper"}, Default = "Default", Callback = function(Value) _G.SelectedKnifeSkin = Value _G.Fluent:Notify({ Title = "Skin Changer", Content = "Equipped: " .. Value, Duration = 2 }) end }) _G.SkinsTab:AddDropdown("GunDropdown", { Title = "Select Visual Gun", Values = {"Default", "Gingerscope", "Emberbow", "Harvester", "Icepiercer"}, Default = "Default", Callback = function(Value) _G.SelectedGunSkin = Value _G.Fluent:Notify({ Title = "Skin Changer", Content = "Equipped: " .. Value, Duration = 2 }) end }) _G.CasesTab:AddParagraph({ Title = "Godly Case Opening", Content = "Open cases with a roulette and You Got... screen to win Godly skins!" }) _G.CasesTab:AddButton({ Title = "Open Gingerscope Box", Callback = function() playCaseOpeningRoulette("Gingerscope", true) end }) _G.CasesTab:AddButton({ Title = "Open Random Godly Box", Callback = function() local allGodlies = { "Nik's Scythe", "Traveler's Axe", "Celestial", "Vampire's Axe", "Emberscythe", "Icebreaker", "Batwing", "Elderwood Scythe", "Hallowscythe", "Logchopper", "Gingerscope", "Emberbow", "Harvester", "Icepiercer" } math.randomseed(tick()) local wonSkin = allGodlies[math.random(1, #allGodlies)] local isGun = string.find(wonSkin, "Gingerscope") or string.find(wonSkin, "Emberbow") or string.find(wonSkin, "Harvester") or string.find(wonSkin, "Icepiercer") playCaseOpeningRoulette(wonSkin, isGun) end }) _G.VisualsTab:AddToggle("CoinsESPToggle", { Title = "ESP Candy/Coins (Orange)", Default = false, Callback = function(Value) _G.CoinsESP = Value end }) _G.VisualsTab:AddToggle("MurderESPToggle", { Title = "ESP Murderer (Red)", Default = false, Callback = function(Value) _G.MurderESP = Value end }) _G.VisualsTab:AddToggle("SheriffESPToggle", { Title = "ESP Sheriff (Blue)", Default = false, Callback = function(Value) _G.SheriffESP = Value end }) _G.VisualsTab:AddToggle("InnocentESPToggle", { Title = "ESP Innocents (Green)", Default = false, Callback = function(Value) _G.InnocentESP = Value end }) _G.VisualsTab:AddToggle("HeroESPToggle", { Title = "ESP Hero (Yellow)", Default = false, Callback = function(Value) _G.HeroESP = Value end }) _G.Window:SelectTab(1) _G.Fluent:Notify({ Title = "MM2 Menu", Content = "All systems successfully loaded!", Duration = 5 }) 

end

