local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RoleInspectorGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 480, 0, 320)
MainFrame.Position = UDim2.new(0.5, -240, 0.5, -160)
MainFrame.BackgroundColor3 = Color3.fromRGB(24, 26, 31)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 35)
TopBar.BackgroundColor3 = Color3.fromRGB(32, 35, 42)
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame

local TopBarCorner = Instance.new("UICorner")
TopBarCorner.CornerRadius = UDim.new(0, 8)
TopBarCorner.Parent = TopBar

local TopBarCover = Instance.new("Frame")
TopBarCover.Size = UDim2.new(1, 0, 0, 10)
TopBarCover.Position = UDim2.new(0, 0, 1, -10)
TopBarCover.BackgroundColor3 = Color3.fromRGB(32, 35, 42)
TopBarCover.BorderSizePixel = 0
TopBarCover.Parent = TopBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 1, 0)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.Text = "Role Inspector (Real-Time Scan)"
Title.TextColor3 = Color3.fromRGB(220, 225, 235)
Title.TextSize = 13
Title.Parent = TopBar

local ScrollingFrame = Instance.new("ScrollingFrame")
ScrollingFrame.Size = UDim2.new(1, -20, 1, -95)
ScrollingFrame.Position = UDim2.new(0, 10, 0, 45)
ScrollingFrame.BackgroundColor3 = Color3.fromRGB(18, 20, 24)
ScrollingFrame.BorderSizePixel = 0
ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
ScrollingFrame.ScrollBarThickness = 6
ScrollingFrame.Parent = MainFrame

local ScrollCorner = Instance.new("UICorner")
ScrollCorner.CornerRadius = UDim.new(0, 6)
ScrollCorner.Parent = ScrollingFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.SortOrder = Enum.SortOrder.LayoutIndex
UIListLayout.Padding = UDim.new(0, 4)
UIListLayout.Parent = ScrollingFrame

local UIPadding = Instance.new("UIPadding")
UIPadding.PaddingTop = UDim.new(0, 8)
UIPadding.PaddingBottom = UDim.new(0, 8)
UIPadding.PaddingLeft = UDim.new(0, 10)
UIPadding.PaddingRight = UDim.new(0, 10)
UIPadding.Parent = ScrollingFrame

local CopyButton = Instance.new("TextButton")
CopyButton.Size = UDim2.new(1, -20, 0, 32)
CopyButton.Position = UDim2.new(0, 10, 1, -42)
CopyButton.BackgroundColor3 = Color3.fromRGB(0, 122, 255)
CopyButton.BorderSizePixel = 0
CopyButton.Font = Enum.Font.GothamSemibold
CopyButton.Text = "Скопировать в буфер"
CopyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CopyButton.TextSize = 13
CopyButton.Parent = MainFrame

local BtnCorner = Instance.new("UICorner")
BtnCorner.CornerRadius = UDim.new(0, 6)
BtnCorner.Parent = CopyButton

local allLogs = {}

local function addLog(text, color)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 18)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Code
    label.Text = text
    label.TextColor3 = color or Color3.fromRGB(120, 220, 120)
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = ScrollingFrame
    
    table.insert(allLogs, text)
    ScrollingCanvasSize = ScrollingFrame.AbsoluteCanvasSize
    ScrollingFrame.CanvasPosition = Vector2.new(0, 99999)
end

CopyButton.MouseButton1Click:Connect(function()
    if setclipboard then
        setclipboard(table.concat(allLogs, "\n"))
        CopyButton.Text = "Скопировано!"
        task.wait(1)
        CopyButton.Text = "Скопировать в буфер"
    end
end)

local function scanGame()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local char = player.Character
            if char then
                local backpack = player:FindFirstChild("Backpack")
                local hasKnife = char:FindFirstChild("Knife") or (backpack and backpack:FindFirstChild("Knife"))
                local hasGun = char:FindFirstChild("Gun") or char:FindFirstChild("Revolver") or (backpack and (backpack:FindFirstChild("Gun") or backpack:FindFirstChild("Revolver")))
                
                local role = "Innocent"
                local col = Color3.fromRGB(80, 220, 100)
                if hasKnife then
                    role = "Murderer"
                    col = Color3.fromRGB(255, 75, 75)
                elseif hasGun then
                    role = "Sheriff"
                    col = Color3.fromRGB(75, 150, 255)
                end
                
                addLog(string.format("[Scan] Player: %s | Role: %s", player.Name, role), col)
            end
        end
    end
    addLog("--- Сканирование завершено (0.2s) ---", Color3.fromRGB(180, 180, 180))
end

task.spawn(function()
    while true do
        pcall(scanGame)
        task.wait(0.2)
    end
end)
