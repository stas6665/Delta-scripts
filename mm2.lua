local Rayfield = loadstring(game:HttpGet('https://sirius.menu/gen2'))()

local Window = Rayfield:CreateWindow({
    name = "MM2 Hub",
    loadingTitle = "Loading MM2...",
    loadingSubtitle = "by Stas_mine12",
    configurationSaving = { enabled = false },
    keySystem = false,
})

local FarmingTab = Window:CreateTab({ name = "Farming", icon = "bookmark" })
local FlingTab = Window:CreateTab({ name = "Fling", icon = "user" })
local TrollTab = Window:CreateTab({ name = "Troll", icon = "smile" })
local CombatTab = Window:CreateTab({ name = "Combat", icon = "shield" })
local SkinsTab = Window:CreateTab({ name = "Skins", icon = "package" })
local VisualsTab = Window:CreateTab({ name = "Visuals", icon = "eye" })

local autoFarmCandy = false
local antiFlingEnabled = false
local autoGrabGunEnabled = false
local autoFlingMurderWhenFull = false
local autoKillWhenFull = false
local killAllActive = false
local notJumpEnabled = false
local playerControlEnabled = false

local farmSpeed = 25
local farmMethod = "Teleport"

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

local selectedTrollPlayerName = ""

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

local notifyGui = nil
local activeNotifFrame = nil

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

        if activeNotifFrame and activeNotifFrame.Parent then
            activeNotifFrame:Destroy()
        end

        local notifFrame = Instance.new("Frame")
        notifFrame.Size = UDim2.new(0, 240, 0, 45)
        notifFrame.Position = UDim2.new(1, -250, 1, -65)
        notifFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        notifFrame.BackgroundTransparency = 0.3
        notifFrame.BorderSizePixel = 0
        notifFrame.Parent = notifyGui
        activeNotifFrame = notifFrame

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = notifFrame

        local stroke = Instance.new("UIStroke")
        stroke.Color = isSuccess and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 140, 0)
        stroke.Thickness = 2
        stroke.Parent = notifFrame

        local titleLabel = Instance.new("TextLabel")
        titleLabel.Size = UDim2.new(1, -20, 0, 18)
        titleLabel.Position = UDim2.new(0, 10, 0, 4)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Text = title
        titleLabel.TextColor3 = isSuccess and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 140, 0)
        titleLabel.TextSize = 13
        titleLabel.Font = Enum.Font.GothamBold
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.Parent = notifFrame

        local msgLabel = Instance.new("TextLabel")
        msgLabel.Size = UDim2.new(1, -20, 0, 18)
        msgLabel.Position = UDim2.new(0, 10, 0, 22)
        msgLabel.BackgroundTransparency = 1
        msgLabel.Text = message
        msgLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        msgLabel.TextSize = 12
        msgLabel.Font = Enum.Font.Gotham
        msgLabel.TextXAlignment = Enum.TextXAlignment.Left
        msgLabel.Parent = notifFrame

        task.spawn(function()
            task.wait(0.6)
            if notifFrame and notifFrame.Parent then
                local TweenService = game:GetService("TweenService")
                local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                
                local tween1 = TweenService:Create(notifFrame, tweenInfo, {BackgroundTransparency = 1})
                local tween2 = TweenService:Create(stroke, tweenInfo, {Transparency = 1})
                local tween3 = TweenService:Create(titleLabel, tweenInfo, {TextTransparency = 1})
                local tween4 = TweenService:Create(msgLabel, tweenInfo, {TextTransparency = 1})
                
                tween1:Play()
                tween2:Play()
                tween3:Play()
                tween4:Play()
                
                task.wait(0.3)
                if notifFrame and notifFrame.Parent then
                    notifFrame:Destroy()
                end
            end
        end)
    end)
end

local function isInLobby()
    local player = game:GetService("Players").LocalPlayer
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return true end

    local root = char.HumanoidRootPart
    local Workspace = game:GetService("Workspace")
    
    local lobbyFolder = Workspace:FindFirstChild("Lobby")
    local mainLobbyObj = lobbyFolder and lobbyFolder:FindFirstChild("Lobby")
    
    if mainLobbyObj then
        local targetPart = nil
        if mainLobbyObj:IsA("BasePart") then
            targetPart = mainLobbyObj
        elseif mainLobbyObj:IsA("Model") then
            targetPart = mainLobbyObj.PrimaryPart or mainLobbyObj:FindFirstChildOfClass("BasePart")
        end

        if targetPart then
            local dist = (root.Position - targetPart.Position).Magnitude
            if dist < 450 then
                return true
            end
        end
    end

    local playerGui = player:FindFirstChild("PlayerGui")
    local mainGui = playerGui and playerGui:FindFirstChild("MainGUI")
    local gameFrame = mainGui and mainGui:FindFirstChild("Game")

    if gameFrame and not gameFrame.Visible then
        return true
    end

    return false
end

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
                        local currentVel = root.AssemblyLinearVelocity
                        
                        if math.abs(currentVel.X) > 50 or math.abs(currentVel.Z) > 50 then
                            root.AssemblyLinearVelocity = Vector3.new(0, currentVel.Y, 0)
                        end
                        root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)

                        local playersList = Players:GetPlayers()
                        for _, p in ipairs(playersList) do
                            if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                                local pRoot = p.Character.HumanoidRootPart
                                if (root.Position - pRoot.Position).Magnitude < 6 then
                                    pRoot.AssemblyLinearVelocity = Vector3.new(0, pRoot.AssemblyLinearVelocity.Y, 0)
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

local notJumpConnection = nil
local function updateNotJump()
    local RunService = game:GetService("RunService")
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer

    if notJumpEnabled then
        if not notJumpConnection then
            notJumpConnection = RunService.Heartbeat:Connect(function()
                if not notJumpEnabled then return end
                pcall(function()
                    if selectedTrollPlayerName and selectedTrollPlayerName ~= "" and selectedTrollPlayerName ~= "No Players" then
                        local targetP = Players:FindFirstChild(selectedTrollPlayerName)
                        if targetP and targetP.Character and targetP.Character:FindFirstChild("HumanoidRootPart") then
                            local tRoot = targetP.Character.HumanoidRootPart
                            local char = player.Character
                            if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChildOfClass("Humanoid") then
                                local root = char.HumanoidRootPart
                                local humanoid = char:FindFirstChildOfClass("Humanoid")

                                humanoid.PlatformStand = true
                                root.CFrame = tRoot.CFrame * CFrame.new(0, 3.5, 0) * CFrame.Angles(math.rad(90), 0, 0)
                                root.AssemblyLinearVelocity = Vector3.zero
                                root.AssemblyAngularVelocity = Vector3.zero
                            end
                        end
                    end
                end)
            end)
        end
    else
        if notJumpConnection then
            notJumpConnection:Disconnect()
            notJumpConnection = nil
        end
        pcall(function()
            local player = Players.LocalPlayer
            local char = player.Character
            if char and char:FindFirstChildOfClass("Humanoid") then
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                humanoid.PlatformStand = false
                humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
        end)
    end
end

local playerControlConnection = nil
local function updatePlayerControl()
    local RunService = game:GetService("RunService")
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer

    if playerControlEnabled then
        if not playerControlConnection then
            playerControlConnection = RunService.Heartbeat:Connect(function()
                if not playerControlEnabled then return end
                pcall(function()
                    if selectedTrollPlayerName and selectedTrollPlayerName ~= "" and selectedTrollPlayerName ~= "No Players" then
                        local targetP = Players:FindFirstChild(selectedTrollPlayerName)
                        if targetP and targetP.Character and targetP.Character:FindFirstChild("HumanoidRootPart") and targetP.Character:FindFirstChildOfClass("Humanoid") then
                            local tRoot = targetP.Character.HumanoidRootPart
                            local tHum = targetP.Character:FindFirstChildOfClass("Humanoid")
                            local char = player.Character
                            
                            if char and char:FindFirstChild("HumanoidRootPart") then
                                local root = char.HumanoidRootPart
                                
                                local targetPos = root.CFrame * CFrame.new(0, 0, -3)
                                tRoot.CFrame = targetPos
                                
                                tHum.PlatformStand = true
                                tRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                                tRoot.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                            end
                        end
                    end
                end)
            end)
        end
    else
        if playerControlConnection then
            playerControlConnection:Disconnect()
            playerControlConnection = nil
        end
        pcall(function()
            local targetP = Players:FindFirstChild(selectedTrollPlayerName)
            if targetP and targetP.Character then
                local tHum = targetP.Character:FindFirstChildOfClass("Humanoid")
                if tHum then
                    tHum.PlatformStand = false
                    tHum:ChangeState(Enum.HumanoidStateType.GettingUp)
                end
            end
        end)
    end
end

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
                                     or (gunDrop.Parent and gunDrop.Parent:FindFirstChildOfClass("ProximityPrompt"))    
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

local function createAutoShootGui()
    if autoShootGui then return end
    local Players = game:GetService("Players")
    local UserInputService = game:GetService("UserInputService")
    local VirtualUser = game:GetService("VirtualUser")
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
                        if not char or not char:FindFirstChild("HumanoidRootPart") then
                            return
                        end
                        local root = char.HumanoidRootPart
                        local hum = char:FindFirstChildOfClass("Humanoid")

                        local backpack = player:FindFirstChild("Backpack")      
                        local gun = char:FindFirstChild("Gun") or (backpack and backpack:FindFirstChild("Gun"))      
                              
                        if not gun then     
                           showCustomNotification("Shoot Murder", "Gun not found in inventory❗️", false)
                           return     
                        end      
                              
                        if gun.Parent == backpack and hum then      
                           hum:EquipTool(gun)    
                           task.wait(0.05) 
                        end      

                        local targetRoot = nil      
                        local playersList = Players:GetPlayers()    
                        for _, p in ipairs(playersList) do      
                           if p ~= player and p.Character then      
                              local pBackpack = p:FindFirstChild("Backpack")      
                              local pChar = p.Character      
                              local pRoot = pChar:FindFirstChild("HumanoidRootPart")      
                              local pHum = pChar:FindFirstChild("Humanoid")      
                                    
                              local hasKnife = (pBackpack and pBackpack:FindFirstChild("Knife")) or (pChar and pChar:FindFirstChild("Knife"))      
                                    
                              if hasKnife and pRoot and pHum and pHum.Health > 0 then      
                                 targetRoot = pRoot      
                                 break      
                              end      
                           end    
                        end      
                              
                        if not targetRoot then     
                           return     
                        end    

                        local origCFrame = root.CFrame

                        root.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 3)
                        
                        game:GetService("RunService").Heartbeat:Wait()

                        local rayAttach = gun:FindFirstChild("GunRaycastAttachment1", true) 
                                          or gun:FindFirstChild("GunRaycastAttachment", true) 
                                          or char:FindFirstChild("GunTipAttachment", true)
                                          or char:FindFirstChild("RightHand")

                        local targetPos = targetRoot.Position + Vector3.new(0, 0.5, 0)    
                        local attachmentCFrame = rayAttach and rayAttach:IsA("Attachment") and rayAttach.WorldCFrame or (rayAttach:IsA("BasePart") and rayAttach.CFrame or root.CFrame)
                        local calculatedCFrame = CFrame.new(attachmentCFrame.Position, targetPos)    

                        local remote = gun:FindFirstChild("Shoot", true) or gun:FindFirstChild("Fire", true)

                        if remote and remote:IsA("RemoteEvent") then      
                           remote:FireServer(calculatedCFrame, targetPos)    
                        end      

                        pcall(function()
                            VirtualUser:Button1Down(Vector2.new(0,0), workspace.CurrentCamera.ViewportSize)
                            task.wait(0.05)
                            VirtualUser:Button1Up(Vector2.new(0,0), workspace.CurrentCamera.ViewportSize)
                        end)

                        showCustomNotification("Shoot Murder", "Shoot successfully completed✅", true)

                        if root and root.Parent then
                           root.CFrame = origCFrame
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

local function executeDrillDownFling(targetType, specificPlayerName)
    if isFlingingActive then return end
    isFlingingActive = true

    task.spawn(function()
        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")
        local player = Players.LocalPlayer
        
        local character, root, humanoid, targetRoot
        local originalProperties = {}
        local originalCanCollideStates = {}
        local propertiesModified = false
        local connection = nil
        local charRemovingConn = nil
        local diedConn = nil
        local cleanedUp = false
        local originalCFrame = nil

        local function cleanup()
            if cleanedUp then return end
            cleanedUp = true

            if connection then connection:Disconnect() end
            if charRemovingConn then charRemovingConn:Disconnect() end
            if diedConn then diedConn:Disconnect() end

            if propertiesModified then
                for part, prop in pairs(originalProperties) do
                    if part and part.Parent then
                        pcall(function()
                            part.CustomPhysicalProperties = prop
                            part.CanCollide = originalCanCollideStates[part]
                        end)
                    end
                end
            end

            pcall(function()
                if humanoid and humanoid.Parent then
                    humanoid.PlatformStand = false
                    humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
                end
            end)

            pcall(function()
                if root and root.Parent then
                    root.AssemblyLinearVelocity = Vector3.zero
                    root.AssemblyAngularVelocity = Vector3.zero
                    root.Velocity = Vector3.zero
                    if originalCFrame then root.CFrame = originalCFrame end
                end
            end)

            isFlingingActive = false
        end

        charRemovingConn = player.CharacterRemoving:Connect(function()
            cleanup()
        end)

        local success, err = pcall(function()
            character = player.Character
            if not character or not character:FindFirstChild("HumanoidRootPart") then 
                error("Local character missing") 
            end

            root = character.HumanoidRootPart
            humanoid = character:FindFirstChildOfClass("Humanoid")
            if not humanoid then error("Humanoid missing") end

            originalCFrame = root.CFrame

            diedConn = humanoid.Died:Connect(function()
                cleanup()
            end)

            for _, obj in ipairs(character:GetDescendants()) do
                if obj:IsA("Weld") or obj:IsA("WeldConstraint") or obj:IsA("Snap") then
                    if obj.Part0 ~= root and obj.Part1 ~= root then
                        pcall(function() obj:Destroy() end)
                    end
                end
            end

            local targetPlayer = nil
            if specificPlayerName and specificPlayerName ~= "" then
                targetPlayer = Players:FindFirstChild(specificPlayerName)
                if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    targetRoot = targetPlayer.Character.HumanoidRootPart
                else
                    error("Selected player not found or has no character")
                end
            else
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= player and p.Character then
                        local bp = p:FindFirstChild("Backpack")
                        local char = p.Character
                        local isKnife = (bp and bp:FindFirstChild("Knife")) or char:FindFirstChild("Knife")
                        local isGun = (bp and bp:FindFirstChild("Gun")) or char:FindFirstChild("Gun")

                        if (targetType == "Murder" and isKnife) or (targetType == "Sheriff" and isGun) then
                            if char:FindFirstChild("HumanoidRootPart") then
                                targetPlayer = p
                                targetRoot = char.HumanoidRootPart
                                break
                            end
                        end
                    end
                end
            end

            if not targetPlayer or not targetRoot then error("Target not found") end

            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    originalProperties[part] = part.CustomPhysicalProperties
                    originalCanCollideStates[part] = part.CanCollide
                    pcall(function()
                        part.CustomPhysicalProperties = PhysicalProperties.new(100, 0, 0, 100, 100)
                        part.CanCollide = true
                    end)
                end
            end
            propertiesModified = true

            humanoid.PlatformStand = true
            humanoid:ChangeState(Enum.HumanoidStateType.Physics)

            local startTime = tick()
            local spinSpeed = 4000

            connection = RunService.Heartbeat:Connect(function()
                local runSuccess, runErr = pcall(function()
                    if not targetPlayer.Parent or not targetPlayer.Character or targetPlayer.Character ~= targetRoot.Parent or not targetRoot.Parent then
                        cleanup()
                        return
                    end

                    local targetHum = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
                    if not targetHum or targetHum.Health <= 0 or (tick() - startTime > 3.0) then
                        cleanup()
                        return
                    end

                    local elapsed = tick() - startTime
                    local spinAngle = elapsed * spinSpeed

                    local cycle = (elapsed % 1.5) / 1.5
                    local currentYOffset = 3.5 - (cycle * 4.5)

                    root.CFrame = targetRoot.CFrame * CFrame.new(0, currentYOffset, 0) * CFrame.Angles(spinAngle, spinAngle, spinAngle)

                    local impactForce = Vector3.new(
                        math.random(-80000, 80000), 
                        -120000 + math.random(-30000, 30000), 
                        math.random(-80000, 80000)
                    )
                    
                    root.AssemblyLinearVelocity = impactForce
                    root.AssemblyAngularVelocity = Vector3.new(spinSpeed, spinSpeed, spinSpeed)
                    root.Velocity = impactForce
                end)

                if not runSuccess then cleanup() end
            end)
        end)

        if not success then
            cleanup()
        end
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

    if not gameFrame or not gameFrame.Visible then return false end

    local coinBags = gameFrame:FindFirstChild("CoinBags")
    if coinBags and coinBags.Visible then
        local descendants = coinBags:GetDescendants()
        for _, obj in ipairs(descendants) do
            if obj.Name == "FullBagIcon" and obj:IsA("GuiObject") and obj.Visible then return true end
        end
        return false
    end
    return false
end

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

                executeDrillDownFling("Murder", nil)    
                    
                while autoFlingMurderWhenFull and checkBagFull(player) do    
                   task.wait(2)    
                end    
            end)    
            task.wait(1)
        end
    end)
end

local function executeKillAll()
    task.spawn(function()
        local Players = game:GetService("Players")
        local player = Players.LocalPlayer

        while killAllActive do
            pcall(function()
                local char = player.Character
                if not char or not char:FindFirstChild("HumanoidRootPart") then
                    task.wait(0.5)
                    return
                end

                local root = char.HumanoidRootPart
                local hum = char:FindFirstChildOfClass("Humanoid")
                local backpack = player:FindFirstChild("Backpack")
                local knife = char:FindFirstChild("Knife") or (backpack and backpack:FindFirstChild("Knife"))

                if not knife then
                    showCustomNotification("Kill All", "Knife not found in inventory!", false)
                    killAllActive = false
                    return
                end

                if knife.Parent == backpack and hum then
                    hum:EquipTool(knife)
                    task.wait(0.1)
                end

                local targets = {}
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                        local pChar = p.Character
                        local pHum = pChar:FindFirstChildOfClass("Humanoid")
                        if pHum and pHum.Health > 0 then
                            local pBp = p:FindFirstChild("Backpack")
                            local hasKnife = (pBp and pBp:FindFirstChild("Knife")) or pChar:FindFirstChild("Knife")
                            if not hasKnife then
                                table.insert(targets, pChar.HumanoidRootPart)
                            end
                        end
                    end
                end

                if #targets == 0 then
                    task.wait(1)
                    return
                end

                for _, tRoot in ipairs(targets) do
                    if not killAllActive then break end
                    pcall(function()
                        if tRoot and tRoot.Parent then
                            local origCFrame = root.CFrame
                            root.CFrame = tRoot.CFrame * CFrame.new(0, 0, 1.5)
                            task.wait(0.05)
                            if knife.Parent == char then
                                knife:Activate()
                            end
                            task.wait(0.05)
                            root.CFrame = origCFrame
                        end
                    end)
                    task.wait(0.2)
                end
            end)
            task.wait(0.5)
        end
    end)
end

local function executeAutoKillWhenFull()
    task.spawn(function()
        local Players = game:GetService("Players")
        local player = Players.LocalPlayer

        while autoKillWhenFull do
            pcall(function()
                if not checkBagFull(player) then
                    task.wait(1)
                    return
                end

                local char = player.Character
                if not char or not char:FindFirstChild("HumanoidRootPart") then
                    task.wait(0.5)
                    return
                end

                local root = char.HumanoidRootPart
                local hum = char:FindFirstChildOfClass("Humanoid")
                local backpack = player:FindFirstChild("Backpack")
                local knife = char:FindFirstChild("Knife") or (backpack and backpack:FindFirstChild("Knife"))

                if not knife then
                    task.wait(1)
                    return
                end

                if knife.Parent == backpack and hum then
                    hum:EquipTool(knife)
                    task.wait(0.1)
                end

                while autoKillWhenFull and checkBagFull(player) do
                    local targets = {}
                    for _, p in ipairs(Players:GetPlayers()) do
                        if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                            local pChar = p.Character
                            local pHum = pChar:FindFirstChildOfClass("Humanoid")
                            if pHum and pHum.Health > 0 then
                                local pBp = p:FindFirstChild("Backpack")
                                local hasKnife = (pBp and pBp:FindFirstChild("Knife")) or pChar:FindFirstChild("Knife")
                                if not hasKnife then
                                    table.insert(targets, pChar.HumanoidRootPart)
                                end
                            end
                        end
                    end

                    for _, tRoot in ipairs(targets) do
                        if not autoKillWhenFull or not checkBagFull(player) then break end
                        pcall(function()
                            if tRoot and tRoot.Parent then
                                local origCFrame = root.CFrame
                                root.CFrame = tRoot.CFrame * CFrame.new(0, 0, 1.5)
                                task.wait(0.05)
                                if knife.Parent == char then
                                    knife:Activate()
                                end
                                task.wait(0.05)
                                root.CFrame = origCFrame
                            end
                        end)
                        task.wait(0.2)
                    end
                    task.wait(0.5)
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

FarmingTab:CreateDropdown({
    name = "Farm Method",
    options = {"Teleport", "Fly"},
    currentOption = "Teleport",
    flag = "FarmMethodDropdown",
    callback = function(option) farmMethod = option end,
})

FarmingTab:CreateSlider({
    name = "Farm Speed (Fly Only)",
    range = {1, 33},
    increment = 1,
    suffix = "s/s",
    currentValue = 25,
    flag = "FarmSpeedSlider",
    callback = function(value) farmSpeed = value end,
})

FarmingTab:CreateToggle({
    name = "Auto Farm Candy",
    currentValue = false,
    flag = "AutoFarmCandyToggle",
    callback = function(value)
        autoFarmCandy = value
        currentFarmSession = currentFarmSession + 1
        local mySessionId = currentFarmSession

        if autoFarmCandy then
            task.spawn(function()
                local Players = game:GetService("Players")
                local player = Players.LocalPlayer

                while autoFarmCandy and (currentFarmSession == mySessionId) do      
                       local success, err = pcall(function()      
                          if isInLobby() then
                             task.wait(1)
                             return
                          end

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
                                    
                                root.CFrame = CFrame.new(nearestCoin.Position)      
                                task.wait(0.03)    
                                showCustomNotification("Auto Farm", "+1 Candy🍬", true)    

                                task.wait(0.01)    
                                if root and root.Parent then    
                                   root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)    
                                   root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)    
                                   root.Velocity = Vector3.new(0, 0, 0)    
                                end    
                                task.wait(0.05)      
                             else      
                                local targetPos = nearestCoin.Position    
                                local RunService = game:GetService("RunService")    
                                    
                                while autoFarmCandy and (currentFarmSession == mySessionId) do    
                                   if isInLobby() then break end
                                   if not nearestCoin.Instance or not nearestCoin.Instance.Parent then break end    
                                       
                                   local currentPos = root.Position    
                                   local distance = (currentPos - targetPos).Magnitude    
                                       
                                   if distance < 1 then    
                                      root.CFrame = CFrame.new(targetPos)    
                                      task.wait(0.03)    
                                      showCustomNotification("Auto Farm", "+1 Candy🍬", true)    
                                      break    
                                   end    
                                       
                                   local step = math.clamp(farmSpeed * 0.08, 0.5, 3)    
                                   local nextPos = currentPos:Lerp(targetPos, math.min(step / distance, 1))    
                                       
                                   root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)    
                                   root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)    
                                     
                                   local safeY = math.min(currentPos.Y, targetPos.Y + 2)
                                   local flatTarget = Vector3.new(targetPos.X, safeY, targetPos.Z)  
                                   root.CFrame = CFrame.new(nextPos.X, safeY, nextPos.Z, flatTarget.X, flatTarget.Y, flatTarget.Z)    
                                       
                                   RunService.Heartbeat:Wait()    
                                end    
                                task.wait(0.01)    
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
    name = "Fling Murder (When Bag Full)",
    currentValue = false,
    flag = "AutoFlingMurderWhenFullToggle",
    callback = function(value)
        autoFlingMurderWhenFull = value
        if autoFlingMurderWhenFull then
            executeAutoFlingMurderWhenFull()
        end
    end,
})

FarmingTab:CreateToggle({
    name = "Auto Kill All (When Bag Full)",
    currentValue = false,
    flag = "AutoKillWhenFullToggle",
    callback = function(value)
        autoKillWhenFull = value
        if autoKillWhenFull then
            executeAutoKillWhenFull()
        end
    end,
})

FarmingTab:CreateToggle({
    name = "Anti Fling",
    currentValue = false,
    flag = "AntiFlingToggle",
    callback = function(value)
        antiFlingEnabled = value
        updateAntiFling()
    end,
})

FlingTab:CreateButton({
    name = "Fling Murder",
    callback = function() executeDrillDownFling("Murder", nil) end,
})

FlingTab:CreateButton({
    name = "Fling Sheriff / Hero",
    callback = function() executeDrillDownFling("Sheriff", nil) end,
})

CombatTab:CreateToggle({
    name = "Kill All (Murderer)",
    currentValue = false,
    flag = "KillAllToggle",
    callback = function(value)
        killAllActive = value
        if killAllActive then
            executeKillAll()
        end
    end,
})

local Players = game:GetService("Players")

local function getPlayerNamesList()
    local names = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Players.LocalPlayer then
            table.insert(names, p.Name)
        end
    end
    if #names == 0 then table.insert(names, "No Players") end
    return names
end

local trollDropdown = TrollTab:CreateDropdown({
    name = "Select Player to Troll",
    options = getPlayerNamesList(),
    currentOption = "No Players",
    flag = "TrollPlayerDropdown",
    callback = function(option)
        selectedTrollPlayerName = option
    end,
})

local function refreshTrollDropdown()
    pcall(function()
        local currentOptions = getPlayerNamesList()
        local stillExists = false
        for _, name in ipairs(currentOptions) do
            if name == selectedTrollPlayerName then
                stillExists = true
                break
            end
        end
        
        if not stillExists and selectedTrollPlayerName ~= "" then
            selectedTrollPlayerName = "No Players"
        end
        
        trollDropdown:Set(currentOptions)
        if stillExists then
            trollDropdown:Set(selectedTrollPlayerName)
        else
            trollDropdown:Set("No Players")
        end
    end)
end

Players.PlayerAdded:Connect(function()
    refreshTrollDropdown()
end)

Players.PlayerRemoving:Connect(function()
    refreshTrollDropdown()
end)

TrollTab:CreateButton({
    name = "Refresh Players List",
    callback = function()
        refreshTrollDropdown()
        showCustomNotification("Troll", "Player list refreshed!", true)
    end,
})

TrollTab:CreateButton({
    name = "Fling Selected Player",
    callback = function()
        if selectedTrollPlayerName and selectedTrollPlayerName ~= "" and selectedTrollPlayerName ~= "No Players" then
            executeDrillDownFling(nil, selectedTrollPlayerName)
        else
            showCustomNotification("Troll", "Select a valid player first!", false)
        end
    end,
})

TrollTab:CreateToggle({
    name = "Not Jump (Ride Selected Player)",
    currentValue = false,
    flag = "NotJumpToggle",
    callback = function(value)
        notJumpEnabled = value
        updateNotJump()
    end,
})

TrollTab:CreateToggle({
    name = "Player Control (Control Selected Player)",
    currentValue = false,
    flag = "PlayerControlToggle",
    callback = function(value)
        playerControlEnabled = value
        updatePlayerControl()
    end,
})

CombatTab:CreateToggle({
    name = "Auto Grab Gun",
    currentValue = false,
    flag = "AutoGrabGunToggle",
    callback = function(value) autoGrabGunEnabled = value end,
})

CombatTab:CreateToggle({
    name = "Auto Shoot Button",
    currentValue = false,
    flag = "AutoShootButtonToggle",
    callback = function(value)
        autoShootButtonEnabled = value
        if autoShootButtonEnabled then createAutoShootGui() else removeAutoShootGui() end
    end,
})

SkinsTab:CreateDropdown({
    name = "Select Weapon Slot",
    options = {"Knife", "Gun"},
    currentOption = "Gun",
    flag = "SkinSlotDropdown",
    callback = function(option) selectedWeaponType = option end,
})

SkinsTab:CreateDropdown({
    name = "Select Skin",
    options = {"Default", "GingerScope", "Celestial", "Emberbow", "Combain", "Evergun", "Laser Gun", "Luger", "Corrupt Knife"},
    currentOption = "Default",
    flag = "SkinNameDropdown",
    callback = function(option) activeSkinName = option end,
})

SkinsTab:CreateButton({
    name = "Apply & Equip Skin",
    callback = function()
        pcall(function()
            local player = game:GetService("Players").LocalPlayer
            local tool = (player.Character and player.Character:FindFirstChild(selectedWeaponType)) or (player.Backpack and player.Backpack:FindFirstChild(selectedWeaponType))
            if tool then applySkinToTool(tool) end
        end)
    end,
})

VisualsTab:CreateToggle({
    name = "ESP Murder",
    currentValue = false,
    flag = "ESPMurderToggle",
    callback = function(value)
        espMurderEnabled = value
    end,
})

VisualsTab:CreateToggle({
    name = "ESP Sheriff/Hero",
    currentValue = false,
    flag = "ESPSheriffHeroToggle",
    callback = function(value)
        espSheriffHeroEnabled = value
    end,
})

VisualsTab:CreateToggle({
    name = "ESP Innocent",
    currentValue = false,
    flag = "ESPInnocentToggle",
    callback = function(value)
        espInnocentEnabled = value
    end,
})

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
                    local hasG = (bp and bp:FindFirstChild("Gun")) or (bp and bp:FindFirstChild("GunDrop")) or char:FindFirstChild("Gun")

                    local shouldHighlight = false    
                    local highlightColor = Color3.fromRGB(255, 255, 255)    

                    if hasK and espMurderEnabled then    
                       shouldHighlight = true    
                       highlightColor = Color3.fromRGB(255, 0, 0)    
                    elseif hasG and not hasK and espSheriffHeroEnabled then    
                       shouldHighlight = true    
                       if gunPickedUpDetected then    
                          highlightColor = Color3.fromRGB(255, 255, 0)    
                       else    
                          highlightColor = Color3.fromRGB(0, 100, 255)    
                       end    
                    elseif not hasK and not hasG and espInnocentEnabled then    
                       shouldHighlight = true    
                       highlightColor = Color3.fromRGB(0, 255, 0)    
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
    name = "Coins / Candy ESP (Orange)",
    currentValue = false,
    flag = "CoinsESPToggle",
    callback = function(value)
        espCoinsEnabled = value
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

VisualsTab:CreateToggle({
    name = "X-Ray",
    currentValue = false,
    flag = "XRayToggle",
    callback = function(value)
        xrayEnabled = value
        updateXray()
    end,
})

VisualsTab:CreateSlider({
    name = "X-Ray Transparency",
    range = {0, 1},
    increment = 0.05,
    suffix = "",
    currentValue = 0.65,
    flag = "XRayTransparencySlider",
    callback = function(value)
        xrayTransparency = value
        if xrayEnabled then updateXray() end
    end,
})
