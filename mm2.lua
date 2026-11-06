local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
Name = "MM2 Hub",
LoadingTitle = "Loading...",
LoadingSubtitle = "by Stas",
ConfigurationSaving = { Enabled = false },
KeySystem = false,
})

local FarmingTab = Window:CreateTab("Farming", 4483362458)
local FlingTab = Window:CreateTab("Fling", 4483362458)
local CombatTab = Window:CreateTab("Combat", 4483362458)
local SkinsTab = Window:CreateTab("Skins", 4483362458)
local VisualsTab = Window:CreateTab("Visuals", 4483362458)

local autoFarmCandy = false
local flingMurderOnFull = false
local killAllWhenFull = false
local antiFlingEnabled = false
local farmSpeed = 25
local farmMethod = "Fly"

local espPlayersEnabled = false
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
root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, math.clamp(root.AssemblyLinearVelocity.Y, -25, 25), root.AssemblyLinearVelocity.Z)
root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)

for _, p in ipairs(Players:GetPlayers()) do  
                 if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then  
                    local pRoot = p.Character.HumanoidRootPart  
                    if (root.Position - pRoot.Position).Magnitude < 5 then  
                       pRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)  
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

local function createAutoShootGui()
if autoShootGui then return end
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
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
  btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)  
  btn.BackgroundTransparency = 1  
  btn.Text = ""  
  btn.AutoButtonColor = false  
  btn.Parent = autoShootGui  
    
  local corner = Instance.new("UICorner")  
  corner.CornerRadius = UDim.new(0, 12)  
  corner.Parent = btn  
    
  local stroke = Instance.new("UIStroke")  
  stroke.Color = Color3.fromRGB(255, 0, 0)  
  stroke.Thickness = 4  
  stroke.Parent = btn  
    
  local textLabel = Instance.new("TextLabel")  
  textLabel.Size = UDim2.new(1, 0, 1, 0)  
  textLabel.BackgroundTransparency = 1  
  textLabel.Text = "Shoot Murder"  
  textLabel.TextColor3 = Color3.fromRGB(0, 0, 0)  
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
                
              local backpack = player:FindFirstChild("Backpack")  
              local gun = char:FindFirstChild("Gun") or (backpack and backpack:FindFirstChild("Gun"))  
              if not gun then return end  
                
              if gun.Parent == backpack then  
                 local humanoid = char:FindFirstChildOfClass("Humanoid")  
                 if humanoid then  
                    humanoid:EquipTool(gun)  
                 else  
                    gun.Parent = char  
                 end  
                 task.wait(0.1)  
              end  
                
              local targetRoot = nil  
              for _, p in ipairs(Players:GetPlayers()) do  
                 if p ~= player and p.Character then  
                    local pBackpack = p:FindFirstChild("Backpack")  
                    local pChar = p.Character  
                    local pRoot = pChar:FindFirstChild("HumanoidRootPart")  
                    local pHum = pChar:FindFirstChild("Humanoid")  
                      
                    local hasKnife = (pBackpack and pBackpack:FindFirstChild("Knife")) or pChar:FindFirstChild("Knife")  
                      
                    if hasKnife and pRoot and pHum and pHum.Health > 0 then  
                       targetRoot = pRoot  
                       break  
                    end  
                 end  
              end  
                
              if targetRoot then  
                 local targetPos = targetRoot.Position + (targetRoot.AssemblyLinearVelocity * 0.05)  
                   
                 local remote = gun:FindFirstChild("Shoot") or gun:FindFirstChild("RemoteEvent") or gun:FindFirstChildOfClass("RemoteEvent")  
                 if not remote then  
                    for _, obj in ipairs(gun:GetDescendants()) do  
                       if obj:IsA("RemoteEvent") then  
                          remote = obj  
                          break  
                       end  
                    end  
                 end  
                   
                 if remote and remote:IsA("RemoteEvent") then  
                    remote:FireServer(targetPos)  
                 else  
                    gun:Activate()  
                 end  
              end  
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

local function executeFlingOnTarget(targetType)
if isFlingingActive then return end
task.spawn(function()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local character = player.Character

if not character or not character:FindFirstChild("HumanoidRootPart") then return end  
  local root = character.HumanoidRootPart  
  local humanoid = character:FindFirstChildOfClass("Humanoid")  
  local originalCFrame = root.CFrame  

  local targetRoot = nil  
  local targetHum = nil  
  local targetChar = nil  
    
  for _, p in ipairs(Players:GetPlayers()) do  
     if p ~= player and p.Character then  
        local backpack = p:FindFirstChild("Backpack")  
        local char = p.Character  
        local isKnife = (backpack and backpack:FindFirstChild("Knife")) or char:FindFirstChild("Knife")  
        local isGun = (backpack and backpack:FindFirstChild("Gun")) or char:FindFirstChild("Gun")  
          
        if (targetType == "Murder" and isKnife) or (targetType == "Sheriff" and isGun) then  
           if char:FindFirstChild("HumanoidRootPart") and char:FindFirstChildOfClass("Humanoid") then  
              targetRoot = char.HumanoidRootPart  
              targetHum = char:FindFirstChildOfClass("Humanoid")  
              targetChar = char  
              break  
           end  
        end  
     end  
  end  

  if targetRoot and targetChar then  
     isFlingingActive = true  

     local originalCollisions = {}  
     local targetPartsCollisions = {}  
     
     pcall(function()
        for _, part in ipairs(character:GetDescendants()) do  
           if part:IsA("BasePart") then  
              originalCollisions[part] = part.CanCollide  
              part.CanCollide = false  
           end  
        end  

        for _, part in ipairs(targetChar:GetDescendants()) do  
           if part:IsA("BasePart") then  
              targetPartsCollisions[part] = part.CanCollide  
           end  
        end  
     end)  

     if humanoid then humanoid.PlatformStand = true end  

     local startTime = tick()  
     local connection  

     connection = RunService.Heartbeat:Connect(function()  
        if not character or not character.Parent or not targetRoot or not targetRoot.Parent then  
           if connection then connection:Disconnect() end  
           root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)  
           root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)  
           if humanoid then humanoid.PlatformStand = false end  
           root.CFrame = originalCFrame  
           for part, canCollideState in pairs(originalCollisions) do  
              if part and part.Parent then part.CanCollide = canCollideState end  
           end  
           isFlingingActive = false  
           return  
        end  

        pcall(function()  
           if targetHum and targetHum.Parent then  
              targetHum.PlatformStand = true  
              targetHum.WalkSpeed = 0  
              targetHum.JumpPower = 0  
              targetHum.AutoRotate = false  
           end  
           if targetRoot and targetRoot.Parent then  
              targetRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)  
              targetRoot.AssemblyAngularVelocity = Vector3.new(0, 0, 0)  
           end  
           for part, _ in pairs(targetPartsCollisions) do  
              if part and part.Parent then  
                 part.CanCollide = false  
              end  
           end  
        end)  

        root.CFrame = targetRoot.CFrame * CFrame.new(0, 0.5, 0)  
        root.AssemblyLinearVelocity = Vector3.new(35000, 35000, 35000)  
        root.AssemblyAngularVelocity = Vector3.new(0, 99999, 0)  

        if tick() - startTime > 0.3 then  
           if connection then connection:Disconnect() end  
             
           pcall(function()  
              if targetHum and targetHum.Parent then  
                 targetHum.PlatformStand = false  
                 targetHum.WalkSpeed = 16  
                 targetHum.JumpPower = 50  
                 targetHum.AutoRotate = true  
              end  
              for part, canCollideState in pairs(targetPartsCollisions) do  
                 if part and part.Parent then  
                    part.CanCollide = canCollideState  
                 end  
              end  
           end)  

           root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)  
           root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)  
           if humanoid then humanoid.PlatformStand = false end  
           root.CFrame = originalCFrame  

           for part, canCollideState in pairs(originalCollisions) do  
              if part and part.Parent then  
                 part.CanCollide = canCollideState  
              end  
           end  

           isFlingingActive = false  
        end  
     end)  
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

local oldHighlight = handle:FindFirstChild("SkinGlow")
if oldHighlight then oldHighlight:Destroy() end

if activeSkinName == "GingerScope" and tool:IsA("Tool") then
local glow = Instance.new("SelectionBox")
glow.Name = "SkinGlow"
glow.Color3 = Color3.fromRGB(255, 140, 0)
glow.LineThickness = 0.03
glow.Adornee = handle
glow.Parent = handle
tool.Activated:Connect(function()
pcall(function()
local snd = handle:FindFirstChild("FireSound") or handle:FindFirstChildOfClass("Sound")
if snd then snd:Play() end
end)
end)
end
end

local function findCoinContainerDeep()
local Workspace = game:GetService("Workspace")

local function recursiveSearch(parent)
for _, child in ipairs(parent:GetChildren()) do
if child.Name == "CoinContainer" then
return child
end

local success, children = pcall(function()  
        return child:GetChildren()  
     end)  
       
     if success and #children > 0 then  
        local found = recursiveSearch(child)  
        if found then return found end  
     end  
  end  
  return nil

end

local container = recursiveSearch(Workspace)
if container then return container end

for _, obj in ipairs(Workspace:GetDescendants()) do
if obj:IsA("Instance") and obj.Name == "CoinContainer" then
return obj
end
end

return nil
end

local function getCoinPosition(cm)
if not cm then return nil end

local visual = cm:FindFirstChild("CoinVisual")
if visual and visual:IsA("BasePart") then
return visual.Position
end

if cm.Name == "CoinVisual" and cm:IsA("BasePart") then
return cm.Position
end

local anyVisual = cm:FindFirstChild("CoinVisual", true)
if anyVisual and anyVisual:IsA("BasePart") then
return anyVisual.Position
end

return nil
end

local function checkBagVisible(player)
local playerGui = player:FindFirstChild("PlayerGui")
local mainGui = playerGui and playerGui:FindFirstChild("MainGUI")
local gameFrame = mainGui and mainGui:FindFirstChild("Game")
local coinBags = gameFrame and gameFrame:FindFirstChild("CoinBags")

if coinBags and coinBags:IsA("GuiObject") and coinBags.Visible then
return true
elseif coinBags and not coinBags:IsA("GuiObject") then
for _, obj in ipairs(coinBags:GetDescendants()) do
if obj:IsA("GuiObject") and obj.Visible then
return true
end
end
end
return false
end

local function checkBagFull(player)
local playerGui = player:FindFirstChild("PlayerGui")
local mainGui = playerGui and playerGui:FindFirstChild("MainGUI")
local gameFrame = mainGui and mainGui:FindFirstChild("Game")
local coinBags = gameFrame and gameFrame:FindFirstChild("CoinBags")

if coinBags then
for _, obj in ipairs(coinBags:GetDescendants()) do
if obj.Name == "FullBagIcon" and obj:IsA("GuiObject") and obj.Visible then
return true
end
end
end
return false
end

-- Автоматический полноценный флинг убийцы при заполнении сумки до 50
task.spawn(function()
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local lastFlingTime = 0

while true do
pcall(function()
if flingMurderOnFull then
if checkBagFull(player) then
if tick() - lastFlingTime > 15 then
lastFlingTime = tick()
executeFlingOnTarget("Murder")
end
end
end
end)
task.wait(1)
end
end)

local xrayConnection = nil

local function setupXrayPart(part)
if not part:IsA("BasePart") then return end

local ancestor = part.Parent
while ancestor and ancestor ~= workspace do
if ancestor.Name == "CoinContainer" or ancestor.Name == "Coin_Server" then
return
end
ancestor = ancestor.Parent
end

if part.Name == "CoinVisual" or part.Name == "Coin" or part.Name == "CoinContainer" or part.Name == "Coin_Server" then
return
end

local Players = game:GetService("Players")
local isPlayer = false
for _, p in ipairs(Players:GetPlayers()) do
if p.Character and (part == p.Character or part:IsDescendantOf(p.Character)) then
isPlayer = true
break
end
end

local isTerrain = part:IsA("Terrain")

if not isPlayer and not isTerrain then
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
end

local function updateXray()
local Workspace = game:GetService("Workspace")

for _, child in ipairs(Workspace:GetChildren()) do
if child:IsA("Model") and child ~= Workspace.CurrentCamera then
local isPlayerModel = false
for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
if p.Character == child then isPlayerModel = true break end
end

if not isPlayerModel and child.Name ~= "CoinContainer" then
for _, obj in ipairs(child:GetDescendants()) do
setupXrayPart(obj)
end
end
end
end

if xrayEnabled then
if not xrayConnection then
xrayConnection = Workspace.DescendantAdded:Connect(function(child)
if xrayEnabled then
task.defer(function()
setupXrayPart(child)
end)
end
end)
end
else
if xrayConnection then
xrayConnection:Disconnect()
xrayConnection = nil
end
end
end

FarmingTab:CreateDropdown({
Name = "Farm Method",
Options = {"Fly", "Teleport"},
CurrentOption = "Fly",
Flag = "FarmMethodDropdown",
Callback = function(Option)
farmMethod = Option
end,
})

FarmingTab:CreateSlider({
Name = "Farm Speed (Studs/s)",
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
                 task.wait(2)  
                 return  
              end  

              if not checkBagVisible(player) then  
                 task.wait(1)  
                 return  
              end  

              local character = player.Character  
              if not character or not character:FindFirstChild("HumanoidRootPart") then  
                 task.wait(0.5)  
                 return  
              end  
                
              local root = character.HumanoidRootPart  
              local humanoid = character:FindFirstChildOfClass("Humanoid")  

              local container = findCoinContainerDeep()  
              if not container or #container:GetChildren() == 0 then  
                 task.wait(1)  
                 return  
              end  

              local availableCoins = {}  
              for _, cm in ipairs(container:GetChildren()) do  
                 local pos = getCoinPosition(cm)  
                 if pos then  
                    table.insert(availableCoins, {Instance = cm, Position = pos})  
                 end  
              end  

              if #availableCoins > 0 then  
                 local nearestCoin = nil  
                 local nearestDist = math.huge  

                 for _, coinData in ipairs(availableCoins) do  
                    local dist = (root.Position - coinData.Position).Magnitude  
                    if dist < nearestDist then  
                       nearestDist = dist  
                       nearestCoin = coinData  
                    end  
                 end  

                 if nearestCoin then  
                    local originalCollisions = {}  
                    for _, part in ipairs(character:GetDescendants()) do  
                       if part:IsA("BasePart") then  
                          originalCollisions[part] = part.CanCollide  
                          part.CanCollide = false  
                       end  
                    end  
                    if humanoid then humanoid.PlatformStand = true end  

                    local function cleanupFarm()  
                       pcall(function()  
                          if humanoid and humanoid.Parent then  
                             humanoid.PlatformStand = false  
                          end  
                          root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)  
                          root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)  
                          for part, canCollideState in pairs(originalCollisions) do  
                             if part and part.Parent then  
                                part.CanCollide = canCollideState  
                             end  
                          end  
                       end)  
                    end  

                    if farmMethod == "Teleport" then  
                       if not checkBagVisible(player) then  
                          cleanupFarm()  
                          return  
                       end  
                       root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)  
                       root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)  
                       root.CFrame = CFrame.new(nearestCoin.Position)  
                         
                       for _, coinDataObj in ipairs(availableCoins) do  
                          if coinDataObj and coinDataObj.Position and coinDataObj.Instance and coinDataObj.Instance.Parent then  
                             if (root.Position - coinDataObj.Position).Magnitude <= 8 then  
                                pcall(function()  
                                   root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)  
                                   root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)  
                                   root.CFrame = CFrame.new(coinDataObj.Position)  
                                   task.wait(0.2)  
                                end)  
                             end  
                          end  
                       end  
                    else  
                       local startPos = root.Position  
                       local targetPos = nearestCoin.Position  
                       local distance = (startPos - targetPos).Magnitude  
                       local travelTime = distance / math.clamp(farmSpeed, 1, 33)  
                       local startTime = tick()  

                       while autoFarmCandy and (currentFarmSession == mySessionId) do  
                          if not checkBagVisible(player) then break end  

                          local elapsed = tick() - startTime  
                          local alpha = math.clamp(elapsed / travelTime, 0, 1)  
                            
                          root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)  
                          root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)  
                            
                          local currentPos = startPos:Lerp(targetPos, alpha)  
                          root.CFrame = CFrame.new(currentPos)  
                            
                          for _, coinDataObj in ipairs(availableCoins) do  
                             if coinDataObj and coinDataObj.Position and coinDataObj.Instance and coinDataObj.Instance.Parent then  
                                if (root.Position - coinDataObj.Position).Magnitude <= 8 then  
                                   pcall(function()  
                                      root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)  
                                      root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)  
                                      root.CFrame = CFrame.new(coinDataObj.Position)  
                                      task.wait(0.2)  
                                   end)  
                                end  
                             end  
                          end  

                          if alpha >= 1 then break end  
                          task.wait(0.01)  
                       end  

                       if autoFarmCandy and (currentFarmSession == mySessionId) and checkBagVisible(player) then  
                          root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)  
                          root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)  
                          root.CFrame = CFrame.new(targetPos)  
                       end  
                    end  

                    task.wait(0.2)  
                    cleanupFarm()  
                 end  
              else  
                 task.wait(0.5)  
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
Name = "Anti-Fling Protection",
CurrentValue = false,
Flag = "AntiFlingToggle",
Callback = function(Value)
antiFlingEnabled = Value
updateAntiFling()
end,
})

FarmingTab:CreateToggle({
Name = "Fling Murder When Full",
CurrentValue = false,
Flag = "FlingMurderWhenFullToggle",
Callback = function(Value) flingMurderOnFull = Value end,
})

FarmingTab:CreateToggle({
Name = "Kill All When Full (If Murder)",
CurrentValue = false,
Flag = "KillAllWhenFullToggle",
Callback = function(Value) killAllWhenFull = Value end,
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

FlingTab:CreateButton({
Name = "Fling Murder",
Callback = function() executeFlingOnTarget("Murder") end,
})

FlingTab:CreateButton({
Name = "Fling Sheriff / Hero",
Callback = function() executeFlingOnTarget("Sheriff") end,
})

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

VisualsTab:CreateToggle({
Name = "Player ESP (Role Colors)",
CurrentValue = false,
Flag = "PlayerESPToggle",
Callback = function(Value)
espPlayersEnabled = Value
if espPlayersEnabled then
task.spawn(function()
local Players = game:GetService("Players")
local player = Players.LocalPlayer
while espPlayersEnabled do
pcall(function()
for _, p in ipairs(Players:GetPlayers()) do
if p ~= player and p.Character then
local char = p.Character
local hl = char:FindFirstChild("ESPHighlight")
if not hl then
hl = Instance.new("Highlight")
hl.Name = "ESPHighlight"
hl.FillTransparency = 0.5
hl.OutlineTransparency = 0
hl.OutlineColor = Color3.fromRGB(255, 255, 255)
hl.Parent = char
end
local bp = p:FindFirstChild("Backpack")
if (bp and bp:FindFirstChild("Knife")) or char:FindFirstChild("Knife") then
hl.FillColor = Color3.fromRGB(255, 0, 0)
elseif (bp and bp:FindFirstChild("Gun")) or char:FindFirstChild("Gun") then
hl.FillColor = Color3.fromRGB(0, 100, 255)
else
hl.FillColor = Color3.fromRGB(0, 255, 0)
end
end
end
end)
task.wait(0.5)
end
for _, p in ipairs(Players:GetPlayers()) do
if p.Character and p.Character:FindFirstChild("ESPHighlight") then p.Character.ESPHighlight:Destroy() end
end
end)
end
end,
})

VisualsTab:CreateToggle({
Name = "Coins / Candy ESP",
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
for _, cm in ipairs(container:GetChildren()) do
local visual = cm:FindFirstChild("CoinVisual") or (cm.Name == "CoinVisual" and cm)
if visual and visual:IsA("BasePart") and not visual:FindFirstChild("CoinHighlight") then
local hl = Instance.new("Highlight")
hl.Name = "CoinHighlight"
hl.FillColor = Color3.fromRGB(255, 140, 0) -- Оранжевый цвет
hl.OutlineColor = Color3.fromRGB(255, 255, 255)
hl.FillTransparency = 0.4
hl.Parent = visual
end
end
end
end)
task.wait(1)
end

local container = findCoinContainerDeep()  
        if container then  
           for _, cm in ipairs(container:GetChildren()) do  
              local visual = cm:FindFirstChild("CoinVisual") or (cm.Name == "CoinVisual" and cm)  
              if visual and visual:FindFirstChild("CoinHighlight") then  
                 visual.CoinHighlight:Destroy()  
              end  
           end  
        end  
     end)  
  end

end,
})

VisualsTab:CreateToggle({
Name = "X-Ray (Transparent Walls)",
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
if xrayEnabled then
updateXray()
end
end,
})
