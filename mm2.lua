local Fluent = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/dawid-scripts/Fluent/master/main.lua"
))()

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Window = Fluent:CreateWindow({
    Title = "Lua Star",
    SubTitle = "v1.0",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Theme = "Dark"
})

local Tabs = {
    Farming = Window:AddTab({
        Title = "Auto Farm",
        Icon = "box"
    })
}

_G.AutoFarmCoins = false
_G.FarmUnderground = false
_G.FarmSpeed = 16

local AntiAFK = false

local Toggle1 = Tabs.Farming:AddToggle("AutoFarmCoins", {
    Title = "Auto Farm Candy",
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
    _G.FarmSpeed = math.clamp(Value, 16, 100)
end)

local Toggle3 = Tabs.Farming:AddToggle("AntiAFK", {
    Title = "Anti-AFK",
    Default = false
})

Toggle3:OnChanged(function(Value)
    AntiAFK = Value
end)

Window:SelectTab(1)

