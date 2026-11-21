local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local StarterPlayer = game:GetService("StarterPlayer")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local parentGui = LocalPlayer:WaitForChild("PlayerGui")

if parentGui:FindFirstChild("CopyUiAllGui") then
	parentGui.CopyUiAllGui:Destroy()
end

local DEFAULT_QUERIES = {
	"inventory",
	"inventory2",
	"item",
	"claime",
	"sync",
	"box",
}

-- === ИНТЕРФЕЙС ===
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CopyUiAllGui"
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
TitleLabel.Size = UDim2.new(0.26, -6, 1, 0)
TitleLabel.Position = UDim2.new(0, 8, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "UI DUMPER"
TitleLabel.TextColor3 = Color3.fromRGB(235, 240, 255)
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 10
TitleLabel.Parent = TopBar

local ScanQueryBtn = Instance.new("TextButton")
ScanQueryBtn.Size = UDim2.new(0, 62, 0, 24)
ScanQueryBtn.Position = UDim2.new(1, -304, 0.5, -12)
ScanQueryBtn.BackgroundColor3 = Color3.fromRGB(45, 135, 235)
ScanQueryBtn.Text = "Find Tree"
ScanQueryBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ScanQueryBtn.Font = Enum.Font.GothamBold
ScanQueryBtn.TextSize = 9
ScanQueryBtn.Parent = TopBar
Instance.new("UICorner", ScanQueryBtn).CornerRadius = UDim.new(0, 6)

local DumpScriptsBtn = Instance.new("TextButton")
DumpScriptsBtn.Size = UDim2.new(0, 66, 0, 24)
DumpScriptsBtn.Position = UDim2.new(1, -236, 0.5, -12)
DumpScriptsBtn.BackgroundColor3 = Color3.fromRGB(125, 65, 195)
DumpScriptsBtn.Text = "Scripts In"
DumpScriptsBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
DumpScriptsBtn.Font = Enum.Font.GothamBold
DumpScriptsBtn.TextSize = 9
DumpScriptsBtn.Parent = TopBar
Instance.new("UICorner", DumpScriptsBtn).CornerRadius = UDim.new(0, 6)

local ClearBtn = Instance.new("TextButton")
ClearBtn.Size = UDim2.new(0, 48, 0, 24)
ClearBtn.Position = UDim2.new(1, -164, 0.5, -12)
ClearBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 70)
ClearBtn.Text = "Clear"
ClearBtn.TextColor3 = Color3.fromRGB(235, 235, 245)
ClearBtn.Font = Enum.Font.GothamBold
ClearBtn.TextSize = 9
ClearBtn.Parent = TopBar
Instance.new("UICorner", ClearBtn).CornerRadius = UDim.new(0, 6)

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 48, 0, 24)
MinBtn.Position = UDim2.new(1, -110, 0.5, -12)
MinBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 70)
MinBtn.Text = "Min"
MinBtn.TextColor3 = Color3.fromRGB(235, 235, 245)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 9
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

local QueryBox = Instance.new("TextBox")
QueryBox.Size = UDim2.new(1, -16, 0, 28)
QueryBox.Position = UDim2.new(0, 8, 0, 40)
QueryBox.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
QueryBox.PlaceholderText = "Доп. запросы (базовые: Inventory, Inventory2, Item, Claime, sync, Box)..."
QueryBox.PlaceholderColor3 = Color3.fromRGB(135, 135, 155)
QueryBox.Text = ""
QueryBox.TextColor3 = Color3.fromRGB(255, 255, 255)
QueryBox.ClearTextOnFocus = false
QueryBox.Font = Enum.Font.Code
QueryBox.TextSize = 12
QueryBox.Parent = MainFrame
Instance.new("UICorner", QueryBox).CornerRadius = UDim.new(0, 6)

local CopyUiBtn = Instance.new("TextButton")
CopyUiBtn.Name = "CopyUiBtn"
CopyUiBtn.Size = UDim2.new(1, -16, 0, 34)
CopyUiBtn.Position = UDim2.new(0, 8, 1, -42)
CopyUiBtn.BackgroundColor3 = Color3.fromRGB(35, 130, 85)
CopyUiBtn.Text = "СКОПИРОВАТЬ ВСЁ ИЗ ИНТЕРФЕЙСА"
CopyUiBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CopyUiBtn.Font = Enum.Font.GothamBold
CopyUiBtn.TextSize = 11
CopyUiBtn.Parent = MainFrame
Instance.new("UICorner", CopyUiBtn).CornerRadius = UDim.new(0, 7)

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
Layout.Padding = UDim.new(0, 2)
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

-- === СТАТУС И КОПИРОВАНИЕ ВСЕГО ВЫВЕДЕННОГО В ИНТЕРФЕЙС ===
local statusSeq = 0
local isBusy = false
local rows = {}
local rowOrder = 0
local maxUiRows = 25000
local stepCounter = 0

local function yieldStep(everyN)
	stepCounter += 1
	if stepCounter % (everyN or 70) == 0 then
		RunService.Heartbeat:Wait()
	end
end

local function setStatus(msg)
	statusSeq += 1
	local cur = statusSeq
	TitleLabel.Text = msg
	task.delay(2.5, function()
		if statusSeq == cur then
			TitleLabel.Text = "UI DUMPER"
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

local function copyToClipboard(str, label)
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

local function copyAllVisibleInUi()
	if #rows == 0 then
		setStatus("Empty!")
		return
	end
	local parts = {}
	for i = 1, #rows do
		local item = rows[i]
		if item and item.FullLine then
			table.insert(parts, item.FullLine)
		end
	end
	copyToClipboard(table.concat(parts, "\n"), "UI All")
end

-- === ЛЁГКИЙ ВЫВОД В ИНТЕРФЕЙС ===
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
	btn.BackgroundTransparency = 0.2
	btn.BorderSizePixel = 0
	btn.Text = lineStr
	btn.TextColor3 = color or Color3.fromRGB(220, 238, 255)
	btn.TextWrapped = true
	btn.TextXAlignment = Enum.TextXAlignment.Left
	btn.Font = Enum.Font.Code
	btn.TextSize = 11
	btn.LayoutOrder = rowOrder
	btn.AutoButtonColor = false
	btn.Parent = Scroll

	btn.Activated:Connect(function()
		copyToClipboard(lineStr, "Line")
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

local function isAnyScript(inst)
	if typeof(inst) ~= "Instance" then
		return false
	end
	local ok, res = pcall(function()
		return inst:IsA("LuaSourceContainer")
	end)
	return ok and res == true
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
		if #s > 300 then
			s = string.sub(s, 1, 300) .. "..."
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

local function dumpRequireValueToUi(val, indent, depth, visited, basePrefix)
	yieldStep(90)
	local pad = basePrefix .. string.rep("  ", indent)
	if type(val) ~= "table" then
		pushUiLine(pad .. formatLeafValue(val), Color3.fromRGB(205, 225, 245))
		return
	end
	if visited[val] or depth >= 6 then
		pushUiLine(pad .. "{...}", Color3.fromRGB(205, 225, 245))
		return
	end
	visited[val] = true
	pushUiLine(pad .. "{", Color3.fromRGB(205, 225, 245))

	local keysCount = 0
	for k, v in pairs(val) do
		keysCount += 1
		if keysCount > 150 then
			pushUiLine(pad .. "  ... (more keys)", Color3.fromRGB(165, 180, 200))
			break
		end
		yieldStep(90)
		local label = formatKeyLabel(k)
		if type(v) == "table" and not visited[v] and (depth + 1) < 6 then
			pushUiLine(pad .. "  " .. label .. " =", Color3.fromRGB(220, 235, 255))
			dumpRequireValueToUi(v, indent + 2, depth + 1, visited, basePrefix)
		else
			pushUiLine(pad .. "  " .. label .. " = " .. formatLeafValue(v), Color3.fromRGB(205, 225, 245))
		end
	end

	pushUiLine(pad .. "}", Color3.fromRGB(205, 225, 245))
	visited[val] = nil
end

local function extractScriptInnerToUi(scriptObj, basePrefix)
	local genv = (typeof(getgenv) == "function" and getgenv()) or nil
	local wroteAnything = false

	if scriptObj:IsA("ModuleScript") then
		local okReq, modVal = pcall(require, scriptObj)
		if okReq then
			wroteAnything = true
			pushUiLine(basePrefix .. "  [MODULE REQUIRE]:", Color3.fromRGB(165, 245, 195))
			dumpRequireValueToUi(modVal, 2, 0, {}, basePrefix)
		else
			wroteAnything = true
			pushUiLine(basePrefix .. "  [MODULE REQUIRE ERR]: " .. tostring(modVal), Color3.fromRGB(255, 150, 120))
		end
	end

	local decompileFn = decompile or (genv and genv.decompile)
	if type(decompileFn) == "function" then
		local okDec, src = pcall(decompileFn, scriptObj)
		if okDec and type(src) == "string" and #src > 0 then
			wroteAnything = true
			pushUiLine(basePrefix .. "  [DECOMPILED]:", Color3.fromRGB(165, 210, 255))
			local lineNum = 0
			for sLine in string.gmatch(src, "[^\r\n]+") do
				lineNum += 1
				if lineNum > 800 then
					pushUiLine(basePrefix .. "    ... (script truncated for FPS)", Color3.fromRGB(165, 180, 200))
					break
				end
				yieldStep(120)
				pushUiLine(basePrefix .. "    " .. sLine, Color3.fromRGB(205, 225, 245))
			end
		end
	end

	local bcFn = getscriptbytecode or (genv and genv.getscriptbytecode)
	if type(bcFn) == "function" then
		local okBc, bc = pcall(bcFn, scriptObj)
		if okBc and type(bc) == "string" and #bc > 0 then
			wroteAnything = true
			pushUiLine(basePrefix .. "  [BYTECODE]: " .. tostring(#bc) .. " bytes", Color3.fromRGB(185, 195, 215))
		end
	end

	if not wroteAnything then
		pushUiLine(basePrefix .. "  [SCRIPT INFO]: Class=" .. scriptObj.ClassName .. " (no source/bytecode returned)", Color3.fromRGB(175, 185, 205))
	end
end

local function describeNodeFast(node)
	local props = {}

	if node:IsA("GuiObject") then
		table.insert(props, "Visible=" .. tostring(node.Visible))
	elseif node:IsA("LayerCollector") then
		table.insert(props, "Enabled=" .. tostring(node.Enabled))
	end

	if node:IsA("TextLabel") or node:IsA("TextButton") or node:IsA("TextBox") then
		if node.Text ~= "" then
			table.insert(props, "Text=" .. formatLeafValue(node.Text))
		end
	elseif node:IsA("ImageLabel") or node:IsA("ImageButton") then
		if node.Image ~= "" then
			table.insert(props, "Image=" .. formatLeafValue(node.Image))
		end
	elseif node:IsA("ValueBase") then
		local okV, val = pcall(function()
			return node.Value
		end)
		if okV then
			table.insert(props, "Value=" .. formatLeafValue(val))
		end
	end

	local okTags, tags = pcall(function()
		return CollectionService:GetTags(node)
	end)
	if okTags and type(tags) == "table" and #tags > 0 then
		table.insert(props, "Tags=[" .. table.concat(tags, ", ") .. "]")
	end

	local okAttr, attrs = pcall(function()
		return node:GetAttributes()
	end)
	if okAttr and type(attrs) == "table" then
		for k, v in pairs(attrs) do
			table.insert(props, "Attr." .. tostring(k) .. "=" .. formatLeafValue(v))
		end
	end

	if #props == 0 then
		return ""
	end
	return "  {" .. table.concat(props, ", ") .. "}"
end

local function dumpSubtreeFastToUi(rootInst, dumpedScriptsSet, collectedScriptsList, seenCollectedSet)
	local count = 0
	local function walk(node, depth, prefix, isLast)
		count += 1
		yieldStep(75)
		local branch = (depth == 0) and "" or (isLast and "└── " or "├── ")
		local line = string.format("%s%s[%s] %s%s  (%s)", prefix, branch, node.ClassName, node.Name, describeNodeFast(node), safeFullName(node))
		pushUiLine(line, depth == 0 and Color3.fromRGB(255, 205, 95) or Color3.fromRGB(215, 235, 255))

		local nextPrefix = (depth == 0) and "" or (prefix .. (isLast and "    " or "│   "))
		if isAnyScript(node) then
			if dumpedScriptsSet then
				dumpedScriptsSet[node] = true
			end
			if collectedScriptsList and seenCollectedSet and not seenCollectedSet[node] then
				seenCollectedSet[node] = true
				table.insert(collectedScriptsList, node)
			end
			extractScriptInnerToUi(node, nextPrefix)
		end

		local okCh, ch = pcall(function()
			return node:GetChildren()
		end)
		if okCh and type(ch) == "table" then
			for i, c in ipairs(ch) do
				walk(c, depth + 1, nextPrefix, i == #ch)
			end
		end
	end
	walk(rootInst, 0, "", true)
	return count
end

local function collectAllReplicatedScripts()
	local list = {}
	local seen = {}
	local function tryAdd(obj)
		if isAnyScript(obj) and not seen[obj] then
			seen[obj] = true
			table.insert(list, obj)
		end
	end

	tryAdd(ReplicatedStorage)
	local okDesc, desc = pcall(function()
		return ReplicatedStorage:GetDescendants()
	end)
	if okDesc and type(desc) == "table" then
		for _, obj in ipairs(desc) do
			tryAdd(obj)
		end
	end
	return list
end

-- === 1. ПОЛНАЯ ВЫГРУЗКА REPLICATEDSTORAGE + ВСЕХ ЕГО СКРИПТОВ + STARTERGUI + ДЕРЕВЬЕВ ===
local function parseQueries(rawText)
	local list = {}
	local seen = {}

	local function addTok(tok)
		local clean = string.match(tostring(tok or ""), "^%s*(.-)%s*$")
		if clean and clean ~= "" then
			local low = string.lower(clean)
			if not seen[low] then
				seen[low] = true
				table.insert(list, low)
			end
		end
	end

	for _, defQ in ipairs(DEFAULT_QUERIES) do
		addTok(defQ)
	end

	local trimmed = string.match(tostring(rawText or ""), "^%s*(.-)%s*$")
	if trimmed and trimmed ~= "" then
		for part in string.gmatch(trimmed, "[^,;|]+") do
			addTok(part)
		end
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

	return false, nil
end

local function getDatabaseRoot()
	local okDb, db = pcall(function()
		return ReplicatedStorage:FindFirstChild("Database")
	end)
	return okDb and db or nil
end

local function getPlayerScriptsRoot()
	if not LocalPlayer then
		return nil
	end
	local okPs, ps = pcall(function()
		return LocalPlayer:FindFirstChild("PlayerScripts")
	end)
	if okPs and ps then
		return ps
	end
	local okSp, sp = pcall(function()
		return StarterPlayer:FindFirstChild("StarterPlayerScripts")
	end)
	return okSp and sp or nil
end

local function getScanRoots()
	local roots = {}
	local seen = {}
	local function addRoot(r)
		if r and not seen[r] then
			seen[r] = true
			table.insert(roots, r)
		end
	end

	addRoot(ReplicatedStorage)
	addRoot(StarterGui)
	addRoot(getDatabaseRoot())
	addRoot(getPlayerScriptsRoot())
	addRoot(LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui"))
	addRoot(LocalPlayer and LocalPlayer:FindFirstChildOfClass("Backpack"))
	addRoot(LocalPlayer and LocalPlayer.Character)

	return roots
end

local function runQueryStructureScan()
	if isBusy then
		setStatus("Busy...")
		return
	end
	isBusy = true
	ScanQueryBtn.Text = "Wait..."
	ScanQueryBtn.BackgroundColor3 = Color3.fromRGB(185, 115, 30)

	task.spawn(function()
		local ok, err = pcall(function()
			local qList = parseQueries(QueryBox.Text)
			pushUiLine("=== ПОЛНЫЙ ДАМП REPLICATEDSTORAGE + STARTERGUI + ДЕРЕВЬЕВ (" .. table.concat(qList, ", ") .. ") ===", Color3.fromRGB(120, 210, 255))

			local roots = getScanRoots()
			local matched = {}
			local seenInst = {}
			local priorityScripts = {}
			local seenPriorityScript = {}

			if ReplicatedStorage then
				seenInst[ReplicatedStorage] = true
				table.insert(matched, { inst = ReplicatedStorage, tag = "root:ReplicatedStorage" })
			end
			if StarterGui then
				seenInst[StarterGui] = true
				table.insert(matched, { inst = StarterGui, tag = "root:StarterGui" })
			end

			local function considerScriptPriority(obj)
				if not isAnyScript(obj) then
					return
				end
				if not seenPriorityScript[obj] then
					seenPriorityScript[obj] = true
					table.insert(priorityScripts, obj)
				end
			end

			for _, repScript in ipairs(collectAllReplicatedScripts()) do
				considerScriptPriority(repScript)
			end

			for _, r in ipairs(roots) do
				if r then
					local mRoot, tagRoot = matchesQuery(r, qList)
					if mRoot and not seenInst[r] then
						seenInst[r] = true
						table.insert(matched, { inst = r, tag = tagRoot })
					end
					considerScriptPriority(r)

					local okDesc, desc = pcall(function()
						return r:GetDescendants()
					end)
					if okDesc and type(desc) == "table" then
						for _, obj in ipairs(desc) do
							yieldStep(250)
							if not seenInst[obj] then
								local m, tag = matchesQuery(obj, qList)
								if m then
									seenInst[obj] = true
									table.insert(matched, { inst = obj, tag = tag })
								end
							end
							considerScriptPriority(obj)
						end
					end
				end
			end

			local totalNodes = 0
			local dumpedScripts = {}

			for idx, entry in ipairs(matched) do
				local inst = entry.inst
				pushUiLine(string.format("▼ #%d [%s] %s (%s)", idx, entry.tag, safeFullName(inst), inst.ClassName), Color3.fromRGB(115, 240, 165))
				totalNodes += dumpSubtreeFastToUi(inst, dumpedScripts, priorityScripts, seenPriorityScript)
			end

			pushUiLine("=== ВСЕ СКРИПТЫ И МОДУЛИ ИЗ REPLICATEDSTORAGE И ВЫБРАННЫХ ВЕТОК ===", Color3.fromRGB(255, 185, 95))
			local extraScriptCount = 0
			for _, sc in ipairs(priorityScripts) do
				if not dumpedScripts[sc] then
					dumpedScripts[sc] = true
					extraScriptCount += 1
					pushUiLine(string.format("  [%s] %s (%s)", sc.ClassName, sc.Name, safeFullName(sc)), Color3.fromRGB(140, 235, 255))
					extractScriptInnerToUi(sc, "  ")
				end
			end

			setStatus("Trees:" .. tostring(#matched) .. " Nodes:" .. tostring(totalNodes) .. " Scr:" .. tostring(extraScriptCount))
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

-- === 2. ФИОЛЕТОВАЯ КНОПКА: СКАНИРОВАТЬ ВСЕ СКРИПТЫ И МОДУЛИ + ВНУТРИ НАЙДЕННЫХ ДЕРЕВЬЕВ ===
local function getTargetScriptBranches()
	local branches = {}
	local seen = {}
	local function addInst(inst)
		if inst and not seen[inst] then
			seen[inst] = true
			table.insert(branches, inst)
		end
	end

	addInst(ReplicatedStorage)
	addInst(StarterGui)
	addInst(getDatabaseRoot())
	addInst(getPlayerScriptsRoot())
	addInst(LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui"))
	addInst(LocalPlayer and LocalPlayer:FindFirstChildOfClass("Backpack"))
	addInst(LocalPlayer and LocalPlayer.Character)

	local qList = parseQueries(QueryBox.Text)
	for _, r in ipairs(branches) do
		if matchesQuery(r, qList) then
			addInst(r)
		end
		local okDesc, desc = pcall(function()
			return r:GetDescendants()
		end)
		if okDesc and type(desc) == "table" then
			for i = 1, #desc do
				yieldStep(180)
				local obj = desc[i]
				if matchesQuery(obj, qList) then
					addInst(obj)
				end
			end
		end
	end

	return branches
end

local function runScriptsBranchesDump()
	if isBusy then
		setStatus("Busy...")
		return
	end
	isBusy = true
	DumpScriptsBtn.Text = "Wait..."
	DumpScriptsBtn.BackgroundColor3 = Color3.fromRGB(185, 115, 30)

	task.spawn(function()
		local ok, err = pcall(function()
			pushUiLine("=== ВСЕ СКРИПТЫ И МОДУЛИ (ВЕТКИ + ВНУТРИ INVENTORY2 / ITEM / CLAIME / SYNC / BOX) ===", Color3.fromRGB(195, 125, 255))
			local branches = getTargetScriptBranches()
			local scriptsFound = 0
			local seenScripts = {}

			for _, branch in ipairs(branches) do
				pushUiLine("▼ BRANCH: " .. safeFullName(branch), Color3.fromRGB(255, 205, 95))
				yieldStep(10)

				if isAnyScript(branch) and not seenScripts[branch] then
					seenScripts[branch] = true
					scriptsFound += 1
					pushUiLine(string.format("  [%s] %s (%s)", branch.ClassName, branch.Name, safeFullName(branch)), Color3.fromRGB(130, 245, 185))
					extractScriptInnerToUi(branch, "  ")
				end

				local okDesc, desc = pcall(function()
					return branch:GetDescendants()
				end)
				if okDesc and type(desc) == "table" then
					for i = 1, #desc do
						yieldStep(60)
						local obj = desc[i]
						if isAnyScript(obj) and not seenScripts[obj] then
							seenScripts[obj] = true
							scriptsFound += 1
							pushUiLine(string.format("  [%s] %s (%s)", obj.ClassName, obj.Name, safeFullName(obj)), Color3.fromRGB(130, 245, 185))
							extractScriptInnerToUi(obj, "  ")
						end
					end
				end
			end

			pushUiLine("=== ИТОГО НАЙДЕНО СКРИПТОВ И МОДУЛЕЙ: " .. tostring(scriptsFound) .. " ===", Color3.fromRGB(195, 125, 255))
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

ScanQueryBtn.Activated:Connect(runQueryStructureScan)
DumpScriptsBtn.Activated:Connect(runScriptsBranchesDump)
CopyUiBtn.Activated:Connect(copyAllVisibleInUi)

ClearBtn.Activated:Connect(function()
	for _, item in ipairs(rows) do
		if item.Btn then
			item.Btn:Destroy()
		end
	end
	table.clear(rows)
	setStatus("Cleared")
end)

local isMin = false
MinBtn.Activated:Connect(function()
	isMin = not isMin
	QueryBox.Visible = not isMin
	Scroll.Visible = not isMin
	CopyUiBtn.Visible = not isMin
	ScanQueryBtn.Visible = not isMin
	DumpScriptsBtn.Visible = not isMin
	ClearBtn.Visible = not isMin
	MainFrame.Size = isMin and UDim2.new(0.55, 0, 0, 34) or UDim2.new(0.94, 0, 0.58, 0)
	MinBtn.Text = isMin and "Max" or "Min"
end)

CloseBtn.Activated:Connect(function()
	ScreenGui:Destroy()
end)

pushUiLine("Готово. Сканер загружен: Find Tree и Scripts In готовы к работе.", Color3.fromRGB(180, 200, 230))
