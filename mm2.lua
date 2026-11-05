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
local farmUnderground = false
local flingMurderOnFull = false
local killAllWhenFull = false
local antiFlingEnabled = false
local autoGrabGunEnabled = false
local farmSpeed = 20

local espPlayersEnabled = false
local espCoinsEnabled = false

local activeTween = nil
local activeFarmRoutine = nil
local currentFarmSession = 0
local isFlingingActive = false

local autoShootGui = nil
local autoShootButtonEnabled = false

local selectedWeaponType = "Gun"
local activeSkinName = "Default"

local skinDatabase = {
   ["Default"] = {MeshId = "", TextureId = ""},

   ["GingerScope"] = {
      MeshId = "rbxassetid://15622152775", 
      TextureId = "rbxassetid://15622152865"
   },
   ["Celestial"] = {
      MeshId = "rbxassetid://14013441230", 
      TextureId = "rbxassetid://14013441315"
   },
   ["Emberbow"] = {
      MeshId = "rbxassetid://15622157077", 
      TextureId = "rbxassetid://15622157144"
   },
   ["Combain"] = {
      MeshId = "rbxassetid://13812499120", 
      TextureId = "rbxassetid://13812499245"
   },
   ["Evergun"] = {
      MeshId = "rbxassetid://15622157077", 
      TextureId = "rbxassetid://15622157144"
   },
   ["Laser Gun"] = {
      MeshId = "rbxassetid://460652273",
      TextureId = "rbxassetid://460652303"
   },
   ["Luger"] = {
      MeshId = "rbxassetid://460652516",
      TextureId = "rbxassetid://460652545"
   },
   ["Corrupt Knife"] = {
      MeshId = "rbxassetid://460651877",
      TextureId = "rbxassetid://460651900"
   }
}

local function createAutoShootGui()
   if autoShootGui then return end
   
   local Players = game:GetService("Players")
   local player = Players.LocalPlayer
   local playerGui = player:FindFirstChild("PlayerGui")
   
   if playerGui then
      autoShootGui = Instance.new("ScreenGui")
      autoShootGui.Name = "MM2AutoShootGui"
      autoShootGui.ResetOnSpawn = false
      
      local btn = Instance.new("TextButton")
      btn.Name = "ShootButton"
      btn.Size = UDim2.new(0, 160, 0, 50)
      btn.Position = UDim2.new(0.5, -80, 0.85, 0)
      btn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
      btn.TextColor3 = Color3.fromRGB(255, 255, 255)
      btn.TextSize = 18
      btn.Font = Enum.Font.SourceSansBold
      btn.Text = "SHOOT MURDER"
      btn.Parent = autoShootGui
      
      local corner = Instance.new("UICorner")
      corner.CornerRadius = UDim.new(0, 10)
      corner.Parent = btn
      
      btn.MouseButton1Click:Connect(function()
         local success, err = pcall(function()
            local char = player.Character
            local backpack = player:FindFirstChild("Backpack")
            local gun = (backpack and backpack:FindFirstChild("Gun")) or (char and char:FindFirstChild("Gun"))
            
            if not gun then return end
            if gun.Parent == backpack then
               gun.Parent = char
            end
            
            local targetChar = nil
            for _, p in ipairs(Players:GetPlayers()) do
               if p ~= player and p.Character then
                  local pBackpack = p:FindFirstChild("Backpack")
                  local pChar = p.Character
                  local isKnife = (pBackpack and pBackpack:FindFirstChild("Knife")) or pChar:FindFirstChild("Knife")
                  if isKnife and pChar:FindFirstChild("HumanoidRootPart") then
                     targetChar = pChar
                     break
                  end
               end
            end
            
            if targetChar and targetChar:FindFirstChild("HumanoidRootPart") then
               local targetRoot = targetChar.HumanoidRootPart
               gun:Activate()
               task.wait(0.05)
               local args = {
                  [1] = 1,
                  [2] = targetRoot.Position,
                  [3] = "AH"
               }
               gun:FindFirstChild("RemoteEvent"):FireServer(unpack(args))
            end
         end)
         if not success then
            warn("AutoShoot Error:", err)
         end
      end)
      
      autoShootGui.Parent = playerGui
   end
end

local function removeAutoShootGui()
   if autoShootGui then
      autoShootGui:Destroy()
      autoShootGui = nil
   end
end

local function executeFlingOnTarget(targetType)
   task.spawn(function()
      local Players = game:GetService("Players")
      local RunService = game:GetService("RunService")
      local player = Players.LocalPlayer
      local character = player.Character
      
      if not character or not character:FindFirstChild("HumanoidRootPart") then return end
      local root = character.HumanoidRootPart
      local originalCFrame = root.CFrame
      
      local targetRoot = nil
      local targetChar = nil
      
      for _, p in ipairs(Players:GetPlayers()) do
         if p ~= player and p.Character then
            local backpack = p:FindFirstChild("Backpack")
            local char = p.Character
            local isKnife = (backpack and backpack:FindFirstChild("Knife")) or char:FindFirstChild("Knife")
            local isGun = (backpack and backpack:FindFirstChild("Gun")) or char:FindFirstChild("Gun")
            
            if targetType == "Murder" and isKnife then
               if char:FindFirstChild("HumanoidRootPart") then
                  targetChar = char
                  targetRoot = char.HumanoidRootPart
                  break
               end
            elseif targetType == "Sheriff" and isGun then
               if char:FindFirstChild("HumanoidRootPart") then
                  targetChar = char
                  targetRoot = char.HumanoidRootPart
                  break
               end
            end
         end
      end
      
      if targetRoot and targetChar then
         isFlingingActive = true
         local startTime = tick()
         
         for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
               part.CanCollide = false
            end
         end
         
         local connection
         connection = RunService.RenderStepped:Connect(function()
            if not character or not character:FindFirstChild("HumanoidRootPart") or not targetRoot or not targetRoot.Parent then
               if connection then connection:Disconnect() end
               isFlingingActive = false
               return
            end
            
            for _, part in ipairs(targetChar:GetDescendants()) do
               if part:IsA("BasePart") then
                  part.CanCollide = true
               end
            end
            
            local randomOffset = CFrame.new(math.random(-4, 4), math.random(-2, 2), math.random(-4, 4))
            root.CFrame = targetRoot.CFrame * randomOffset
            
            root.AssemblyLinearVelocity = Vector3.new(500000, 500000, 500000)
            root.AssemblyAngularVelocity = Vector3.new(99999, 99999, 99999)
            
            targetRoot.AssemblyLinearVelocity = Vector3.new(math.random(-50000, 50000), -500000, math.random(-50000, 50000))
            
            if tick() - startTime > 1.5 then
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
   if not tool or activeSkinName == "Default" then return end
   
   local handle = tool:FindFirstChild("Handle")
   if not handle then return end
   
   local skinData = skinDatabase[activeSkinName]
   if not skinData then return end
   
   local mesh = handle:FindFirstChildOfClass("SpecialMesh")
   if not mesh then
      mesh = Instance.new("SpecialMesh")
      mesh.Parent = handle
   end
   
   if skinData.MeshId ~= "" then mesh.MeshId = skinData.MeshId end
   if skinData.TextureId ~= "" then mesh.TextureId = skinData.TextureId end
   
   local oldHighlight = handle:FindFirstChild("SkinGlow")
   if oldHighlight then oldHighlight:Destroy() end
   
   if activeSkinName == "GingerScope" then
      local glow = Instance.new("SelectionBox")
      glow.Name = "SkinGlow"
      glow.Color3 = Color3.fromRGB(255, 140, 0)
      glow.LineThickness = 0.03
      glow.Adornee = handle
      glow.Parent = handle
      
      tool.Activated:Connect(function()
         pcall(function()
            local originalSound = handle:FindFirstChild("FireSound") or handle:FindFirstChildOfClass("Sound")
            if originalSound then
               originalSound:Play()
            end
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
      
      if activeTween then
         activeTween:Cancel()
         activeTween = nil
      end

      if autoFarmCandy then
         currentFarmSession = currentFarmSession + 1
         local mySessionId = currentFarmSession

         activeFarmRoutine = task.spawn(function()
            local Players = game:GetService("Players")
            local Workspace = game:GetService("Workspace")
            local TweenService = game:GetService("TweenService")
            local player = Players.LocalPlayer

            while autoFarmCandy and (currentFarmSession == mySessionId) do
               local success, err = pcall(function()
                  local reachedLimit = false
                  local playerGui = player:FindFirstChild("PlayerGui")
                  local mainGui = playerGui and playerGui:FindFirstChild("MainGUI")
                  local gameFrame = mainGui and mainGui:FindFirstChild("Game")
                  local coinBags = gameFrame and gameFrame:FindFirstChild("CoinBags")
                  
                  if coinBags then
                     local candyBag = coinBags:FindFirstChild("Candy")
                     if candyBag then
                        local fullIcon = candyBag:FindFirstChild("FullBagIcon")
                        if fullIcon and fullIcon:IsA("GuiObject") and fullIcon.Visible then
                           reachedLimit = true
                        end
                     end
                  end
                  
                  if reachedLimit then
                     autoFarmCandy = false
                     if activeTween then
                        activeTween:Cancel()
                        activeTween = nil
                     end
                     
                     local character = player.Character
                     local backpack = player:FindFirstChild("Backpack")
                     local isLocalMurderer = (backpack and backpack:FindFirstChild("Knife")) or (character and character:FindFirstChild("Knife"))
                     
                     if killAllWhenFull and isLocalMurderer then
                        local root = character and character:FindFirstChild("HumanoidRootPart")
                        if root then
                           local originalCFrame = root.CFrame
                           local knife = (backpack and backpack:FindFirstChild("Knife")) or (character and character:FindFirstChild("Knife"))
                           if knife then knife.Parent = character end
                           
                           for _, p in ipairs(Players:GetPlayers()) do
                              if p ~= player and p.Character then
                                 local targetChar = p.Character
                                 local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
                                 local targetHum = targetChar:FindFirstChild("Humanoid")
                                 
                                 if targetRoot and targetHum and targetHum.Health > 0 then
                                    root.CFrame = targetRoot.CFrame
                                    task.wait(0.03)
                                    if knife then pcall(function() knife:Activate() end) end
                                 end
                              end
                           end
                           task.wait(0.1)
                           root.CFrame = originalCFrame
                        end
                     elseif flingMurderOnFull then
                        executeFlingOnTarget("Murder")
                     end
                     
                     return
                  end

                  if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                     local character = player.Character
                     local root = character.HumanoidRootPart
                     
                     local nearestCoinVisual = nil
                     local shortestDistance = math.huge

                     for _, child in ipairs(Workspace:GetChildren()) do
                        local container = child:FindFirstChild("CoinContainer")
                        if container then
                           for _, coinModel in ipairs(container:GetChildren()) do
                              if coinModel.Name == "Coin_Server" then
                                 local visual = coinModel:FindFirstChild("CoinVisual")
                                 if visual and visual:IsA("BasePart") then
                                    local dist = (root.Position - visual.Position).Magnitude
                                    if dist < shortestDistance then
                                       shortestDistance = dist
                                       nearestCoinVisual = visual
                                    end
                                 end
                              end
                           end
                        end
                     end

                     if nearestCoinVisual and autoFarmCandy and (currentFarmSession == mySessionId) then
                        local targetCFrame = nearestCoinVisual.CFrame
                        if farmUnderground then
                           targetCFrame = nearestCoinVisual.CFrame * CFrame.new(0, -3.5, 0) * CFrame.Angles(math.rad(90), 0, 0)
                        end
                        
                        root.Anchored = true
                        
                        local distance = (root.Position - targetCFrame.Position).Magnitude
                        local selectedSpeed = math.clamp(farmSpeed, 1, 33)
                        local tweenTime = distance / selectedSpeed
                        
                        local tweenInfo = TweenInfo.new(tweenTime, Enum.EasingStyle.Linear)
                        activeTween = TweenService:Create(root, tweenInfo, {CFrame = targetCFrame})
                        
                        activeTween:Play()
                        
                        while activeTween and activeTween.PlaybackState == Enum.PlaybackState.Playing do
                           if not autoFarmCandy or (currentFarmSession ~= mySessionId) then
                              activeTween:Cancel()
                              activeTween = nil
                              break
                           end
                           
                           if not nearestCoinVisual or not nearestCoinVisual.Parent or not nearestCoinVisual.Parent.Parent then
                              activeTween:Cancel()
                              activeTween = nil
                              break
                           end
                           
                           task.wait(0.02)
                        end
                        activeTween = nil
                        
                        if root then
                           root.Anchored = false
                        end
                     end
                  end
               end)
               if not success then
                  warn("AutoFarm Error:", err)
               end
               task.wait(0.01)
            end
            
            pcall(function()
               if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                  player.Character.HumanoidRootPart.Anchored = false
               end
            end)
            
            if currentFarmSession == mySessionId then
               activeFarmRoutine = nil
            end
         end)
      end
   end,
})

FarmingTab:CreateToggle({
   Name = "Farm Candies Underground",
   CurrentValue = false,
   Flag = "FarmUndergroundToggle",
   Callback = function(Value)
      farmUnderground = Value
   end,
})

FarmingTab:CreateSlider({
   Name = "Farm Speed (Studs/s)",
   Range = {1, 33},
   Increment = 1,
   Suffix = "s/s",
   CurrentValue = 20,
   Flag = "FarmSpeedSlider",
   Callback = function(Value)
      farmSpeed = Value
   end,
})

FarmingTab:CreateToggle({
   Name = "Anti-Fling Protection",
   CurrentValue = false,
   Flag = "AntiFlingToggle",
   Callback = function(Value)
      antiFlingEnabled = Value
      if not antiFlingEnabled then
         pcall(function()
            local Players = game:GetService("Players")
            local player = Players.LocalPlayer
            for _, p in ipairs(Players:GetPlayers()) do
               if p ~= player and p.Character then
                  for _, part in ipairs(p.Character:GetDescendants()) do
                     if part:IsA("BasePart") then
                        part.CanCollide = true
                     end
                  end
               end
            end
         end)
      end
   end,
})

FarmingTab:CreateToggle({
   Name = "Auto Grab Gun",
   CurrentValue = false,
   Flag = "AutoGrabGunToggle",
   Callback = function(Value)
      autoGrabGunEnabled = Value
      if autoGrabGunEnabled then
         task.spawn(function()
            local Workspace = game:GetService("Workspace")
            local Players = game:GetService("Players")
            local player = Players.LocalPlayer
            
            while autoGrabGunEnabled do
               pcall(function()
                  local gunDrop = Workspace:FindFirstChild("GunDrop")
                  if gunDrop and player.Character then
                     local backpack = player:FindFirstChild("Backpack")
                     local hasGun = (backpack and backpack:FindFirstChild("Gun")) or player.Character:FindFirstChild("Gun")
                     
                     if not hasGun then
                        local handle = gunDrop:FindFirstChild("Handle") or gunDrop:FindFirstChild("Part") or gunDrop
                        if handle and handle:IsA("BasePart") then
                           local character = player.Character
                           local hrp = character:FindFirstChild("HumanoidRootPart")
                           local originalCFrame = hrp and hrp.CFrame
                           
                           if hrp then
                              hrp.CFrame = handle.CFrame
                              task.wait(0.15)
                              if originalCFrame then
                                 hrp.CFrame = originalCFrame
                              end
                           end
                        end
                     end
                  end
               end)
               task.wait(0.5)
            end
         end)
      end
   end,
})

FarmingTab:CreateToggle({
   Name = "Fling Murder When Full",
   CurrentValue = false,
   Flag = "FlingMurderWhenFullToggle",
   Callback = function(Value)
      flingMurderOnFull = Value
   end,
})

FarmingTab:CreateToggle({
   Name = "Kill All When Full (If Murder)",
   CurrentValue = false,
   Flag = "KillAllWhenFullToggle",
   Callback = function(Value)
      killAllWhenFull = Value
   end,
})

CombatTab:CreateToggle({
   Name = "Auto Shoot Button",
   CurrentValue = false,
   Flag = "AutoShootButtonToggle",
   Callback = function(Value)
      autoShootButtonEnabled = Value
      if autoShootButtonEnabled then
         createAutoShootGui()
      else
         removeAutoShootGui()
      end
   end,
})

FlingTab:CreateButton({
   Name = "Fling Murder",
   Callback = function()
      executeFlingOnTarget("Murder")
   end,
})

FlingTab:CreateButton({
   Name = "Fling Sheriff / Hero",
   Callback = function()
      executeFlingOnTarget("Sheriff")
   end,
})

SkinsTab:CreateDropdown({
   Name = "Select Weapon Slot",
   Options = {"Knife", "Gun"},
   CurrentOption = "Gun",
   Flag = "SkinSlotDropdown",
   Callback = function(Option)
      selectedWeaponType = Option
   end,
})

SkinsTab:CreateDropdown({
   Name = "Select Skin",
   Options = {"Default", "GingerScope", "Celestial", "Emberbow", "Combain", "Evergun", "Laser Gun", "Luger", "Corrupt Knife"},
   CurrentOption = "Default",
   Flag = "SkinNameDropdown",
   Callback = function(Option)
      activeSkinName = Option
   end,
})

SkinsTab:CreateButton({
   Name = "Apply & Equip Skin",
   Callback = function()
      pcall(function()
         local Players = game:GetService("Players")
         local player = Players.LocalPlayer
         local character = player.Character
         local backpack = player:FindFirstChild("Backpack")
         
         local targetTool = (character and character:FindFirstChild(selectedWeaponType)) or (backpack and backpack:FindFirstChild(selectedWeaponType))
         if targetTool then
            applySkinToTool(targetTool)
         end
      end)
   end,
})

task.spawn(function()
   local Players = game:GetService("Players")
   local player = Players.LocalPlayer
   
   local function monitorTool(tool)
      if tool:IsA("Tool") and (tool.Name == "Knife" or tool.Name == "Gun") then
         tool.Equipped:Connect(function()
            task.wait(0.02)
            applySkinToTool(tool)
         end)
         applySkinToTool(tool)
      end
   end

   local function setupCharacterListener(char)
      if not char then return end
      char.ChildAdded:Connect(monitorTool)
      for _, child in ipairs(char:GetChildren()) do
         monitorTool(child)
      end
      
      local backpack = player:FindFirstChild("Backpack")
      if backpack then
         backpack.ChildAdded:Connect(monitorTool)
         for _, child in ipairs(backpack:GetChildren()) do
            monitorTool(child)
         end
      end
   end
   
   if player.Character then setupCharacterListener(player.Character) end
   player.CharacterAdded:Connect(setupCharacterListener)
   
   player.ChildAdded:Connect(function(child)
      if child.Name == "Backpack" then
         child.ChildAdded:Connect(monitorTool)
      end
   end)
end)

task.spawn(function()
   local Players = game:GetService("Players")
   local RunService = game:GetService("RunService")
   local player = Players.LocalPlayer
   
   RunService.Stepped:Connect(function()
      if not antiFlingEnabled or isFlingingActive then return end
      
      pcall(function()
         local character = player.Character
         if character then
            local root = character:FindFirstChild("HumanoidRootPart")
            if root then
               if root.AssemblyLinearVelocity.Magnitude > 75 then
                  root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                  root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
               end
               
               for _, p in ipairs(Players:GetPlayers()) do
                  if p ~= player and p.Character then
                     for _, part in ipairs(p.Character:GetDescendants()) do
                        if part:IsA("BasePart") then
                           part.CanCollide = false
                        end
                     end
                  end
               end
            end
         end
      end)
   end)
end)

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
                        local highlight = char:FindFirstChild("ESPHighlight")
                        
                        if not highlight then
                           highlight = Instance.new("Highlight")
                           highlight.Name = "ESPHighlight"
                           highlight.FillTransparency = 0.5
                           highlight.OutlineTransparency = 0
                           highlight.Parent = char
                        end
                        
                        local backpack = p:FindFirstChild("Backpack")
                        local isMurderer = (backpack and backpack:FindFirstChild("Knife")) or char:FindFirstChild("Knife")
                        local hasGun = (backpack and backpack:FindFirstChild("Gun")) or char:FindFirstChild("Gun")
                        
                        if isMurderer then
                           highlight.FillColor = Color3.fromRGB(255, 0, 0)
                           highlight.OutlineColor = Color3.fromRGB(150, 0, 0)
                        elseif hasGun then
                           highlight.FillColor = Color3.fromRGB(0, 100, 255)
                           highlight.OutlineColor = Color3.fromRGB(0, 50, 150)
                        else
                           highlight.FillColor = Color3.fromRGB(0, 255, 0)
                           highlight.OutlineColor = Color3.fromRGB(0, 150, 0)
                        end
                     end
                  end
               end)
               task.wait(0.5)
            end
            
            for _, p in ipairs(Players:GetPlayers()) do
               if p.Character and p.Character:FindFirstChild("ESPHighlight") then
                  p.Character.ESPHighlight:Destroy()
               end
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
                  for _, child in ipairs(Workspace:GetChildren()) do
                     local container = child:FindFirstChild("CoinContainer")
                     if container then
                        local children = container:GetChildren()
                        for i = 1, #children do
                           local coinModel = children[i]
                           if coinModel.Name == "Coin_Server" then
                              if not coinModel:FindFirstChild("CoinHighlight") then
                                 local highlight = Instance.new("Highlight")
                                 highlight.Name = "CoinHighlight"
                                 highlight.FillColor = Color3.fromRGB(255, 215, 0)
                                 highlight.OutlineColor = Color3.fromRGB(255, 140, 0)
                                 highlight.FillTransparency = 0.4
                                 highlight.Parent = coinModel
                              end
                           end
                        end
                     end
                  end
               end)
               task.wait(1)
            end
            
            for _, child in ipairs(Workspace:GetChildren()) do
               local container = child:FindFirstChild("CoinContainer")
               if container then
                  local children = container:GetChildren()
                  for i = 1, #children do
                     local coinModel = children[i]
                     if coinModel:FindFirstChild("CoinHighlight") then
                        coinModel.CoinHighlight:Destroy()
                     end
                  end
               end
            end
         end)
      end
   end,
})
