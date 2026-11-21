local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local CONFIG = {
	DefaultQuery = "NewItem",
	YieldEveryNodes = 250, -- каждые N узлов отдаём кадр, чтобы телефон не фризил
	SearchInPlayerGui = true,
	SearchInReplicatedStorage = true,
	SearchInWorkspace = false,
}

local function getGuiParent()
	local ok, res = pcall(function()
		return CoreGui
	end)
	if ok and res then
		local test = Instance.new("Folder")
		local canUseCore = pcall(function()
			test.Parent = res
			test:Destroy()
		end)
		if canUseCore then
			return res
		end
	end
	return playerGui
end

local function appendFullSubtree(root, outLines, counter)
	local children = root:GetChildren()
	for i, child in ipairs(children) do
		counter.children += 1
		counter.step += 1
		if counter.step % CONFIG.YieldEveryNodes == 0 then
			task.wait()
		end

		local isLast = (i == #children)
		local connector = isLast and "└── " or "├── "
		local nextPrefix = counter.prefix .. (isLast and "    " or "│   ")

		table.insert(outLines, string.format("%s%s%s [%s]", counter.prefix, connector, child.Name, child.ClassName))

		local prevPrefix = counter.prefix
		counter.prefix = nextPrefix
		appendFullSubtree(child, outLines, counter)
		counter.prefix = prevPrefix
	end
end

local function searchAndBuildFullReport(query)
	local trimmed = string.gsub(query or "", "^%s*(.-)%s*$", "%1")
	if trimmed == "" then
		return "Введи название или часть слова в поле поиска."
	end

	local needle = string.lower(trimmed)
	local roots = {}
	if CONFIG.SearchInPlayerGui then
		table.insert(roots, playerGui)
	end
	if CONFIG.SearchInReplicatedStorage then
		table.insert(roots, ReplicatedStorage)
	end
	if CONFIG.SearchInWorkspace then
		table.insert(roots, workspace)
	end

	local matches = {}
	local scanStep = 0
	for _, root in ipairs(roots) do
		for _, desc in ipairs(root:GetDescendants()) do
			scanStep += 1
			if scanStep % CONFIG.YieldEveryNodes == 0 then
				task.wait()
			end

			if desc.Name ~= "TreeSearchUI" and not desc:FindFirstAncestor("TreeSearchUI") then
				if string.find(string.lower(desc.Name), needle, 1, true) then
					table.insert(matches, desc)
				end
			end
		end
	end

	if #matches == 0 then
		return string.format("По запросу «%s» ничего не найдено.", trimmed)
	end

	local lines = {
		string.format("ЗАПРОС: %s | НАЙДЕНО: %d (БЕЗ ЛИМИТОВ)", trimmed, #matches),
		string.rep("=", 44),
	}

	for idx, match in ipairs(matches) do
		table.insert(lines, string.format("\n[%d] %s [%s]", idx, match:GetFullName(), match.ClassName))
		local counter = {
			children = 0,
			step = 0,
			prefix = "",
		}
		appendFullSubtree(match, lines, counter)
		table.insert(lines, string.format("    Всего потомков в ветке: %d", counter.children))
	end

	return table.concat(lines, "\n")
end

-- Построение компактного тёмного UI для телефона
local parentGui = getGuiParent()
local existing = parentGui:FindFirstChild("TreeSearchUI")
if existing then
	existing:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TreeSearchUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = parentGui

local mainFrame = Instance.new("Frame")
mainFrame.Name = "Main"
mainFrame.Size = UDim2.new(0.92, 0, 0.74, 0)
mainFrame.Position = UDim2.new(0.04, 0, 0.13, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 10)

local uiStroke = Instance.new("UIStroke")
uiStroke.Color = Color3.fromRGB(255, 195, 0)
uiStroke.Thickness = 1.5
uiStroke.Parent = mainFrame

local sizeConstraint = Instance.new("UISizeConstraint")
sizeConstraint.MaxSize = Vector2.new(460, 680)
sizeConstraint.MinSize = Vector2.new(260, 280)
sizeConstraint.Parent = mainFrame

local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.new(1, 0, 0, 38)
topBar.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
topBar.BorderSizePixel = 0
topBar.Parent = mainFrame
Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 10)

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -84, 1, 0)
titleLabel.Position = UDim2.new(0, 12, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "TREE SEARCH (FULL)"
titleLabel.TextColor3 = Color3.fromRGB(255, 210, 40)
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 14
titleLabel.Parent = topBar

local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 32, 0, 26)
minBtn.Position = UDim2.new(1, -72, 0.5, -13)
minBtn.BackgroundColor3 = Color3.fromRGB(36, 36, 44)
minBtn.Text = "-"
minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 16
minBtn.Parent = topBar
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 6)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 32, 0, 26)
closeBtn.Position = UDim2.new(1, -36, 0.5, -13)
closeBtn.BackgroundColor3 = Color3.fromRGB(165, 38, 38)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 13
closeBtn.Parent = topBar
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

local bodyFrame = Instance.new("Frame")
bodyFrame.Name = "Body"
bodyFrame.Size = UDim2.new(1, -16, 1, -48)
bodyFrame.Position = UDim2.new(0, 8, 0, 44)
bodyFrame.BackgroundTransparency = 1
bodyFrame.Parent = mainFrame

local searchBox = Instance.new("TextBox")
searchBox.Size = UDim2.new(1, -88, 0, 36)
searchBox.Position = UDim2.new(0, 0, 0, 0)
searchBox.BackgroundColor3 = Color3.fromRGB(26, 26, 34)
searchBox.Text = CONFIG.DefaultQuery
searchBox.PlaceholderText = "Введи имя объекта..."
searchBox.PlaceholderColor3 = Color3.fromRGB(130, 130, 145)
searchBox.TextColor3 = Color3.fromRGB(245, 245, 250)
searchBox.ClearTextOnFocus = false
searchBox.Font = Enum.Font.Code
searchBox.TextSize = 13
searchBox.Parent = bodyFrame
Instance.new("UICorner", searchBox).CornerRadius = UDim.new(0, 7)

local findBtn = Instance.new("TextButton")
findBtn.Size = UDim2.new(0, 82, 0, 36)
findBtn.Position = UDim2.new(1, -82, 0, 0)
findBtn.BackgroundColor3 = Color3.fromRGB(255, 195, 0)
findBtn.Text = "Найти"
findBtn.TextColor3 = Color3.fromRGB(15, 15, 18)
findBtn.Font = Enum.Font.GothamBold
findBtn.TextSize = 13
findBtn.Parent = bodyFrame
Instance.new("UICorner", findBtn).CornerRadius = UDim.new(0, 7)

local copyBtn = Instance.new("TextButton")
copyBtn.Size = UDim2.new(0.5, -4, 0, 30)
copyBtn.Position = UDim2.new(0, 0, 0, 42)
copyBtn.BackgroundColor3 = Color3.fromRGB(34, 34, 44)
copyBtn.Text = "Копировать"
copyBtn.TextColor3 = Color3.fromRGB(235, 235, 245)
copyBtn.Font = Enum.Font.GothamBold
copyBtn.TextSize = 12
copyBtn.Parent = bodyFrame
Instance.new("UICorner", copyBtn).CornerRadius = UDim.new(0, 6)

local clearBtn = Instance.new("TextButton")
clearBtn.Size = UDim2.new(0.5, -4, 0, 30)
clearBtn.Position = UDim2.new(0.5, 4, 0, 42)
clearBtn.BackgroundColor3 = Color3.fromRGB(34, 34, 44)
clearBtn.Text = "Очистить"
clearBtn.TextColor3 = Color3.fromRGB(235, 235, 245)
clearBtn.Font = Enum.Font.GothamBold
clearBtn.TextSize = 12
clearBtn.Parent = bodyFrame
Instance.new("UICorner", clearBtn).CornerRadius = UDim.new(0, 6)

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, 0, 1, -80)
scrollFrame.Position = UDim2.new(0, 0, 0, 80)
scrollFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 13)
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 5
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.XY
scrollFrame.Parent = bodyFrame
Instance.new("UICorner", scrollFrame).CornerRadius = UDim.new(0, 8)

local outputLabel = Instance.new("TextLabel")
outputLabel.Size = UDim2.new(0, 0, 0, 0)
outputLabel.AutomaticSize = Enum.AutomaticSize.XY
outputLabel.BackgroundTransparency = 1
outputLabel.Text = "Нажми «Найти» для полного поиска."
outputLabel.TextColor3 = Color3.fromRGB(215, 220, 230)
outputLabel.TextXAlignment = Enum.TextXAlignment.Left
outputLabel.TextYAlignment = Enum.TextYAlignment.Top
outputLabel.RichText = false
outputLabel.Font = Enum.Font.Code
outputLabel.TextSize = 12
outputLabel.Parent = scrollFrame

local pad = Instance.new("UIPadding")
pad.PaddingTop = UDim.new(0, 8)
pad.PaddingBottom = UDim.new(0, 8)
pad.PaddingLeft = UDim.new(0, 8)
pad.PaddingRight = UDim.new(0, 12)
pad.Parent = outputLabel

local currentReport = ""
local isBusy = false

local function runSearch()
	if isBusy then
		return
	end
	isBusy = true
	findBtn.Text = "..."
	outputLabel.Text = "Сканирую полное дерево..."

	local ok, result = pcall(function()
		return searchAndBuildFullReport(searchBox.Text)
	end)

	currentReport = ok and result or ("Ошибка сканирования: " .. tostring(result))
	outputLabel.Text = currentReport
	scrollFrame.CanvasPosition = Vector2.new(0, 0)
	findBtn.Text = "Найти"
	isBusy = false
end

findBtn.MouseButton1Click:Connect(runSearch)
searchBox.FocusLost:Connect(function(enterPressed)
	if enterPressed then
		runSearch()
	end
end)

copyBtn.MouseButton1Click:Connect(function()
	if currentReport == "" then
		return
	end
	if setclipboard then
		local ok = pcall(setclipboard, currentReport)
		copyBtn.Text = ok and "Скопировано!" or "Нет доступа"
	else
		copyBtn.Text = "Нет setclipboard"
	end
	task.delay(1.2, function()
		if copyBtn.Parent then
			copyBtn.Text = "Копировать"
		end
	end)
end)

clearBtn.MouseButton1Click:Connect(function()
	if isBusy then
		return
	end
	searchBox.Text = ""
	currentReport = ""
	outputLabel.Text = ""
	scrollFrame.CanvasPosition = Vector2.new(0, 0)
end)

local minimized = false
minBtn.MouseButton1Click:Connect(function()
	minimized = not minimized
	bodyFrame.Visible = not minimized
	mainFrame.Size = minimized and UDim2.new(0.92, 0, 0, 38) or UDim2.new(0.92, 0, 0.74, 0)
	minBtn.Text = minimized and "+" or "-"
end)

closeBtn.MouseButton1Click:Connect(function()
	screenGui:Destroy()
end)

runSearch()
