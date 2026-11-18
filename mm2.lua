local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local guiParent = (gethui and gethui()) or CoreGui
local oldGui = guiParent:FindFirstChild("RoleInspectorExactSourceUI")
if oldGui then oldGui:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RoleInspectorExactSourceUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = guiParent

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 480, 0, 360)
MainFrame.Position = UDim2.new(0.5, -240, 0.5, -180)
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
TitleLabel.Text = "Role Inspector [Exact Remote Source]"
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

local rawLogs = {}

local function addLogUI(text, color)
    local t = os.date("*t")
    local milliseconds = string.format("%.3f", tick() % 1):sub(3)
    local timestamp = string.format("[%02d:%02d:%02d.%s] ", t.hour, t.min, t.sec, milliseconds)
    
    local fullText = timestamp .. text
    table.insert(rawLogs, fullText)
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -8, 0, 0)
    label.AutomaticSize = Enum.AutomaticSize.Y
    label.BackgroundTransparency = 1
    label.Text = fullText
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
        setclipboard(table.concat(rawLogs, "\n"))
        CopyBtn.Text = "✅ Скопировано!"
        task.wait(1.5)
        CopyBtn.Text = "📋 Скопировать логи"
    end
end)

local function serialize(val)
    if type(val) == "table" then
        local parts = {}
        for k, v in pairs(val) do
            table.insert(parts, tostring(k) .. "=" .. serialize(v))
        end
        return "{" .. table.concat(parts, ", ") .. "}"
    elseif typeof(val) == "Instance" then
        return val:GetFullName() .. " [" .. val.ClassName .. "]"
    else
        return tostring(val)
    end
end

local trackedObjects = {}

local function inspectObject(obj)
    if trackedObjects[obj] then return end
    
    local success, name = pcall(function() return obj.Name end)
    if success and name and string.find(string.lower(name), "role") then
        trackedObjects[obj] = true
        local fullPath = pcall(function() return obj:GetFullName() end) and obj:GetFullName() or tostring(obj)
        
        addLogUI("🔍 Найден объект: " .. fullPath, Color3.fromRGB(115, 215, 130))

        if obj:IsA("RemoteEvent") then
            obj.OnClientEvent:Connect(function(...)
                local args = table.pack(...)
                local logLines = { "🔥 [ВХОДЯЩИЙ ИВЕНТ]" }
                table.insert(logLines, "   📂 Путь: " .. fullPath)
                table.insert(logLines, "   📡 Точный источник: [СЕРВЕР -> КЛИЕНТ] (Отправлено сервером)")
                
                if args.n == 0 then
                    table.insert(logLines, "   📦 Аргументы: (пусто)")
                else
                    table.insert(logLines, "   📦 Аргументы:")
                    for i = 1, args.n do
                        local argVal = args[i]
                        table.insert(logLines, "      # " .. i .. " [" .. typeof(argVal) .. "]: " .. serialize(argVal))
                        
                        if typeof(argVal) == "string" and (argVal == "Murderer" or argVal == "Sheriff" or argVal == "Innocent") then
                            table.insert(logLines, "      ⚡ [РОЛЬ]: " .. argVal)
                        end
                    end
                end
                addLogUI(table.concat(logLines, "\n"), Color3.fromRGB(255, 185, 75))
            end)
            
            local oldFireServer = obj.FireServer
            obj.FireServer = function(self, ...)
                local args = table.pack(...)
                local logLines = { "📤 [ИЗХОДЯЩИЙ ИВЕНТ]" }
                table.insert(logLines, "   📂 Путь: " .. fullPath)
                table.insert(logLines, "   📡 Точный источник: [КЛИЕНТ -> СЕРВЕР] (Отправлено нашим клиентом)")
                
                if args.n == 0 then
                    table.insert(logLines, "   📦 Аргументы: (пусто)")
                else
                    table.insert(logLines, "   📦 Аргументы:")
                    for i = 1, args.n do
                        local argVal = args[i]
                        table.insert(logLines, "      # " .. i .. " [" .. typeof(argVal) .. "]: " .. serialize(argVal))
                    end
                end
                addLogUI(table.concat(logLines, "\n"), Color3.fromRGB(100, 200, 255))
                
                return oldFireServer(self, unpack(args, 1, args.n))
            end
        end
    end
end

local servicesToScan = {
    workspace,
    ReplicatedStorage,
    game:GetService("ReplicatedFirst"),
    Players,
    game:GetService("StarterGui"),
    game:GetService("StarterPack"),
    game:GetService("Lighting")
}

task.spawn(function()
    addLogUI("[System] Сканер запущен...", Color3.fromRGB(100, 180, 255))
    while true do
        for _, service in ipairs(servicesToScan) do
            pcall(function()
                for _, descendant in ipairs(service:GetDescendants()) do
                    inspectObject(descendant)
                end
            end)
        end
        task.wait(0.1)
    end
end)

for _, service in ipairs(servicesToScan) do
    pcall(function()
        service.DescendantAdded:Connect(function(newObj)
            inspectObject(newObj)
        end)
    end)
end
