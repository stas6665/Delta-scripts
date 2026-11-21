-- Auto-scan on startup + Output Window + Copy All button
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

if not RunService:IsClient() then
	return
end

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local existingGui = playerGui:FindFirstChild("ScannerOutputGui")
if existingGui then
	existingGui:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ScannerOutputGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 999
screenGui.Parent = playerGui

local function addCorner(parent: Instance, radius: number)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
	return corner
end

local function addStroke(parent: Instance, color: Color3, thickness: number)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness
	stroke.Parent = parent
	return stroke
end

local mainWin = Instance.new("Frame")
mainWin.Name = "OutputWindow"
mainWin.AnchorPoint = Vector2.new(0.5, 0.5)
mainWin.Position = UDim2.fromScale(0.5, 0.5)
mainWin.Size = UDim2.fromOffset(330, 260)
mainWin.BackgroundColor3 = Color3.fromRGB(16, 18, 24)
mainWin.ZIndex = 1000
mainWin.Parent = screenGui
addCorner(mainWin, 8)
addStroke(mainWin, Color3.fromRGB(95, 165, 255), 1.5)

local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.new(1, 0, 0, 28)
topBar.BackgroundColor3 = Color3.fromRGB(26, 30, 40)
topBar.ZIndex = 1001
topBar.Parent = mainWin
addCorner(topBar, 8)

local titleLbl = Instance.new("TextLabel")
titleLbl.Size = UDim2.new(1, -104, 1, 0)
titleLbl.Position = UDim2.fromOffset(10, 0)
titleLbl.BackgroundTransparency = 1
titleLbl.Font = Enum.Font.GothamBold
titleLbl.TextSize = 13
titleLbl.TextXAlignment = Enum.TextXAlignment.Left
titleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLbl.Text = "UI Tree Scanner"
titleLbl.ZIndex = 1002
titleLbl.Parent = topBar

local scanBtn = Instance.new("TextButton")
scanBtn.Name = "RescanButton"
scanBtn.Size = UDim2.fromOffset(22, 20)
scanBtn.Position = UDim2.new(1, -96, 0.5, -10)
scanBtn.BackgroundColor3 = Color3.fromRGB(52, 140, 92)
scanBtn.Font = Enum.Font.GothamBold
scanBtn.TextSize = 11
scanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
scanBtn.Text = "R"
scanBtn.ZIndex = 1002
scanBtn.Parent = topBar
addCorner(scanBtn, 5)

local minBtn = Instance.new("TextButton")
minBtn.Name = "MinimizeButton"
minBtn.Size = UDim2.fromOffset(22, 20)
minBtn.Position = UDim2.new(1, -72, 0.5, -10)
minBtn.BackgroundColor3 = Color3.fromRGB(45, 52, 68)
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 13
minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minBtn.Text = "-"
minBtn.ZIndex = 1002
minBtn.Parent = topBar
addCorner(minBtn, 5)

local clearBtn = Instance.new("TextButton")
clearBtn.Name = "ClearButton"
clearBtn.Size = UDim2.fromOffset(22, 20)
clearBtn.Position = UDim2.new(1, -48, 0.5, -10)
clearBtn.BackgroundColor3 = Color3.fromRGB(70, 55, 110)
clearBtn.Font = Enum.Font.GothamBold
clearBtn.TextSize = 11
clearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
clearBtn.Text = "C"
clearBtn.ZIndex = 1002
clearBtn.Parent = topBar
addCorner(clearBtn, 5)

local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseButton"
closeBtn.Size = UDim2.fromOffset(22, 20)
closeBtn.Position = UDim2.new(1, -24, 0.5, -10)
closeBtn.BackgroundColor3 = Color3.fromRGB(175, 52, 52)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 12
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Text = "X"
closeBtn.ZIndex = 1002
closeBtn.Parent = topBar
addCorner(closeBtn, 5)

-- Перетаскивание (тач + мышь)
local dragging = false
local dragStart: Vector3? = nil
local winStart: UDim2? = nil

topBar.InputBegan:Connect(function(input: InputObject)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		winStart = mainWin.Position
	end
end)

UserInputService.InputChanged:Connect(function(input: InputObject)
	if not dragging or not dragStart or not winStart then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		local delta = input.Position - dragStart
		mainWin.Position = UDim2.new(
			winStart.X.Scale,
			winStart.X.Offset + delta.X,
			winStart.Y.Scale,
			winStart.Y.Offset + delta.Y
		)
	end
end)

UserInputService.InputEnded:Connect(function(input: InputObject)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
		dragStart = nil
		winStart = nil
	end
end)

local body = Instance.new("Frame")
body.Name = "Body"
body.Size = UDim2.new(1, -16, 1, -36)
body.Position = UDim2.fromOffset(8, 32)
body.BackgroundTransparency = 1
body.ZIndex = 1001
body.Parent = mainWin

local scroll = Instance.new("ScrollingFrame")
scroll.Name = "OutputScroll"
scroll.Size = UDim2.new(1, 0, 1, -38)
scroll.Position = UDim2.fromOffset(0, 0)
scroll.BackgroundColor3 = Color3.fromRGB(22, 25, 34)
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 5
scroll.CanvasSize = UDim2.fromOffset(600, 400)
scroll.ZIndex = 1002
scroll.Parent = body
addCorner(scroll, 6)
addStroke(scroll, Color3.fromRGB(48, 56, 76), 1)

local outputLabel = Instance.new("TextLabel")
outputLabel.Name = "OutputLabel"
outputLabel.Size = UDim2.new(0, 1200, 0, 2000)
outputLabel.Position = UDim2.fromOffset(6, 6)
outputLabel.BackgroundTransparency = 1
outputLabel.Font = Enum.Font.Code
outputLabel.TextSize = 11
outputLabel.TextXAlignment = Enum.TextXAlignment.Left
outputLabel.TextYAlignment = Enum.TextYAlignment.Top
outputLabel.TextWrapped = false
outputLabel.RichText = false
outputLabel.TextColor3 = Color3.fromRGB(225, 232, 245)
outputLabel.Text = "Сканирование..."
outputLabel.ZIndex = 1003
outputLabel.Parent = scroll

local copyBtn = Instance.new("TextButton")
copyBtn.Name = "CopyAllButton"
copyBtn.Size = UDim2.new(1, 0, 0, 32)
copyBtn.Position = UDim2.new(0, 0, 1, -32)
copyBtn.BackgroundColor3 = Color3.fromRGB(58, 130, 225)
copyBtn.Font = Enum.Font.GothamBold
copyBtn.TextSize = 13
copyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
copyBtn.Text = "Копировать всё"
copyBtn.ZIndex = 1002
copyBtn.Parent = body
addCorner(copyBtn, 6)

local keywords = {
	"inventory",
	"claim",
	"christmas",
	"halloween",
	"hellowen",
	"box",
}

local function getMatchedKeywords(name: string): { string }
	local lower = string.lower(name)
	local matched = {}
	for _, kw in ipairs(keywords) do
		if string.find(lower, kw, 1, true) then
			table.insert(matched, kw)
		end
	end
	return matched
end

local function formatNodeInfo(inst: Instance, matched: { string }?): string
	local parentName = inst.Parent and inst.Parent.Name or "nil"
	local info = string.format("%s [%s] (Parent: %s)", inst.Name, inst.ClassName, parentName)
	if inst:IsA("GuiObject") then
		info ..= string.format(" | Visible=%s", tostring(inst.Visible))
	elseif inst:IsA("LayerCollector") then
		info ..= string.format(" | Enabled=%s", tostring(inst.Enabled))
	end
	if matched and #matched > 0 then
		info ..= " | Match: " .. table.concat(matched, ",")
	end
	return info
end

local function dumpSubtree(root: Instance, lines: { string }, prefix: string, maxDepth: number, currentDepth: number)
	if currentDepth > maxDepth then
		return
	end
	for _, child in ipairs(root:GetChildren()) do
		local m = getMatchedKeywords(child.Name)
		table.insert(lines, string.format("%s|-- %s", prefix, formatNodeInfo(child, m)))
		dumpSubtree(child, lines, prefix .. "|   ", maxDepth, currentDepth + 1)
	end
end

local function updateCanvasForText(text: string)
	local lineCount = 1
	for _ in string.gmatch(text, "\n") do
		lineCount += 1
	end

	local maxLen = 20
	for line in string.gmatch(text, "[^\n]+") do
		if #line > maxLen then
			maxLen = #line
		end
	end

	local width = math.max(scroll.AbsoluteSize.X, maxLen * 7 + 24)
	local height = math.max(scroll.AbsoluteSize.Y, lineCount * 15 + 24)

	outputLabel.Size = UDim2.fromOffset(width, height)
	scroll.CanvasSize = UDim2.fromOffset(width + 12, height + 12)
	scroll.CanvasPosition = Vector2.zero
end

local function runScan()
	local lines = { "=== PlayerGui Tree & Path Scan ===" }
	local foundAny = false

	table.insert(lines, "\n--- 1. EXACT MATCHES & WHERE THEY ARE ---")
	for _, gui in ipairs(playerGui:GetChildren()) do
		if gui ~= screenGui then
			local rootMatches = getMatchedKeywords(gui.Name)
			if #rootMatches > 0 then
				foundAny = true
				table.insert(lines, "[ROOT] " .. gui:GetFullName() .. " -> " .. formatNodeInfo(gui, rootMatches))
				dumpSubtree(gui, lines, "    ", 3, 1)
			end

			for _, desc in ipairs(gui:GetDescendants()) do
				local matches = getMatchedKeywords(desc.Name)
				if #matches > 0 then
					foundAny = true
					table.insert(lines, "")
					table.insert(lines, "[MATCH] " .. desc:GetFullName())
					table.insert(lines, "  Где находится: " .. formatNodeInfo(desc, matches))
					if desc.Parent then
						table.insert(lines, "  Внутри родителя: " .. desc.Parent:GetFullName() .. " [" .. desc.Parent.ClassName .. "]")
					end
					local childrenCount = #desc:GetChildren()
					table.insert(lines, "  Вложенных объектов: " .. tostring(childrenCount))
					if childrenCount > 0 then
						table.insert(lines, "  Дерево внутри:")
						dumpSubtree(desc, lines, "    ", 3, 1)
					end
				end
			end
		end
	end

	if not foundAny then
		table.insert(lines, "Совпадений по Inventory / Claim / Christmas / Halloween / Hellowen / Box не найдено.")
	end

	table.insert(lines, "\n--- 2. ALL SCREENGUIS IN PLAYERGUI ---")
	for _, gui in ipairs(playerGui:GetChildren()) do
		if gui ~= screenGui then
			table.insert(lines, "  * " .. formatNodeInfo(gui))
			for _, child in ipairs(gui:GetChildren()) do
				table.insert(lines, "      - " .. formatNodeInfo(child))
			end
		end
	end

	local result = table.concat(lines, "\n")
	outputLabel.Text = result
	updateCanvasForText(result)
	print(result)
end

copyBtn.MouseButton1Click:Connect(function()
	local textToCopy = outputLabel.Text
	local copied = false
	if typeof(setclipboard) == "function" then
		copied = pcall(setclipboard, textToCopy)
	end

	if copied then
		copyBtn.Text = "Скопировано!"
		copyBtn.BackgroundColor3 = Color3.fromRGB(52, 155, 92)
	else
		copyBtn.Text = "Нет setclipboard"
		copyBtn.BackgroundColor3 = Color3.fromRGB(185, 120, 40)
	end

	task.delay(1.2, function()
		if copyBtn and copyBtn.Parent then
			copyBtn.Text = "Копировать всё"
			copyBtn.BackgroundColor3 = Color3.fromRGB(58, 130, 225)
		end
	end)
end)

scanBtn.MouseButton1Click:Connect(runScan)

clearBtn.MouseButton1Click:Connect(function()
	outputLabel.Text = ""
	updateCanvasForText("")
end)

local minimized = false
minBtn.MouseButton1Click:Connect(function()
	minimized = not minimized
	body.Visible = not minimized
	mainWin.Size = minimized and UDim2.fromOffset(330, 28) or UDim2.fromOffset(330, 260)
	minBtn.Text = minimized and "+" or "-"
end)

closeBtn.MouseButton1Click:Connect(function()
	screenGui:Destroy()
end)

-- Автосканирование сразу при запуске и повторно через 1 сек после догрузки UI
runScan()
task.delay(1, function()
	if screenGui and screenGui.Parent then
		runScan()
	end
end)
