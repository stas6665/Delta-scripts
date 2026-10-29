local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Window = Fluent:CreateWindow({
Title = "MM2: Auto Farm Coins",
SubTitle = "v3.9.2 Bag Yeet Fix",
TabWidth = 160,
Size = UDim2.fromOffset(580, 460),
Acrylic = false,
Theme = "Darker",
MinimizeKey = Enum.KeyCode.Minus
})

local _G = getgenv and getgenv() or _G
_G.AutoFarmCoins = false
_G.FarmUnderground = false
_G.FarmSpeed = 25

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")

local collectedCoins = {}

LocalPlayer.Idled:Connect(function()
VirtualUser:CaptureController()
VirtualUser:ClickButton2(Vector2.new())
end)

local noclipConnection
local function toggleNoClip(enable)
if enable then
if not noclipConnection then
noclipConnection = RunService.Stepped:Connect(function()
local character = LocalPlayer.Character
if character then
for _, part in ipairs(character:GetDescendants()) do
if part:IsA("BasePart") then
part.CanCollide = false
end
end
end
end)
end
elseif noclipConnection then
noclipConnection:Disconnect()
noclipConnection = nil
end
end

local function isBagFull()
local mainGui = LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("MainGui")
local gameGui = mainGui and mainGui:FindFirstChild("Game")
local coinBags = gameGui and (gameGui:FindFirstChild("CoinBags") or gameGui:FindFirstChild("CoinBag"))
local coinLabel = coinBags and coinBags:FindFirstChild("Coins")

if coinLabel and coinLabel:IsA("TextLabel") then local current = coinLabel.Text:match("^(%d+)") if current then return math.floor(tonumber(current)) >= 50 end end return false 

end

local function yeetMurderer()
local murderer = nil
for _, p in ipairs(Players:GetPlayers()) do
if p ~= LocalPlayer and p.Character then
local backpack = p:FindFirstChild("Backpack")
if (backpack and backpack:FindFirstChild("Knife")) or p.Character:FindFirstChild("Knife") then
murderer = p
break
end
end
end

if not murderer or not murderer.Character then return end local myCharacter = LocalPlayer.Character local myRoot = myCharacter and myCharacter:FindFirstChild("HumanoidRootPart") local mRoot = murderer.Character:FindFirstChild("HumanoidRootPart") if not myRoot or not mRoot then return end toggleNoClip(true) myRoot.CFrame = mRoot.CFrame * CFrame.new(0, 0, 1.5) task.wait(0.1) if mRoot and mRoot.Parent then local bV = Instance.new("BodyVelocity") bV.MaxForce = Vector3.new(1e9, 1e9, 1e9) bV.Velocity = Vector3.new(0, -5000, 0) bV.Parent = mRoot game:GetService("Debris"):AddItem(bV, 2) end task.wait(0.2) if myRoot then myRoot.CFrame = CFrame.new(0, 500, 0) end task.wait(1.5) 

end

local function findCoinContainer()
for _, obj in ipairs(workspace:GetDescendants()) do
if obj.Name == "CoinContainer" and obj:IsA("Folder") then
return obj
end
end
return nil
end

local function getClosestCoin()
local coinContainer = findCoinContainer()
if not coinContainer then return nil end

local character = LocalPlayer.Character local myRoot = character and character:FindFirstChild("HumanoidRootPart") if not myRoot then return nil end local closestCoinModel = nil local shortestDistance = math.huge for _, coinModel in ipairs(coinContainer:GetChildren()) do if coinModel.Name == "Coin_Server" and not collectedCoins[coinModel] then local touchPart = coinModel:FindFirstChild("CoinVisual") or coinModel:FindFirstChildWhichIsA("BasePart") if touchPart then local distance = (myRoot.Position - touchPart.Position).Magnitude if distance < shortestDistance then shortestDistance = distance closestCoinModel = coinModel end end end end return closestCoinModel 

end

workspace.ChildAdded:Connect(function(child)
if child.Name == "Normal" or child.Name == "Innocent" then
table.clear(collectedCoins)
end
end)

task.spawn(function()
while true do
task.wait(0.05)

if _G.AutoFarmCoins then if not isBagFull() then local targetCoinModel = getClosestCoin() if targetCoinModel and targetCoinModel.Parent then local character = LocalPlayer.Character local myRoot = character and character:FindFirstChild("HumanoidRootPart") local touchPart = targetCoinModel:FindFirstChild("CoinVisual") or targetCoinModel:FindFirstChildWhichIsA("BasePart") if myRoot and touchPart then toggleNoClip(true) local targetCFrame = touchPart.CFrame if _G.FarmUnderground then targetCFrame = touchPart.CFrame * CFrame.new(0, -6, 0) end local distance = (myRoot.Position - targetCFrame.Position).Magnitude local duration = distance / math.max(_G.FarmSpeed, 1) local tween = TweenService:Create( myRoot, TweenInfo.new(duration, Enum.EasingStyle.Linear), {CFrame = targetCFrame} ) tween:Play() while tween.PlaybackState == Enum.PlaybackState.Playing and _G.AutoFarmCoins and targetCoinModel.Parent do task.wait(0.02) end if not _G.AutoFarmCoins then tween:Cancel() toggleNoClip(false) else if firetouchinterest and targetCoinModel.Parent and touchPart.Parent then firetouchinterest(myRoot, touchPart, 0) task.wait(0.02) firetouchinterest(myRoot, touchPart, 1) task.wait(0.05) if not targetCoinModel.Parent then collectedCoins[targetCoinModel] = true end end end end else task.wait(0.5) end else yeetMurderer() end else toggleNoClip(false) end end 

end)

local FarmingTab = Window:AddTab({ Title = "Coin Farm", Icon = "box" })

FarmingTab:AddToggle("AutoFarmCoinsToggle", {
Title = "Auto Farm Coins / Candy",
Default = false,
Callback = function(Value)
_G.AutoFarmCoins = Value
end
})

FarmingTab:AddToggle("FarmUndergroundToggle", {
Title = "Farm Underground (Safe)",
Default = false,
Callback = function(Value)
_G.FarmUnderground = Value
end
})

local SpeedSlider = FarmingTab:AddSlider("FarmSpeedSlider", {
Title = "Farm Speed",
Min = 15,
Max = 50,
Default = 25,
Rounding = 0,
Callback = function(Value)
_G.FarmSpeed = Value
end
})

pcall(function()
local sliderFrame = SpeedSlider.Frame
local sliderRail = sliderFrame:FindFirstChild("SliderRail", true)

if sliderRail then sliderRail.Size = UDim2.new(1, 0, 0, 14) local uiCorner = sliderRail:FindFirstChildWhichIsA("UICorner") if uiCorner then uiCorner.CornerRadius = UDim.new(0, 7) end local accentBar = sliderRail:FindFirstChildWhichIsA("Frame") if accentBar then accentBar.Size = UDim2.new(accentBar.Size.X.Scale, 0, 1, 0) local barCorner = accentBar:FindFirstChildWhichIsA("UICorner") if barCorner then barCorner.CornerRadius = UDim.new(0, 7) end end local button = sliderRail:FindFirstChildWhichIsA("ImageLabel") if button then button.Size = UDim2.fromOffset(24, 24) end end 

end)





