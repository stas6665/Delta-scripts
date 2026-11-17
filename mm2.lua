local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

if playerGui:FindFirstChild("RoleInspectorGui") then
playerGui.RoleInspectorGui:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RoleInspectorGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 550, 0, 400)
mainFrame.Position = UDim2.new(0.5, -275, 0.5, -200)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 40)
titleLabel.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 15
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.Text = "Role Inspector (Optimized Real-Time Scan)"
titleLabel.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 8)
titleCorner.Parent = titleLabel

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, -20, 1, -100)
scrollFrame.Position = UDim2.new(0, 10, 0, 50)
scrollFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
scrollFrame.BorderSizePixel = 0
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollFrame.Parent = mainFrame

local logLabel = Instance.new("TextLabel")
logLabel.Size = UDim2.new(1, 0, 1, 0)
logLabel.BackgroundTransparency = 1
logLabel.TextColor3 = Color3.fromRGB(0, 255, 128)
logLabel.TextSize = 13
logLabel.Font = Enum.Font.Code
logLabel.TextXAlignment = Enum.TextXAlignment.Left
logLabel.TextYAlignment = Enum.TextYAlignment.Top
logLabel.TextWrapped = true
logLabel.Text = "Оптимизированное сканирование запущено...\n"
logLabel.Parent = scrollFrame

local copyButton = Instance.new("TextButton")
copyButton.Size = UDim2.new(1, -20, 0, 35)
copyButton.Position = UDim2.new(0, 10, 1, -42)
copyButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
copyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
copyButton.TextSize = 14
copyButton.Font = Enum.Font.SourceSansBold
copyButton.Text = "📋 Скопировать в буфер"
copyButton.Parent = mainFrame

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 6)
btnCorner.Parent = copyButton

local fullLogText = ""
local function Log(text)
print(text)
fullLogText = fullLogText .. text .. "\n"
logLabel.Text = fullLogText
end

copyButton.MouseButton1Click:Connect(function()
if setclipboard then
setclipboard(fullLogText)
copyButton.Text = "✅ Скопировано!"
task.wait(1.5)
copyButton.Text = "📋 Скопировать в буфер"
else
copyButton.Text = "❌ setclipboard не поддерживается"
task.wait(1.5)
copyButton.Text = "📋 Скопировать в буфер"
end
end)

local function InspectTable(tbl, indent)
indent = indent or ""
local result = "{\n"
for k, v in pairs(tbl) do
local keyStr = tostring(k)
if typeof(k) == "Instance" then
keyStr = k.Name .. " [" .. k.ClassName .. "]"
end

if type(v) == "table" then result = result .. indent .. " " .. keyStr .. " = " .. InspectTable(v, indent .. " ") .. ",\n" else local valStr = tostring(v) if typeof(v) == "Instance" then valStr = v.Name .. " [" .. v.ClassName .. "]" end result = result .. indent .. " " .. keyStr .. " = " .. valStr .. " (" .. typeof(v) .. "),\n" end end return result .. indent .. "}" 

end

local hookedObjects = {}

local function RunScan()
local containers = {ReplicatedStorage, Workspace}

for _, container in ipairs(containers) do pcall(function() for _, child in ipairs(container:GetDescendants()) do if child.Name:lower():match("role") and not hookedObjects[child] then hookedObjects[child] = true Log("➕ Найдено: " .. child:GetFullName() .. " [" .. child.ClassName .. "]") if child:IsA("RemoteEvent") or child:IsA("UnreliableRemoteEvent") then child.OnClientEvent:Connect(function(...) Log("\n🔥 [Сработал] " .. child:GetFullName()) local args = {...} for i, arg in ipairs(args) do if type(arg) == "table" then Log(" Arg #" .. i .. " (Table): " .. InspectTable(arg)) else local val = tostring(arg) if typeof(arg) == "Instance" then val = arg.Name .. " [" .. arg.ClassName .. "]" end Log(" Arg #" .. i .. " (" .. typeof(arg) .. "): " .. val) end end end) end end end end) end 

end

local timeAccumulator = 0
RunService.Heartbeat:Connect(function(dt)
timeAccumulator = timeAccumulator + dt
if timeAccumulator >= 0.5 then
timeAccumulator = 0
RunScan()
end
end)

