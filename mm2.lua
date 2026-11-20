local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local parentGui = LocalPlayer:WaitForChild("PlayerGui")

if parentGui:FindFirstChild("SafeDumpNoCrashGui") then
	parentGui.SafeDumpNoCrashGui:Destroy()
end

-- === ИНТЕРФЕЙС ===
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SafeDumpNoCrashGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = parentGui

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0.94, 0, 0.58, 0)
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
TitleLabel.Size = UDim2.new(0.24, -6, 1, 0)
TitleLabel.Position = UDim2.new(0, 8, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "SAFE DUMP"
TitleLabel.TextColor3 = Color3.fromRGB(235, 240, 255)
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 10
TitleLabel.Parent = TopBar

local ScanQueryBtn = Instance.new("TextButton")
ScanQueryBtn.Size = UDim2.new(0, 58, 0, 24)
ScanQueryBtn.Position = UDim2.new(1, -366, 0.5, -12)
ScanQueryBtn.BackgroundColor3 = Color3.fromRGB(45, 135, 235)
ScanQueryBtn.Text = "Find Tree"
ScanQueryBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ScanQueryBtn.Font = Enum.Font.GothamBold
ScanQueryBtn.TextSize = 9
ScanQueryBtn.Parent = TopBar
Instance.new("UICorner", ScanQueryBtn).CornerRadius = UDim.new(0, 6)

local DumpScriptsBtn = Instance.new("TextButton")
DumpScriptsBtn.Size = UDim2.new(0, 62, 0, 24)
DumpScriptsBtn.Position = UDim2.new(1, -302, 0.5, -12)
DumpScriptsBtn.BackgroundColor3 = Color3.fromRGB(125, 65, 195)
DumpScriptsBtn.Text = "Scripts In"
DumpScriptsBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
DumpScriptsBtn.Font = Enum.Font.GothamBold
DumpScriptsBtn.TextSize = 9
DumpScriptsBtn.Parent = TopBar
Instance.new("UICorner", DumpScriptsBtn).CornerRadius = UDim.new(0, 6)

local SaveFileBtn = Instance.new("TextButton")
SaveFileBtn.Size = UDim2.new(0, 60, 0, 24)
SaveFileBtn.Position = UDim2.new(1, -234, 0.5, -12)
SaveFileBtn.BackgroundColor3 = Color3.fromRGB(30, 125, 145)
SaveFileBtn.Text = "Save File"
SaveFileBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SaveFileBtn.Font = Enum.Font.GothamBold
SaveFileBtn.TextSize = 9
SaveFileBtn.Parent = TopBar
Instance.new("UICorner", SaveFileBtn).CornerRadius = UDim.new(0, 6)

local ClearBtn = Instance.new("TextButton")
ClearBtn.Size = UDim2.new(0, 46, 0, 24)
ClearBtn.Position = UDim2.new(1, -168, 0.5, -12)
ClearBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 70)
ClearBtn.Text = "Clear"
ClearBtn.TextColor3 = Color3.fromRGB(235, 235, 245)
ClearBtn.Font = Enum.Font.GothamBold
ClearBtn.TextSize = 9
ClearBtn.Parent = TopBar
Instance.new("UICorner", ClearBtn).CornerRadius = UDim.new(0, 6)

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 44, 0, 24)
MinBtn.Position = UDim2.new(1, -116, 0.5, -12)
MinBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 70)
MinBtn.Text = "Min"
MinBtn.TextColor3 = Color3.fromRGB(235, 235, 245)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 9
MinBtn.Parent = TopBar
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 38, 0, 24)
CloseBtn.Position = UDim2.new(1, -44, 0.5, -12)
CloseBtn.BackgroundColor3 = Color3.fromRGB(165, 45, 55)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 10
CloseBtn.Parent = TopBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

local QueryBox = Instance.new("TextBox")
QueryBox.Size = UDim2.new(1, -16, 0, 28)
QueryBox.Position = UDim2.new(0, 8, 0, 40)
QueryBox.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
QueryBox.PlaceholderText = "Введи слово (Claimed, Inventory, Box, Sync, Icecream)..."
QueryBox.PlaceholderColor3 = Color3.fromRGB(135, 135, 155)
QueryBox.Text = ""
QueryBox.TextColor3 = Color3.fromRGB(255, 255, 255)
QueryBox.ClearTextOnFocus = false
QueryBox.Font = Enum.Font.Code
QueryBox.TextSize = 12
QueryBox.Parent = MainFrame
Instance.new("UICorner", QueryBox).CornerRadius = UDim.new(0, 6)

local SafeCopyBtn = Instance.new("TextButton")
SafeCopyBtn.Name = "SafeCopyBtn"
SafeCopyBtn.Size = UDim2.new(1, -16, 0, 34)
SafeCopyBtn.Position = UDim2.new(0, 8, 1, -42)
SafeCopyBtn.BackgroundColor3 = Color3.fromRGB(35, 130, 85)
SafeCopyBtn.Text = "БЕЗОПАСНОЕ КОПИРОВАНИЕ (БЕЗ ВЫЛЕТОВ)"
SafeCopyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SafeCopyBtn.Font = Enum.Font.GothamBold
SafeCopyBtn.TextSize = 11
SafeCopyBtn.Parent = MainFrame
Instance.new("UICorner", SafeCopyBtn).CornerRadius = UDim.new(0, 7)

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

-- === СТАТУС, БЕЗОПАСНЫЙ БУФЕР И ЗАПИСЬ В ФАЙЛ ===
local SAFE_DIRECT_LIMIT = 45000
local SAFE_CHUNK_LIMIT = 20000
local statusSeq = 0
local linesCache = {}
local chunksCache = {}
local nextChunkIdx = 1
local isBusy = false

local function setStatus(msg)
	statusSeq += 1
	local cur = statusSeq
	TitleLabel.Text = msg
	task.delay(2.5, function()
		if statusSeq == cur then
			TitleLabel.Text = "SAFE DUMP"
		end
	end)
end

local function resetChunks()
	table.clear(chunksCache)
	nextChunkIdx = 1
	SafeCopyBtn.Text = "БЕЗОПАСНОЕ КОПИРОВАНИЕ (БЕЗ ВЫЛЕТОВ)"
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

local function getFileApis()
	local genv = (typeof(getgenv) == "function" and getgenv()) or nil
	local wFn = writefile or (genv and genv.writefile)
	local aFn = appendfile or (genv and genv.appendfile)
	return wFn, aFn
end

local function copyClipSafe(str, label)
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
		setStatus((label or "Copied") .. " [" .. tostring(#txt) .. "]")
		return true
	end
	setStatus("Clip Err")
	return false
end

local function buildChunksFromLines(srcLines, maxChars)
	local limit = maxChars or SAFE_CHUNK_LIMIT
	local out = {}
	local buf = {}
	local curLen = 0

	for i = 1, #srcLines do
		if i % 900 == 0 then
			RunService.Heartbeat:Wait()
		end
		local line = tostring(srcLines[i])
		if #line > limit then
			line = string.sub(line, 1, limit) .. "...[TRIMMED]"
		end
		local addLen = #line + (#buf > 0 and 1 or 0)
		if #buf > 0 and (curLen + addLen) > limit then
			table.insert(out, table.concat(buf, "\n"))
			table.clear(buf)
			curLen = 0
			addLen = #line
		end
		table.insert(buf, line)
		curLen += addLen
	end

	if #buf > 0 then
		table.insert(out, table.concat(buf, "\n"))
	end
	return out
end

local function estimateTotalChars(srcLines)
	local total = 0
	for i = 1, #srcLines do
		total += #tostring(srcLines[i]) + 1
	end
	return total
end

local function saveReportToFile()
	if isBusy then
		setStatus("Busy...")
		return
	end
	if #linesCache == 0 then
		setStatus("Empty!")
		return
	end

	local writeFn, appendFn = getFileApis()
	if type(writeFn) ~= "function" then
		setStatus("No writefile")
		return
	end

	isBusy = true
	SaveFileBtn.Text = "Saving..."
	task.spawn(function()
		local fileName = "game_dump_" .. tostring(os.time()) .. ".txt"
		local ok, err = pcall(function()
			writeFn(fileName, "")
			local batch = {}
			local batchLen = 0
			for i = 1, #linesCache do
				if i % 800 == 0 then
					RunService.Heartbeat:Wait()
				end
				local ln = tostring(linesCache[i]) .. "\n"
				if batchLen + #ln > 32000 then
					if type(appendFn) == "function" then
						appendFn(fileName, table.concat(batch))
					else
						writeFn(fileName, table.concat(batch))
					end
					table.clear(batch)
					batchLen = 0
				end
				table.insert(batch, ln)
				batchLen += #ln
			end
			if #batch > 0 then
				if type(appendFn) == "function" then
					appendFn(fileName, table.concat(batch))
				else
					writeFn(fileName, table.concat(batch))
				end
			end
		end)
		if ok then
			setStatus("Saved: " .. fileName)
		else
			setStatus("File Err: " .. tostring(err))
		end
		isBusy = false
		SaveFileBtn.Text = "Save File"
	end)
end

-- === ВЫВОД В ИНТЕРФЕЙС ===
local rows = {}
local rowOrder = 0
local maxUiRows = 220

local function pushUiLine(text, color)
	rowOrder += 1
	local lineStr = tostring(text)
	if #lineStr > 450 then
		lineStr = string.sub(lineStr, 1, 450) .. "..."
	end

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
	btn.Parent = Scroll
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

	btn.Activated:Connect(function()
		copyClipSafe(lineStr, "Line")
	end)

	table.insert(rows, {
		FullLine = lineStr,
		Btn = btn,
	})
end

-- === ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ===
local function safeFullName(inst)
	if typeof(inst) ~= "Instance" then
		return tostring(inst)
	end
	local ok, res = pcall(function()
		return inst:GetFullName()
	end)
	return ok and res or tostring(inst)
end

local function isServerOnlyScript(inst)
	if typeof(inst) ~= "Instance" then
		return true
	end
	if inst:IsA("Script") and not inst:IsA("LocalScript") then
		local okCtx, ctx = pcall(function()
			return inst.RunContext
		end)
		if okCtx and ctx == Enum.RunContext.Client then
			return false
		end
		return true
	end
	return false
end

local function hasMatchedAncestor(obj, matchedSet)
	local cur = obj.Parent
	while cur do
		if matchedSet[cur] then
			return true
		end
		cur = cur.Parent
	end
	return false
end

local function describeNode(node)
	local props = {}
	if node:IsA("TextLabel") or node:IsA("TextButton") or node:IsA("TextBox") then
		if node.Text ~= "" then
			table.insert(props, "Text=" .. string.format("%q", tostring(node.Text)))
		end
	elseif node:IsA("ImageLabel") or node:IsA("ImageButton") then
		if node.Image ~= "" then
			table.insert(props, "Image=" .. tostring(node.Image))
		end
	elseif node:IsA("ValueBase") then
		local okV, val = pcall(function()
			return node.Value
		end)
		if okV then
			table.insert(props, "Value=" .. tostring(val))
		end
	end

	local okAttr, attrs = pcall(function()
		return node:GetAttributes()
	end)
	if okAttr and type(attrs) == "table" then
		for k, v in pairs(attrs) do
			table.insert(props, "Attr." .. tostring(k) .. "=" .. tostring(v))
		end
	end

	if #props == 0 then
		return ""
	end
	return "  {" .. table.concat(props, ", ") .. "}"
end

local function dumpSubtree(rootInst, reportLines, uiBudget)
	local count = 0
	local function walk(node, depth, prefix, isLast)
		count += 1
		if count % 400 == 0 then
			RunService.Heartbeat:Wait()
		end
		local branch = (depth == 0) and "" or (isLast and "└── " or "├── ")
		local line = string.format("%s%s[%s] %s%s  (%s)", prefix, branch, node.ClassName, node.Name, describeNode(node), safeFullName(node))
		table.insert(reportLines, line)
		if uiBudget.left > 0 then
			uiBudget.left -= 1
			pushUiLine(line, depth == 0 and Color3.fromRGB(255, 205, 95) or Color3.fromRGB(215, 235, 255))
		end

		local okCh, ch = pcall(function()
			return node:GetChildren()
		end)
		if okCh and type(ch) == "table" then
			local nextPrefix = (depth == 0) and "" or (prefix .. (isLast and "    " or "│   "))
			for i, c in ipairs(ch) do
				walk(c, depth + 1, nextPrefix, i == #ch)
			end
		end
	end
	walk(rootInst, 0, "", true)
	return count
end

-- === 1. ПОИСК ПОЛНЫХ ДЕРЕВЬЕВ ПО ЗАПРОСУ ===
local function parseQueries(rawText)
	local trimmed = string.match(tostring(rawText or ""), "^%s*(.-)%s*$")
	if not trimmed or trimmed == "" then
		return { "claimed", "claim", "inventory", "box" }
	end
	local list = {}
	for part in string.gmatch(trimmed, "[^,;|]+") do
		local tok = string.match(part, "^%s*(.-)%s*$")
		if tok and tok ~= "" then
			table.insert(list, string.lower(tok))
		end
	end
	return (#list > 0) and list or { string.lower(trimmed) }
end

local function matchesQuery(obj, qList)
	local nameLow = string.lower(tostring(obj.Name or ""))
	for _, q in ipairs(qList) do
		if string.find(nameLow, q, 1, true) then
			return true, "name:" .. q
		end
	end

	if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
		local tLow = string.lower(tostring(obj.Text or ""))
		for _, q in ipairs(qList) do
			if string.find(tLow, q, 1, true) then
				return true, "text:" .. q
			end
		end
	elseif obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
		local iLow = string.lower(tostring(obj.Image or ""))
		for _, q in ipairs(qList) do
			if string.find(iLow, q, 1, true) then
				return true, "image:" .. q
			end
		end
	elseif obj:IsA("ValueBase") then
		local okV, val = pcall(function()
			return obj.Value
		end)
		if okV then
			local vLow = string.lower(tostring(val))
			for _, q in ipairs(qList) do
				if string.find(vLow, q, 1, true) then
					return true, "val:" .. q
				end
			end
		end
	end

	return false, nil
end

local function runQueryStructureScan()
	if isBusy then
		setStatus("Busy...")
		return
	end
	isBusy = true
	resetChunks()
	ScanQueryBtn.Text = "Wait..."
	ScanQueryBtn.BackgroundColor3 = Color3.fromRGB(185, 115, 30)

	task.spawn(function()
		local ok, err = pcall(function()
			local qList = parseQueries(QueryBox.Text)
			pushUiLine("=== ПОИСК ДЕРЕВЬЕВ: " .. table.concat(qList, ", ") .. " ===", Color3.fromRGB(120, 210, 255))

			local roots = {
				ReplicatedStorage,
				LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui"),
				LocalPlayer and LocalPlayer:FindFirstChildOfClass("Backpack"),
				LocalPlayer and LocalPlayer.Character,
				workspace,
			}

			local matched = {}
			local matchedSet = {}
			local steps = 0

			for _, r in ipairs(roots) do
				if r then
					local okDesc, desc = pcall(function()
						return r:GetDescendants()
					end)
					if okDesc and type(desc) == "table" then
						for _, obj in ipairs(desc) do
							steps += 1
							if steps % 700 == 0 then
								RunService.Heartbeat:Wait()
							end
							if not matchedSet[obj] and not hasMatchedAncestor(obj, matchedSet) then
								local m, tag = matchesQuery(obj, qList)
								if m then
									matchedSet[obj] = true
									table.insert(matched, { inst = obj, tag = tag })
								end
							end
						end
					end
				end
			end

			local report = {}
			local totalNodes = 0
			local uiBudget = { left = 200 }

			for idx, entry in ipairs(matched) do
				local inst = entry.inst
				local head = string.format("▼ #%d [%s] %s (%s)", idx, entry.tag, safeFullName(inst), inst.ClassName)
				table.insert(report, head)
				if uiBudget.left > 0 then
					uiBudget.left -= 1
					pushUiLine(head, Color3.fromRGB(115, 240, 165))
				end
				totalNodes += dumpSubtree(inst, report, uiBudget)
				table.insert(report, "")
			end

			linesCache = report
			local totalChars = estimateTotalChars(linesCache)
			pushUiLine(string.format("ГОТОВО: веток %d, узлов %d, символов ~%d.", #matched, totalNodes, totalChars), Color3.fromRGB(110, 235, 145))
			setStatus("Chars: " .. tostring(totalChars))
		end)

		if not ok then
			pushUiLine("Ошибка: " .. tostring(err), Color3.fromRGB(255, 85, 85))
			setStatus("Err")
		end

		isBusy = false
		ScanQueryBtn.Text = "Find Tree"
		ScanQueryBtn.BackgroundColor3 = Color3.fromRGB(45, 135, 235)
	end)
end

-- === 2. ОБХОД СКРИПТОВ И РАЗБОР REQUIRE(MODULE) ===
local function getTargetScriptBranches()
	local branches = {}
	local seen = {}
	local function addPath(parentObj, childName)
		if not parentObj then
			return
		end
		local ok, found = pcall(function()
			return parentObj:FindFirstChild(childName)
		end)
		if ok and found and not seen[found] then
			seen[found] = true
			table.insert(branches, found)
		end
	end

	addPath(ReplicatedStorage, "ClientTweenEvents")
	addPath(ReplicatedStorage, "Database")
	addPath(ReplicatedStorage, "ClientServices")
	addPath(ReplicatedStorage, "Modules")
	local okDb, db = pcall(function()
		return ReplicatedStorage:FindFirstChild("Database")
	end)
	if okDb and db then
		addPath(db, "Sync")
	end
	return branches
end

local function formatKeyLabel(k)
	if type(k) == "string" then
		if string.match(k, "^[%a_][%w_]*$") then
			return k
		end
		return string.format("[%q]", k)
	end
	return "[" .. tostring(k) .. "]"
end

local function formatLeafValue(val)
	local t = typeof(val)
	if t == "string" then
		local s = val
		if #s > 180 then
			s = string.sub(s, 1, 180) .. "..."
		end
		return string.format("%q", s)
	elseif t == "number" or t == "boolean" or t == "nil" then
		return tostring(val)
	elseif t == "Instance" then
		return string.format("<%s:%s>", val.ClassName, val.Name)
	elseif t == "function" then
		return "<function>"
	end
	return "<" .. t .. ">"
end

local function dumpRequireValueLines(val, outLines, indent, depth, visited, lineBudget)
	if lineBudget.left <= 0 then
		return
	end
	local pad = string.rep("  ", indent)
	if type(val) ~= "table" then
		table.insert(outLines, pad .. formatLeafValue(val))
		lineBudget.left -= 1
		return
	end
	if visited[val] or depth >= 4 then
		table.insert(outLines, pad .. "{...}")
		lineBudget.left -= 1
		return
	end
	visited[val] = true
	table.insert(outLines, pad .. "{")
	lineBudget.left -= 1

	local c = 0
	for k, v in pairs(val) do
		c += 1
		if c > 45 or lineBudget.left <= 0 then
			table.insert(outLines, pad .. "  ...")
			lineBudget.left -= 1
			break
		end
		local label = formatKeyLabel(k)
		if type(v) == "table" and not visited[v] and (depth + 1) < 4 then
			table.insert(outLines, pad .. "  " .. label .. " =")
			lineBudget.left -= 1
			dumpRequireValueLines(v, outLines, indent + 2, depth + 1, visited, lineBudget)
		else
			table.insert(outLines, pad .. "  " .. label .. " = " .. formatLeafValue(v))
			lineBudget.left -= 1
		end
	end

	if lineBudget.left > 0 then
		table.insert(outLines, pad .. "}")
		lineBudget.left -= 1
	end
	visited[val] = nil
end

local function extractScriptInnerContent(scriptObj)
	local lines = {}
	local genv = (typeof(getgenv) == "function" and getgenv()) or nil

	local decompileFn = decompile or (genv and genv.decompile)
	if type(decompileFn) == "function" then
		local okDec, src = pcall(decompileFn, scriptObj)
		if okDec and type(src) == "string" and #src > 0 then
			table.insert(lines, "  [DECOMPILED]:")
			for sLine in string.gmatch(src, "[^\r\n]+") do
				table.insert(lines, "    " .. sLine)
			end
			return lines
		end
	end

	if scriptObj:IsA("ModuleScript") then
		local okReq, modVal = pcall(require, scriptObj)
		if okReq then
			table.insert(lines, "  [REQUIRE]:")
			dumpRequireValueLines(modVal, lines, 2, 0, {}, { left = 120 })
			return lines
		end
	end

	local bcFn = getscriptbytecode or (genv and genv.getscriptbytecode)
	if type(bcFn) == "function" then
		local okBc, bc = pcall(bcFn, scriptObj)
		if okBc and type(bc) == "string" and #bc > 0 then
			table.insert(lines, "  [BYTECODE]: " .. tostring(#bc) .. " bytes")
		end
	end

	if #lines == 0 then
		table.insert(lines, "  [INNER]: недоступно")
	end
	return lines
end

local function runScriptsBranchesDump()
	if isBusy then
		setStatus("Busy...")
		return
	end
	isBusy = true
	resetChunks()
	DumpScriptsBtn.Text = "Wait..."
	DumpScriptsBtn.BackgroundColor3 = Color3.fromRGB(185, 115, 30)

	task.spawn(function()
		local ok, err = pcall(function()
			pushUiLine("=== СКРИПТЫ И МОДУЛИ (БЕЗ СЕРВЕРНЫХ) ===", Color3.fromRGB(185, 130, 255))
			local branches = getTargetScriptBranches()
			local report = {}
			local scriptsFound = 0
			local uiBudget = { left = 200 }

			for _, branch in ipairs(branches) do
				table.insert(report, "▼ BRANCH: " .. safeFullName(branch))
				local candidates = { branch }
				local okDesc, desc = pcall(function()
					return branch:GetDescendants()
				end)
				if okDesc and type(desc) == "table" then
					for _, d in ipairs(desc) do
						table.insert(candidates, d)
					end
				end

				for idx, obj in ipairs(candidates) do
					if idx % 200 == 0 then
						RunService.Heartbeat:Wait()
					end
					if obj:IsA("LuaSourceContainer") and not isServerOnlyScript(obj) then
						scriptsFound += 1
						local sHead = string.format("  [%s] %s (%s)", obj.ClassName, obj.Name, safeFullName(obj))
						table.insert(report, sHead)
						if uiBudget.left > 0 then
							uiBudget.left -= 1
							pushUiLine(sHead, Color3.fromRGB(120, 240, 175))
						end
						for _, iLine in ipairs(extractScriptInnerContent(obj)) do
							table.insert(report, iLine)
						end
					end
				end
				table.insert(report, "")
			end

			linesCache = report
			local totalChars = estimateTotalChars(linesCache)
			pushUiLine(string.format("ГОТОВО: скриптов/модулей %d, символов ~%d.", scriptsFound, totalChars), Color3.fromRGB(110, 235, 145))
			setStatus("Chars: " .. tostring(totalChars))
		end)

		if not ok then
			pushUiLine("Ошибка: " .. tostring(err), Color3.fromRGB(255, 85, 85))
			setStatus("Err")
		end

		isBusy = false
		DumpScriptsBtn.Text = "Scripts In"
		DumpScriptsBtn.BackgroundColor3 = Color3.fromRGB(125, 65, 195)
	end)
end

local function runSafeCopy()
	if isBusy then
		setStatus("Busy...")
		return
	end
	if #linesCache == 0 then
		setStatus("Empty!")
		return
	end

	local estChars = estimateTotalChars(linesCache)
	if estChars <= SAFE_DIRECT_LIMIT and #chunksCache == 0 then
		local wholeText = table.concat(linesCache, "\n")
		copyClipSafe(wholeText, "Copied")
		return
	end

	if #chunksCache == 0 then
		isBusy = true
		SafeCopyBtn.Text = "Slicing..."
		task.spawn(function()
			chunksCache = buildChunksFromLines(linesCache, SAFE_CHUNK_LIMIT)
			nextChunkIdx = 1
			isBusy = false
			if #chunksCache > 0 then
				local idx = nextChunkIdx
				local total = #chunksCache
				local head = string.format("[PART %d/%d]\n", idx, total)
				if copyClipSafe(head .. chunksCache[idx], string.format("Part %d/%d", idx, total)) then
					nextChunkIdx += 1
					SafeCopyBtn.Text = string.format("ЧАСТЬ %d/%d -> ДАЛЕЕ", idx, total)
				end
			end
		end)
		return
	end

	if nextChunkIdx > #chunksCache then
		nextChunkIdx = 1
	end
	local idx = nextChunkIdx
	local total = #chunksCache
	local head = string.format("[PART %d/%d]\n", idx, total)
	if copyClipSafe(head .. chunksCache[idx], string.format("Part %d/%d", idx, total)) then
		nextChunkIdx += 1
		SafeCopyBtn.Text = string.format("ЧАСТЬ %d/%d -> ДАЛЕЕ", idx, total)
	end
end

ScanQueryBtn.Activated:Connect(runQueryStructureScan)
DumpScriptsBtn.Activated:Connect(runScriptsBranchesDump)
SaveFileBtn.Activated:Connect(saveReportToFile)
SafeCopyBtn.Activated:Connect(runSafeCopy)

ClearBtn.Activated:Connect(function()
	for _, item in ipairs(rows) do
		if item.Btn then
			item.Btn:Destroy()
		end
	end
	table.clear(rows)
	table.clear(linesCache)
	resetChunks()
	setStatus("Cleared")
end)

local isMin = false
MinBtn.Activated:Connect(function()
	isMin = not isMin
	QueryBox.Visible = not isMin
	Scroll.Visible = not isMin
	SafeCopyBtn.Visible = not isMin
	ScanQueryBtn.Visible = not isMin
	DumpScriptsBtn.Visible = not isMin
	SaveFileBtn.Visible = not isMin
	ClearBtn.Visible = not isMin
	MainFrame.Size = isMin and UDim2.new(0.55, 0, 0, 34) or UDim2.new(0.94, 0, 0.58, 0)
	MinBtn.Text = isMin and "Max" or "Min"
end)

CloseBtn.Activated:Connect(function()
	ScreenGui:Destroy()
end)

pushUiLine("Для защиты от вылетов на телефоне: малый отчёт копируется целиком, огромный — безопасными частями или в файл.", Color3.fromRGB(180, 200, 230))
