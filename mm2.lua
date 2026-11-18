local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local function getRoleFromScoreboard(player)
    local role = "Innocent"
    pcall(function()
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        if not playerGui then return end
        
        local scoreboards = {"Scoreboard", "Scoreboard_Phone"}
        for _, sbName in ipairs(scoreboards) do
            local sb = playerGui:FindFirstChild(sbName)
            if sb then
                for _, descendant in ipairs(sb:GetDescendants()) do
                    if descendant:IsA("TextLabel") and (descendant.Text == player.Name or descendant.Text:find(player.Name)) then
                        local parentFrame = descendant.Parent
                        while parentFrame and parentFrame ~= sb do
                            local nameLower = string.lower(parentFrame.Name)
                            if nameLower:find("murderer") then
                                role = "Murderer"
                            elseif nameLower:find("sheriff") then
                                role = "Sheriff"
                            elseif nameLower:find("hero") then
                                role = "Hero"
                            end
                            parentFrame = parentFrame.Parent
                        end
                    end
                end
            end
        end
    end)
    return role
end

local function createESP(player)
    if player == LocalPlayer then return end
    
    local function addBillboard(char)
        if char:FindFirstChild("MM2RoleESPTag") then return end
        
        local head = char:WaitForChild("Head", 5)
        if not head then return end
        
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "MM2RoleESPTag"
        billboard.Size = UDim2.new(0, 120, 0, 40)
        billboard.StudsOffset = Vector3.new(0, 2.8, 0)
        billboard.AlwaysOnTop = true
        billboard.Parent = head
        
        local textLabel = Instance.new("TextLabel")
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.Text = player.Name
        textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        textLabel.TextStrokeTransparency = 0
        textLabel.Font = Enum.Font.GothamBold
        textLabel.TextSize = 13
        textLabel.Parent = billboard
        
        task.spawn(function()
            while char and char.Parent do
                local role = getRoleFromScoreboard(player)
                if role == "Murderer" then
                    textLabel.Text = player.Name .. "\n[🔪 УБИЙЦА]"
                    textLabel.TextColor3 = Color3.fromRGB(255, 50, 50) -- Красный
                elseif role == "Sheriff" or role == "Hero" then
                    textLabel.Text = player.Name .. "\n[🔫 ШЕРИФ]"
                    textLabel.TextColor3 = Color3.fromRGB(50, 150, 255) -- Синий
                else
                    textLabel.Text = player.Name .. "\n[Мирный]"
                    textLabel.TextColor3 = Color3.fromRGB(50, 255, 50) -- Зеленый
                end
                task.wait(0.5)
            end
        end)
    end
    
    if player.Character then
        task.spawn(function() addBillboard(player.Character) end)
    end
    player.CharacterAdded:Connect(function(char)
        task.spawn(function() addBillboard(char) end)
    end)
end

for _, p in ipairs(Players:GetPlayers()) do
    createESP(p)
end
Players.PlayerAdded:Connect(createESP)
