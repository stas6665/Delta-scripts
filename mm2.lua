local Material = loadstring(game:HttpGet("https://githubusercontent.com"))()

local UI = Material.Load({
    Title = "MM2 Ultimate Farm 2026",
    Style = 3,
    SizeX = 400,
    SizeY = 350,
    Theme = "Dark"
})

local MainTab = UI.New({ Title = "Main" })

_G.AutoFarmCandies = false
_G.FarmSpeed = 16 

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

RunService.Stepped:Connect(function()
    if _G.AutoFarmCandies then
        local Character = LocalPlayer.Character
        if Character then
            for _, part in pairs(Character:GetChildren()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end
end)

local function GetEventCandy()
    local Character = LocalPlayer.Character
    local RootPart = Character and Character:FindFirstChild("HumanoidRootPart")
    if not RootPart then return nil end

    local ClosestCandy = nil
    local ShortestDistance = math.huge

    for _, obj in pairs(game.Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            if obj.Name == "CandyCorn" or obj.Name == "Candy" or obj.Name == "Coin" then
                if not obj:IsDescendantOf(game.Workspace:FindFirstChild("Lobby")) then
                    local Distance = (RootPart.Position - obj.Position).Magnitude
                    if Distance < ShortestDistance then
                        ShortestDistance = Distance
                        ClosestCandy = obj
                    end
                end
            end
        end
    end
    return ClosestCandy
end

task.spawn(function()
    local BodyVelocity = nil
    
    while task.wait() do
        local Character = LocalPlayer.Character
        local RootPart = Character and Character:FindFirstChild("HumanoidRootPart")
        
        if _G.AutoFarmCandies and RootPart then
            local Target = GetEventCandy()
            
            if Target then
                if not BodyVelocity or BodyVelocity.Parent ~= RootPart then
                    BodyVelocity = Instance.new("BodyVelocity")
                    BodyVelocity.MaxForce = Vector3.new(100000, 100000, 100000)
                    BodyVelocity.Parent = RootPart
                end
                
                local Direction = (Target.Position - RootPart.Position).Unit
                local Distance = (Target.Position - RootPart.Position).Magnitude
                
                if Distance > 2 then
                    BodyVelocity.Velocity = Direction * _G.FarmSpeed
                    RootPart.CFrame = CFrame.new(RootPart.Position, Target.Position)
                else
                    BodyVelocity.Velocity = Vector3.new(0, 0, 0)
                    RootPart.CFrame = CFrame.new(Target.Position)
                    if Target:FindFirstChild("TouchInterest") then
                        firetouchinterest(RootPart, Target, 0)
                        firetouchinterest(RootPart, Target, 1)
                    end
                end
            else
                if BodyVelocity then BodyVelocity.Velocity = Vector3.new(0, 0, 0) end
            end
        else
            if BodyVelocity then
                BodyVelocity:Destroy()
                BodyVelocity = nil
            end
        end
    end
end)

MainTab.Toggle({
    Text = "Safe Auto Farm",
    Callback = function(state)
        _G.AutoFarmCandies = state
    end,
    Enabled = false
})

MainTab.Slider({
    Text = "Fly Speed Max 27",
    Callback = function(val)
        _G.FarmSpeed = val
    end,
    Min = 5,
    Max = 27,
    Def = 16
})

UI.Banner({ Text = "Script Loaded Successfully!" })

