local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local parentGui = LocalPlayer:WaitForChild("PlayerGui")

if parentGui:FindFirstChild("UnlimitedTreeGui") then
	parentGui.UnlimitedTreeGui:Destroy()
end

-- === КАСТОМНЫЙ ИНТЕРФЕЙС ===
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "UnlimitedTreeGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = parentGui

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0.94, 0, 0.56, 0)
MainFrame.Position = UDim2.new(0.03, 0, 0.04, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
MainFrame.BackgroundTransparency = 0.08
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(80, 80, 100)
Stroke.Thickness = 1
Stroke.Parent = MainFrame

local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 34)
TopBar.BackgroundColor3 = Color3.fromRGB(26, 26, 34)
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame
Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 10)

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(0.32, -8, 1, 0)
TitleLabel.Position = UDim2.new(0, 10, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "TREE SCAN"
TitleLabel.TextColor3 = Color3.fromRGB(235, 240, 255)
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 11
TitleLabel.Parent = TopBar

local RunBtn = Instance.new("TextButton")
RunBtn.Size = UDim2.new(0, 62, 0, 24)
RunBtn.Position = UDim2.new(1, -304, 0.5, -12)
RunBtn.BackgroundColor3 = Color3.fromRGB(45, 135, 235)
RunBtn.Text = "Scan All"
RunBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
RunBtn.Font = Enum.Font.GothamBold
RunBtn.TextSize = 10
RunBtn.Parent = TopBar
Instance.new("UICorner", RunBtn).CornerRadius = UDim.new(0, 6)

local TopCopyBtn = Instance.new("TextButton")
TopCopyBtn.Size = UDim2.new(0, 64, 0, 24)
TopCopyBtn.Position = UDim2.new(1, -236, 0.5, -12)
TopCopyBtn.BackgroundColor3 = Color3.fromRGB(35, 130, 85)
TopCopyBtn.Text = "Кусок"
TopCopyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
TopCopyBtn.Font = Enum.Font.GothamBold
TopCopyBtn.TextSize = 9
TopCopyBtn.Parent = TopBar
Instance.new("UICorner", TopCopyBtn).CornerRadius = UDim.new(0, 6)

local ClearBtn = Instance.new("TextButton")
ClearBtn.Size = UDim2.new(0, 50, 0, 24)
ClearBtn.Position = UDim2.new(1, -166, 0.5, -12)
ClearBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 70)
ClearBtn.Text = "Clear"
ClearBtn.TextColor3 = Color3.fromRGB(235, 235, 245)
ClearBtn.Font = Enum.Font.GothamBold
ClearBtn.TextSize = 10
ClearBtn.Parent = TopBar
Instance.new("UICorner", ClearBtn).CornerRadius = UDim.new(0, 6)

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 50, 0, 24)
MinBtn.Position = UDim2.new(1, -110, 0.5, -12)
MinBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 70)
MinBtn.Text = "Min"
MinBtn.TextColor3 = Color3.fromRGB(235, 235, 245)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 10
MinBtn.Parent = TopBar
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 42, 0, 24)
CloseBtn.Position = UDim2.new(1, -52, 0.5, -12)
CloseBtn.BackgroundColor3 = Color3.fromRGB(165, 45, 55)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 10
CloseBtn.Parent = TopBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

local FilterBox = Instance.new("TextBox")
FilterBox.Size = UDim2.new(1, -16, 0, 28)
FilterBox.Position = UDim2.new(0, 8, 0, 40)
FilterBox.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
FilterBox.PlaceholderText = "Фильтр по пути/имени (Inventory, Sync, Item, Module, Box, Claim)..."
FilterBox.PlaceholderColor3 = Color3.fromRGB(135, 135, 155)
FilterBox.Text = ""
FilterBox.TextColor3 = Color3.fromRGB(255, 255, 255)
FilterBox.ClearTextOnFocus = false
FilterBox.Font = Enum.Font.Code
FilterBox.TextSize = 12
FilterBox.Parent = MainFrame
Instance.new("UICorner", FilterBox).CornerRadius = UDim.new(0, 6)

local CopyBufferBtn = Instance.new("TextButton")
CopyBufferBtn.Name = "CopyToClipboardBtn"
CopyBufferBtn.Size = UDim2.new(1, -16, 0, 34)
CopyBufferBtn.Position = UDim2.new(0, 8, 1, -42)
CopyBufferBtn.BackgroundColor3 = Color3.fromRGB(35, 130, 85)
CopyBufferBtn.Text = "КОПИРОВАТЬ ПО КУСКАМ"
CopyBufferBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CopyBufferBtn.Font = Enum.Font.GothamBold
CopyBufferBtn.TextSize = 12
CopyBufferBtn.Parent = MainFrame
Instance.new("UICorner", CopyBufferBtn).CornerRadius = UDim.new(0, 7)

local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -16, 1, -118)
Scroll.Position = UDim2.new(0, 8, 0, 74)
Scroll.BackgroundColor3 = Color3.fromRGB(11, 11, 15)
Scroll.BorderSizePixel = 0
Scroll.ScrollBarThickness = 5
Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Scroll.Parent = MainFrame
Instance.new("UICorner", Scroll).CornerRadius = UDim.new(0, 6)

local Layout = Instance.new("UIListLayout")
Layout.Padding = UDim.new(0, 3)
Layout.SortOrder = Enum.SortOrder.LayoutOrder
Layout.Parent = Scroll

-- Перетаскивание окна (тач + мышь)
do
	local dragging = false
	local dragInput, dragStart, startPos

	TopBar.InputBegan:Connect(function(input)
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

	TopBar.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and input == dragInput then
			local delta = input.Position - dragStart
			MainFrame.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end
	end)
end

-- === УТИЛИТЫ СТАТУСА И КОПИРОВАНИЯ ПО КУСКАМ ===
local statusSeq = 0
local function setStatus(msg)
	statusSeq += 1
	local cur = statusSeq
	TitleLabel.Text = msg
	task.delay(2.5, function()
		if statusSeq == cur then
			TitleLabel.Text = "TREE SCAN"
		end
	end)
end

local function getClipboardFn()
	local genv = (typeof(getgenv) == "function" and getgenv()) or nil
	return setclipboard
		or toclipboard
		or set_clipboard
		or writeclipboard
		or (genv and genv.setclipboard)
		or (genv and genv.toclipboard)
		or (genv and genv.set_clipboard)
		or (genv and genv.writeclipboard)
		or nil
end

local function copySingleText(str, statusLabel)
	local txt = tostring(str or "")
	if #txt == 0 then
		setStatus("Empty!")
		return false
	end
	local fn = getClipboardFn()
	if type(fn) ~= "function" then
		setStatus("No Clip API")
		return false
	end
	local ok = pcall(fn, txt)
	if ok then
		setStatus((statusLabel or "Copied") .. " [" .. tostring(#txt) .. "]")
		return true
	end
	setStatus("Clip Err")
	return false
end

local function buildChunksFromLines(linesList, maxCharsPerChunk)
	local limit = maxCharsPerChunk or 35000
	local chunks = {}
	local currentLines = {}
	local currentLen = 0

	for i = 1, #linesList do
		local line = tostring(linesList[i])
		local addLen = #line + (#currentLines > 0 and 1 or 0)

		if #currentLines > 0 and (currentLen + addLen) > limit then
			table.insert(chunks, table.concat(currentLines, "\n"))
			table.clear(currentLines)
			currentLen = 0
			addLen = #line
		end

		table.insert(currentLines, line)
		currentLen += addLen
	end

	if #currentLines > 0 then
		table.insert(chunks, table.concat(currentLines, "\n"))
	end

	return chunks
end

-- === ВЫВОД СТРОК В ИНТЕРФЕЙС ===
local rows = {}
local rowOrder = 0
local reportLinesCache = {}
local chunksCache = {}
local nextChunkIndex = 1
local isScanning = false
local maxUiRows = 450

local function resetChunkQueue()
	table.clear(chunksCache)
	nextChunkIndex = 1
	CopyBufferBtn.Text = "КОПИРОВАТЬ ПО КУСКАМ"
end

local function passesFilter(lineText, query)
	if query == "" then
		return true
	end
	return string.find(string.lower(lineText), string.lower(query), 1, true) ~= nil
end

local function applyFilterNow()
	resetChunkQueue()
	local q = FilterBox.Text
	for _, item in ipairs(rows) do
		item.Btn.Visible = passesFilter(item.FullLine, q)
	end
end

local function pushUiLine(text, color)
	rowOrder += 1
	local lineStr = tostring(text)

	if #rows >= maxUiRows then
		local first = table.remove(rows, 1)
		if first and first.Btn then
			first.Btn:Destroy()
		end
	end

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, -8, 0, 0)
	btn.AutomaticSize = Enum.AutomaticSize.Y
	btn.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
	btn.BackgroundTransparency = 0.15
	btn.Text = lineStr
	btn.TextColor3 = color or Color3.fromRGB(220, 238, 255)
	btn.TextWrapped = true
	btn.TextXAlignment = Enum.TextXAlignment.Left
	btn.Font = Enum.Font.Code
	btn.TextSize = 11
	btn.LayoutOrder = rowOrder
	btn.AutoButtonColor = true
	btn.Visible = passesFilter(lineStr, FilterBox.Text)
	btn.Parent = Scroll
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

	btn.Activated:Connect(function()
		copySingleText(lineStr, "Line")
	end)

	table.insert(rows, {
		FullLine = lineStr,
		Btn = btn,
	})
end

-- === ПОИСК ДЕРЕВЬЕВ БЕЗ ОГРАНИЧЕНИЙ ПО ВЫСОТЕ ===
local TARGET_NAMES = {
	"Inventory",
	"Sync",
	"Item",
	"Module",
	"Box",
	"Claim",
}

local function matchName(name)
	local low = string.lower(tostring(name or ""))
	for _, target in ipairs(TARGET_NAMES) do
		local tLow = string.lower(target)
		if low == tLow then
			return true, target .. ":exact"
		elseif string.find(low, tLow, 1, true) then
			return true, target .. ":part"
		end
	end
	return false, nil
end

local function safeFullName(inst)
	if typeof(inst) ~= "Instance" then
		return tostring(inst)
	end
	local ok, res = pcall(function()
		return inst:GetFullName()
	end)
	return ok and res or tostring(inst)
end

local function getNodeExtraInfo(node)
	local details = {}

	if node:IsA("TextLabel") or node:IsA("TextButton") or node:IsA("TextBox") then
		if node.Text ~= "" then
			table.insert(details, "Text=" .. string.format("%q", tostring(node.Text)))
		end
	end

	if node:IsA("ImageLabel") or node:IsA("ImageButton") then
		if node.Image ~= "" then
			table.insert(details, "Image=" .. tostring(node.Image))
		end
	end

	if node:IsA("ValueBase") then
		local okVal, val = pcall(function()
			return node.Value
		end)
		if okVal then
			table.insert(details, "Value=" .. tostring(val))
		end
	end

	local okAttrs, attrs = pcall(function()
		return node:GetAttributes()
	end)
	if okAttrs and type(attrs) == "table" then
		for k, v in pairs(attrs) do
			table.insert(details, "Attr." .. tostring(k) .. "=" .. tostring(v))
		end
	end

	if #details == 0 then
		return ""
	end
	return "  {" .. table.concat(details, ", ") .. "}"
end

local function collectRoots()
	local searchRoots = {
		ReplicatedStorage,
		StarterPlayer:FindFirstChild("StarterPlayerScripts"),
		StarterPlayer:FindFirstChild("StarterCharacterScripts"),
		LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui"),
		LocalPlayer and LocalPlayer:FindFirstChildOfClass("Backpack"),
		LocalPlayer and LocalPlayer.Character,
		StarterGui,
		Workspace,
	}

	local found = {}
	local seen = {}
	local steps = 0

	for _, r in ipairs(searchRoots) do
		if r then
			local m0, tag0 = matchName(r.Name)
			if m0 and not seen[r] then
				seen[r] = true
				table.insert(found, { inst = r, tag = tag0 })
			end

			local okDesc, desc = pcall(function()
				return r:GetDescendants()
			end)
			if okDesc and type(desc) == "table" then
				for _, obj in ipairs(desc) do
					steps += 1
					if steps % 800 == 0 then
						RunService.Heartbeat:Wait()
					end
					local m, tag = matchName(obj.Name)
					if m and not seen[obj] then
						seen[obj] = true
						table.insert(found, { inst = obj, tag = tag })
					end
				end
			end
		end
	end

	return found
end

local function traverseUnlimited(rootInst, reportLines, uiBudgetRef, includeDetails)
	local count = 0

	local function walk(node, depth, prefix, isLast)
		count += 1
		if count % 350 == 0 then
			RunService.Heartbeat:Wait()
		end

		local branch = (depth == 0) and "" or (isLast and "└── " or "├── ")
		local extra = includeDetails and getNodeExtraInfo(node) or ""
		local line = string.format("%s%s[%s] %s%s  (%s)", prefix, branch, node.ClassName, node.Name, extra, safeFullName(node))
		table.insert(reportLines, line)

		if uiBudgetRef.left > 0 then
			uiBudgetRef.left -= 1
			pushUiLine(line, depth == 0 and Color3.fromRGB(255, 205, 95) or Color3.fromRGB(215, 235, 255))
		end

		local okCh, children = pcall(function()
			return node:GetChildren()
		end)
		if okCh and type(children) == "table" then
			local nextPrefix = (depth == 0) and "" or (prefix .. (isLast and "    " or "│   "))
			for i, child in ipairs(children) do
				walk(child, depth + 1, nextPrefix, i == #children)
			end
		end
	end

	walk(rootInst, 0, "", true)
	return count
end

local function startFullScan()
	if isScanning then
		setStatus("Scanning...")
		return
	end
	isScanning = true
	resetChunkQueue()
	RunBtn.Text = "Wait..."
	RunBtn.BackgroundColor3 = Color3.fromRGB(185, 115, 30)

	task.spawn(function()
		local ok, err = pcall(function()
			pushUiLine("=== ПОИСК ВСЕХ ДЕРЕВЬЕВ (Inventory, Sync, Item, Module, Box, Claim) БЕЗ ЛИМИТА ВЫСОТЫ ===", Color3.fromRGB(120, 210, 255))
			local roots = collectRoots()
			local report = {}
			local totalNodes = 0
			local uiBudget = { left = 380 }

			table.insert(report, "=== UNLIMITED TREES SCAN: Inventory, Sync, Item, Module, Box, Claim ===")
			table.insert(report, "Found roots: " .. tostring(#roots))
			table.insert(report, "")

			for idx, entry in ipairs(roots) do
				local inst = entry.inst
				local isClaimBranch = string.find(string.lower(entry.tag), "claim", 1, true) ~= nil
					or string.find(string.lower(inst.Name), "claim", 1, true) ~= nil

				local head = string.format("▼ #%d [%s] %s (%s)", idx, entry.tag, safeFullName(inst), inst.ClassName)
				table.insert(report, head)
				if uiBudget.left > 0 then
					uiBudget.left -= 1
					pushUiLine(head, isClaimBranch and Color3.fromRGB(115, 240, 165) or Color3.fromRGB(255, 130, 120))
				end

				local nodesInTree = traverseUnlimited(inst, report, uiBudget, isClaimBranch)
				totalNodes += nodesInTree

				local foot = string.format("--- Узлов в ветке #%d: %d ---", idx, nodesInTree)
				table.insert(report, foot)
				table.insert(report, "")
			end

			table.insert(report, "TOTAL TREES: " .. tostring(#roots) .. " | TOTAL NODES: " .. tostring(totalNodes))
			reportLinesCache = report

			local previewChunks = buildChunksFromLines(reportLinesCache, 35000)
			pushUiLine(string.format("ГОТОВО: веток %d, узлов %d, кусков ~%d. Жми 'КОПИРОВАТЬ ПО КУСКАМ'.", #roots, totalNodes, #previewChunks), Color3.fromRGB(110, 235, 145))
			setStatus("Done: " .. tostring(#roots) .. " trees")
		end)

		if not ok then
			pushUiLine("Ошибка: " .. tostring(err), Color3.fromRGB(255, 85, 85))
			setStatus("Scan Error")
		end

		isScanning = false
		RunBtn.Text = "Scan All"
		RunBtn.BackgroundColor3 = Color3.fromRGB(45, 135, 235)
	end)
end

local function prepareChunksIfNeeded()
	if #chunksCache > 0 then
		return true
	end

	local sourceLines = {}
	if FilterBox.Text ~= "" then
		for _, item in ipairs(rows) do
			if item.Btn.Visible then
				table.insert(sourceLines, item.FullLine)
			end
		end
	else
		sourceLines = reportLinesCache
	end

	if #sourceLines == 0 then
		return false
	end

	chunksCache = buildChunksFromLines(sourceLines, 35000)
	nextChunkIndex = 1
	return #chunksCache > 0
end

local function copyNextChunk()
	if not prepareChunksIfNeeded() then
		setStatus("Empty!")
		return
	end

	if nextChunkIndex > #chunksCache then
		nextChunkIndex = 1
	end

	local idx = nextChunkIndex
	local total = #chunksCache
	local chunkText = chunksCache[idx]

	local ok = copySingleText(chunkText, string.format("Chunk %d/%d", idx, total))
	if ok then
		nextChunkIndex += 1
		if nextChunkIndex <= total then
			CopyBufferBtn.Text = string.format("КУСОК %d/%d (ДАЛЕЕ)", idx, total)
		else
			CopyBufferBtn.Text = string.format("КУСОК %d/%d (ПОВТОР)", idx, total)
		end
	end
end

RunBtn.Activated:Connect(startFullScan)
TopCopyBtn.Activated:Connect(copyNextChunk)
CopyBufferBtn.Activated:Connect(copyNextChunk)
FilterBox:GetPropertyChangedSignal("Text"):Connect(applyFilterNow)

ClearBtn.Activated:Connect(function()
	for _, item in ipairs(rows) do
		if item.Btn then
			item.Btn:Destroy()
		end
	end
	table.clear(rows)
	table.clear(reportLinesCache)
	resetChunkQueue()
	setStatus("Cleared")
end)

local isMin = false
MinBtn.Activated:Connect(function()
	isMin = not isMin
	FilterBox.Visible = not isMin
	Scroll.Visible = not isMin
	CopyBufferBtn.Visible = not isMin
	RunBtn.Visible = not isMin
	TopCopyBtn.Visible = not isMin
	ClearBtn.Visible = not isMin
	MainFrame.Size = isMin and UDim2.new(0.55, 0, 0, 34) or UDim2.new(0.94, 0, 0.56, 0)
	MinBtn.Text = isMin and "Max" or "Min"
end)

CloseBtn.Activated:Connect(function()
	ScreenGui:Destroy()
end)

pushUiLine("Интерфейс готов. Жми 'Scan All', затем 'КОПИРОВАТЬ ПО КУСКАМ'.", Color3.fromRGB(180, 200, 230))
