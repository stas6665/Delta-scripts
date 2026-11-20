local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local parentGui = LocalPlayer:WaitForChild("PlayerGui")

if parentGui:FindFirstChild("WholeGameChunkDumpGui") then
	parentGui.WholeGameChunkDumpGui:Destroy()
end

-- === ИНТЕРФЕЙС ===
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "WholeGameChunkDumpGui"
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
TitleLabel.Size = UDim2.new(0.28, -8, 1, 0)
TitleLabel.Position = UDim2.new(0, 10, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "WHOLE GAME"
TitleLabel.TextColor3 = Color3.fromRGB(235, 240, 255)
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 11
TitleLabel.Parent = TopBar

local RunBtn = Instance.new("TextButton")
RunBtn.Size = UDim2.new(0, 62, 0, 24)
RunBtn.Position = UDim2.new(1, -342, 0.5, -12)
RunBtn.BackgroundColor3 = Color3.fromRGB(45, 135, 235)
RunBtn.Text = "Dump All"
RunBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
RunBtn.Font = Enum.Font.GothamBold
RunBtn.TextSize = 10
RunBtn.Parent = TopBar
Instance.new("UICorner", RunBtn).CornerRadius = UDim.new(0, 6)

local TopCopyBtn = Instance.new("TextButton")
TopCopyBtn.Size = UDim2.new(0, 56, 0, 24)
TopCopyBtn.Position = UDim2.new(1, -274, 0.5, -12)
TopCopyBtn.BackgroundColor3 = Color3.fromRGB(35, 130, 85)
TopCopyBtn.Text = "Кусок"
TopCopyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
TopCopyBtn.Font = Enum.Font.GothamBold
TopCopyBtn.TextSize = 9
TopCopyBtn.Parent = TopBar
Instance.new("UICorner", TopCopyBtn).CornerRadius = UDim.new(0, 6)

local ResetQueueBtn = Instance.new("TextButton")
ResetQueueBtn.Size = UDim2.new(0, 44, 0, 24)
ResetQueueBtn.Position = UDim2.new(1, -212, 0.5, -12)
ResetQueueBtn.BackgroundColor3 = Color3.fromRGB(70, 60, 110)
ResetQueueBtn.Text = "1/N"
ResetQueueBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ResetQueueBtn.Font = Enum.Font.GothamBold
ResetQueueBtn.TextSize = 9
ResetQueueBtn.Parent = TopBar
Instance.new("UICorner", ResetQueueBtn).CornerRadius = UDim.new(0, 6)

local ClearBtn = Instance.new("TextButton")
ClearBtn.Size = UDim2.new(0, 48, 0, 24)
ClearBtn.Position = UDim2.new(1, -162, 0.5, -12)
ClearBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 70)
ClearBtn.Text = "Clear"
ClearBtn.TextColor3 = Color3.fromRGB(235, 235, 245)
ClearBtn.Font = Enum.Font.GothamBold
ClearBtn.TextSize = 10
ClearBtn.Parent = TopBar
Instance.new("UICorner", ClearBtn).CornerRadius = UDim.new(0, 6)

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 48, 0, 24)
MinBtn.Position = UDim2.new(1, -108, 0.5, -12)
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
FilterBox.PlaceholderText = "Фильтр по строкам (Remote, Claim, Box, Script)..."
FilterBox.PlaceholderColor3 = Color3.fromRGB(135, 135, 155)
FilterBox.Text = ""
FilterBox.TextColor3 = Color3.fromRGB(255, 255, 255)
FilterBox.ClearTextOnFocus = false
FilterBox.Font = Enum.Font.Code
FilterBox.TextSize = 12
FilterBox.Parent = MainFrame
Instance.new("UICorner", FilterBox).CornerRadius = UDim.new(0, 6)

local CopyBufferBtn = Instance.new("TextButton")
CopyBufferBtn.Name = "CopyChunksBtn"
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

-- === СТАТУС И БЕЗЛАГОВОЕ КОПИРОВАНИЕ ПО КУСКАМ ===
local CHUNK_CHAR_LIMIT = 24000
local statusSeq = 0
local chunksCache = {}
local nextChunkIndex = 1
local isBuildingChunks = false

local function setStatus(msg)
	statusSeq += 1
	local cur = statusSeq
	TitleLabel.Text = msg
	task.delay(2.5, function()
		if statusSeq == cur then
			TitleLabel.Text = "WHOLE GAME"
		end
	end)
end

local function refreshChunkButtonLabel()
	if #chunksCache == 0 then
		CopyBufferBtn.Text = "КОПИРОВАТЬ ПО КУСКАМ"
		return
	end
	local showIdx = math.clamp(nextChunkIndex, 1, #chunksCache)
	CopyBufferBtn.Text = string.format("КУСОК %d/%d", showIdx, #chunksCache)
end

local function resetChunkIndexToStart()
	nextChunkIndex = 1
	refreshChunkButtonLabel()
	if #chunksCache > 0 then
		setStatus("Queue -> 1/" .. tostring(#chunksCache))
	end
end

local function clearChunksCache()
	table.clear(chunksCache)
	nextChunkIndex = 1
	refreshChunkButtonLabel()
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

-- Нарезка массива строк на куски по границе строк без фризов
local function buildChunksSmoothly(linesList, maxCharsPerChunk)
	isBuildingChunks = true
	local limit = maxCharsPerChunk or CHUNK_CHAR_LIMIT
	local chunks = {}
	local currentLines = {}
	local currentLen = 0

	for i = 1, #linesList do
		if i % 1200 == 0 then
			RunService.Heartbeat:Wait()
		end

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

	isBuildingChunks = false
	return chunks
end

-- === СПИСОК И ВЫВОД ===
local rows = {}
local rowOrder = 0
local reportLinesCache = {}
local isDumping = false
local maxUiRows = 350

local function passesFilter(lineText, query)
	if query == "" then
		return true
	end
	return string.find(string.lower(lineText), string.lower(query), 1, true) ~= nil
end

local function applyFilterNow()
	clearChunksCache()
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

-- === СБОР ВСЕХ СЕРВИСОВ, СКРИПТОВ, РЕМОУТОВ И СТРУКТУРЫ ИГРЫ ===
local function safeFullName(inst)
	if typeof(inst) ~= "Instance" then
		return tostring(inst)
	end
	local ok, res = pcall(function()
		return inst:GetFullName()
	end)
	return ok and res or tostring(inst)
end

local function isRemoteInstance(node)
	return node:IsA("RemoteEvent")
		or node:IsA("RemoteFunction")
		or node:IsA("UnreliableRemoteEvent")
end

local function getWholeGameRoots()
	local roots = {}
	local seen = {}

	local function addRoot(inst)
		if inst and typeof(inst) == "Instance" and not seen[inst] then
			seen[inst] = true
			table.insert(roots, inst)
		end
	end

	local okChildren, gameChildren = pcall(function()
		return game:GetChildren()
	end)
	if okChildren and type(gameChildren) == "table" then
		for _, child in ipairs(gameChildren) do
			addRoot(child)
		end
	end

	local extraServices = {
		"Workspace",
		"Players",
		"ReplicatedFirst",
		"ReplicatedStorage",
		"StarterPlayer",
		"StarterGui",
		"StarterPack",
		"Lighting",
		"SoundService",
		"Chat",
		"TextChatService",
		"CoreGui",
	}
	for _, svcName in ipairs(extraServices) do
		local okSvc, svc = pcall(function()
			return game:GetService(svcName)
		end)
		if okSvc and svc then
			addRoot(svc)
		end
	end

	return roots
end

local function describeInstance(node)
	local meta = {}

	if isRemoteInstance(node) then
		table.insert(meta, "Remote")
	elseif node:IsA("LuaSourceContainer") then
		table.insert(meta, "Script")
	end

	if node:IsA("TextLabel") or node:IsA("TextButton") or node:IsA("TextBox") then
		if node.Text ~= "" then
			table.insert(meta, "Text=" .. string.format("%q", tostring(node.Text)))
		end
	elseif node:IsA("ImageLabel") or node:IsA("ImageButton") then
		if node.Image ~= "" then
			table.insert(meta, "Image=" .. tostring(node.Image))
		end
	elseif node:IsA("ValueBase") then
		local okV, val = pcall(function()
			return node.Value
		end)
		if okV then
			table.insert(meta, "Value=" .. tostring(val))
		end
	end

	local okAttr, attrs = pcall(function()
		return node:GetAttributes()
	end)
	if okAttr and type(attrs) == "table" then
		for k, v in pairs(attrs) do
			table.insert(meta, "Attr." .. tostring(k) .. "=" .. tostring(v))
		end
	end

	if #meta == 0 then
		return ""
	end
	return "  {" .. table.concat(meta, ", ") .. "}"
end

local function dumpWholeBranch(rootInst, reportLines, uiBudgetRef, visitedInstances, remotesList)
	local nodeCount = 0
	local scriptCount = 0
	local remoteCount = 0

	local function walk(node, depth, prefix, isLast)
		if not node or visitedInstances[node] then
			return
		end
		visitedInstances[node] = true

		nodeCount += 1
		local isRem = isRemoteInstance(node)
		if isRem then
			remoteCount += 1
			table.insert(remotesList, string.format("[%s] %s  (%s)", node.ClassName, node.Name, safeFullName(node)))
		elseif node:IsA("LuaSourceContainer") then
			scriptCount += 1
		end

		if nodeCount % 500 == 0 then
			RunService.Heartbeat:Wait()
		end

		local branch = (depth == 0) and "" or (isLast and "└── " or "├── ")
		local info = describeInstance(node)
		local line = string.format("%s%s[%s] %s%s  (%s)", prefix, branch, node.ClassName, node.Name, info, safeFullName(node))
		table.insert(reportLines, line)

		if uiBudgetRef.left > 0 then
			uiBudgetRef.left -= 1
			local col = Color3.fromRGB(215, 235, 255)
			if depth == 0 then
				col = Color3.fromRGB(255, 205, 95)
			elseif isRem then
				col = Color3.fromRGB(255, 195, 80)
			elseif node:IsA("LuaSourceContainer") then
				col = Color3.fromRGB(120, 240, 175)
			end
			pushUiLine(line, col)
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
	return nodeCount, scriptCount, remoteCount
end

local function startWholeGameDump()
	if isDumping or isBuildingChunks then
		setStatus("Busy...")
		return
	end
	isDumping = true
	clearChunksCache()
	RunBtn.Text = "Wait..."
	RunBtn.BackgroundColor3 = Color3.fromRGB(185, 115, 30)

	task.spawn(function()
		local ok, err = pcall(function()
			pushUiLine("=== ПОЛНЫЙ ДАМП ИГРЫ (СТРУКТУРА + СКРИПТЫ + ВСЕ REMOTE) ===", Color3.fromRGB(120, 210, 255))

			local roots = getWholeGameRoots()
			local report = {}
			local remotesList = {}
			local visitedInstances = {}
			local totalNodes = 0
			local totalScripts = 0
			local totalRemotes = 0
			local uiBudget = { left = 320 }

			table.insert(report, "=== WHOLE GAME STRUCTURE + ALL REMOTES DUMP ===")
			table.insert(report, "")

			for idx, rootInst in ipairs(roots) do
				if not visitedInstances[rootInst] then
					local head = string.format("▼ ROOT #%d: %s (%s)", idx, safeFullName(rootInst), rootInst.ClassName)
					table.insert(report, head)
					if uiBudget.left > 0 then
						uiBudget.left -= 1
						pushUiLine(head, Color3.fromRGB(255, 140, 120))
					end

					local nCount, sCount, rCount = dumpWholeBranch(rootInst, report, uiBudget, visitedInstances, remotesList)
					totalNodes += nCount
					totalScripts += sCount
					totalRemotes += rCount

					local foot = string.format("--- %s: узлов %d, скриптов %d, remote %d ---", rootInst.Name, nCount, sCount, rCount)
					table.insert(report, foot)
					table.insert(report, "")
				end
			end

			table.insert(report, "=== ALL REMOTES SUMMARY (" .. tostring(#remotesList) .. ") ===")
			for i, remLine in ipairs(remotesList) do
				table.insert(report, string.format("%d. %s", i, remLine))
			end
			table.insert(report, "")
			table.insert(report, string.format("GRAND TOTAL: Roots=%d | Nodes=%d | Scripts=%d | Remotes=%d", #roots, totalNodes, totalScripts, totalRemotes))
			reportLinesCache = report

			setStatus("Slicing...")
			chunksCache = buildChunksSmoothly(reportLinesCache, CHUNK_CHAR_LIMIT)
			nextChunkIndex = 1
			refreshChunkButtonLabel()

			pushUiLine(string.format("ГОТОВО: узлов %d, скриптов %d, remote %d, кусков %d. Жми 'КУСОК 1/%d'.", totalNodes, totalScripts, totalRemotes, #chunksCache, #chunksCache), Color3.fromRGB(110, 235, 145))
			setStatus("Chunks: " .. tostring(#chunksCache))
		end)

		if not ok then
			pushUiLine("Ошибка дампа: " .. tostring(err), Color3.fromRGB(255, 85, 85))
			setStatus("Dump Error")
		end

		isDumping = false
		RunBtn.Text = "Dump All"
		RunBtn.BackgroundColor3 = Color3.fromRGB(45, 135, 235)
	end)
end

local function copyNextChunk()
	if isBuildingChunks then
		setStatus("Slicing...")
		return
	end

	if #chunksCache == 0 then
		if #reportLinesCache > 0 then
			task.spawn(function()
				setStatus("Slicing...")
				chunksCache = buildChunksSmoothly(reportLinesCache, CHUNK_CHAR_LIMIT)
				nextChunkIndex = 1
				refreshChunkButtonLabel()
				if #chunksCache > 0 then
					local text1 = chunksCache[1]
					if copySingleText(text1, "Chunk 1/" .. tostring(#chunksCache)) then
						nextChunkIndex = 2
						refreshChunkButtonLabel()
					end
				end
			end)
			return
		end
		setStatus("Empty!")
		return
	end

	if nextChunkIndex > #chunksCache then
		nextChunkIndex = 1
	end

	local idx = nextChunkIndex
	local total = #chunksCache
	local chunkText = chunksCache[idx]

	local header = string.format("--- CHUNK %d / %d ---\n", idx, total)
	local ok = copySingleText(header .. chunkText, string.format("Chunk %d/%d", idx, total))
	if ok then
		nextChunkIndex += 1
		if nextChunkIndex <= total then
			CopyBufferBtn.Text = string.format("КУСОК %d/%d -> СЛЕД.", idx, total)
		else
			CopyBufferBtn.Text = string.format("КОНЕЦ (%d/%d) | ПОВТОР", idx, total)
		end
	end
end

RunBtn.Activated:Connect(startWholeGameDump)
TopCopyBtn.Activated:Connect(copyNextChunk)
CopyBufferBtn.Activated:Connect(copyNextChunk)
ResetQueueBtn.Activated:Connect(resetChunkIndexToStart)
FilterBox:GetPropertyChangedSignal("Text"):Connect(applyFilterNow)

ClearBtn.Activated:Connect(function()
	for _, item in ipairs(rows) do
		if item.Btn then
			item.Btn:Destroy()
		end
	end
	table.clear(rows)
	table.clear(reportLinesCache)
	clearChunksCache()
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
	ResetQueueBtn.Visible = not isMin
	ClearBtn.Visible = not isMin
	MainFrame.Size = isMin and UDim2.new(0.55, 0, 0, 34) or UDim2.new(0.94, 0, 0.56, 0)
	MinBtn.Text = isMin and "Max" or "Min"
end)

CloseBtn.Activated:Connect(function()
	ScreenGui:Destroy()
end)

pushUiLine("Готов выгрузить всю игру и копировать по кускам без лагов. Нажми 'Dump All'.", Color3.fromRGB(180, 200, 230))
