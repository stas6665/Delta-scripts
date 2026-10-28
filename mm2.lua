local Fluent = loadstring(game:HttpGet("https://github.com"))()
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Window = Fluent:CreateWindow({
    Title = "Star Hub",
    SubTitle = "v3.7.2",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Theme = "Dark"
})

local Tabs = {
    Farming = Window:AddTab({ Title = "Auto Farm", Icon = "box" })
}

_G.AutoFarmCoins = false
_G.FarmUnderground = false
_G.FarmSpeed = 16

local function getRoot()
    return LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
end

local function noclip()
    if LocalPlayer.Character then
        for _, child in pairs(LocalPlayer.Character:GetChildren()) do
            if child:IsA("BasePart") then
                child.CanCollide = false
            end
        end
    end
end

task.spawn(function()
    while true do
        task.wait()
        if _G.AutoFarmCoins then
            pcall(function()
                local coinContainer = workspace:FindFirstChild("CoinContainer") or workspace:FindFirstChild("CoinContainer", true)
                local hrp = getRoot()
                
                if coinContainer and hrp then
                    for _, coin in pairs(coinContainer:GetChildren()) do
                        if _G.AutoFarmCoins and coin:IsA("BasePart") and coin.Transparency == 0 then
                            noclip()
                            local targetPos = coin.Position
                            if _G.FarmUnderground then
                                targetPos = coin.Position - Vector3.new(0, 6, 0)
                            end
                            
                            local distance = (hrp.Position - targetPos).Magnitude
                            local speed = _G.FarmSpeed
                            local duration = distance / speed
                            
                            local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
                            local tween = TweenService:Create(hrp, tweenInfo, {CFrame = CFrame.new(targetPos)})
                            tween:Play()
                            tween.Completed:Wait()
                            task.wait(0.1)
                        end
                    end
                end
            end)
        end
    end
end)

task.spawn(function()
    local vu = game:GetService("VirtualUser")
    LocalPlayer.Idled:Connect(function()
        vu:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        vu:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    end)
end)

local Toggle1 = Tabs.Farming:AddToggle("AutoFarmCoins", {
    Title = "Auto Farm Coins", 
    Default = false 
})
Toggle1:OnChanged(function(Value)
    _G.AutoFarmCoins = Value
end)

local Toggle2 = Tabs.Farming:AddToggle("FarmUnderground", {
    Title = "Farm Underground", 
    Default = false 
})
Toggle2:OnChanged(function(Value)
    _G.FarmUnderground = Value
end)

local Slider = Tabs.Farming:AddSlider("FarmSpeed", {
    Title = "Farm Speed",
    Min = 16,
    Max = 100,
    Default = 16,
    Rounding = 0
})
Slider:OnChanged(function(Value)
    _G.FarmSpeed = Value
end)

Window:SelectTab(1)


