local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Qanuir/orion-ui/refs/heads/main/source.lua"))()

local Window = OrionLib:MakeWindow({
    Name = "Star Hub | Universal MM2 Farm",
    HidePremium = false,
    SaveConfig = false,
    IntroText = "Loading Star Hub..."
})

local _G = getgenv and getgenv() or _G
_G.AutoFarmCoins = false
_G.FarmUnderground = false
_G.FarmSpeed = 16

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")
local Debris = game:GetService("Debris")

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
    local playerData = LocalPlayer:FindFirstChild("PlayerData")

    if playerData then
        local coins = playerData:FindFirstChild("Coins")
        local maxCoins = playerData:FindFirstChild("MaxCoins")

        if coins and coins.Value >= (maxCoins and maxCoins.Value or 40) then
            return true
        end
    end

    return false
end

local function yeetMurderer()
    local murderer

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local backpack = p:FindFirstChild("Backpack")

            if (backpack and backpack:FindFirstChild("Knife"))
                or p.Character:FindFirstChild("Knife") then
                murderer = p
                break
            end
        end
    end

    if not murderer or not murderer.Character then
        return
    end

    local myCharacter = LocalPlayer.Character
    local myRoot = myCharacter and myCharacter:FindFirstChild("HumanoidRootPart")
    local mRoot = murderer.Character:FindFirstChild("HumanoidRootPart")

    if not myRoot or not mRoot then
        return
    end

    toggleNoClip(true)

    local spinAV = Instance.new("BodyAngularVelocity")
    spinAV.MaxTorque = Vector3.new(0, 1e9, 0)
    spinAV.AngularVelocity = Vector3.new(0, 150, 0)
    spinAV.Parent = myRoot

    myRoot.CFrame = mRoot.CFrame * CFrame.new(0, 0, 1)
    task.wait(0.1)

    local direction = mRoot.Position - myRoot.Position
    if direction.Magnitude < 0.001 then
        direction = Vector3.new(0, 0, 1)
    else
        direction = direction.Unit
    end

    local bV = Instance.new("BodyVelocity")
    bV.MaxForce = Vector3.new(1e7, 1e7, 1e7)
    bV.Velocity = direction * 100 + Vector3.new(0, 4500, 4500)
    bV.Parent = mRoot

    local mAV = Instance.new("BodyAngularVelocity")
    mAV.MaxTorque = Vector3.new(1e7, 1e7, 1e7)
    mAV.AngularVelocity = Vector3.new(0, 200, 0)
    mAV.Parent = mRoot

    Debris:AddItem(spinAV, 1)
    Debris:AddItem(bV, 1.5)
    Debris:AddItem(mAV, 1.5)

    task.wait(1.5)
end

local function findCoinContainer()
    return workspace:FindFirstChild("CoinContainer", true)
end

task.spawn(function()
    while task.wait() do
        if _G.AutoFarmCoins then
            if not isBagFull() then
                local coinContainer = findCoinContainer()

                if coinContainer then
                    for _, child in ipairs(coinContainer:GetDescendants()) do
                        if not _G.AutoFarmCoins or isBagFull() then
                            break
                        end

                        if child.Name == "CoinVisual" and child:IsA("BasePart") then
                            local character = LocalPlayer.Character
                            local myRoot = character and character:FindFirstChild("HumanoidRootPart")

                            if myRoot and child.Parent then
                                toggleNoClip(true)

                                local targetCFrame = child.CFrame

                                if _G.FarmUnderground then
                                    targetCFrame = child.CFrame * CFrame.new(0, -5, 0)
                                end

                                local distance = (myRoot.Position - targetCFrame.Position).Magnitude
                                local duration = distance / math.max(_G.FarmSpeed, 1)

                                local tween = TweenService:Create(
                                    myRoot,
                                    TweenInfo.new(duration, Enum.EasingStyle.Linear),
                                    {CFrame = targetCFrame}
                                )

                                tween:Play()
                                tween.Completed:Wait()

                                if not _G.AutoFarmCoins then
                                    tween:Cancel()
                                    break
                                end

                                if firetouchinterest then
                                    firetouchinterest(myRoot, child, 0)
                                    task.wait(0.02)
                                    firetouchinterest(myRoot, child, 1)
                                end

                                task.wait(0.05)
                            end
                        end
                    end
                end
            else
                yeetMurderer()
                task.wait(1)
            end
        else
            toggleNoClip(false)
        end
    end
end)

local FarmTab = Window:NewTab("Farming")
local FarmSection = FarmTab:NewSection("Auto Farm")

FarmSection:NewToggle(
    "Candy Farm",
    "Auto collect candies",
    function(state)
        _G.AutoFarmCoins = state
    end
)

FarmSection:NewToggle(
    "Farm Underground",
    "Collect candies underground",
    function(state)
        _G.FarmUnderground = state
    end
)

FarmSection:NewSlider(
    "Farm Speed",
    "Candy farming speed",
    35,
    16,
    function(value)
        _G.FarmSpeed = value
    end
)

OrionLib:Init()
