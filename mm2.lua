local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local outputBuffer = {}
table.insert(outputBuffer, "=== DETAILED REMOTE INSPECTOR ===")

local function Log(text)
    print(text)
    table.insert(outputBuffer, text)
    if #outputBuffer > 50 then
        table.remove(outputBuffer, 1)
    end
end

local function InspectTable(tbl, indent)
    indent = indent or ""
    local result = "{\n"
    for k, v in pairs(tbl) do
        local keyStr = tostring(k)
        if typeof(k) == "Instance" then 
            keyStr = k.Name .. " [" .. k.ClassName .. "]" 
        end
        
        if type(v) == "table" then
            result = result .. indent .. "  " .. keyStr .. " = " .. InspectTable(v, indent .. "  ") .. ",\n"
        else
            local valStr = tostring(v)
            if typeof(v) == "Instance" then 
                valStr = v.Name .. " [" .. v.ClassName .. "]" 
            end
            result = result .. indent .. "  " .. keyStr .. " = " .. valStr .. " (" .. typeof(v) .. "),\n"
        end
    end
    return result .. indent .. "}"
end

local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
if remotesFolder then
    for _, child in ipairs(remotesFolder:GetDescendants()) do
        if child:IsA("RemoteEvent") or child:IsA("UnreliableRemoteEvent") then
            child.OnClientEvent:Connect(function(...)
                Log("\n[FIRED EVENT]: " .. child.GetFullName())
                local args = {...}
                for i, arg in ipairs(args) do
                    if type(arg) == "table" then
                        Log("  Arg #" .. i .. " (Table) content: " .. InspectTable(arg))
                    else
                        local val = tostring(arg)
                        if typeof(arg) == "Instance" then val = arg.Name .. " [" .. arg.ClassName .. "]" end
                        Log("  Arg #" .. i .. " (" .. typeof(arg) .. "): " .. val)
                    end
                end
            end)
            Log("[Connected to]: " .. child.Name)
        end
    end
end

local old = CoreGui:FindFirstChild("RemoteInspectorGui")
if old then old:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RemoteInspectorGui"
screenGui.Parent = CoreGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 480, 0, 400)
frame.Position = UDim2.new(0.5, -240, 0.5, -200)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
frame.BorderSizePixel = 0
frame.Parent = screenGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
title.Text = "Event Contents Inspector"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 16
title.Font = Enum.Font.GothamBold
title.Parent = frame

local scrollingBox = Instance.new("ScrollingFrame")
scrollingBox.Size = UDim2.new(1, -20, 1, -100)
scrollingBox.Position = UDim2.new(0, 10, 0, 50)
scrollingBox.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
scrollingBox.CanvasSize = UDim2.new(0, 0, 10, 0)
scrollingBox.Parent = frame

local textBox = Instance.new("TextLabel")
textBox.Size = UDim2.new(1, -10, 1, 0)
textBox.Position = UDim2.new(0, 5, 0, 0)
textBox.BackgroundTransparency = 1
textBox.Text = "Waiting for events to fire..."
textBox.TextColor3 = Color3.fromRGB(0, 255, 128)
textBox.TextSize = 12
textBox.Font = Enum.Font.Code
textBox.TextXAlignment = Enum.TextXAlignment.Left
textBox.TextYAlignment = Enum.TextYAlignment.Top
textBox.Parent = scrollingBox

task.spawn(function()
    while task.wait(0.4) do
        textBox.Text = table.concat(outputBuffer, "\n")
    end
end)

local copyButton = Instance.new("TextButton")
copyButton.Size = UDim2.new(1, -20, 0, 35)
copyButton.Position = UDim2.new(0, 10, 1, -45)
copyButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
copyButton.Text = "COPY ALL CONTENTS"
copyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
copyButton.TextSize = 14
copyButton.Font = Enum.Font.GothamBold
copyButton.Parent = frame

copyButton.MouseButton1Click:Connect(function()
    pcall(function()
        setclipboard(table.concat(outputBuffer, "\n"))
    end)
    copyButton.Text = "COPIED TO CLIPBOARD!"
    task.wait(1.5)
    copyButton.Text = "COPY ALL CONTENTS"
end)
