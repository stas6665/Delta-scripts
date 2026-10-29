local Fluent = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/main.lua"))()

local Window = Fluent:CreateWindow({
Title = "MM2: Dex Fixed Auto Farm",
SubTitle = "v4.2.0 Structure Patch",
TabWidth = 160,
Size = UDim2.fromOffset(580, 460),
Acrylic = false,
Theme = "Darker",
MinimizeKey = Enum.KeyCode.Minus
})

local _G = getgenv and getgenv() or _G
_G.AutoFarmCoins = false
_G.FarmUnderground = false
_G.FarmSpeed = 22 -- Трохи зменшено швидкість, щоб античіт карти не кікав за телепорт

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")

local collectedCoins = {}

-- Anti-AFK
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

if coinLabel and coinLabel:IsA("TextLabel") then local current = coinLabel.Text:match("^(%d+)") if current then return math.floor(tonumber(current)) >= 40 -- Стоїть ліміт 40 для безпеки сумки end end return false 

end

-- НОВА ЛОГІКА: Динамічний пошук папки з монетами відповідно до скріншотів з Dex
local function findCoinContainer()
for _, child in ipairs(workspace:GetChildren()) do
-- Шукаємо активну папку карти (вона зазвичай містить CoinContainer або CoinAreas)
if child:IsA("Folder") and child.Name ~= "PetContainer" and child.Name ~= "WeaponDisplays" then
local container = child:FindFirstChild("CoinContainer") or child:FindFirstChild("CoinAreas") or child:FindFirstChild("CoinFolder")
if container then
return container
end
end
end
-- Запасний варіант, якщо карту завантажено незвично
for _, obj in ipairs(workspace:GetDescendants()) do
if (obj.Name == "CoinContainer" or obj.Name == "CoinAreas") and obj:IsA("Folder") then
return obj
end
end
return nil
end

-- НОВА ЛОГІКА: Пошук найближчої монети за будь-яким ім'ям всередині контейнера
local function getClosestCoin()
local coinContainer = findCoinContainer()
if not coinContainer then return nil end

local character = LocalPlayer.Character local myRoot = character and character:FindFirstChild("HumanoidRootPart") if not myRoot then return nil end local closestCoin = nil local shortestDistance = math.huge -- Перебираємо все, що лежить у CoinContainer / CoinAreas for _, coin in ipairs(coinContainer:GetChildren()) do if not collectedCoins[coin] then -- Монети можуть бути як моделями (Model), так і поодинокими партами (BasePart) local touchPart = coin:IsA("BasePart") and coin or coin:FindFirstChild("CoinVisual") or coin:FindFirstChildWhichIsA("BasePart") if touchPart then local distance = (myRoot.Position - touchPart.Position).Magnitude if distance < shortestDistance then shortestDistance = distance closestCoin = coin end end end end return closestCoin 

end

workspace.ChildAdded:Connect(function(child)
if child:IsA("Folder") then
table.clear(collectedCoins)
end
end)

-- Головний робочий цикл фарму
task.spawn(function()
while true do
task.wait(0.05)

if _G.AutoFarmCoins then if not isBagFull() then local targetCoin = getClosestCoin() if targetCoin and targetCoin.Parent then local character = LocalPlayer.Character local myRoot = character and character:FindFirstChild("HumanoidRootPart") local touchPart = targetCoin:IsA("BasePart") and targetCoin or targetCoin:FindFirstChild("CoinVisual") or targetCoin:FindFirstChildWhichIsA("BasePart") if myRoot and touchPart then toggleNoClip(true) local targetCFrame = touchPart.CFrame if _G.FarmUnderground then targetCFrame = touchPart.CFrame * CFrame.new(0, -6, 0) end local distance = (myRoot.Position - targetCFrame.Position).Magnitude local duration = distance / math.max(_G.FarmSpeed, 1) local tween = TweenService:Create( myRoot, TweenInfo.new(duration, Enum.EasingStyle.Linear), {CFrame = targetCFrame} ) tween:Play() while tween.PlaybackState == Enum.PlaybackState.Playing and _G.AutoFarmCoins and targetCoin.Parent do task.wait(0.02) end if not _G.AutoFarmCoins then tween:Cancel() toggleNoClip(false) else -- Режим збирання if firetouchinterest then firetouchinterest(myRoot, touchPart, 0) task.wait(0.02) firetouchinterest(myRoot, touchPart, 1) else -- Фізичний блінк для слабких екзекуторів local oldCFrame = myRoot.CFrame myRoot.CFrame = touchPart.CFrame task.wait(0.04) myRoot.CFrame = oldCFrame end collectedCoins[targetCoin] = true task.wait(0.05) end end else task.wait(0.3) end else -- Очікування нового раунду у повітрі local character = LocalPlayer.Character local myRoot = character and character:FindFirstChild("HumanoidRootPart") if myRoot then myRoot.CFrame = CFrame.new(0, 500, 0) end task.wait(2) end else toggleNoClip(false) end end 

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

FarmingTab:AddSlider("FarmSpeedSlider", {
Title = "Farm Speed",
Min = 15,
Max = 45,
Default = 22,
Rounding = 0,
Callback = function(Value)
_G.FarmSpeed = Value
end
})







