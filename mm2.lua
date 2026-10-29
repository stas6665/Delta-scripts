
local Fluent = loadstring(game:HttpGet(
    "https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"
))()

local Window = Fluent:CreateWindow({
    Title = "Star Hub (MM2 Halloween)",
    SubTitle = "v3.7.2",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Theme = "Dark"
})

local Tabs = {
    AutoFarm = Window:AddTab({
        Title = "Auto Farm",
        Icon = "box"
    })
}

_G.AutoFarmCoins = false
_G.FarmUnderground = false
_G.FarmSpeed = 16

task.spawn(function()
    game:GetService("RunService").Stepped:Connect(function()
        if _G.AutoFarmCoins then
            local player = game.Players.LocalPlayer
            local character = player.Character

            if character then
                for _, part in pairs(character:GetChildren()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end
    end)
end)

local function getMurderer()
    for _, p in pairs(game.Players:GetPlayers()) do
        local character = p.Character
        local backpack = p:FindFirstChild("Backpack")

        if (character and character:FindFirstChild("Knife"))
            or (backpack and backpack:FindFirstChild("Knife")) then
            return character
        end
    end

    return nil
end

local function getBagCount()
    local player = game.Players.LocalPlayer
    local mainData = player:FindFirstChild("playerData")
        or player:FindFirstChild("Data")

    if mainData and mainData:FindFirstChild("Coins") then
        return mainData.Coins.Value
    end

    local gui = player:FindFirstChild("PlayerGui")
    local mainGui = gui and gui:FindFirstChild("MainGui")
    local gameGui = mainGui and mainGui:FindFirstChild("Game")
    local coinBag = gameGui and gameGui:FindFirstChild("CoinBag")
    local coins = coinBag and coinBag:FindFirstChild("Coins")

    if coins and coins:IsA("TextLabel") then
        return tonumber(coins.Text:match("(%d+)")) or 0
    end

    return 0
end

local function startHalloweenFlyFarm()
    task.spawn(function()
        while _G.AutoFarmCoins do
            task.wait(0.05)

            local player = game.Players.LocalPlayer
            local character = player.Character
                or player.CharacterAdded:Wait()

            local rootPart = character:FindFirstChild("HumanoidRootPart")
            if not rootPart then
                continue
            end

            if getBagCount() >= 50 then
                local murdererChar = getMurderer()

                if murdererChar then
                    local murdererRoot =
                        murdererChar:FindFirstChild("HumanoidRootPart")

                    if murdererRoot then
                        local startTime = tick()

                        while tick() - startTime < 4
                            and _G.AutoFarmCoins do
                            task.wait()

                            if not rootPart.Parent
                                or not murdererRoot.Parent then
                                break
                            end

                            rootPart.CFrame =
                                murdererRoot.CFrame
                                * CFrame.new(0, -4, 0)
                                * CFrame.Angles(
                                    0,
                                    math.rad(tick() * 5000 % 360),
                                    0
                                )
                        end

                        task.wait(0.5)
                    end
                end

                continue
            end

            local mainContainer =
                workspace:FindFirstChild("CoinContainer")
                or (
                    workspace:FindFirstChild("Normal")
                    and workspace.Normal:FindFirstChild("CoinContainer")
                )

            if mainContainer then
                for _, item in pairs(mainContainer:GetChildren()) do
                    if not _G.AutoFarmCoins
                        or getBagCount() >= 50 then
                        break
                    end

                    local name = item.Name:lower()

                    if item:FindFirstChild("CoinVisualizer")
                        or name:match("coin")
                        or name:match("candy") then

                        local touchPart =
                            item:IsA("BasePart")
                            and item
                            or item:FindFirstChildWhichIsA("BasePart")

                        if touchPart then
                            local offset = _G.FarmUnderground
                                and Vector3.new(0, -4.5, 0)
                                or Vector3.new(0, 0, 0)

                            local targetCFrame =
                                touchPart.CFrame * CFrame.new(offset)

                            while (
                                rootPart.Position - targetCFrame.Position
                            ).Magnitude > 1.5 and _G.AutoFarmCoins do

                                if getBagCount() >= 50 then
                                    break
                                end

                                rootPart.CFrame = rootPart.CFrame:Lerp(
                                    targetCFrame,
                                    _G.FarmSpeed / 100
                                )

                                task.wait()
                            end

                            task.wait(0.15)
                        end
                    end
                end
            end
        end
    end)
end

local FarmCoinsToggle = Tabs.AutoFarm:AddToggle(
    "AutoFarmCoins",
    {
        Title = "Auto Fly Farm Candy",
        Default = false
    }
)

FarmCoinsToggle:OnChanged(function(Value)
    _G.AutoFarmCoins = Value

    if Value then
        startHalloweenFlyFarm()
    end
end)

local FarmUndergroundToggle = Tabs.AutoFarm:AddToggle(
    "FarmUnderground",
    {
        Title = "Farm Underground",
        Description =
            "Fly and collect candies strictly under the map/textures",
        Default = false
    }
)

FarmUndergroundToggle:OnChanged(function(Value)
    _G.FarmUnderground = Value
end)

local SpeedSlider = Tabs.AutoFarm:AddSlider(
    "FarmSpeed",
    {
        Title = "Fly Speed",
        Description = "Smooth movement speed",
        Default = 16,
        Min = 12,
        Max = 30,
        Rounding = 0
    }
)

SpeedSlider:OnChanged(function(Value)
    _G.FarmSpeed = Value
end)

Fluent:Notify({
    Title = "Star Hub Loaded",
    Content = "Interface loaded!",
    Duration = 5
})
