local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Window = Fluent:CreateWindow({
Title = "MM2: Dex Fixed Auto Farm",
SubTitle = "v6.1.0 Safe & Aggressive",
TabWidth = 160,
Size = UDim2.fromOffset(580, 460),
Acrylic = false,
Theme = "Darker",
MinimizeKey = Enum.KeyCode.Minus
})

local customTheme = {
Accent = Color3.fromRGB(255, 130, 0),
ToggleActive = Color3.fromRGB(255, 130, 0),
ToggleDisabled = Color3.fromRGB(110, 90, 0),
SliderActive = Color3.fromRGB(255, 130, 0),
SliderInactive = Color3.fromRGB(110, 90, 0)
}

for option, color in pairs(customTheme) do
pcall(function()
Fluent.ThemeManager:SetColor(option, color)
end)
end

task.spawn(function()
local coreGui = game:GetService("CoreGui")
local mainFrame = nil

for i = 1, 50 do local fluentGui = coreGui:FindFirstChild("Fluent", true) if fluentGui then mainFrame = fluentGui:FindFirstChild("Frame", true) if mainFrame then break end end task.wait(0.1) end if mainFrame and not mainFrame:FindFirstChild("HalloweenWallpaper") then local wallpaper = Instance.new("ImageLabel") wallpaper.Name = "HalloweenWallpaper" wallpaper.Image = "rbxassetid://72861721472668" wallpaper.Size = UDim2.new(1, 0, 1, 0) wallpaper.Position = UDim2.new(0, 0, 0, 0) wallpaper.BackgroundTransparency = 1 wallpaper.ImageTransparency = 0.85 wallpaper.ScaleType = Enum.ScaleType.Crop wallpaper.ZIndex = 0 wallpaper.Parent = mainFrame end 

end)

local _G = getgenv and getgenv() or _G
_G.AutoFarmCoins = false
_G.FarmUnderground = false
_G.FarmSpeed = 22
_G.FlingMurderer = false
_G.CoinsESP = false

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")

local collectedCoins = {}
local currentMurderer = nil

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

local function getCoinCount()
local mainGui = LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("MainGui")
local gameGui = mainGui and mainGui:FindFirstChild("Game")
local coinBags = gameGui and (gameGui:FindFirstChild("CoinBags") or gameGui:FindFirstChild("CoinBag"))
local coinLabel = coinBags and coinBags:FindFirstChild("Coins")

if coinLabel and coinLabel:IsA("TextLabel") then local current, max = coinLabel.Text:match("(%d+)%s*/%s*(%d+)") if current and max then return tonumber(current), tonumber(max) else local singleNum = coinLabel.Text:match("^(%d+)") if singleNum then return tonumber(singleNum), 50 end end end return 0, 50 

end

local function isBagFull()
local current, max = getCoinCount()
return current >= max
end

local function findCoinContainer()
local mapObj = workspace:FindFirstChild("Map") or workspace:FindFirstChild("Mineshaft")
if mapObj then
local container = mapObj:FindFirstChild("CoinContainer", true)
if container then return container end
end

for _, child in ipairs(workspace:GetChildren()) do if (child:IsA("Model") or child:IsA("Folder")) and child.Name ~= "PetContainer" and child.Name ~= "WeaponDisplays" and not Players:GetPlayerFromCharacter(child) then local container = child:FindFirstChild("CoinContainer", true) if container then return container end end end return workspace:FindFirstChild("CoinContainer", true) 

end

local function getHitboxPart(coinRoot)
if coinRoot:IsA("BasePart") and coinRoot.Name == "CoinVisual" then return coinRoot end
local visual = coinRoot:FindFirstChild("CoinVisual", true)
if visual and visual:IsA("BasePart") then return visual end
if coinRoot:IsA("BasePart") then return coinRoot end
return coinRoot:FindFirstChildWhichIsA("BasePart", true)
end

local function getClosestCoin()
local coinContainer = findCoinContainer()
if not coinContainer then return nil end

local character = LocalPlayer.Character local myRoot = character and character:FindFirstChild("HumanoidRootPart") if not myRoot then return nil end local closestCoin = nil local shortestDistance = math.huge for _, obj in ipairs(coinContainer:GetDescendants()) do if obj.Name == "Coin_Server" and not collectedCoins[obj] and obj.Parent then local touchPart = getHitboxPart(obj) if touchPart then local distance = (myRoot.Position - touchPart.Position).Magnitude if distance < shortestDistance then shortestDistance = distance closestCoin = obj end end end end return closestCoin 

end

local function getMurderer()
if currentMurderer and currentMurderer.Parent and currentMurderer.Character and currentMurderer.Character:FindFirstChild("HumanoidRootPart") then
return currentMurderer
end

local LogFolder = game:GetService("ReplicatedStorage"):FindFirstChild("MatchToLog") or game:GetService("ReplicatedStorage"):FindFirstChild("PreRoundLog") if LogFolder then local MurderData = LogFolder:FindFirstChild("Murder") or LogFolder:FindFirstChild("Murderer") if MurderData and MurderData:IsA("StringValue") and MurderData.Value ~= "" then local p = Players:FindFirstChild(MurderData.Value) if p and p.Character then currentMurderer = p return p end end end for _, player in ipairs(Players:GetPlayers()) do if player ~= LocalPlayer and player.Character then local pBackpack = player:FindFirstChild("Backpack") local hasKnife = player.Character:FindFirstChild("Knife") or (pBackpack and pBackpack:FindFirstChild("Knife")) if not hasKnife and player:FindFirstChild("PlayerGui") then local mainGui = player.PlayerGui:FindFirstChild("MainGui") local gameGui = mainGui and mainGui:FindFirstChild("Game") local roleLabel = gameGui and gameGui:FindFirstChild("Role") if roleLabel and (roleLabel.Text == "Murderer" or roleLabel.Text == "Убийца") then hasKnife = true end end if hasKnife then currentMurderer = player return player end end end return nil 

end

workspace.ChildAdded:Connect(function()
table.clear(collectedCoins)
currentMurderer = nil
end)

local function applyCoinHighlight(coinObj)
local visual = coinObj:FindFirstChild("CoinVisual", true) or coinObj
if visual and not visual:FindFirstChild("CoinESP") then
local highlight = Instance.new("Highlight")
highlight.Name = "CoinESP"
highlight.FillColor = Color3.fromRGB(255, 130, 0)
highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
highlight.FillTransparency = 0.4
highlight.OutlineTransparency = 0.2
highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
highlight.Enabled = _G.CoinsESP
highlight.Parent = visual
end
end

task.spawn(function()
while true do
task.wait(0.5)
local container = findCoinContainer()
if container then
for _, obj in ipairs(container:GetDescendants()) do
if obj.Name == "Coin_Server" then
applyCoinHighlight(obj)
local visual = obj:FindFirstChild("CoinVisual", true) or obj
local esp = visual:FindFirstChild("CoinESP")
if esp then
esp.Enabled = _G.CoinsESP
end
end
end
end
end
end)

local function flingTarget(targetPlayer)
local character = LocalPlayer.Character
local targetChar = targetPlayer.Character
local myRoot = character and character:FindFirstChild("HumanoidRootPart")
local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")

if myRoot and targetRoot then local oldVelocity = myRoot.Velocity myRoot.Velocity = Vector3.new(999999, 999999, 999999) myRoot.CFrame = targetRoot.CFrame task.wait(0.1) myRoot.Velocity = oldVelocity end 

end

task.spawn(function()
while true do
task.wait(0.05)

if _G.AutoFarmCoins then 

if not isBagFull() then
local targetCoin = getClosestCoin()
if targetCoin and targetCoin.Parent then
local character = LocalPlayer.Character
local myRoot = character and character:FindFirstChild("HumanoidRootPart")
local hitboxPart = getHitboxPart(targetCoin)
if myRoot and hitboxPart then
toggleNoClip(true)
local targetCFrame = hitboxPart.CFrame
if _G.FarmUnderground then
targetCFrame = hitboxPart.CFrame * CFrame.new(0, -4.5, 0)
end
local distance = (myRoot.Position - targetCFrame.Position).Magnitude
local duration = distance / math.max(_G.FarmSpeed, 1)
local tween = TweenService:Create(
myRoot,
TweenInfo.new(duration, Enum.EasingStyle.Linear),
{CFrame = targetCFrame}
)
tween:Play()
while tween.PlaybackState == Enum.PlaybackState.Playing and _G.AutoFarmCoins and targetCoin.Parent and not isBagFull() do
task.wait(0.02)
end
if not _G.AutoFarmCoins then
tween:Cancel()
else
collectedCoins[targetCoin] = true
end
end
end
else
if _G.FlingMurderer then
local muder = getMurderer()
if muder then
flingTarget(muder)
end
end
toggleNoClip(false)
task.wait(1)
end
else
toggleNoClip(false)
end
end
end)
local FarmingTab = Window:AddTab({ Title = "Farming", Icon = "activity" })
local VisualsTab = Window:AddTab({ Title = "Visuals", Icon = "eye" })
FarmingTab:AddToggle("AutoFarmToggle", {
Title = "Auto Farm Coins",
Default = false,
Callback = function(Value) _G.AutoFarmCoins = Value end
})
FarmingTab:AddToggle("UndergroundToggle", {
Title = "Farm Underground (Safe)",
Default = false,
Callback = function(Value) _G.FarmUnderground = Value end
})
FarmingTab:AddToggle("FlingMurdererToggle", {
Title = "Fling Murderer when Full",
Default = false,
Callback = function(Value) _G.FlingMurderer = Value end
})
FarmingTab:AddSlider("FarmSpeedSlider", {
Title = "Farm Speed",
Min = 15,
Max = 45,
Default = 22,
Rounding = 0,
Callback = function(Value) _G.FarmSpeed = Value end
})
VisualsTab:AddToggle("CoinsESPToggle", {
Title = "Orange Coins ESP",
Default = false,
Callback = function(Value) _G.CoinsESP = Value end
})
Window:SelectTab(1)
Fluent:Notify({
Title = "MM2 Script",
Content = "Script loaded successfully!",
Duration = 5
})

