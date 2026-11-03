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
local VisualsTab = Window:CreateTab("Visuals", 4483362458)

local autoFarmCandy = false
local farmUnderground = false
local stopWhenFull = false
local flingMurderOnFull = false
local killAllWhenFull = false
local antiFlingEnabled = false
local autoGrabGunEnabled = false
local currentSpeed = 1

local espPlayersEnabled = false
local espCoinsEnabled = false

local activeTween = nil
local activeFarmRoutine = nil

local function executeFlingOnTarget(targetType)
task.spawn(function()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local character = player.Character

if not character or not character:FindFirstChild("HumanoidRootPart") then return end local root = character.HumanoidRootPart local originalCFrame = root.CFrame local targetRoot = nil local targetChar = nil for _, p in ipairs(Players:GetPlayers()) do if p ~= player and p.Character then local backpack = p:FindFirstChild("Backpack") local char = p.Character local isKnife = (backpack and backpack:FindFirstChild("Knife")) or char:FindFirstChild("Knife") local isGun = (backpack and backpack:FindFirstChild("Gun")) or char:FindFirstChild("Gun") if targetType == "Murder" and isKnife then if char:FindFirstChild("HumanoidRootPart") then targetChar = char targetRoot = char.HumanoidRootPart break end elseif targetType == "Sheriff" and isGun then if char:FindFirstChild("HumanoidRootPart") then targetChar = char targetRoot = char.HumanoidRootPart break end end end end if targetRoot and targetChar then local startTime = tick() local connection connection = RunService.RenderStepped:Connect(function() if not character or not character:FindFirstChild("HumanoidRootPart") or not targetRoot or not targetRoot.Parent then if connection then connection:Disconnect() end return end for _, part in ipairs(targetChar:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide = true end end local randomOffset = CFrame.new(math.random(-3, 3), math.random(-3, 3), math.random(-3, 3)) root.CFrame = targetRoot.CFrame * randomOffset root.AssemblyLinearVelocity = Vector3.new(0, 500000, 0) root.AssemblyAngularVelocity = Vector3.new(99999, 99999, 99999) targetRoot.AssemblyLinearVelocity = Vector3.new(math.random(-50000, 50000), -500000, math.random(-50000, 50000)) targetRoot.AssemblyAngularVelocity = Vector3.new(99999, 99999, 99999) if tick() - startTime > 1.5 then if connection then connection:Disconnect() end root.AssemblyLinearVelocity = Vector3.new(0, 0, 0) root.AssemblyAngularVelocity = Vector3.new(0, 0, 0) root.CFrame = originalCFrame end end) end 

end)
end

FarmingTab:CreateToggle({
Name = "Auto Farm Candy",
CurrentValue = false,
Flag = "AutoFarmCandyToggle",
Callback = function(Value)
autoFarmCandy = Value
if autoFarmCandy then
if activeFarmRoutine then return end
activeFarmRoutine = task.spawn(function()
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

while autoFarmCandy do pcall(function() for _, child in ipairs(Workspace:GetChildren()) do local container = child:FindFirstChild("CoinContainer") if container then for _, coinModel in ipairs(container:GetChildren()) do if not autoFarmCandy then break end if coinModel.Name == "Coin_Server" and player.Character then local root = player.Character:FindFirstChild("HumanoidRootPart") local visual = coinModel:FindFirstChild("CoinVisual") if root and visual and visual:IsA("BasePart") then local targetCFrame = visual.CFrame if farmUnderground then targetCFrame = visual.CFrame * CFrame.new(0, -3.5, 0) * CFrame.Angles(math.rad(90), 0, 0) end if farmUnderground or math.abs(root.Position.Y - visual.Position.Y) < 30 then local distance = (root.Position - targetCFrame.Position).Magnitude local flySpeed = math.clamp(currentSpeed * 4, 10, 200) local tweenTime = distance / flySpeed local tweenInfo = TweenInfo.new(tweenTime, Enum.EasingStyle.Linear) activeTween = TweenService:Create(root, tweenInfo, {CFrame = targetCFrame}) activeTween:Play() activeTween.Completed:Wait() activeTween = nil task.wait(0.2) end end end end end end end) task.wait(0.5) end activeFarmRoutine = nil end) else if activeTween then activeTween:Cancel() activeTween = nil end activeFarmRoutine = nil end 

end,
})

FarmingTab:CreateToggle({
Name = "Farm Candies Underground",
CurrentValue = false,
Flag = "FarmUndergroundToggle",
Callback = function(Value)
farmUnderground = Value
end,
})

FarmingTab:CreateSlider({
Name = "Farm Speed",
Range = {1, 50},
Increment = 1,
Suffix = "x",
CurrentValue = 1,
Flag = "FarmSpeedSlider",
Callback = function(Value)
currentSpeed = Value
end,
})

FarmingTab:CreateToggle({
Name = "Anti-Fling Protection",
CurrentValue = false,
Flag = "AntiFlingToggle",
Callback = function(Value)
antiFlingEnabled = Value
end,
})

task.spawn(function()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

RunService.Stepped:Connect(function()
if not antiFlingEnabled then return end

pcall(function() local character = player.Character if character then local root = character:FindFirstChild("HumanoidRootPart") if root then if root.AssemblyLinearVelocity.Magnitude > 75 then root.AssemblyLinearVelocity = Vector3.new(0, 0, 0) root.AssemblyAngularVelocity = Vector3.new(0, 0, 0) end for _, p in ipairs(Players:GetPlayers()) do if p ~= player and p.Character then for _, part in ipairs(p.Character:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide = false end end end end end end end) 

end)
end)

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

while autoGrabGunEnabled do pcall(function() local gunDrop = Workspace:FindFirstChild("GunDrop") if gunDrop and player.Character then local backpack = player:FindFirstChild("Backpack") local hasGun = (backpack and backpack:FindFirstChild("Gun")) or player.Character:FindFirstChild("Gun") if not hasGun then local handle = gunDrop:FindFirstChild("Handle") or gunDrop:FindFirstChild("Part") or gunDrop if handle and handle:IsA("BasePart") then local character = player.Character local hrp = character:FindFirstChild("HumanoidRootPart") local originalCFrame = hrp and hrp.CFrame if hrp then hrp.CFrame = handle.CFrame task.wait(0.15) if originalCFrame then hrp.CFrame = originalCFrame end end end end end end) task.wait(0.5) end end) end 

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

FarmingTab:CreateToggle({
Name = "Stop Farm When Bag Is Full",
CurrentValue = false,
Flag = "StopWhenFullToggle",
Callback = function(Value)
stopWhenFull = Value
if stopWhenFull then
task.spawn(function()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

while stopWhenFull do pcall(function() local reachedLimit = false local leaderstats = player:FindFirstChild("leaderstats") if leaderstats then local candyStat = leaderstats:FindFirstChild("Candy") or leaderstats:FindFirstChild("Coins") if candyStat and candyStat.Value >= 50 then reachedLimit = true end end local playerGui = player:FindFirstChild("PlayerGui") local mainGui = playerGui and playerGui:FindFirstChild("MainGUI") local gameFrame = mainGui and mainGui:FindFirstChild("Game") local coinBags = gameFrame and gameFrame:FindFirstChild("CoinBags") if coinBags then local candyBag = coinBags:FindFirstChild("Candy", true) local fullIcon = candyBag and candyBag:FindFirstChild("FullBagIcon") if fullIcon and fullIcon.Visible then reachedLimit = true end end if reachedLimit then autoFarmCandy = false if activeTween then activeTween:Cancel() activeTween = nil end local character = player.Character local backpack = player:FindFirstChild("Backpack") local isLocalMurderer = (backpack and backpack:FindFirstChild("Knife")) or (character and character:FindFirstChild("Knife")) if killAllWhenFull and isLocalMurderer then local root = character and character:FindFirstChild("HumanoidRootPart") if root then local originalCFrame = root.CFrame local knife = (backpack and backpack:FindFirstChild("Knife")) or (character and character:FindFirstChild("Knife")) if knife then knife.Parent = character end for _, p in ipairs(Players:GetPlayers()) do if p ~= player and p.Character then local targetChar = p.Character local targetRoot = targetChar:FindFirstChild("HumanoidRootPart") local targetHum = targetChar:FindFirstChild("Humanoid") if targetRoot and targetHum and targetHum.Health > 0 then root.CFrame = targetRoot.CFrame task.wait(0.03) if knife then pcall(function() knife:Activate() end) end end end end task.wait(0.1) root.CFrame = originalCFrame end elseif flingMurderOnFull then executeFlingOnTarget("Murder") end task.wait(5) end end) task.wait(1) end end) end 

end,
})

FlingTab:CreateButton({
Name = "Fling Murder",
Callback = function()
executeFlingOnTarget("Murder")
end,
})

FlingTab:CreateButton({
Name = "Fling Sheriff",
Callback = function()
executeFlingOnTarget("Sheriff")
end,
})

VisualsTab:CreateToggle({
Name = "Player ESP (Role Colors)",
CurrentValue = false,
Flag = "PlayerESPToggle",
Callback = function(Value)
espPlayersEnabled = Value
if espPlayersEnabled then
task.spawn(function()
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local player = Players.LocalPlayer

local originalSheriff = nil local lastRoundTimer = nil while espPlayersEnabled do pcall(function() local roundTimer = nil local playerGui = player:FindFirstChild("PlayerGui") local mainGui = playerGui and playerGui:FindFirstChild("MainGUI") local gameFrame = mainGui and mainGui:FindFirstChild("Game") local timerLabel = gameFrame and (gameFrame:FindFirstChild("Timer", true) or gameFrame:FindFirstChild("TimerLabel", true)) if timerLabel then roundTimer = timerLabel.Text end if lastRoundTimer ~= roundTimer then lastRoundTimer = roundTimer originalSheriff = nil end if not originalSheriff then for _, p in ipairs(Players:GetPlayers()) do if p ~= player and p.Character then local backpack = p:FindFirstChild("Backpack") local char = p.Character if (backpack and backpack:FindFirstChild("Gun")) or char:FindFirstChild("Gun") then originalSheriff = p break end end end end for _, p in ipairs(Players:GetPlayers()) do if p ~= player and p.Character then local char = p.Character local highlight = char:FindFirstChild("ESPHighlight") if not highlight then highlight = Instance.new("Highlight") highlight.Name = "ESPHighlight" highlight.FillTransparency = 0.5 highlight.OutlineTransparency = 0 highlight.Parent = char end local backpack = p:FindFirstChild("Backpack") local isMurderer = (backpack and backpack:FindFirstChild("Knife")) or char:FindFirstChild("Knife") local hasGun = (backpack and backpack:FindFirstChild("Gun")) or char:FindFirstChild("Gun") if isMurderer then highlight.FillColor = Color3.fromRGB(255, 0, 0) highlight.OutlineColor = Color3.fromRGB(150, 0, 0) elseif hasGun then if originalSheriff and p == originalSheriff then highlight.FillColor = Color3.fromRGB(0, 100, 255) highlight.OutlineColor = Color3.fromRGB(0, 50, 150) else highlight.FillColor = Color3.fromRGB(255, 255, 0) highlight.OutlineColor = Color3.fromRGB(200, 200, 0) end else highlight.FillColor = Color3.fromRGB(0, 255, 0) highlight.OutlineColor = Color3.fromRGB(0, 150, 0) end end end end) task.wait(1) end for _, p in ipairs(Players:GetPlayers()) do if p.Character and p.Character:FindFirstChild("ESPHighlight") then p.Character.ESPHighlight:Destroy() end end end) end 

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

while espCoinsEnabled do pcall(function() for _, child in ipairs(Workspace:GetChildren()) do local container = child:FindFirstChild("CoinContainer") if container then for _, coinModel in ipairs(container:GetChildren()) do if coinModel.Name == "Coin_Server" then local visual = coinModel:FindFirstChild("CoinVisual") if visual and not visual:FindFirstChild("CoinHighlight") then local highlight = Instance.new("Highlight") highlight.Name = "CoinHighlight" highlight.FillColor = Color3.fromRGB(255, 215, 0) highlight.OutlineColor = Color3.fromRGB(255, 140, 0) highlight.FillTransparency = 0.4 highlight.Parent = visual end end end end end end) task.wait(1) end for _, child in ipairs(Workspace:GetChildren()) do local container = child:FindFirstChild("CoinContainer") if container then for _, coinModel in ipairs(container:GetChildren()) do local visual = coinModel:FindFirstChild("CoinVisual") if visual and visual:FindFirstChild("CoinHighlight") then visual.CoinHighlight:Destroy() end end end end end) end 

end,
})

