local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")

local guiParent = (gethui and gethui()) or CoreGui
local oldGui = guiParent:FindFirstChild("SourceRoleInspector")
if oldGui then oldGui:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SourceRoleInspector"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = guiParent

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 540, 0, 380)
MainFrame.Position = UDim2.new(0.5, -270, 0.5, -190)
MainFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 24)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(55, 55, 60)
UIStroke.Thickness = 1
UIStroke.Parent = MainFrame

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 32)
Header.BackgroundColor3 = Color3.fromRGB(32, 33, 36)
Header.BorderSizePixel = 0
Header.Parent = MainFrame

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 8)
HeaderCorner.Parent = Header

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -40, 1, 0)
TitleLabel.Position = UDim2.new(0, 12, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "Role Inspector [With Source Tracking]"
TitleLabel.TextColor3 = Color3.fromRGB(235, 235, 235)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 13
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = Header

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 32, 0, 32)
CloseBtn.Position = UDim2.new(1, -32, 0, 0)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 14
CloseBtn.Parent = Header

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- Перетаскивание окна
local dragging, dragInput, dragStart, startPos
Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)
Header.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

local LogScroll = Instance.new("ScrollingFrame")
LogScroll.Size = UDim2.new(1, -16, 1, -82)
LogScroll.Position = UDim2.new(0, 8, 0, 38)
LogScroll.BackgroundTransparency = 1
LogScroll.ScrollBarThickness = 4
LogScroll.ScrollBarImageColor3 = Color3.fromRGB(90, 90, 95)
LogScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
LogScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
LogScroll.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 4)
UIListLayout.Parent = LogScroll

local CopyBtn = Instance.new("TextButton")
CopyBtn.Size = UDim2.new(1, -16, 0, 32)
CopyBtn.Position = UDim2.new(0, 8, 1, -38)
CopyBtn.BackgroundColor3 = Color3.fromRGB(24, 119, 242)
CopyBtn.Text = "📋 Скопировать логи"
CopyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CopyBtn.Font = Enum.Font.GothamBold
CopyBtn.TextSize = 13
CopyBtn.Parent = MainFrame

local CopyCorner = Instance.new("UICorner")
CopyCorner.CornerRadius = UDim.new(0, 6)
CopyCorner.Parent = CopyBtn

local reportLines = {}

local function addLine(text, color)
    table.insert(reportLines, text)
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -8, 0, 0)
    label.AutomaticSize = Enum.AutomaticSize.Y
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = color or Color3.fromRGB(130, 220, 140)
    label.Font = Enum.Font.Code
    label.TextSize = 11
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = LogScroll

    task.defer(function()
        LogScroll.CanvasPosition = Vector2.new(0, LogScroll.AbsoluteCanvasSize.Y)
    end)
end

CopyBtn.MouseButton1Click:Connect(function()
    if setclipboard then
        setclipboard(table.concat(reportLines, "\n"))
        CopyBtn.Text = "✅ Скопировано!"
        task.wait(1.5)
        CopyBtn.Text = "📋 Скопировать логи"
    end
end)

local processed = {}

local function inspect(obj)
    if processed[obj] then return end
    processed[obj] = true
    
    local successName, name = pcall(function() return obj.Name end)
    if not successName or not name then return end
    
    local successPath, fullPath = pcall(function() return obj:GetFullName() end)
    if not successPath or not fullPath then return end
    
    if string.find(string.lower(name), "role") or string.find(string.lower(fullPath), "role") then
        addLine("🌍 [Обнаружено в игре]: " .. fullPath .. " [" .. obj.ClassName .. "]", Color3.fromRGB(255, 200, 100))
        
        if obj:IsA("RemoteEvent") then
            obj.OnClientEvent:Connect(function(...)
                local args = {...}
                -- Определяем родителя/источник ивента в структуре игры
                local sourceName = "Неизвестный источник"
                pcall(function()
                    sourceName = obj.Parent and obj.Parent:GetFullName() or "Корневой сервис"
                end)
                
                addLine(" 🔥 [Сработал ивент]: " .. name, Color3.fromRGB(255, 120, 120))
                addLine("    📍 Откуда прилетело (Путь): " .. fullPath, Color3.fromRGB(100, 220, 255))
                addLine("    📦 Контейнер-источник (Parent): " .. sourceName, Color3.fromRGB(200, 150, 255))
                
                for i, arg in ipairs(args) do
                    addLine(string.format("    ↳ Аргумент #%d [%s]: %s", i, typeof(arg), tostring(arg)), Color3.fromRGB(255, 185, 75))
                end
            end)
        end
    end
end

task.spawn(function()
    addLine("⚡ Сканер с отслеживанием источника запущен...", Color3.fromRGB(100, 180, 255))
    
    local containers = {
        workspace,
        game:GetService("ReplicatedStorage"),
        game:GetService("ReplicatedFirst"),
        game:GetService("Players"),
        game:GetService("StarterGui")
    }
    
    while true do
        for _, container in ipairs(containers) do
            task.spawn(function()
                pcall(function()
                    for _, descendant in ipairs(container:GetDescendants()) do
                        inspect(descendant)
                    end
                end)
            end)
        end
        task.wait(0.2)
    end
end)

pcall(function()
    game.DescendantAdded:Connect(function(newObj)
        task.defer(function() inspect(newObj) end)
    end)
end)
