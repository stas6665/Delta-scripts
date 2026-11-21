local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local MAX_TOTAL_CHARS = 190000
local TRUNCATE_NOTICE = "\n... [ОСТАНОВЛЕНО: достигнут лимит 190 000 символов] ..."

local FALLBACK_KEYWORDS = {
	"inventory",
	"christmas",
	"halloween",
	"fx",
	"box",
	"item",
	"newitem",
}

local MAX_DEPTH = 4
local MAX_NODES_PER_TREE = 45
local CHUNK_SIZE = 3500

local oldGui = playerGui:FindFirstChild("TreeScannerQueryUI")
if oldGui then
	oldGui:Destroy()
end

local function parseQueryInput(rawText)
	local list = {}
	if typeof(rawText) == "string" then
		for token in string.gmatch(rawText, "[^,%s;|]+") do
			local cleaned = string.lower(token)
			if cleaned ~= "" then
				table.insert(list, cleaned)
			end
		end
	end
	if #list == 0 then
		for _, kw in ipairs(FALLBACK_KEYWORDS) do
			table.insert(list, kw)
		end
	end
	return list
end

local function matchesAnyKeyword(nameStr, keywords)
	if typeof(nameStr) ~= "string" or nameStr == "" then
		return false
	end
	local lower = string.lower(nameStr)
	for _, kw in ipairs(keywords) do
		if string.find(lower, kw, 1, true) ~= nil then
			return true
		end
	end
	return false
end

local function formatNodeDetails(obj)
	local info = {
		"[" .. obj.ClassName .. "]",
		obj:GetFullName(),
	}

	if obj:IsA("GuiObject") then
		table.insert(info, "Visible=" .. tostring(obj.Visible))
	end

	if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
		local cleanText = tostring(obj.Text):gsub("\r", " "):gsub("\n", "\\n")
		if #cleanText > 50 then
			cleanText = string.sub(cleanText, 1, 47) .. "..."
		end
		table.insert(info, 'Text="' .. cleanText .. '"')
	elseif obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
		if obj.Image ~= "" then
			table.insert(info, "Image=" .. tostring(obj.Image))
		end
	end

	return table.concat(info, " | ")
end

local function collectRootMatches(rootContainer, keywords)
	local roots = {}
	for _, desc in ipairs(rootContainer:GetDescendants()) do
		if matchesAnyKeyword(desc.Name, keywords) then
			local hasMatchedAncestor = false
			local parent = desc.Parent
			while parent and parent ~= rootContainer do
				if matchesAnyKeyword(parent.Name, keywords) then
					hasMatchedAncestor = true
					break
				end
				parent = parent.Parent
			end

			if not hasMatchedAncestor then
				table.insert(roots, desc)
			end
		end
	end
	return roots
end

local function clampToLimit(text)
	if #text <= MAX_TOTAL_CHARS then
		return text
	end
	local keepLen = math.max(0, MAX_TOTAL_CHARS - #TRUNCATE_NOTICE)
	local cut = string.sub(text, 1, keepLen) .. TRUNCATE_NOTICE
	if #cut > MAX_TOTAL_CHARS then
		cut = string.sub(cut, 1, MAX_TOTAL_CHARS)
	end
	return cut
end

local function buildQueryTreeReport(keywords)
	local allLines = {}
	local currentLen = 0
	local limitReached = false
	local includedTrees = 0

	local function tryAppendLine(line)
		if limitReached then
			return false
		end
		local sepLen = (#allLines > 0) and 1 or 0
		local needed = sepLen + #line
		local reserve = #TRUNCATE_NOTICE
		if currentLen + needed + reserve > MAX_TOTAL_CHARS then
			limitReached = true
			return false
		end
		table.insert(allLines, line)
		currentLen += needed
		return true
	end

	local targets = {
		{ label = "PlayerGui", container = playerGui },
		{ label = "ReplicatedStorage", container = ReplicatedStorage },
	}

	local totalRoots = 0
	local collectedByTarget = {}

	for _, target in ipairs(targets) do
		local roots = collectRootMatches(target.container, keywords)
		totalRoots += #roots
		table.insert(collectedByTarget, {
			label = target.label,
			roots = roots,
		})
	end

	tryAppendLine("ЗАПРОСЫ: " .. table.concat(keywords, ", "))
	tryAppendLine("НАЙДЕНО ВЕТОК ВСЕГО: " .. tostring(totalRoots))

	for _, entry in ipairs(collectedByTarget) do
		if limitReached then
			break
		end

		if not tryAppendLine("") then break end
		if not tryAppendLine(">>> РАЗДЕЛ: " .. entry.label .. " (веток: " .. tostring(#entry.roots) .. ") <<<") then break end

		for _, rootObj in ipairs(entry.roots) do
			if limitReached then
				break
			end

			local treeLines = {}
			table.insert(treeLines, "==================================================")
			table.insert(treeLines, "КОРЕНЬ: " .. rootObj:GetFullName())
			table.insert(treeLines, "==================================================")

			local baseDepth = #string.split(rootObj:GetFullName(), ".")
			local nodeCount = 0

			local function walk(current)
				if MAX_NODES_PER_TREE > 0 and nodeCount >= MAX_NODES_PER_TREE then
					return
				end

				local currentDepth = #string.split(current:GetFullName(), ".") - baseDepth
				if MAX_DEPTH > 0 and currentDepth > MAX_DEPTH then
					return
				end

				nodeCount += 1
				local indent = string.rep("  ", currentDepth)
				table.insert(treeLines, indent .. "├─ " .. formatNodeDetails(current))

				for _, child in ipairs(current:GetChildren()) do
					walk(child)
					if MAX_NODES_PER_TREE > 0 and nodeCount >= MAX_NODES_PER_TREE then
						break
					end
				end
			end

			walk(rootObj)

			local treeBlock = table.concat(treeLines, "\n")
			local sepLen = (#allLines > 0) and 1 or 0
			if currentLen + sepLen + #treeBlock + #TRUNCATE_NOTICE > MAX_TOTAL_CHARS then
				limitReached = true
				break
			end

			for _, l in ipairs(treeLines) do
				if not tryAppendLine(l) then
					break
				end
			end
			includedTrees += 1
		end
	end

	local fullReport = table.concat(allLines, "\n")
	if limitReached then
		fullReport = clampToLimit(fullReport .. TRUNCATE_NOTICE)
	else
		fullReport = clampToLimit(fullReport)
	end

	return fullReport, totalRoots, includedTrees, limitReached
end

local function copyReportToClipboard(reportText)
	if typeof(setclipboard) == "function" then
		local ok = pcall(setclipboard, reportText)
		return ok, ok and "Скопировано в буфер" or "Ошибка setclipboard"
	elseif typeof(toclipboard) == "function" then
		local ok = pcall(toclipboard, reportText)
		return ok, ok and "Скопировано в буфер" or "Ошибка toclipboard"
	end
	return false, "Буфер обмена недоступен"
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TreeScannerQueryUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local mainWindow = Instance.new("Frame")
mainWindow.Size = UDim2.new(0, 315, 0, 265)
mainWindow.Position = UDim2.new(0.5, -157, 0.5, -132)
mainWindow.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
mainWindow.BorderSizePixel = 0
mainWindow.Active = true
mainWindow.Draggable = true
mainWindow.Parent = screenGui

Instance.new("UICorner", mainWindow).CornerRadius = UDim.new(0, 12)
local mainStroke = Instance.new("UIStroke", mainWindow)
mainStroke.Color = Color3.fromRGB(165, 65, 255)
mainStroke.Thickness = 1.6

local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 36)
topBar.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
topBar.BorderSizePixel = 0
topBar.Parent = mainWindow
Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 12)

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -82, 1, 0)
titleLabel.Position = UDim2.new(0, 12, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Tree scanner"
titleLabel.TextColor3 = Color3.fromRGB(245, 245, 255)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 15
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = topBar

local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 30, 0, 26)
minBtn.Position = UDim2.new(1, -68, 0.5, -13)
minBtn.BackgroundColor3 = Color3.fromRGB(36, 36, 46)
minBtn.Text = "-"
minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 16
minBtn.Parent = topBar
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 6)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 26)
closeBtn.Position = UDim2.new(1, -34, 0.5, -13)
closeBtn.BackgroundColor3 = Color3.fromRGB(190, 45, 65)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.Parent = topBar
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

local content = Instance.new("Frame")
content.Size = UDim2.new(1, -20, 1, -44)
content.Position = UDim2.new(0, 10, 0, 40)
content.BackgroundTransparency = 1
content.Parent = mainWindow

local queryInput = Instance.new("TextBox")
queryInput.Size = UDim2.new(1, 0, 0, 34)
queryInput.BackgroundColor3 = Color3.fromRGB(26, 26, 34)
queryInput.TextColor3 = Color3.fromRGB(255, 255, 255)
queryInput.PlaceholderText = "Введи: MainGUI, Inventory, NewItem, FX, Box..."
queryInput.PlaceholderColor3 = Color3.fromRGB(135, 135, 155)
queryInput.Text = "MainGUI, Inventory, NewItem, FX, Box"
queryInput.ClearTextOnFocus = false
queryInput.Font = Enum.Font.Gotham
queryInput.TextSize = 12
queryInput.Parent = content
Instance.new("UICorner", queryInput).CornerRadius = UDim.new(0, 8)

local scanBtn = Instance.new("TextButton")
scanBtn.Size = UDim2.new(1, 0, 0, 36)
scanBtn.Position = UDim2.new(0, 0, 0, 40)
scanBtn.BackgroundColor3 = Color3.fromRGB(130, 45, 235)
scanBtn.Text = "Найти дерево"
scanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
scanBtn.Font = Enum.Font.GothamBold
scanBtn.TextSize = 14
scanBtn.Parent = content
Instance.new("UICorner", scanBtn).CornerRadius = UDim.new(0, 8)

local copyBtn = Instance.new("TextButton")
copyBtn.Size = UDim2.new(1, 0, 0, 36)
copyBtn.Position = UDim2.new(0, 0, 0, 82)
copyBtn.BackgroundColor3 = Color3.fromRGB(36, 36, 46)
copyBtn.Text = "Скопировать в буфер"
copyBtn.TextColor3 = Color3.fromRGB(165, 165, 185)
copyBtn.Font = Enum.Font.GothamBold
copyBtn.TextSize = 14
copyBtn.AutoButtonColor = false
copyBtn.Parent = content
Instance.new("UICorner", copyBtn).CornerRadius = UDim.new(0, 8)

local alphaBtn = Instance.new("TextButton")
alphaBtn.Size = UDim2.new(1, 0, 0, 22)
alphaBtn.Position = UDim2.new(0, 0, 0, 124)
alphaBtn.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
alphaBtn.Text = "Прозрачность окна: 0%"
alphaBtn.TextColor3 = Color3.fromRGB(220, 220, 235)
alphaBtn.Font = Enum.Font.GothamMedium
alphaBtn.TextSize = 11
alphaBtn.Parent = content
Instance.new("UICorner", alphaBtn).CornerRadius = UDim.new(0, 6)

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, 0, 0, 44)
statusLabel.Position = UDim2.new(0, 0, 1, -44)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Введи имена и нажми «Найти дерево»"
statusLabel.TextColor3 = Color3.fromRGB(190, 190, 210)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 11
statusLabel.TextWrapped = true
statusLabel.Parent = content

local lastReport = nil
local isScanning = false

local function setCopyButtonReady(ready)
	if ready then
		copyBtn.BackgroundColor3 = Color3.fromRGB(45, 155, 95)
		copyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		copyBtn.AutoButtonColor = true
	else
		copyBtn.BackgroundColor3 = Color3.fromRGB(36, 36, 46)
		copyBtn.TextColor3 = Color3.fromRGB(165, 165, 185)
		copyBtn.AutoButtonColor = false
	end
end

scanBtn.MouseButton1Click:Connect(function()
	if isScanning then
		return
	end
	isScanning = true
	scanBtn.Text = "Поиск..."
	statusLabel.Text = "Сканирую до 190 000 символов..."
	setCopyButtonReady(false)
	lastReport = nil

	local keywords = parseQueryInput(queryInput.Text)

	task.defer(function()
		local report, totalRoots, includedTrees, limitHit = buildQueryTreeReport(keywords)
		lastReport = report
		setCopyButtonReady(true)

		for i = 1, #report, CHUNK_SIZE do
			print(string.sub(report, i, i + CHUNK_SIZE - 1))
		end

		local suffix = limitHit and " [лимит]" or ""
		statusLabel.Text = string.format(
			"Веток: %d (в отчёте: %d) | %d/%d%s",
			totalRoots,
			includedTrees,
			#report,
			MAX_TOTAL_CHARS,
			suffix
		)

		scanBtn.Text = "Найти дерево"
		isScanning = false
	end)
end)

copyBtn.MouseButton1Click:Connect(function()
	if not lastReport or #lastReport == 0 then
		statusLabel.Text = "Сначала нажми «Найти дерево»"
		return
	end

	local ok, msg = copyReportToClipboard(lastReport)
	statusLabel.Text = ok
		and string.format("%s (%d симв.)", msg, #lastReport)
		or msg
end)

local minimized = false
minBtn.MouseButton1Click:Connect(function()
	minimized = not minimized
	content.Visible = not minimized
	mainWindow.Size = minimized and UDim2.new(0, 315, 0, 36) or UDim2.new(0, 315, 0, 265)
	minBtn.Text = minimized and "+" or "-"
end)

closeBtn.MouseButton1Click:Connect(function()
	screenGui:Destroy()
end)

local alphaPercent = 0
alphaBtn.MouseButton1Click:Connect(function()
	alphaPercent = (alphaPercent + 20) % 80
	mainWindow.BackgroundTransparency = alphaPercent / 100
	alphaBtn.Text = "Прозрачность окна: " .. tostring(alphaPercent) .. "%"
end)
