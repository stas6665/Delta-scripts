-- =======================================================
-- DELTA EXECUTOR: MAX SPEED 26 NOCLIP FARM WITH ANTI-AFK
-- =======================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

local MAX_CANDIES = 50
local FARM_SPEED = 26 -- Maximum safe speed requested
local isFarming = false

-- 1. ANTI-AFK SYSTEM (Prevents disconnection for 20 minutes)
local VirtualUser = game:GetService("VirtualUser")
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new(0, 0))
    print("[Anti-AFK]: Prevented kick for inactivity.")
end)

-- 2. MOBILE-FRIENDLY INTERFACE (GUI)
local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local ActionButton = Instance.new("TextButton")
local Corner = Instance.new("UICorner")

pcall(function()
    ScreenGui.Parent = CoreGui
end)
if not ScreenGui.Parent then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

MainFrame.Name = "DeltaMaxFarmFrame"
MainFrame.Size = UDim2.new(0, 150, 0, 45)
MainFrame.Position = UDim2.new(0.75, 0, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.Active = true
MainFrame.Draggable = true 
MainFrame.Parent = ScreenGui

ActionButton.Name = "ActionButton"
ActionButton.Size = UDim2.new(1, 0, 1, 0)
ActionButton.Text = "START SPEED FARM"
ActionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ActionButton.TextSize = 14
ActionButton.Font = Enum.Font.SourceSansBold
ActionButton.BackgroundTransparency = 1
ActionButton.Parent = MainFrame

Corner.CornerRadius = UDim.new(0, 6)
Corner.Parent = MainFrame

-- 3. SCANNING FOR EVENT COINS (CANDIES)
local function getCandies()
    local list = {}
    local map = Workspace:FindFirstChild("Normal") and Workspace.Normal:FindFirstChild("Map")
    local searchIn = map or Workspace
    
    for _, obj in pairs(searchIn:GetDescendants()) do
        if obj:IsA("TouchTransmitter") then
            local parent = obj.Parent
            if parent and parent:IsA("BasePart") then
                local name = parent.Name:lower()
                -- Filtering out invisible developer traps
                if (name:match("coin") or name:match("candy")) and parent.Transparency < 1 then
                    table.insert(list, parent)
                    if #list >= MAX_CANDIES then break end
                end
            end
        end
    end
    return list
end

-- 4. NOCLIP AND TWEEN MOVEMENT ALGORITHM
local function startSpeedFarm()
    if isFarming then return end
    isFarming = true
    
    local character = LocalPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    
    if not rootPart then 
        ActionButton.Text = "NO CHARACTER"
        task.wait(2)
        ActionButton.Text = "START SPEED FARM"
        isFarming = false
        return 
    end

    local candies = getCandies()
    local totalCandies = #candies

    if totalCandies == 0 then
        ActionButton.Text = "NO CANDIES"
        task.wait(2)
        ActionButton.Text = "START SPEED FARM"
        isFarming = false
        return
    end

    ActionButton.Text = "FARMING..."
    print("[MM2 Farm]: Starting noclip speed farm. Items: " .. tostring(totalCandies))

    -- Enable Noclip (Disables collisions with walls/objects during flight)
    local noclipConnection
    noclipConnection = game:GetService("RunService").Stepped:Connect(function()
        if isFarming and character then
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide == true then
                    part.CanCollide = false
                end
            end
        end
    end)

    -- Moving through objects to each candy at maximum safe speed (26)
    for _, candy in pairs(candies) do
        character = LocalPlayer.Character
        rootPart = character and character:FindFirstChild("HumanoidRootPart")
        
        if rootPart and candy and candy.Parent then
            -- Distance calculation to maintain constant speed of 26
            local distance = (rootPart.Position - candy.Position).Magnitude
            local travelTime = distance / FARM_SPEED

            local tweenInfo = TweenInfo.new(travelTime, Enum.EasingStyle.Linear)
            local tween = TweenService:Create(rootPart, tweenInfo, {CFrame = candy.CFrame})
            
            tween:Play()
            tween.Completed:Wait()
            
            -- Trigger server contact registration
            firetouchinterest(rootPart, candy, 0)
            firetouchinterest(rootPart, candy, 1)
        else
            break
        end
    end
    
    -- Disabling Noclip after work is done
    if noclipConnection then noclipConnection:Disconnect() end
    
    ActionButton.Text = "BAG IS FULL!"
    task.wait(2)
    ActionButton.Text = "START SPEED FARM"
    isFarming = false
end

-- BUTTON CLICK EVENT
ActionButton.MouseButton1Click:Connect(function()
    pcall(startSpeedFarm)
end)
