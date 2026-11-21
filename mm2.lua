local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local StarterPlayer = game:GetService("StarterPlayer")
local CollectionService = game:GetService("CollectionService")

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
QueryBox.PlaceholderText = "Имя дерева (например: Item)..."
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

local OutputLabel = Instance.new("TextLabel")
OutputLabel.Size = UDim2.new(1, -10, 0, 0)
OutputLabel.Position = UDim2.new(0, 4, 0, 2)
OutputLabel.AutomaticSize = Enum.AutomaticSize.Y
OutputLabel.BackgroundTransparency = 1
OutputLabel.Text = "Готово. Введи имя (например Item) и нажми Find Tree."
OutputLabel.TextColor3 = Color3.fromRGB(215, 235, 255)
OutputLabel.TextWrapped = true
OutputLabel.TextXAlignment = Enum.TextXAlignment.Left
OutputLabel.TextYAlignment = Enum.TextYAlignment.Top
OutputLabel.Font = Enum.Font.Code
OutputLabel.TextSize = 11
OutputLabel.Parent = Scroll

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

-- === БУФЕР ВЫВОДА И КОПИРОВАНИЕ ===
local statusSeq = 0
local isBusy = false
local currentDumpText = OutputLabel.Text
local MAX_LABEL_CHARS = 185000 -- строго ниже лимита Roblox TextLabel (~200000)
local MAX_CLIP_CHARS = 1500000

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

local function safeSetLabelText(txt)
	local str = tostring(txt or "")
	if #str > MAX_LABEL_CHARS then
		str = string.sub(str, 1, MAX_LABEL_CHARS) .. "\n... [PREVIEW TRIMMED AT 185K CHARS; FULL TEXT IN CLIPBOARD]"
	end
	local ok = pcall(function()
		OutputLabel.Text = str
	end)
	if not ok then
		OutputLabel.Text = string.sub(str, 1, 100000) .. "\n... [TRIMMED]"
	end
end

local function flushBufferToUi(lines)
	local full = table.concat(lines, "\n")
	if #full > MAX_CLIP_CHARS then
		full = string.sub(full, 1, MAX_CLIP_CHARS) .. "\n... [TRUNCATED FOR MEMORY SAFETY]"
	end
	currentDumpText = full
	safeSetLabelText(full)
	Scroll.CanvasPosition = Vector2.new(0, 0)
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

local function copyAllVisibleInUi()
	local txt = tostring(currentDumpText or "")
	if #txt == 0 then
		setStatus("Empty!")
		return
	end
	local fn = getClipboardFn()
	if type(fn) ~= "function" then
		setStatus("No Clip API")
		return
	end
	local ok = pcall(fn, txt)
	if ok then
		setStatus("Copied [" .. tostring(#txt) .. "]")
	else
		setStatus("Clip Err")
	end
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
		if #val > 200 then
			return string.format("%q", string.sub(val, 1, 200) .. "...")
		end
		return string.format("%q", val)
	elseif t == "number" or t == "boolean" or t == "nil" then
		return tostring(val)
	elseif t == "Instance" then
		return string.format("<%s:%s>", val.ClassName, val.Name)
	elseif t == "function" then
		return "<function>"
	end
	return "<" .. t .. ">"
end

local function dumpRequireToBuffer(out, val, indent, depth, visited, basePrefix)
	local pad = basePrefix .. string.rep("  ", indent)
	if type(val) ~= "table" then
		table.insert(out, pad .. formatLeafValue(val))
		return
	end
	if visited[val] or depth >= 4 then
		table.insert(out, pad .. "{...}")
		return
	end
	visited[val] = true
	table.insert(out, pad .. "{")

	local keysCount = 0
	for k, v in pairs(val) do
		keysCount += 1
		if keysCount > 60 then
			table.insert(out, pad .. "  ... (more keys)")
			break
		end
		local label = formatKeyLabel(k)
		if type(v) == "table" and not visited[v] and (depth + 1) < 4 then
			table.insert(out, pad .. "  " .. label .. " =")
			dumpRequireToBuffer(out, v, indent + 2, depth + 1, visited, basePrefix)
		else
			table.insert(out, pad .. "  " .. label .. " = " .. formatLeafValue(v))
		end
	end

	table.insert(out, pad .. "}")
	visited[val] = nil
end

local function extractScriptInnerToBuffer(out, scriptObj, basePrefix, includeRequire)
	local genv = (typeof(getgenv) == "function" and getgenv()) or nil

	if includeRequire and scriptObj:IsA("ModuleScript") then
		local okReq, modVal = pcall(require, scriptObj)
		if okReq then
			table.insert(out, basePrefix .. "  [MODULE REQUIRE]:")
			dumpRequireToBuffer(out, modVal, 2, 0, {}, basePrefix)
		else
			table.insert(out, basePrefix .. "  [MODULE REQUIRE ERR]: " .. tostring(modVal))
		end
	end

	local decompileFn = decompile or (genv and genv.decompile)
	if type(decompileFn) == "function" then
		local okDec, src = pcall(decompileFn, scriptObj)
		if okDec and type(src) == "string" and #src > 0 then
			table.insert(out, basePrefix .. "  [DECOMPILED]:")
			local lineNum = 0
			for sLine in string.gmatch(src, "[^\r\n]+") do
				lineNum += 1
				if lineNum > 250 then
					table.insert(out, basePrefix .. "    ... (truncated)")
					break
				end
				table.insert(out, basePrefix .. "    " .. sLine)
			end
			return
		end
	end

	local bcFn = getscriptbytecode or (genv and genv.getscriptbytecode)
	if type(bcFn) == "function" then
		local okBc, bc = pcall(bcFn, scriptObj)
		if okBc and type(bc) == "string" and #bc > 0 then
			table.insert(out, basePrefix .. "  [BYTECODE]: " .. tostring(#bc) .. " bytes")
		end
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

local function dumpSubtreeToBuffer(out, rootInst, includeRequire)
	local count = 0
	local function walk(node, depth, prefix, isLast)
		count += 1
		local branch = (depth == 0) and "" or (isLast and "└── " or "├── ")
		table.insert(out, string.format("%s%s[%s] %s%s  (%s)", prefix, branch, node.ClassName, node.Name, describeNodeFast(node), safeFullName(node)))

		local nextPrefix = (depth == 0) and "" or (prefix .. (isLast and "    " or "│   "))
		if isAnyScript(node) then
			extractScriptInnerToBuffer(out, node, nextPrefix, includeRequire)
		end

		local okCh, ch = pcall(function()
			return node:GetChildren()
		end)
		if okCh and type(ch) == "table" then
			for i = 1, #ch do
				walk(ch[i], depth + 1, nextPrefix, i == #ch)
			end
		end
	end
	walk(rootInst, 0, "", true)
	return count
end

-- === ЗАПРОСЫ И КОРНИ ===
local function getCustomQueries(rawText)
	local list = {}
	local seen = {}
	local trimmed = string.match(tostring(rawText or ""), "^%s*(.-)%s*$")
	if not trimmed or trimmed == "" then
		return list
	end
	for part in string.gmatch(trimmed, "[^,;|%s]+") do
		local tok = string.match(part, "^%s*(.-)%s*$")
		if tok and tok ~= "" then
			local low = string.lower(tok)
			if not seen[low] then
				seen[low] = true
				table.insert(list, low)
			end
		end
	end
	if #list == 0 then
		table.insert(list, string.lower(trimmed))
	end
	return list
end

local function parseQueries(rawText)
	local list = {}
	local seen = {}
	local function addTok(tok)
		local low = string.lower(tostring(tok or ""))
		if low ~= "" and not seen[low] then
			seen[low] = true
			table.insert(list, low)
		end
	end
	for _, d in ipairs(DEFAULT_QUERIES) do
		addTok(d)
	end
	for _, c in ipairs(getCustomQueries(rawText)) do
		addTok(c)
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

-- === БЫСТРЫЙ FIND TREE ===
local function runQueryStructureScan()
	if isBusy then
		setStatus("Busy...")
		return
	end
	isBusy = true
	ScanQueryBtn.Text = "..."

	task.defer(function()
		local t0 = os.clock()
		local ok, err = pcall(function()
			local customList = getCustomQueries(QueryBox.Text)
			local hasCustom = (#customList > 0)
			local qList = hasCustom and customList or parseQueries("")

			local out = {}
			local roots = getScanRoots()
			local matched = {}
			local seenInst = {}

			if hasCustom then
				table.insert(out, "=== TREES FOR: " .. table.concat(qList, ", ") .. " ===")
				for _, r in ipairs(roots) do
					if r then
						local mRoot, tagRoot = matchesQuery(r, qList)
						if mRoot and not seenInst[r] then
							seenInst[r] = true
							table.insert(matched, { inst = r, tag = tagRoot })
						end
						local okDesc, desc = pcall(function()
							return r:GetDescendants()
						end)
						if okDesc and type(desc) == "table" then
							for i = 1, #desc do
								local obj = desc[i]
								if not seenInst[obj] then
									local m, tag = matchesQuery(obj, qList)
									if m then
										seenInst[obj] = true
										table.insert(matched, { inst = obj, tag = tag })
									end
								end
							end
						end
					end
				end

				local totalNodes = 0
				for idx, entry in ipairs(matched) do
					table.insert(out, string.format("\n★ #%d [%s] %s (%s)", idx, entry.tag, safeFullName(entry.inst), entry.inst.ClassName))
					totalNodes += dumpSubtreeToBuffer(out, entry.inst, false)
				end

				if #matched == 0 then
					table.insert(out, "Nothing found for: " .. table.concat(qList, ", "))
				end

				flushBufferToUi(out)
				setStatus(string.format("Found:%d Nodes:%d (%.2fs)", #matched, totalNodes, os.clock() - t0))
				return
			end

			table.insert(out, "=== REPLICATEDSTORAGE + STARTERGUI + DEFAULT (" .. table.concat(qList, ", ") .. ") ===")
			local priorityRoots = { ReplicatedStorage, StarterGui }
			for _, pr in ipairs(priorityRoots) do
				if pr and not seenInst[pr] then
					seenInst[pr] = true
					table.insert(matched, { inst = pr, tag = "root:" .. pr.Name })
				end
			end

			for _, r in ipairs(roots) do
				if r then
					local okDesc, desc = pcall(function()
						return r:GetDescendants()
					end)
					if okDesc and type(desc) == "table" then
						for i = 1, #desc do
							local obj = desc[i]
							if not seenInst[obj] then
								local m, tag = matchesQuery(obj, qList)
								if m then
									seenInst[obj] = true
									table.insert(matched, { inst = obj, tag = tag })
								end
							end
						end
					end
				end
			end

			local totalNodes = 0
			for idx, entry in ipairs(matched) do
				table.insert(out, string.format("\n▼ #%d [%s] %s (%s)", idx, entry.tag, safeFullName(entry.inst), entry.inst.ClassName))
				totalNodes += dumpSubtreeToBuffer(out, entry.inst, false)
			end

			flushBufferToUi(out)
			setStatus(string.format("Trees:%d Nodes:%d (%.2fs)", #matched, totalNodes, os.clock() - t0))
		end)

		if not ok then
			currentDumpText = "Ошибка: " .. tostring(err)
			safeSetLabelText(currentDumpText)
			setStatus("Err")
		end

		isBusy = false
		ScanQueryBtn.Text = "Find Tree"
	end)
end

-- === БЫСТРЫЙ SCRIPTS IN ===
local function runScriptsBranchesDump()
	if isBusy then
		setStatus("Busy...")
		return
	end
	isBusy = true
	DumpScriptsBtn.Text = "..."

	task.defer(function()
		local t0 = os.clock()
		local ok, err = pcall(function()
			local out = { "=== SCRIPTS & MODULES ===" }
			local branches = getScanRoots()
			local scriptsFound = 0
			local seenScripts = {}

			for _, branch in ipairs(branches) do
				if branch then
					local okDesc, desc = pcall(function()
						return branch:GetDescendants()
					end)
					if okDesc and type(desc) == "table" then
						for i = 1, #desc do
							local obj = desc[i]
							if isAnyScript(obj) and not seenScripts[obj] then
								seenScripts[obj] = true
								scriptsFound += 1
								table.insert(out, string.format("\n[%s] %s (%s)", obj.ClassName, obj.Name, safeFullName(obj)))
								extractScriptInnerToBuffer(out, obj, "  ", true)
							end
						end
					end
				end
			end

			flushBufferToUi(out)
			setStatus(string.format("Scripts:%d (%.2fs)", scriptsFound, os.clock() - t0))
		end)

		if not ok then
			currentDumpText = "Ошибка: " .. tostring(err)
			safeSetLabelText(currentDumpText)
			setStatus("Err")
		end

		isBusy = false
		DumpScriptsBtn.Text = "Scripts In"
	end)
end

ScanQueryBtn.Activated:Connect(runQueryStructureScan)
QueryBox.FocusLost:Connect(function(enterPressed)
	if enterPressed then
		runQueryStructureScan()
	end
end)
DumpScriptsBtn.Activated:Connect(runScriptsBranchesDump)
CopyUiBtn.Activated:Connect(copyAllVisibleInUi)

ClearBtn.Activated:Connect(function()
	currentDumpText = ""
	OutputLabel.Text = ""
	Scroll.CanvasPosition = Vector2.new(0, 0)
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
