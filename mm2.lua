local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local parentGui = LocalPlayer:WaitForChild("PlayerGui")

if parentGui:FindFirstChild("FullReportCopyGui") then
	parentGui.FullReportCopyGui:Destroy()
end

-- === ИНТЕРФЕЙС ===
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FullReportCopyGui"
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
TitleLabel.Size = UDim2.new(0.28, -8, 1, 0)
TitleLabel.Position = UDim2.new(0, 10, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "FULL COPY"
TitleLabel.TextColor3 = Color3.fromRGB(235, 240, 255)
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 11
TitleLabel.Parent = TopBar

local ScanQueryBtn = Instance.new("TextButton")
ScanQueryBtn.Size = UDim2.new(0, 62, 0, 24)
ScanQueryBtn.Position = UDim2.new(1, -346, 0.5, -12)
ScanQueryBtn.BackgroundColor3 = Color3.fromRGB(45, 135, 235)
ScanQueryBtn.Text = "Find Tree"
ScanQueryBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ScanQueryBtn.Font = Enum.Font.GothamBold
ScanQueryBtn.TextSize = 10
ScanQueryBtn.Parent = TopBar
Instance.new("UICorner", ScanQueryBtn).CornerRadius = UDim.new(0, 6)

local DumpScriptsBtn = Instance.new("TextButton")
DumpScriptsBtn.Size = UDim2.new(0, 66, 0, 24)
DumpScriptsBtn.Position = UDim2.new(1, -278, 0.5, -12)
DumpScriptsBtn.BackgroundColor3 = Color3.fromRGB(125, 65, 195)
DumpScriptsBtn.Text = "Scripts In"
DumpScriptsBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
DumpScriptsBtn.Font = Enum.Font.GothamBold
DumpScriptsBtn.TextSize = 10
DumpScriptsBtn.Parent = TopBar
Instance.new("UICorner", DumpScriptsBtn).CornerRadius = UDim.new(0, 6)

local TopCopyBtn = Instance.new("TextButton")
TopCopyBtn.Size = UDim2.new(0, 52, 0, 24)
TopCopyBtn.Position = UDim2.new(1, -206, 0.5, -12)
TopCopyBtn.BackgroundColor3 = Color3.fromRGB(35, 130, 85)
TopCopyBtn.Text = "Copy"
TopCopyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
TopCopyBtn.Font = Enum.Font.GothamBold
TopCopyBtn.TextSize = 9
TopCopyBtn.Parent = TopBar
Instance.new("UICorner", TopCopyBtn).CornerRadius = UDim.new(0, 6)

local ClearBtn = Instance.new("TextButton")
ClearBtn.Size = UDim2.new(0, 48, 0, 24)
ClearBtn.Position = UDim2.new(1, -148, 0.5, -12)
ClearBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 70)
ClearBtn.Text = "Clear"
ClearBtn.TextColor3 = Color3.fromRGB(235, 235, 245)
ClearBtn.Font = Enum.Font.GothamBold
ClearBtn.TextSize = 10
ClearBtn.Parent = TopBar
Instance.new("UICorner", ClearBtn).CornerRadius = UDim.new(0, 6)

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 46, 0, 24)
MinBtn.Position = UDim2.new(1, -94, 0.5, -12)
MinBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 70)
MinBtn.Text = "Min"
MinBtn.TextColor3 = Color3.fromRGB(235, 235, 245)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 10
MinBtn.Parent = TopBar
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 40, 0, 24)
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
QueryBox.PlaceholderText = "Запрос структуры (Claimed, Inventory, Box, Sync, Item)..."
QueryBox.PlaceholderColor3 = Color3.fromRGB(135, 135, 155)
QueryBox.Text = ""
QueryBox.TextColor3 = Color3.fromRGB(255, 255, 255)
QueryBox.ClearTextOnFocus = false
QueryBox.Font = Enum.Font.Code
QueryBox.TextSize = 12
QueryBox.Parent = MainFrame
Instance.new("UICorner", QueryBox).CornerRadius = UDim.new(0, 6)

local CopyAllBtn = Instance.new("TextButton")
CopyAllBtn.Name = "CopyAllBtn"
CopyAllBtn.Size = UDim2.new(1, -16, 0, 34)
CopyAllBtn.Position = UDim2.new(0, 8, 1, -42)
CopyAllBtn.BackgroundColor3 = Color3.fromRGB(35, 130, 85)
CopyAllBtn.Text = "СКОПИРОВАТЬ ВСЁ ЦЕЛИКОМ"
CopyAllBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CopyAllBtn.Font = Enum.Font.GothamBold
CopyAllBtn.TextSize = 12
CopyAllBtn.Parent = MainFrame
Instance.new("UICorner", CopyAllBtn).CornerRadius = UDim.new(0, 7)

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

-- === СТАТУС И КОПИРОВАНИЕ ВСЁ ЦЕЛИКОМ ===
local statusSeq = 0
local fullReportCache = ""
local isBusy = false

local function setStatus(msg)
	statusSeq += 1
	local cur = statusSeq
	TitleLabel.Text = msg
	task.delay(2.5, function()
		if statusSeq == cur then
			TitleLabel.Text = "FULL COPY"
		end
	end)
end

local function refreshCopyLabel()
	if #fullReportCache > 0 then
		CopyAllBtn.Text = string.format("СКОПИРОВАТЬ ВСЁ (%d)", #fullReportCache)
	else
		CopyAllBtn.Text = "СКОПИРОВАТЬ ВСЁ ЦЕЛИКОМ"
	end
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

local function copyTextToClipboard(str, statusLabel)
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
		setStatus((statusLabel or "Copied All") .. " [" .. tostring(#txt) .. "]")
		return true
	end
	setStatus("Clip Err")
	return false
end

local function buildFullReportSmoothly(linesList)
	local parts = {}
	for i = 1, #linesList do
		if i % 1500 == 0 then
			RunService.Heartbeat:Wait()
		end
		table.insert(parts, tostring(linesList[i]))
	end
	return table.concat(parts, "\n")
end

-- === ВЫВОД В ИНТЕРФЕЙС ===
local rows = {}
local rowOrder = 0
local maxUiRows = 350

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
	btn.Parent = Scroll
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

	btn.Activated:Connect(function()
		copyTextToClipboard(lineStr, "Line")
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

-- === 1. ПОИСК ПОЛНЫХ ДЕРЕВЬЕВ ПО ЗАПРОСУ БЕЗ ДУБЛЕЙ ВЛОЖЕННЫХ ВЕТОК ===
local function parseQueries(rawText)
	local trimmed = string.match(tostring(rawText or ""), "^%s*(.-)%s*$")
	if not trimmed or trimmed == "" then
		return { "claimed", "claim", "inventory", "box", "sync", "reward", "item" }
	end
	local list = {}
	for part in string.gmatch(trimmed, "[^,;|]+") do
		local tok = string.match(part, "^%s*(.-)%s*$")
		if tok and tok ~= "" then
			table.insert(list, string.lower(tok))
		end
	end
	if #list == 0 then
		return { string.lower(trimmed) }
	end
	return list
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

	local okAttr, attrs = pcall(function()
		return obj:GetAttributes()
	end)
	if okAttr and type(attrs) == "table" then
		for k, v in pairs(attrs) do
			local combo = string.lower(tostring(k) .. "=" .. tostring(v))
			for _, q in ipairs(qList) do
				if string.find(combo, q, 1, true) then
					return true, "attr:" .. q
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
	fullReportCache = ""
	refreshCopyLabel()
	ScanQueryBtn.Text = "Wait..."
	ScanQueryBtn.BackgroundColor3 = Color3.fromRGB(185, 115, 30)

	task.spawn(function()
		local ok, err = pcall(function()
			local qList = parseQueries(QueryBox.Text)
			pushUiLine("=== ПОИСК ПОЛНЫХ ДЕРЕВЬЕВ ПО ЗАПРОСУ: " .. table.concat(qList, ", ") .. " ===", Color3.fromRGB(120, 210, 255))

			local roots = {
				ReplicatedStorage,
				LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui"),
				LocalPlayer and LocalPlayer:FindFirstChildOfClass("Backpack"),
				LocalPlayer and LocalPlayer.Character,
				game:GetService("StarterGui"),
				game:GetService("StarterPlayer"),
				workspace,
			}

			local matched = {}
			local matchedSet = {}
			local steps = 0

			for _, r in ipairs(roots) do
				if r then
					if not hasMatchedAncestor(r, matchedSet) then
						local m0, tag0 = matchesQuery(r, qList)
						if m0 and not matchedSet[r] then
							matchedSet[r] = true
							table.insert(matched, { inst = r, tag = tag0 })
						end
					end

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
			local uiBudget = { left = 320 }

			table.insert(report, "=== QUERY FULL TREES DUMP: " .. table.concat(qList, ", ") .. " ===")
			table.insert(report, "Top-level matched trees: " .. tostring(#matched))
			table.insert(report, "")

			for idx, entry in ipairs(matched) do
				local inst = entry.inst
				local head = string.format("▼ #%d [%s] %s (%s)", idx, entry.tag, safeFullName(inst), inst.ClassName)
				table.insert(report, head)
				if uiBudget.left > 0 then
					uiBudget.left -= 1
					pushUiLine(head, Color3.fromRGB(115, 240, 165))
				end

				local nCount = dumpSubtree(inst, report, uiBudget)
				totalNodes += nCount
				table.insert(report, string.format("--- Узлов в дереве #%d: %d ---", idx, nCount))
				table.insert(report, "")
			end

			table.insert(report, string.format("TOTAL TREES: %d | TOTAL NODES: %d", #matched, totalNodes))
			fullReportCache = buildFullReportSmoothly(report)
			refreshCopyLabel()

			pushUiLine(string.format("ГОТОВО: деревьев %d, узлов %d, символов %d.", #matched, totalNodes, #fullReportCache), Color3.fromRGB(110, 235, 145))
			setStatus("Chars: " .. tostring(#fullReportCache))
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

-- === 2. ОБХОД ВСЕХ СКРИПТОВ И РАЗБОР REQUIRE(MODULE) ===
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
		if #s > 260 then
			s = string.sub(s, 1, 260) .. "...(" .. tostring(#val) .. " chars)"
		end
		return string.format("%q", s)
	elseif t == "number" or t == "boolean" or t == "nil" then
		return tostring(val)
	elseif t == "Instance" then
		return string.format("<Instance:%s:%s>", val.ClassName, safeFullName(val))
	elseif t == "function" then
		local okInfo, infoName = pcall(debug.info, val, "n")
		if okInfo and type(infoName) == "string" and infoName ~= "" then
			return "<function:" .. infoName .. ">"
		end
		return "<function>"
	elseif t == "Vector3" or t == "CFrame" or t == "Color3" or t == "UDim2" then
		return "<" .. t .. ":" .. tostring(val) .. ">"
	end
	return "<" .. t .. ":" .. tostring(val) .. ">"
end

local function collectSortedTableEntries(tbl)
	local arrayItems = {}
	local dictItems = {}
	local arrayCount = #tbl

	for k, v in pairs(tbl) do
		if type(k) == "number" and k >= 1 and k <= arrayCount and math.floor(k) == k then
			table.insert(arrayItems, { k = k, v = v, isArr = true })
		else
			table.insert(dictItems, { k = k, v = v, isArr = false })
		end
	end

	table.sort(arrayItems, function(a, b)
		return a.k < b.k
	end)

	table.sort(dictItems, function(a, b)
		return tostring(a.k) < tostring(b.k)
	end)

	local merged = {}
	for _, item in ipairs(arrayItems) do
		table.insert(merged, item)
	end
	for _, item in ipairs(dictItems) do
		table.insert(merged, item)
	end
	return merged
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

	if visited[val] then
		table.insert(outLines, pad .. "{<circular table>}")
		lineBudget.left -= 1
		return
	end

	if depth >= 5 then
		local keysPreview = {}
		local c = 0
		for k in pairs(val) do
			c += 1
			if c > 12 then
				table.insert(keysPreview, "...")
				break
			end
			table.insert(keysPreview, formatKeyLabel(k))
		end
		table.insert(outLines, pad .. "{... keys: " .. table.concat(keysPreview, ", ") .. "}")
		lineBudget.left -= 1
		return
	end

	visited[val] = true

	local okMt, mt = pcall(getmetatable, val)
	local mtSuffix = (type(mt) == "table") and "  [has_metatable]" or ""
	table.insert(outLines, pad .. "{" .. mtSuffix)
	lineBudget.left -= 1

	local entries = collectSortedTableEntries(val)
	local maxEntries = 80
	for i = 1, math.min(#entries, maxEntries) do
		if lineBudget.left <= 0 then
			break
		end
		local entry = entries[i]
		local label = entry.isArr and ("[" .. tostring(entry.k) .. "]") or formatKeyLabel(entry.k)
		if type(entry.v) == "table" and not visited[entry.v] and (depth + 1) < 5 then
			table.insert(outLines, pad .. "  " .. label .. " =")
			lineBudget.left -= 1
			dumpRequireValueLines(entry.v, outLines, indent + 2, depth + 1, visited, lineBudget)
		else
			table.insert(outLines, pad .. "  " .. label .. " = " .. formatLeafValue(entry.v))
			lineBudget.left -= 1
		end
	end

	if #entries > maxEntries and lineBudget.left > 0 then
		table.insert(outLines, pad .. "  ... (ещё ключей/элементов: " .. tostring(#entries - maxEntries) .. ")")
		lineBudget.left -= 1
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
			table.insert(lines, "  [DECOMPILED SOURCE]:")
			for sLine in string.gmatch(src, "[^\r\n]+") do
				table.insert(lines, "    " .. sLine)
			end
			return lines
		end
	end

	local okSrc, rawSrc = pcall(function()
		return scriptObj.Source
	end)
	if okSrc and type(rawSrc) == "string" and #rawSrc > 0 then
		table.insert(lines, "  [SOURCE]:")
		for sLine in string.gmatch(rawSrc, "[^\r\n]+") do
			table.insert(lines, "    " .. sLine)
		end
		return lines
	end

	local bcFn = getscriptbytecode or (genv and genv.getscriptbytecode)
	if type(bcFn) == "function" then
		local okBc, bc = pcall(bcFn, scriptObj)
		if okBc and type(bc) == "string" and #bc > 0 then
			table.insert(lines, "  [BYTECODE]: " .. tostring(#bc) .. " bytes")
		end
	end

	if scriptObj:IsA("ModuleScript") then
		local okReq, modVal = pcall(require, scriptObj)
		if okReq then
			table.insert(lines, "  [REQUIRE RETURN]:")
			local reqLines = {}
			dumpRequireValueLines(modVal, reqLines, 2, 0, {}, { left = 240 })
			for _, rLine in ipairs(reqLines) do
				table.insert(lines, rLine)
			end
			return lines
		else
			table.insert(lines, "  [REQUIRE ERR]: " .. tostring(modVal))
		end
	end

	if #lines == 0 then
		table.insert(lines, "  [INNER]: исходник/декомпиляция недоступны на клиенте")
	end
	return lines
end

local function runScriptsBranchesDump()
	if isBusy then
		setStatus("Busy...")
		return
	end
	isBusy = true
	fullReportCache = ""
	refreshCopyLabel()
	DumpScriptsBtn.Text = "Wait..."
	DumpScriptsBtn.BackgroundColor3 = Color3.fromRGB(185, 115, 30)

	task.spawn(function()
		local ok, err = pcall(function()
			pushUiLine("=== ОБХОД СКРИПТОВ И REQUIRE(MODULE) (КРОМЕ СЕРВЕРНЫХ) ===", Color3.fromRGB(185, 130, 255))

			local branches = getTargetScriptBranches()
			local report = {}
			local scriptsFound = 0
			local uiBudget = { left = 320 }

			table.insert(report, "=== CLIENT SCRIPTS & MODULES DUMP (NON-SERVER) ===")
			table.insert(report, "")

			for bIdx, branch in ipairs(branches) do
				local bHead = string.format("▼ BRANCH #%d: %s", bIdx, safeFullName(branch))
				table.insert(report, bHead)
				if uiBudget.left > 0 then
					uiBudget.left -= 1
					pushUiLine(bHead, Color3.fromRGB(255, 205, 95))
				end

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
						local sHead = string.format("  [%s] %s  (%s)", obj.ClassName, obj.Name, safeFullName(obj))
						table.insert(report, sHead)
						if uiBudget.left > 0 then
							uiBudget.left -= 1
							pushUiLine(sHead, Color3.fromRGB(120, 240, 175))
						end

						local innerLines = extractScriptInnerContent(obj)
						for _, iLine in ipairs(innerLines) do
							table.insert(report, iLine)
							if uiBudget.left > 0 then
								uiBudget.left -= 1
								pushUiLine(iLine, Color3.fromRGB(210, 225, 245))
							end
						end
					end
				end

				table.insert(report, "")
			end

			table.insert(report, string.format("TOTAL CLIENT SCRIPTS/MODULES: %d", scriptsFound))
			fullReportCache = buildFullReportSmoothly(report)
			refreshCopyLabel()

			pushUiLine(string.format("ГОТОВО: скриптов/модулей %d, символов %d.", scriptsFound, #fullReportCache), Color3.fromRGB(110, 235, 145))
			setStatus("Scripts: " .. tostring(scriptsFound))
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

local function copyFullReport()
	if #fullReportCache == 0 then
		setStatus("Empty!")
		return
	end
	copyTextToClipboard(fullReportCache, "Full")
end

ScanQueryBtn.Activated:Connect(runQueryStructureScan)
DumpScriptsBtn.Activated:Connect(runScriptsBranchesDump)
TopCopyBtn.Activated:Connect(copyFullReport)
CopyAllBtn.Activated:Connect(copyFullReport)

ClearBtn.Activated:Connect(function()
	for _, item in ipairs(rows) do
		if item.Btn then
			item.Btn:Destroy()
		end
	end
	table.clear(rows)
	fullReportCache = ""
	refreshCopyLabel()
	setStatus("Cleared")
end)

local isMin = false
MinBtn.Activated:Connect(function()
	isMin = not isMin
	QueryBox.Visible = not isMin
	Scroll.Visible = not isMin
	CopyAllBtn.Visible = not isMin
	ScanQueryBtn.Visible = not isMin
	DumpScriptsBtn.Visible = not isMin
	TopCopyBtn.Visible = not isMin
	ClearBtn.Visible = not isMin
	MainFrame.Size = isMin and UDim2.new(0.55, 0, 0, 34) or UDim2.new(0.94, 0, 0.58, 0)
	MinBtn.Text = isMin and "Max" or "Min"
end)

CloseBtn.Activated:Connect(function()
	ScreenGui:Destroy()
end)

pushUiLine("Готово. Нажми 'Find Tree' или 'Scripts In', затем 'СКОПИРОВАТЬ ВСЁ ЦЕЛИКОМ'.", Color3.fromRGB(180, 200, 230))
