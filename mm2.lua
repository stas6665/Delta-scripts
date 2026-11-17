local CoreGui = game:GetService("CoreGui")
local outputBuffer = {}

local function ScanService(service, indent)
    indent = indent or ""
    local children = service:GetChildren()
    
    for _, child in ipairs(children) do
        local nameLower = string.lower(child.Name)
        
        if string.find(nameLower, "role") then
            local info = indent .. "├── " .. child.Name .. " [" .. child.ClassName .. "]"
            table.insert(outputBuffer, info)
            
            local function DumpInner(innerObj, innerIndent)
                for _, subChild in ipairs(innerObj:GetChildren()) do
                    local subInfo = innerIndent .. "│   ├── " .. subChild.Name .. " [" .. subChild.ClassName .. "]"
                    table.insert(outputBuffer, subInfo)
                    if #subChild:GetChildren() > 0 then
                        DumpInner(subChild, innerIndent .. "│   ")
                    end
                end
            end
            
            if #child:GetChildren() > 0 then
                DumpInner(child, indent)
            end
        end
        
        if #child:GetChildren() > 0 then
            ScanService(child, indent .. "│   ")
        end
    end
end

table.insert(outputBuffer, "=== STARTING GLOBAL SEARCH FOR 'ROLE' ===")
pcall(function()
    ScanService(game, "")
end)
table.insert(outputBuffer, "=== SEARCH COMPLETED ===")

local finalResult = table.concat(outputBuffer, "\n")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GlobalRoleFinderGui"
screenGui.Parent = CoreGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 450, 0, 350)
frame.Position = UDim2.new(0.5, -225, 0.5, -175)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0
frame.Parent = screenGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
title.Text = "Global Role Search Results"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 16
title.Font = Enum.Font.SourceSansBold
title.Parent = frame

local scrollingBox = Instance.new("ScrollingFrame")
scrollingBox.Size = UDim2.new(1, -20, 1, -100)
scrollingBox.Position = UDim2.new(0, 10, 0, 50)
scrollingBox.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
scrollingBox.CanvasSize = UDim2.new(0, 0, 3, 0)
scrollingBox.Parent = frame

local textBox = Instance.new("TextLabel")
textBox.Size = UDim2.new(1, -10, 1, 0)
textBox.Position = UDim2.new(0, 5, 0, 0)
textBox.BackgroundTransparency = 1
textBox.Text = finalResult
textBox.TextColor3 = Color3.fromRGB(0, 255, 128)
textBox.TextSize = 14
textBox.Font = Enum.Font.Code
textBox.TextXAlignment = Enum.TextXAlignment.Left
textBox.TextYAlignment = Enum.TextYAlignment.Top
textBox.Parent = scrollingBox

local copyButton = Instance.new("TextButton")
copyButton.Size = UDim2.new(1, -20, 0, 35)
copyButton.Position = UDim2.new(0, 10, 1, -45)
copyButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
copyButton.Text = "COPY TO CLIPBOARD"
copyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
copyButton.TextSize = 14
copyButton.Font = Enum.Font.SourceSansBold
copyButton.Parent = frame

copyButton.MouseButton1Click:Connect(function()
    pcall(function()
        setclipboard(finalResult)
    end)
    copyButton.Text = "COPIED SUCCESSFULLY!"
    task.wait(1.5)
    copyButton.Text = "COPY TO CLIPBOARD"
end)
