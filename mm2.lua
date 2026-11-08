local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
Name = "MM2 Hub [Instant Optimized]",
LoadingTitle = "Loading MM2...",
LoadingSubtitle = "by Stas (Final)",
ConfigurationSaving = { Enabled = false },
KeySystem = false,
})

local FarmingTab = Window:CreateTab("Farming", 4483362458)
local FlingTab = Window:CreateTab("Fling", 4483362458)
local CombatTab = Window:CreateTab("Combat", 4483362458)
local SkinsTab = Window:CreateTab("Skins", 4483362458)
local VisualsTab = Window:CreateTab("Visuals", 4483362458)

local autoFarmCandy = false
local antiFlingEnabled = false
local autoGrabGunEnabled = false
local autoFlingMurderWhenFull = false
local autoKillWhenFull = false

local farmSpeed = 25
local farmMethod = "Teleport"

-- ESP Variables
local espMurderEnabled = false
local espSheriffHeroEnabled = false
local espInnocentEnabled = false

local espCoinsEnabled = false
local xrayEnabled = false
local xrayTransparency = 0.65

local currentFarmSession = 0
local isFlingingActive = false

local autoShootGui = nil
local autoShootButtonEnabled = false

local selectedWeaponType = "Gun"
local activeSkinName = "Default"

local skinDatabase = {
["Default"] = {MeshId = "", TextureId = ""},
["GingerScope"] = {MeshId = "rbxassetid://15622152775", TextureId = "rbxassetid://15622152865"},
["Celestial"] = {MeshId = "rbxassetid://14013441230", TextureId = "rbxassetid://14013441315"},
["Emberbow"] = {MeshId = "rbxassetid://15622157077", TextureId = "rbxassetid://15622157144"},
["Combain"] = {MeshId = "rbxassetid://13812499120", TextureId = "rbxassetid://13812499245"},
["Evergun"] = {MeshId = "rbxassetid://15622157077", TextureId = "rbxassetid://15622157144"},
["Laser Gun"] = {MeshId = "rbxassetid://460652273", TextureId = "rbxassetid://460652303"},
["Luger"] = {MeshId = "rbxassetid://460652516", TextureId = "rbxassetid://460652545"},
["Corrupt Knife"] = {MeshId = "rbxassetid://460651877", TextureId = "rbxassetid://460651900"}
}

-- Custom Bottom-Right Notification System
local notifyGui = nil
local function showCustomNotification(title, message, isSuccess)
pcall(function()
local player = game:GetService("Players").LocalPlayer
local playerGui = player:FindFirstChild("PlayerGui")
if not playerGui then return end

if not notifyGui or not notifyGui.Parent then  
     notifyGui = Instance.new("ScreenGui")  
     notifyGui.Name = "MM2CustomNotifications"  
     notifyGui.ResetOnSpawn = false  
     notifyGui.Parent = playerGui  
  end  

  for _, child in ipairs(notifyGui:GetChildren()) do  
     child:Destroy()  
  end  

  local notifFrame = Instance.new("Frame")  
  notifFrame.Size = UDim2.new(0, 240, 0, 45)  
  notifFrame.Position = UDim2.new(1, -250, 1, -55)  
  notifFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)  
  notifFrame.BackgroundTransparency = 0.3  
  notifFrame.BorderSizePixel = 0  
  notifFrame.Parent = notifyGui  

  local corner = Instance.new("UICorner")  
  corner.CornerRadius = UDim.new(0, 8)  
  corner.Parent = notifFrame  

  local stroke = Instance.new("UIStroke")  
  stroke.Color = isSuccess and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 140, 0)  
  stroke.Thickness = 2  
  stroke.Parent = notifFrame  

  local iconLabel = Instance.new("TextLabel")  
  iconLabel.Size = UDim2.new(0, 30, 1, 0)  
  iconLabel.Position = UDim2.new(0, 5, 0, 0)  
  iconLabel.BackgroundTransparency = 1  
  iconLabel.Text = isSuccess and "✓" or "!"  
  iconLabel.TextColor3 = isSuccess and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 140, 0)  
  iconLabel.TextSize = 22  
  iconLabel.Font = Enum.Font.GothamBold  
  iconLabel.Parent = notifFrame  

  local titleLabel = Instance.new("TextLabel")  
  titleLabel.Size = UDim2.new(1, -40, 0, 18)  
  titleLabel.Position = UDim2.new(0, 35, 0, 4)  
  titleLabel.BackgroundTransparency = 1  
  titleLabel.Text = title  
  titleLabel.TextColor3 = isSuccess and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 140, 0)  
  titleLabel.TextSize = 13  
  titleLabel.Font = Enum.Font.GothamBold  
  titleLabel.TextXAlignment = Enum.TextXAlignment.Left  
  titleLabel.Parent = notifFrame  

  local msgLabel = Instance.new("TextLabel")  
  msgLabel.Size = UDim2.new(1, -40, 0, 18)  
  msgLabel.Position = UDim2.new(0, 35, 0, 22)  
  msgLabel.BackgroundTransparency = 1  
  msgLabel.Text = message  
  msgLabel.TextColor3 = Color3.fromRGB(255, 255, 255)  
  msgLabel.TextSize = 12  
  msgLabel.Font = Enum.Font.Gotham  
  msgLabel.TextXAlignment = Enum.TextXAlignment.Left  
  msgLabel.Parent = notifFrame  

  task.spawn(function()  
     task.wait(0.7)  
     if notifFrame and notifFrame.Parent then  
        notifFrame:Destroy()  
     end  
  end)
end)
end

-- GunDrop Tracking
local gunWasDropped = false
local gunPickedUpDetected = false

task.spawn(function()
local Workspace = game:GetService("Workspace")
while true do
pcall(function()
local foundGunDrop = false
local descendants = Workspace:GetDescendants()
for _, obj in ipairs(descendants) do
if obj.Name == "GunDrop" or obj.Name == "GunDropModel" then
foundGunDrop = true
break
end
end

if foundGunDrop then  
        gunWasDropped = true  
     else  
        if gunWasDropped then  
           gunPickedUpDetected = true  
        end  
     end  

     if not foundGunDrop and not workspace:FindFirstChild("GunDrop", true) then  
        local player = game:GetService("Players").LocalPlayer  
        local playerGui = player and player:FindFirstChild("PlayerGui")  
        local mainGui = playerGui and playerGui:FindFirstChild("MainGUI")  
        local gameFrame = mainGui and mainGui:FindFirstChild("Game")  
        if gameFrame and not gameFrame.Visible then  
           gunWasDropped = false  
           gunPickedUpDetected = false  
        end  
     end  
  end)  
  task.wait(0.5)
end
end)

-- Anti Fling & No-Push Protection
local antiFlingConnection = nil
local function updateAntiFling()
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

if antiFlingEnabled then
if not antiFlingConnection then
antiFlingConnection = RunService.Stepped:Connect(function()
if not antiFlingEnabled then return end
pcall(function()
local char = player.Character
if char and char:FindFirstChild("HumanoidRootPart") then
local root = char.HumanoidRootPart
root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
root.AssemblyLinearVelocity = Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)

local playersList = Players:GetPlayers()  
              for _, p in ipairs(playersList) do    
                 if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then    
                    local pRoot = p.Character.HumanoidRootPart    
                    if (root.Position - pRoot.Position).Magnitude < 6 then    
                       pRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)  
                       pRoot.AssemblyAngularVelocity = Vector3.new(0, 0, 0)  
                    end    
                 end    
              end    
           end    
        end)    
     end)    
  end
else
if antiFlingConnection then
antiFlingConnection:Disconnect()
antiFlingConnection = nil
end
end
end

-- Виправлений Auto Grab Gun (з глибоким пошуком через GetDescendants)
task.spawn(function()
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

while true do
pcall(function()
if autoGrabGunEnabled then
local player = Players.LocalPlayer
local backpack = player:FindFirstChild("Backpack")
local char = player.Character

local hasGun = (char and char:FindFirstChild("Gun")) or (backpack and backpack:FindFirstChild("Gun"))  
          
        if not hasGun and char and char:FindFirstChild("HumanoidRootPart") then  
           local root = char.HumanoidRootPart  
             
           local gunDrop = nil  
           for _, obj in ipairs(Workspace:GetDescendants()) do  
              if obj.Name == "GunDrop" or obj.Name == "GunDropModel" then  
                 if obj:IsA("BasePart") then  
                    gunDrop = obj  
                    break  
                 elseif obj:IsA("Model") then  
                    gunDrop = obj.PrimaryPart or obj:FindFirstChild("Handle") or obj:FindFirstChildOfClass("BasePart")  
                    if gunDrop then break end  
                 end  
              end  
           end  
             
           if gunDrop and gunDrop:IsA("BasePart") then  
              local origCFrame = root.CFrame  
              root.CFrame = gunDrop.CFrame  
              
              local prompt = gunDrop:FindFirstChildOfClass("ProximityPrompt")   
                             or (gun.Parent and gunDrop.Parent:FindFirstChildOfClass("ProximityPrompt"))  
              if prompt then  
                 fireproximityprompt(prompt)  
              end  
                
              task.wait(0.01)  
              root.CFrame = origCFrame  
              showCustomNotification("Auto Grab", "Gun grabbed instantly!", true)  
           end  
        end  
     end  
  end)  
  task.wait(0.2)
end
end)

-- Кнопка Shoot Murder (Миттєвий телепорт впритул + реальний вистріл + повернення назад)
local function createAutoShootGui()
if autoShootGui then return end
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local playerGui = player:FindFirstChild("PlayerGui")

if playerGui then
autoShootGui = Instance.new("ScreenGui")
autoShootGui.Name = "MM2AutoShootGui"
autoShootGui.ResetOnSpawn = false

local btn = Instance.new("TextButton")    
  btn.Name = "ShootButton"    
  btn.Size = UDim2.new(0, 320, 0, 60)    
  btn.Position = UDim2.new(0.5, -160, 0.75, 0)    
  btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)  
  btn.BackgroundTransparency = 0.3  
  btn.Text = ""    
  btn.AutoButtonColor = false    
  btn.Parent = autoShootGui    
      
  local corner = Instance.new("UICorner")    
  corner.CornerRadius = UDim.new(0, 12)    
  corner.Parent = btn    
      
  local stroke = Instance.new("UIStroke")    
  stroke.Name = "BorderStroke"  
  stroke.Color = Color3.fromRGB(255, 0, 0)    
  stroke.Thickness = 4    
  stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border  
  stroke.Parent = btn    
      
  local textLabel = Instance.new("TextLabel")    
  textLabel.Size = UDim2.new(1, 0, 1, 0)    
  textLabel.BackgroundTransparency = 1    
  textLabel.Text = "Shoot Murder"    
  textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)    
  textLabel.TextSize = 24    
  textLabel.Font = Enum.Font.GothamBold    
  textLabel.Parent = btn    

  local dragging = false    
  local activeInput = nil    
  local dragStart = nil    
  local startPos = nil    
  local hasMoved = false    

  btn.InputBegan:Connect(function(input)    
     if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and not activeInput then    
        dragging = true    
        activeInput = input    
        dragStart = input.Position    
        startPos = btn.Position    
        hasMoved = false    
     end    
  end)    
      
  UserInputService.InputChanged:Connect(function(input)    
     if input == activeInput and dragging then    
        local delta = input.Position - dragStart    
        if delta.Magnitude > 5 then    
           hasMoved = true    
        end    
        btn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)    
     end    
  end)    
      
  UserInputService.InputEnded:Connect(function(input)    
     if input == activeInput then    
        if not hasMoved then    
           pcall(function()    
              local char = player.Character    
              if not char or not char:FindFirstChild("HumanoidRootPart") then return end    
              local root = char.HumanoidRootPart
              local hum = char:FindFirstChildOfClass("Humanoid")  
                  
              local backpack = player:FindFirstChild("Backpack")    
              local gun = char:FindFirstChild("Gun") or (backpack and backpack:FindFirstChild("Gun"))    
                
              if not gun then   
                 showCustomNotification("Shoot Murder", "Gun not found!", false)  
                 return   
              end    
                  
              if gun.Parent == backpack and hum then    
                 hum:EquipTool(gun)  
                 task.wait(0.01)  
              end    

              if gun:FindFirstChild("CantShoot") then  
                 pcall(function() gun.CantShoot.Value = false end)  
              end  
                  
              local targetRoot = nil    
              local playersList = Players:GetPlayers()  
              for _, p in ipairs(playersList) do    
                 if p ~= player and p.Character then    
                    local pBackpack = p:FindFirstChild("Backpack")    
                    local pChar = p.Character    
                    local pRoot = pChar:FindFirstChild("HumanoidRootPart")    
                    local pHum = pChar:FindFirstChildOfClass("Humanoid")    
                        
                    local hasKnife = (pBackpack and pBackpack:FindFirstChild("Knife")) or (pChar and pChar:FindFirstChild("Knife"))    
                        
                    if hasKnife and pRoot and pHum and pHum.Health > 0 then    
                       targetRoot = pRoot    
                       break    
                    end    
                 end  
              end    
                  
              if not targetRoot then   
                 showCustomNotification("Shoot Murder", "Murder not found!", false)  
                 return   
              end  

              local originalCFrame = root.CFrame

              -- 1. Стрибок впритул до маньяка на 1 кадр
              root.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 1)
              RunService.Heartbeat:Wait()

              -- 2. Реальний вистріл через активацію зброї
              if gun.Parent == char then
                 gun:Activate()
              end

              local targetPos = targetRoot.Position + Vector3.new(0, 0.5, 0)  
              local rayAttach = root:FindFirstChild("GunRaycastAttachment")  
              local attachmentCFrame = rayAttach and rayAttach.WorldCFrame or root.CFrame  
              local calculatedCFrame = CFrame.new(attachmentCFrame.Position, targetPos)  

              local remote = gun:FindFirstChild("Shoot")   
                             or gun:FindFirstChild("Shootts")  
                             or (gun:FindFirstChild("GunClient") and (gun.GunClient:FindFirstChild("Shoot") or gun.GunClient:FindFirstChild("Shootts")))  
                             or gun:FindFirstChildOfClass("RemoteEvent")  

              if remote and remote:IsA("RemoteEvent") then    
                 remote:FireServer(calculatedCFrame, targetPos)  
              end    

              -- 3. Миттєве повернення на твоє місце
              root.CFrame = originalCFrame

              showCustomNotification("Shoot Murder", "Instant shot fired!", true)  
           end)    
        end    
            
        dragging = false    
        activeInput = nil    
        dragStart = nil    
        startPos = nil    
        hasMoved = false    
     end    
  end)    

  autoShootGui.Parent = playerGui
end
end

local function removeAutoShootGui()
if autoShootGui then autoShootGui:Destroy() autoShootGui = nil end
end

-- Drill Down Fling Engine
local function executeDrillDownFling(targetType)
if isFlingingActive then return end
isFlingingActive = true

task.spawn(function()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local character, root, humanoid, targetRoot, targetPlayer
local originalProperties = {}
local originalCanCollideStates = {}
local propertiesModified = false
local connection = nil
local cleanedUp = false
local originalCFrame = nil

local function cleanup()  
     if cleanedUp then return end  
     cleanedUp = true  

     if connection then connection:Disconnect() end  

     if propertiesModified then  
        for part, prop in pairs(originalProperties) do  
           if part and part.Parent then  
              part.CustomPhysicalProperties = prop  
              part.CanCollide = originalCanCollideStates[part]  
           end  
        end  
     end  

     if humanoid and humanoid.Parent then   
        humanoid.PlatformStand = false   
        humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)  
     end  
       
     if root and root.Parent then  
        root.AssemblyLinearVelocity = Vector3.zero  
        root.AssemblyAngularVelocity = Vector3.zero  
        root.Velocity = Vector3.zero  
        if originalCFrame then root.CFrame = originalCFrame end  
     end  
       
     isFlingingActive = false    
  end  

  local success, err = pcall(function()  
     character = player.Character  
     if not character or not character:FindFirstChild("HumanoidRootPart") then error("Local character missing") end    

     root = character.HumanoidRootPart    
     humanoid = character:FindFirstChildOfClass("Humanoid")    
     originalCFrame = root.CFrame    

     local playersList = Players:GetPlayers()  
     local targetPlayer = nil  
     for _, p in ipairs(playersList) do    
        if p ~= player and p.Character then    
           local backpack = p:FindFirstChild("Backpack")    
           local char = p.Character    
           local isKnife = (backpack and backpack:FindFirstChild("Knife")) or (char and char:FindFirstChild("Knife"))  
           local isGun = (backpack and backpack:FindFirstChild("Gun")) or (char and char:FindFirstChild("Gun"))  

           if (targetType == "Murder" and isKnife) or (targetType == "Sheriff" and isGun) then    
              if char:FindFirstChild("HumanoidRootPart") then    
                 targetPlayer = p  
                 targetRoot = char.HumanoidRootPart    
                 break    
              end    
           end    
        end    
     end    

     if not targetPlayer or not targetRoot then error("Target not found") end    

     local descendants = character:GetDescendants()  
     for _, part in ipairs(descendants) do  
        if part:IsA("BasePart") then  
           originalProperties[part] = part.CustomPhysicalProperties  
           originalCanCollideStates[part] = part.CanCollide  
           part.CustomPhysicalProperties = PhysicalProperties.new(100, 0.01, 1, 100, 100)  
           part.CanCollide = true  
        end  
     end  
     propertiesModified = true   

     if humanoid then   
        humanoid.PlatformStand = true   
        humanoid:ChangeState(Enum.HumanoidStateType.Physics)  
     end    

     local startTime = tick()    
     local spinSpeed = 4000    
     local downwardForce = -30000    

     connection = RunService.Heartbeat:Connect(function()    
        local runSuccess, runErr = pcall(function()  
           if not targetPlayer.Parent or not targetPlayer.Character or targetPlayer.Character ~= targetRoot.Parent or not targetRoot.Parent then    
              cleanup()  
              return    
           end    

           local targetHum = targetPlayer.Character:FindFirstChildOfClass("Humanoid")  
           if not targetHum or targetHum.Health <= 0 or (tick() - startTime > 2.0) then    
              cleanup()  
              return    
           end  

           local elapsed = tick() - startTime  
           local spinAngle = elapsed * spinSpeed  
           root.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 0) * CFrame.Angles(0, spinAngle, 0)  
             
           root.AssemblyLinearVelocity = Vector3.new(0, 20, 0)  
           root.AssemblyAngularVelocity = Vector3.new(0, spinSpeed, 0)  
           root.Velocity = Vector3.new(0, 20, 0)  

           targetRoot.AssemblyLinearVelocity = Vector3.new(math.random(-5000, 5000), downwardForce, math.random(-5000, 5000))  
           targetRoot.Velocity = Vector3.new(math.random(-5000, 5000), downwardForce, math.random(-5000, 5000))  
        end)  

        if not runSuccess then cleanup() end  
     end)  
  end)  

  if not success then cleanup() end
end)
end

local function findCoinContainerDeep()
local Workspace = game:GetService("Workspace")
local children = Workspace:GetChildren()
for _, child in ipairs(children) do
if child:IsA("Model") and child.Name ~= "Lobby" and child ~= Workspace.CurrentCamera then
local container = child:FindFirstChild("CoinContainer", true)
if container then return container end
end
end
return nil
end

local function getCoinPosition(cm)
if not cm then return nil end
local visual = cm:FindFirstChild("CoinVisual") or (cm.Name == "CoinVisual" and cm) or cm:FindFirstChild("CoinVisual", true)
if visual and visual:IsA("BasePart") then return visual.Position end
return nil
end

local function checkBagFull(player)
local playerGui = player:FindFirstChild("PlayerGui")
local mainGui = playerGui and playerGui:FindFirstChild("MainGUI")
local gameFrame = mainGui and mainGui:FindFirstChild("Game")

if not gameFrame or not gameFrame.Visible then return true end

local coinBags = gameFrame:FindFirstChild("CoinBags")
if coinBags and coinBags.Visible then
local descendants = coinBags:GetDescendants()
for _, obj in ipairs(descendants) do
if obj.Name == "FullBagIcon" and obj:IsA("GuiObject") and obj.Visible then return true end
end
return false
end
return true
end

-- Auto Fling Murder (When Bag Full)
local function executeAutoFlingMurderWhenFull()
task.spawn(function()
local Players = game:GetService("Players")
local player = Players.LocalPlayer

while autoFlingMurderWhenFull do  
     pcall(function()  
        if not checkBagFull(player) then  
           task.wait(1)  
           return  
        end  

        executeDrillDownFling("Murder")  
          
        while autoFlingMurderWhenFull and checkBagFull(player) do  
           task.wait(2)  
        end  
     end)  
     task.wait(1)  
  end
end)
end

-- Auto Kill All (When Bag Full)
local function executeAutoKillWhenFull()
task.spawn(function()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

while autoKillWhenFull do  
     pcall(function()  
        if not checkBagFull(player) then  
           task.wait(1)  
           return  
        end  

        local char = player.Character  
        if not char or not char:FindFirstChild("HumanoidRootPart") then  
           task.wait(1)  
           return  
        end  
        local root = char.HumanoidRootPart  
        local humanoid = char:FindFirstChildOfClass("Humanoid")  
        local backpack = player:FindFirstChild("Backpack")  

        local knife = char:FindFirstChild("Knife") or (backpack and backpack:FindFirstChild("Knife"))  
        if not knife then  
           task.wait(1)  
           return  
        end  

        if knife.Parent == backpack and humanoid then  
           humanoid:EquipTool(knife)  
           task.wait(0.05)  
        end  

        local targetRoots = {}  
        local PlayersList = Players:GetPlayers()  
        for _, p in ipairs(PlayersList) do  
           if p ~= player and p.Character and autoKillWhenFull then  
              local pChar = p.Character  
              local pRoot = pChar:FindFirstChild("HumanoidRootPart")  
              local pHum = pChar:FindFirstChildOfClass("Humanoid")  

              if pRoot and pHum and pHum.Health > 0 then  
                 table.insert(targetRoots, pRoot)  
                 local pCharDescendants = pChar:GetDescendants()  
                 for _, part in ipairs(pCharDescendants) do  
                    if part:IsA("BasePart") then  
                       part.CanCollide = false  
                    end  
                 end  
              end  
           end  
        end  

        if #targetRoots == 0 then  
           task.wait(1)  
           return  
        end  

        local startTime = tick()  
        local connection  
        connection = RunService.Heartbeat:Connect(function()  
           pcall(function()  
              if not checkBagFull(player) or (tick() - startTime > 5) then  
                 if connection then connection:Disconnect() end  
                 return  
              end  

              for _, tRoot in ipairs(targetRoots) do  
                 if tRoot and tRoot.Parent then  
                    tRoot.CFrame = root.CFrame * CFrame.new(0, 0, -2.5)  
                    tRoot.AssemblyLinearVelocity = Vector3.zero  
                    tRoot.AssemblyAngularVelocity = Vector3.zero  
                 end  
              end  

              if knife.Parent == char then  
                 knife:Activate()  
              end  
           end)  
        end)  

        while autoKillWhenFull and checkBagFull(player) and (tick() - startTime < 5) do  
           task.wait(0.2)  
        end  

        if connection then connection:Disconnect() end  

        for _, tRoot in ipairs(targetRoots) do  
           if tRoot and tRoot.Parent then  
              local pChar = tRoot.Parent  
              local pCharDescendants = pChar:GetDescendants()  
              for _, part in ipairs(pCharDescendants) do  
                 if part:IsA("BasePart") then  
                    part.CanCollide = true  
                 end  
              end  
           end  
        end  

        while autoKillWhenFull and checkBagFull(player) do  
           task.wait(2)  
        end  
     end)  
     task.wait(1)  
  end
end)
end

local function applySkinToTool(tool)
if not tool then return end
local handle = tool:FindFirstChild("Handle") or tool:FindFirstChildOfClass("BasePart")
if not handle then return end
local skinData = skinDatabase[activeSkinName]
if not skinData then return end

local mesh = handle:FindFirstChildOfClass("SpecialMesh")
if not mesh then mesh = Instance.new("SpecialMesh"); mesh.Parent = handle end
if skinData.MeshId ~= "" then mesh.MeshId = skinData.MeshId end
if skinData.TextureId ~= "" then mesh.TextureId = skinData.TextureId end
end

-- Optimized X-ray Logic
local function setupXrayPart(part)
if not part:IsA("BasePart") then return end
if part.Name:find("Coin") or part.Parent.Name:find("Coin") then return end

local Players = game:GetService("Players")
local player = Players.LocalPlayer
if player.Character and part:IsDescendantOf(player.Character) then return end
for _, p in ipairs(Players:GetPlayers()) do
if p.Character and part:IsDescendantOf(p.Character) then return end
end

if xrayEnabled then
if part:GetAttribute("OriginalTransparency") == nil then
part:SetAttribute("OriginalTransparency", part.Transparency)
end
part.Transparency = xrayTransparency
else
local orig = part:GetAttribute("OriginalTransparency")
if orig ~= nil then
part.Transparency = orig
part:SetAttribute("OriginalTransparency", nil)
end
end
end

local function updateXray()
local Workspace = game:GetService("Workspace")
for _, child in ipairs(Workspace:GetChildren()) do
if child:IsA("Model") and child ~= Workspace.CurrentCamera then
for _, obj in ipairs(child:GetDescendants()) do
setupXrayPart(obj)
end
end
end
end

workspace.DescendantAdded:Connect(function(obj)
if xrayEnabled and obj:IsA("BasePart") then
task.delay(0.1, function()
if obj and obj.Parent then
setupXrayPart(obj)
end
end)
end
end)

-- UI Elements Creation (Farming Tab)
FarmingTab:CreateDropdown({
Name = "Farm Method",
Options = {"Teleport", "Fly"},
CurrentOption = "Teleport",
Flag = "FarmMethodDropdown",
Callback = function(Option) farmMethod = Option end,
})

FarmingTab:CreateSlider({
Name = "Farm Speed (Fly Only)",
Range = {1, 33},
Increment = 1,
Suffix = "s/s",
CurrentValue = 25,
Flag = "FarmSpeedSlider",
Callback = function(Value) farmSpeed = Value end,
})

FarmingTab:CreateToggle({
Name = "Auto Farm Candy",
CurrentValue = false,
Flag = "AutoFarmCandyToggle",
Callback = function(Value)
autoFarmCandy = Value
currentFarmSession = currentFarmSession + 1
local mySessionId = currentFarmSession

if autoFarmCandy then    
     task.spawn(function()    
        local Players = game:GetService("Players")    
        local player = Players.LocalPlayer    

        while autoFarmCandy and (currentFarmSession == mySessionId) do    
           local success, err = pcall(function()    
              if checkBagFull(player) then    
                 task.wait(1)    
                 return    
              end    

              local character = player.Character    
              if not character or not character:FindFirstChild("HumanoidRootPart") then    
                 task.wait(0.5)    
                 return    
              end    
                  
              local root = character.HumanoidRootPart    
              local container = findCoinContainerDeep()    
              if not container or #container:GetChildren() == 0 then    
                 task.wait(1)    
                 return    
              end    

              local availableCoins = {}    
              local containerChildren = container:GetChildren()  
              for _, cm in ipairs(containerChildren) do    
                 local pos = getCoinPosition(cm)    
                 if pos then   
                    local dist = (root.Position - pos).Magnitude  
                    if dist <= 100 then  
                       table.insert(availableCoins, {Instance = cm, Position = pos})   
                    end  
                 end    
              end    

              if #availableCoins == 0 then  
                 for _, cm in ipairs(containerChildren) do    
                    local pos = getCoinPosition(cm)    
                    if pos then table.insert(availableCoins, {Instance = cm, Position = pos}) end    
                 end  
              end  

              if #availableCoins == 0 then task.wait(0.5); return end  

              local nearestCoin = nil    
              local nearestDist = math.huge    
              for _, coinData in ipairs(availableCoins) do    
                 local dist = (root.Position - coinData.Position).Magnitude    
                 if dist < nearestDist then nearestDist = dist; nearestCoin = coinData end    
              end    

              if nearestCoin and nearestCoin.Instance and nearestCoin.Instance.Parent then    
                 if farmMethod == "Teleport" then    
                    root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)  
                    root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)  
                    root.Velocity = Vector3.new(0, 0, 0)  
                      
                    root.CFrame = CFrame.new(nearestCoin.Position + Vector3.new(0, 0.2, 0))    
                      
                    showCustomNotification("Auto Farm", "+1 Candy", true)  

                    task.wait(0.01)  
                    if root and root.Parent then  
                       root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)  
                       root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)  
                       root.Velocity = Vector3.new(0, 0, 0)  
                    end  
                    task.wait(0.1)    
                 else    
                    local targetPos = nearestCoin.Position + Vector3.new(0, 0.2, 0)  
                    local RunService = game:GetService("RunService")  
                      
                    while autoFarmCandy and (currentFarmSession == mySessionId) do  
                       if not nearestCoin.Instance or not nearestCoin.Instance.Parent then break end  
                         
                       local currentPos = root.Position  
                       local distance = (currentPos - targetPos).Magnitude  
                         
                       if distance < 1 then  
                          root.CFrame = CFrame.new(targetPos)  
                          showCustomNotification("Auto Farm", "+1 Candy", true)  
                          break  
                       end  
                         
                       local step = math.clamp(farmSpeed * 0.08, 0.5, 3)  
                       local nextPos = currentPos:Lerp(targetPos, math.min(step / distance, 1))  
                         
                       root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)  
                       root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)  
                       root.CFrame = CFrame.new(nextPos, targetPos)  
                         
                       RunService.Heartbeat:Wait()  
                    end  
                    task.wait(0.02)  
                 end    
              end    
           end)    
           if not success then warn("AutoFarm Error:", err) end    
           task.wait(0.01)    
        end    
     end)    
  end
end,
})

FarmingTab:CreateToggle({
Name = "Fling Murder (When Bag Full)",
CurrentValue = false,
Flag = "AutoFlingMurderWhenFullToggle",
Callback = function(Value)
autoFlingMurderWhenFull = Value
if autoFlingMurderWhenFull then
executeAutoFlingMurderWhenFull()
end
end,
})

FarmingTab:CreateToggle({
Name = "Kill All (When Bag Full)",
CurrentValue = false,
Flag = "AutoKillWhenFullToggle",
Callback = function(Value)
autoKillWhenFull = Value
if autoKillWhenFull then
executeAutoKillWhenFull()
end
end,
})

FarmingTab:CreateToggle({
Name = "Anti Fling",
CurrentValue = false,
Flag = "AntiFlingToggle",
Callback = function(Value)
antiFlingEnabled = Value
updateAntiFling()
end,
})

-- UI Elements Creation (Fling Tab)
FlingTab:CreateButton({
Name = "Fling Murder",
Callback = function() executeDrillDownFling("Murder") end,
})

FlingTab:CreateButton({
Name = "Fling Sheriff / Hero",
Callback = function() executeDrillDownFling("Sheriff") end,
})

-- UI Elements Creation (Combat Tab)
CombatTab:CreateToggle({
Name = "Auto Grab Gun",
CurrentValue = false,
Flag = "AutoGrabGunToggle",
Callback = function(Value) autoGrabGunEnabled = Value end,
})

CombatTab:CreateToggle({
Name = "Auto Shoot Button",
CurrentValue = false,
Flag = "AutoShootButtonToggle",
Callback = function(Value)
autoShootButtonEnabled = Value
if autoShootButtonEnabled then createAutoShootGui() else removeAutoShootGui() end
end,
})

-- UI Elements Creation (Skins Tab)
SkinsTab:CreateDropdown({
Name = "Select Weapon Slot",
Options = {"Knife", "Gun"},
CurrentOption = "Gun",
Flag = "SkinSlotDropdown",
Callback = function(Option) selectedWeaponType = Option end,
})

SkinsTab:CreateDropdown({
Name = "Select Skin",
Options = {"Default", "GingerScope", "Celestial", "Emberbow", "Combain", "Evergun", "Laser Gun", "Luger", "Corrupt Knife"},
CurrentOption = "Default",
Flag = "SkinNameDropdown",
Callback = function(Option) activeSkinName = Option end,
})

SkinsTab:CreateButton({
Name = "Apply & Equip Skin",
Callback = function()
pcall(function()
local player = game:GetService("Players").LocalPlayer
local tool = (player.Character and player.Character:FindFirstChild(selectedWeaponType)) or (player.Backpack and player.Backpack:FindFirstChild(selectedWeaponType))
if tool then applySkinToTool(tool) end
end)
end,
})

-- UI Elements Creation (Visuals Tab)
VisualsTab:CreateToggle({
Name = "ESP Murder",
CurrentValue = false,
Flag = "ESPMurderToggle",
Callback = function(Value)
espMurderEnabled = Value
end,
})

VisualsTab:CreateToggle({
Name = "ESP Sheriff/Hero",
CurrentValue = false,
Flag = "ESPSheriffHeroToggle",
Callback = function(Value)
espSheriffHeroEnabled = Value
end,
})

VisualsTab:CreateToggle({
Name = "ESP Innocent",
CurrentValue = false,
Flag = "ESPInnocentToggle",
Callback = function(Value)
espInnocentEnabled = Value
end,
})

-- Main ESP Loop
task.spawn(function()
local Players = game:GetService("Players")
local player = Players.LocalPlayer

while true do
pcall(function()
local playersList = Players:GetPlayers()
for _, p in ipairs(playersList) do
if p ~= player and p.Character then
local char = p.Character
local hl = char:FindFirstChild("ESPHighlight")

local bp = p:FindFirstChild("Backpack")  
           local hasK = (bp and bp:FindFirstChild("Knife")) or char:FindFirstChild("Knife")  
           local hasG = (bp and bp:FindFirstChild("Gun")) or char:FindFirstChild("Gun")  

           local shouldHighlight = false  
           local highlightColor = Color3.fromRGB(255, 255, 255)  

           if hasK and espMurderEnabled then  
              shouldHighlight = true  
              highlightColor = Color3.fromRGB(255, 0, 0) -- Red (Murder)  
           elseif hasG and not hasK and espSheriffHeroEnabled then  
              if gunPickedUpDetected then  
                 shouldHighlight = true  
                 highlightColor = Color3.fromRGB(255, 255, 0) -- Hero (Yellow)  
              else  
                 shouldHighlight = true  
                 highlightColor = Color3.fromRGB(0, 100, 255) -- Sheriff (Blue)  
              end  
           elseif not hasK and not hasG and espInnocentEnabled then  
              shouldHighlight = true  
              highlightColor = Color3.fromRGB(0, 255, 0) -- Green (Innocent)  
           end  

           if shouldHighlight then  
              if not hl then  
                 hl = Instance.new("Highlight")  
                 hl.Name = "ESPHighlight"  
                 hl.FillTransparency = 0.5  
                 hl.OutlineTransparency = 0  
                 hl.OutlineColor = Color3.fromRGB(255, 255, 255)  
                 hl.Parent = char  
              end  
              hl.FillColor = highlightColor  
           else  
              if hl then  
                 hl:Destroy()  
              end  
           end  
        end  
     end  
  end)  
  task.wait(0.5)
end
end)

VisualsTab:CreateToggle({
Name = "Coins / Candy ESP (Orange)",
CurrentValue = false,
Flag = "CoinsESPToggle",
Callback = function(Value)
espCoinsEnabled = Value
if espCoinsEnabled then
task.spawn(function()
while espCoinsEnabled do
pcall(function()
local container = findCoinContainerDeep()
if container then
local containerChildren = container:GetChildren()
for _, cm in ipairs(containerChildren) do
local visual = cm:FindFirstChild("CoinVisual") or (cm.Name == "CoinVisual" and cm)
if visual and visual:IsA("BasePart") and not visual:FindFirstChild("CoinHighlight") then
local hl = Instance.new("Highlight")
hl.Name = "CoinHighlight"
hl.FillColor = Color3.fromRGB(255, 140, 0)
hl.OutlineColor = Color3.fromRGB(255, 255, 255)
hl.FillTransparency = 0.4
hl.Parent = visual
end
end
end
end)
task.wait(1)
end
end)
end
end,
})

-- X-ray Toggle
VisualsTab:CreateToggle({
Name = "X-ray",
CurrentValue = false,
Flag = "XRayToggle",
Callback = function(Value)
xrayEnabled = Value
updateXray()
end,
})

VisualsTab:CreateSlider({
Name = "X-Ray Transparency",
Range = {0, 1},
Increment = 0.05,
Suffix = "",
CurrentValue = 0.65,
Flag = "XRayTransparencySlider",
Callback = function(Value)
xrayTransparency = Value
if xrayEnabled then updateXray() end
end,
})
