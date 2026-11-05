local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "MM2 Hub",
   LoadingTitle = "Loading...",
   LoadingSubtitle = "by User",
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
local autoGrabGunEnabled = false
local farmSpeed = 25

local espPlayersEnabled = false
local espCoinsEnabled = false

local activeFarmRoutine = nil
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
      btn.Size = UDim2.new(0, 120, 0, 120)
      btn.Position = UDim2.new(0.5, -60, 0.75, 0)
      btn.BackgroundColor3 = Color3.fromRGB(120, 120, 120)
      btn.BackgroundTransparency = 0.4
      btn.TextColor3 = Color3.fromRGB(0, 0, 0)
      btn.TextSize = 18
      btn.Font = Enum.Font.SourceSansBold
      btn.Text = "auto Shoot"
      btn.TextWrapped = true
      btn.Parent = autoShootGui
      
      local textStroke = Instance.new("UIStroke")
      textStroke.Color = Color3.fromRGB(255, 255, 255)
      textStroke.Thickness = 1.2
      textStroke.Parent = btn
      
      local corner = Instance.new("UICorner")
      corner.CornerRadius = UDim.new(0, 8)
      corner.Parent = btn
      
      local stroke = Instance.new("UIStroke")
      stroke.Color = Color3.fromRGB(180, 180, 180)
      stroke.Thickness = 2
      stroke.Parent = btn

      local dragging, dragInput, dragStart, startPos
      btn.InputBegan:Connect(function(input)
         if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = btn.Position
            input.Changed:Connect(function()
               if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
         end
      end)
      
      btn.InputChanged:Connect(function(input)
         if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
         end
      end)
      
      UserInputService.InputChanged:Connect(function(input)
         if input == dragInput and dragging then
            local delta = input.Position - dragStart
            btn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
         end
      end)
      
      btn.MouseButton1Click:Connect(function()
         pcall(function()
            local char = player.Character
            local backpack = player:FindFirstChild("Backpack")
            local gun = (backpack and backpack:FindFirstChild("Gun")) or (char and char:FindFirstChild("Gun"))
            if not gun then return end
            if gun.Parent == backpack then gun.Parent = char end
            
            local targetChar = nil
            for _, p in ipairs(Players:GetPlayers()) do
               if p ~= player and p.Character then
                  local pBackpack = p:FindFirstChild("Backpack")
                  local pChar = p.Character
                  if ((pBackpack and pBackpack:FindFirstChild("Knife")) or pChar:FindFirstChild("Knife")) and pChar:FindFirstChild("HumanoidRootPart") then
                     targetChar = pChar
                     break
                  end
               end
            end
            
            if targetChar and targetChar:FindFirstChild("HumanoidRootPart") then
               local targetRoot = targetChar.HumanoidRootPart
               gun:Activate()
               task.wait(0.05)
               gun:FindFirstChild("RemoteEvent"):FireServer(1, targetRoot.Position, "AH")
            end
         end)
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
      local originalCFrame = root.CFrame
      
      local targetRoot = nil
      for _, p in ipairs(Players:GetPlayers()) do
         if p ~= player and p.Character then
            local backpack = p:FindFirstChild("Backpack")
            local char = p.Character
            local isKnife = (backpack and backpack:FindFirstChild("Knife")) or char:FindFirstChild("Knife")
            local isGun = (backpack and backpack:FindFirstChild("Gun")) or char:FindFirstChild("Gun")
            
            if (targetType == "Murder" and isKnife) or (targetType == "Sheriff" and isGun) then
               if char:FindFirstChild("HumanoidRootPart") then
                  targetRoot = char.HumanoidRootPart
                  break
               end
            end
         end
      end
      
      if targetRoot then
         isFlingingActive = true
         local startTime = tick()
         
         for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
         end
         
         local connection
         connection = RunService.Heartbeat:Connect(function()
            if not character or not character.Parent or not targetRoot or not targetRoot.Parent then
               if connection then connection:Disconnect() end
               isFlingingActive = false
               return
            end
            
            local salt = tick() * 60
            local pos = targetRoot.Position
            root.CFrame = CFrame.new(pos + Vector3.new(math.sin(salt) * 2, -5, math.cos(salt) * 2))
            
            root.AssemblyLinearVelocity = Vector3.new(50000, -100000, 50000)
            root.AssemblyAngularVelocity = Vector3.new(99999, 99999, 99999)
            
            if tick() - startTime > 1.2 then
               if connection then connection:Disconnect() end
               root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
               root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
               root.CFrame = originalCFrame
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
            local Workspace = game:GetService("Workspace")
            local player = Players.LocalPlayer

            while autoFarmCandy and (currentFarmSession == mySessionId) do
               local success, err = pcall(function()
                  local character = player.Character
                  if not character or not character:FindFirstChild("HumanoidRootPart") then
                     task.wait(0.5)
                     return
                  end
                  
                  local root = character.HumanoidRootPart
                  
                  local reachedLimit = false
                  local playerGui = player:FindFirstChild("PlayerGui")
                  local mainGui = playerGui and playerGui:FindFirstChild("MainGUI")
                  local gameFrame = mainGui and mainGui:FindFirstChild("Game")
                  local coinBags = gameFrame and gameFrame:FindFirstChild("CoinBags")
                  
                  if coinBags then
                     for _, bag in ipairs(coinBags:GetChildren()) do
                        local fullIcon = bag:FindFirstChild("FullBagIcon")
                        if fullIcon and fullIcon:IsA("GuiObject") and fullIcon.Visible then
                           reachedLimit = true
                           break
                        end
                     end
                  end
                  
                  if reachedLimit then
                     autoFarmCandy = false
                     currentFarmSession = currentFarmSession + 1
                     
                     if flingMurderOnFull then
                        executeFlingOnTarget("Murder")
                     elseif killAllWhenFull then
                        local backpack = player:FindFirstChild("Backpack")
                        local knife = (backpack and backpack:FindFirstChild("Knife")) or (character and character:FindFirstChild("Knife"))
                        if knife then
                           knife.Parent = character
                           
                           for _, p in ipairs(Players:GetPlayers()) do
                              if p ~= player and p.Character then
                                 local targetChar = p.Character
                                 local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
                                 local targetHum = targetChar:FindFirstChild("Humanoid")
                                 
                                 if targetRoot and targetHum and targetHum.Health > 0 then
                                    pcall(function()
                                       local remote = knife:FindFirstChild("RemoteEvent") or knife:FindFirstChildOfClass("RemoteEvent")
                                       if remote then
                                          remote:FireServer("Throw", targetRoot.Position)
                                       end
                                    end)
                                    task.wait(0.02)
                                 end
                              end
                           end
                        end
                     end
                     return
                  end

                  local map = Workspace:FindFirstChild("Map")
                  if not map then task.wait(0.5) return end

                  local container = map:FindFirstChild("CoinContainer")
                  if not container then task.wait(0.5) return end

                  local availableCoins = {}
                  for _, cm in ipairs(container:GetChildren()) do
                     if cm.Name == "Coin_Server" then
                        local visual = cm:FindFirstChild("CoinVisual")
                        if visual and visual:IsA("BasePart") then
                           table.insert(availableCoins, visual)
                        end
                     end
                  end

                  table.sort(availableCoins, function(a, b)
                     return (root.Position - a.Position).Magnitude < (root.Position - b.Position).Magnitude
                  end)

                  if #availableCoins > 0 then
                     for _, targetCoin in ipairs(availableCoins) do
                        if not autoFarmCandy or (currentFarmSession ~= mySessionId) then break end
                        if targetCoin and targetCoin.Parent and targetCoin.Parent.Parent then
                           local targetPos = targetCoin.Position
                           local startPos = root.Position
                           local distance = (startPos - targetPos).Magnitude
                           local selectedSpeed = math.clamp(farmSpeed, 1, 33)
                           local travelTime = distance / selectedSpeed
                           local startTime = tick()
                           
                           while autoFarmCandy and (currentFarmSession == mySessionId) do
                              local elapsed = tick() - startTime
                              local alpha = math.clamp(elapsed / travelTime, 0, 1)
                              if not targetCoin or not targetCoin.Parent then break end
                              
                              local currentRotation = root.CFrame - root.CFrame.Position
                              local currentPos = startPos:Lerp(targetCoin.Position, alpha)
                              root.CFrame = currentRotation + currentPos
                              
                              if alpha >= 1 then break end
                              task.wait(0.01)
                           end
                           
                           if autoFarmCandy and (currentFarmSession == mySessionId) then
                              root.CFrame = (root.CFrame - root.CFrame.Position) + targetPos
                              task.wait(0.2)
                           end
                        end
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
   Name = "Anti-Fling Protection",
   CurrentValue = false,
   Flag = "AntiFlingToggle",
   Callback = function(Value) antiFlingEnabled = Value end,
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
            local Workspace = game:GetService("Workspace")
            while espCoinsEnabled do
               pcall(function()
                  local map = Workspace:FindFirstChild("Map")
                  if map then
                     local container = map:FindFirstChild("CoinContainer")
                     if container then
                        for _, cm in ipairs(container:GetChildren()) do
                           if cm.Name == "Coin_Server" then
                              local vis = cm:FindFirstChild("CoinVisual")
                              if vis and vis:IsA("BasePart") and not vis:FindFirstChild("CoinHighlight") then
                                 local hl = Instance.new("Highlight")
                                 hl.Name = "CoinHighlight"
                                 hl.FillColor = Color3.fromRGB(255, 215, 0)
                                 hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                                 hl.FillTransparency = 0.4
                                 hl.Parent = vis
                              end
                           end
                        end
                     end
                  end
               end)
               task.wait(1)
            end
            local map = Workspace:FindFirstChild("Map")
            if map and map:FindFirstChild("CoinContainer") then
               for _, cm in ipairs(map.CoinContainer:GetChildren()) do
                  local vis = cm:FindFirstChild("CoinVisual")
                  if vis and vis:FindFirstChild("CoinHighlight") then vis.CoinHighlight:Destroy() end
               end
            end
         end)
      end
   end,
})
