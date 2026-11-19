local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local targetNick = "Stas_mine12"
local parentGui = player:WaitForChild("PlayerGui")

if parentGui:FindFirstChild("MobileOmniLogger") then
	parentGui.MobileOmniLogger:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MobileOmniLogger"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = parentGui

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0.94, 0, 0.5, 0)
MainFrame.Position = UDim2.new(0.03, 0, 0.04, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
MainFrame.BackgroundTransparency = 0.12
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Parent = ScreenGui

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(70, 70, 85)
Stroke.Thickness = 1
Stroke.Parent = MainFrame

local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 32)
TopBar.BackgroundColor3 = Color3.fromRGB(26, 26, 32)
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame

Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 10)

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(0.26, -6, 1, 0)
TitleLabel.Position = UDim2.new(0, 8, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "ESP+KNIFE " .. targetNick
TitleLabel.TextColor3 = Color3.fromRGB(235, 235, 245)
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 10
TitleLabel.Parent = TopBar

local TreeScanBtn = Instance.new("TextButton")
TreeScanBtn.Size = UDim2.new(0, 62, 0, 22)
TreeScanBtn.Position = UDim2.new(1, -362, 0.5, -11)
TreeScanBtn.BackgroundColor3 = Color3.fromRGB(95, 55, 165)
TreeScanBtn.Text = "TreeScan"
TreeScanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
TreeScanBtn.Font = Enum.Font.GothamBold
TreeScanBtn.TextSize = 9
TreeScanBtn.Parent = TopBar
Instance.new("UICorner", TreeScanBtn).CornerRadius = UDim.new(0, 6)

local PulseBtn = Instance.new("TextButton")
PulseBtn.Size = UDim2.new(0, 56, 0, 22)
PulseBtn.Position = UDim2.new(1, -296, 0.5, -11)
PulseBtn.BackgroundColor3 = Color3.fromRGB(65, 65, 85)
PulseBtn.Text = "Pulse:OFF"
PulseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
PulseBtn.Font = Enum.Font.GothamBold
PulseBtn.TextSize = 9
PulseBtn.Parent = TopBar
Instance.new("UICorner", PulseBtn).CornerRadius = UDim.new(0, 6)

local ScanBtn = Instance.new("TextButton")
ScanBtn.Size = UDim2.new(0, 52, 0, 22)
ScanBtn.Position = UDim2.new(1, -234, 0.5, -11)
ScanBtn.BackgroundColor3 = Color3.fromRGB(38, 125, 75)
ScanBtn.Text = "Scan:ON"
ScanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ScanBtn.Font = Enum.Font.GothamBold
ScanBtn.TextSize = 9
ScanBtn.Parent = TopBar
Instance.new("UICorner", ScanBtn).CornerRadius = UDim.new(0, 6)

local CopyBtn = Instance.new("TextButton")
CopyBtn.Size = UDim2.new(0, 48, 0, 22)
CopyBtn.Position = UDim2.new(1, -176, 0.5, -11)
CopyBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 58)
CopyBtn.Text = "Filter"
CopyBtn.TextColor3 = Color3.fromRGB(230, 230, 240)
CopyBtn.Font = Enum.Font.GothamBold
CopyBtn.TextSize = 9
CopyBtn.Parent = TopBar
Instance.new("UICorner", CopyBtn).CornerRadius = UDim.new(0, 6)

local ClearBtn = Instance.new("TextButton")
ClearBtn.Size = UDim2.new(0, 50, 0, 22)
ClearBtn.Position = UDim2.new(1, -122, 0.5, -11)
ClearBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 58)
ClearBtn.Text = "Clear"
ClearBtn.TextColor3 = Color3.fromRGB(230, 230, 240)
ClearBtn.Font = Enum.Font.GothamBold
ClearBtn.TextSize = 9
ClearBtn.Parent = TopBar
Instance.new("UICorner", ClearBtn).CornerRadius = UDim.new(0, 6)

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0, 52, 0, 22)
ToggleBtn.Position = UDim2.new(1, -64, 0.5, -11)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 58)
ToggleBtn.Text = "Min"
ToggleBtn.TextColor3 = Color3.fromRGB(230, 230, 240)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 9
ToggleBtn.Parent = TopBar
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 6)

local FilterBox = Instance.new("TextBox")
FilterBox.Size = UDim2.new(1, -16, 0, 28)
FilterBox.Position = UDim2.new(0, 8, 0, 38)
FilterBox.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
FilterBox.PlaceholderText = "Фильтр (FULL_TREE, TREE_SCRIPT, SCRIPT_PATH, SCRIPT_SRC, ROLE_LIST)..."
FilterBox.PlaceholderColor3 = Color3.fromRGB(130, 130, 150)
FilterBox.Text = ""
FilterBox.TextColor3 = Color3.fromRGB(255, 255, 255)
FilterBox.ClearTextOnFocus = false
FilterBox.Font = Enum.Font.Code
FilterBox.TextSize = 12
FilterBox.Parent = MainFrame
Instance.new("UICorner", FilterBox).CornerRadius = UDim.new(0, 6)

local BottomCopyBtn = Instance.new("TextButton")
BottomCopyBtn.Name = "CopyAllToClipboardBtn"
BottomCopyBtn.Size = UDim2.new(1, -16, 0, 32)
BottomCopyBtn.Position = UDim2.new(0, 8, 1, -40)
BottomCopyBtn.BackgroundColor3 = Color3.fromRGB(32, 110, 235)
BottomCopyBtn.Text = "Скопировать в буфер"
BottomCopyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
BottomCopyBtn.Font = Enum.Font.GothamBold
BottomCopyBtn.TextSize = 12
BottomCopyBtn.Parent = MainFrame
Instance.new("UICorner", BottomCopyBtn).CornerRadius = UDim.new(0, 7)

local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -16, 1, -114)
Scroll.Position = UDim2.new(0, 8, 0, 72)
Scroll.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
Scroll.BorderSizePixel = 0
Scroll.ScrollBarThickness = 5
Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Scroll.Parent = MainFrame
Instance.new("UICorner", Scroll).CornerRadius = UDim.new(0, 6)

local Layout = Instance.new("UIListLayout")
Layout.Padding = UDim.new(0, 4)
Layout.SortOrder = Enum.SortOrder.LayoutOrder
Layout.Parent = Scroll

-- Перетаскивание окна
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

local statusToken = 0
local function notifyStatus(msg)
	statusToken += 1
	local currentToken = statusToken
	TitleLabel.Text = msg
	task.delay(1.8, function()
		if statusToken == currentToken then
			TitleLabel.Text = "ESP+KNIFE " .. targetNick
		end
	end)
end

local function resolveClipboardFn()
	local genv = (typeof(getgenv) == "function" and getgenv()) or nil
	local candidates = {
		setclipboard,
		toclipboard,
		set_clipboard,
		writeclipboard,
		Clipboard and Clipboard.set,
		Clipboard and Clipboard.Set,
		genv and genv.setclipboard,
		genv and genv.toclipboard,
		genv and genv.set_clipboard,
		genv and genv.writeclipboard,
	}
	for _, fn in ipairs(candidates) do
		if type(fn) == "function" then
			return fn
		end
	end
	return nil
end

local function copyToClipboard(text, labelForStatus)
	local str = tostring(text or "")
	if #str == 0 then
		notifyStatus("Empty text")
		return false
	end

	local fn = resolveClipboardFn()
	if type(fn) ~= "function" then
		notifyStatus("No Clip API")
		warn("[EspLogger] Нет доступной функции буфера обмена. Длина текста: " .. tostring(#str))
		return false
	end

	local ok, err = pcall(fn, str)
	if ok then
		notifyStatus((labelForStatus or "Copied!") .. " (" .. tostring(#str) .. "ch)")
		return true
	else
		notifyStatus("Clip Err")
		warn("[EspLogger] Ошибка копирования в буфер: " .. tostring(err))
		return false
	end
end

local logs = {}
local maxLogs = 1500
local logOrder = 0
local pulseEnabled = false
local scanEnabled = true
local lastFullDumpText = ""

local function matchesFilter(entryText, filterText)
	if filterText == "" then
		return true
	end
	return string.find(string.lower(entryText), string.lower(filterText), 1, true) ~= nil
end

local function refreshLogs()
	local filterText = FilterBox.Text
	for _, item in ipairs(logs) do
		item.Button.Visible = matchesFilter(item.RawText, filterText)
	end
end

local function safeFullName(inst)
	if typeof(inst) ~= "Instance" then
		return tostring(inst)
	end
	local ok, res = pcall(function()
		return inst:GetFullName()
	end)
	return ok and res or inst.Name
end

local function formatValue(val)
	local t = typeof(val)
	if t == "Vector3" then
		return string.format("V3(%.2f, %.2f, %.2f)", val.X, val.Y, val.Z)
	elseif t == "CFrame" then
		local p = val.Position
		local lv = val.LookVector
		return string.format("CF(P:%.2f,%.2f,%.2f | L:%.2f,%.2f,%.2f)", p.X, p.Y, p.Z, lv.X, lv.Y, lv.Z)
	elseif t == "Ray" then
		local o = val.Origin
		local d = val.Direction
		return string.format("Ray(O:%.2f,%.2f,%.2f | D:%.2f,%.2f,%.2f)", o.X, o.Y, o.Z, d.X, d.Y, d.Z)
	elseif t == "Color3" then
		return string.format("RGB(%d, %d, %d)", math.round(val.R * 255), math.round(val.G * 255), math.round(val.B * 255))
	elseif t == "Instance" then
		return string.format("%s [%s]", safeFullName(val), val.ClassName)
	elseif t == "table" then
		local items = {}
		local count = 0
		for k, v in pairs(val) do
			count += 1
			if count <= 8 then
				table.insert(items, tostring(k) .. "=" .. formatValue(v))
			end
		end
		if count == 0 then
			return "{}"
		end
		local suffix = count > 8 and string.format(" (+%d)", count - 8) or ""
		return "{" .. table.concat(items, ", ") .. suffix .. "}"
	else
		return tostring(val)
	end
end

local function formatAttributes(inst)
	if typeof(inst) ~= "Instance" then
		return ""
	end
	local ok, attrs = pcall(function()
		return inst:GetAttributes()
	end)
	if not ok or type(attrs) ~= "table" then
		return ""
	end
	local parts = {}
	for k, v in pairs(attrs) do
		table.insert(parts, string.format("%s=%s", tostring(k), formatValue(v)))
	end
	table.sort(parts)
	if #parts == 0 then
		return ""
	end
	return " | Attrs{" .. table.concat(parts, ", ") .. "}"
end

local scrollScheduled = false
local function scheduleScrollToBottom()
	if scrollScheduled then
		return
	end
	scrollScheduled = true
	task.defer(function()
		scrollScheduled = false
		Scroll.CanvasPosition = Vector2.new(0, Scroll.AbsoluteCanvasSize.Y)
	end)
end

local function LogEvent(tag, message)
	logOrder += 1
	local stamp = os.date("%H:%M:%S")
	local fullText = string.format("[%s] [%s] %s", stamp, tag or "LOG", tostring(message))

	if #logs >= maxLogs then
		local oldest = table.remove(logs, 1)
		if oldest and oldest.Button then
			oldest.Button:Destroy()
		end
	end

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, -8, 0, 0)
	btn.AutomaticSize = Enum.AutomaticSize.Y
	btn.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
	btn.BackgroundTransparency = 0.25
	btn.Text = fullText
	btn.TextColor3 = Color3.fromRGB(220, 240, 255)
	btn.TextWrapped = true
	btn.TextXAlignment = Enum.TextXAlignment.Left
	btn.Font = Enum.Font.Code
	btn.TextSize = 11
	btn.LayoutOrder = logOrder
	btn.AutoButtonColor = true
	btn.Visible = matchesFilter(fullText, FilterBox.Text)
	btn.Parent = Scroll
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

	btn.MouseButton1Click:Connect(function()
		copyToClipboard(fullText, "Copied line")
	end)

	table.insert(logs, {
		RawText = fullText,
		Button = btn,
	})

	scheduleScrollToBottom()
end

local attrWatched = {}
local function watchAttributes(inst, tagPrefix)
	if typeof(inst) ~= "Instance" or attrWatched[inst] then
		return
	end
	attrWatched[inst] = true

	local initAttrs = formatAttributes(inst)
	if initAttrs ~= "" then
		LogEvent(tagPrefix or "ATTR", string.format("%s [%s]%s", safeFullName(inst), inst.ClassName, initAttrs))
	end

	pcall(function()
		inst.AttributeChanged:Connect(function(attrName)
			if not scanEnabled then
				return
			end
			local newVal = inst:GetAttribute(attrName)
			LogEvent(
				tagPrefix or "ATTR",
				string.format("%s [%s] -> %s = %s", safeFullName(inst), inst.ClassName, tostring(attrName), formatValue(newVal))
			)
		end)
	end)
end

local function formatArgs(...)
	local parts = {}
	for i = 1, select("#", ...) do
		local arg = select(i, ...)
		local s = formatValue(arg)
		if typeof(arg) == "Instance" then
			watchAttributes(arg, "OBJ_ATTR")
			s = s .. formatAttributes(arg)
		end
		parts[i] = s
	end
	return table.concat(parts, ", ")
end

-- === ЦЕЛЫЕ ДЕРЕВЬЯ ПО ПОИСКАМ (Sync, Item, Inventory, Module, Moduls) + СКРИПТЫ ===
local TARGET_TREE_KEYWORDS = { "sync", "item", "inventory", "module", "moduls" }
local autoTreeScanEnabled = false
local autoTreeScanThread = nil
local loggedScanSignatures = {}

local function containsAnyKeyword(text, list)
	local low = string.lower(tostring(text or ""))
	for _, kw in ipairs(list) do
		if string.find(low, kw, 1, true) then
			return true
		end
	end
	return false
end

local function isReadableClientScript(inst)
	return typeof(inst) == "Instance" and (inst:IsA("LocalScript") or inst:IsA("ModuleScript"))
end

local function readClientScriptSource(scriptObj)
	if not isReadableClientScript(scriptObj) then
		return nil, "not_script", false
	end

	local okSrc, src = pcall(function()
		return scriptObj.Source
	end)
	if okSrc and type(src) == "string" and #src > 0 then
		return src, "Source", true
	end

	local env = (typeof(getgenv) == "function" and getgenv()) or _G
	local decFn = (type(decompile) == "function" and decompile)
		or (env and type(env.decompile) == "function" and env.decompile)
		or nil

	if decFn then
		local okDec, decOut = pcall(decFn, scriptObj)
		if okDec and type(decOut) == "string" and #decOut > 0 then
			local isReal = not string.find(string.lower(decOut), "decompile failed", 1, true)
				and not string.find(string.lower(decOut), "unable to decompile", 1, true)
			return decOut, "decompile", isReal
		end
	end

	if type(getscriptbytecode) == "function" then
		local okBc, bc = pcall(getscriptbytecode, scriptObj)
		if okBc and type(bc) == "string" and #bc > 0 then
			return string.format("-- [Bytecode %d bytes; decompile unavailable for %s]", #bc, safeFullName(scriptObj)), "bytecode", false
		end
	end

	return string.format("-- [Unreadable/No decompile API for %s]", safeFullName(scriptObj)), "unreadable", false
end

local function collectAllClientRoots()
	local roots = {
		Workspace,
		ReplicatedStorage,
		player:FindFirstChildOfClass("PlayerGui"),
		player:FindFirstChildOfClass("Backpack"),
		player.Character,
		StarterPlayer:FindFirstChild("StarterPlayerScripts"),
		StarterPlayer:FindFirstChild("StarterCharacterScripts"),
		StarterGui,
	}
	local all = {}
	local seen = {}
	for _, r in ipairs(roots) do
		if r and not seen[r] then
			seen[r] = true
			table.insert(all, r)
			local okDesc, descList = pcall(function()
				return r:GetDescendants()
			end)
			if okDesc and type(descList) == "table" then
				for _, d in ipairs(descList) do
					if not seen[d] then
						seen[d] = true
						table.insert(all, d)
					end
				end
			end
		end
	end
	return all
end

local function collectWholeTrees(allObjs)
	local candidates = {}
	for _, obj in ipairs(allObjs) do
		if containsAnyKeyword(obj.Name, TARGET_TREE_KEYWORDS) then
			table.insert(candidates, obj)
		end
	end

	local wholeTrees = {}
	for _, cand in ipairs(candidates) do
		local insideExisting = false
		for _, chosen in ipairs(wholeTrees) do
			local okAnc, isDesc = pcall(function()
				return cand:IsDescendantOf(chosen)
			end)
			if okAnc and isDesc then
				insideExisting = true
				break
			end
		end
		if not insideExisting then
			table.insert(wholeTrees, cand)
		end
	end
	return wholeTrees
end

local function buildWholeTreeLines(rootObj)
	local linesOut = {}

	local function walk(node, depth, prefix, isLast)
		local branch = (depth == 0) and "" or (isLast and "└── " or "├── ")
		local meta = ""
		pcall(function()
			if node:IsA("Tool") then
				meta = " | TextureId=" .. tostring(node.TextureId)
			elseif node:IsA("Decal") or node:IsA("Texture") then
				meta = " | Texture=" .. tostring(node.Texture)
			elseif node:IsA("MeshPart") then
				meta = " | MeshId=" .. tostring(node.MeshId)
			elseif node:IsA("SpecialMesh") then
				meta = " | MeshId=" .. tostring(node.MeshId) .. " | TextureId=" .. tostring(node.TextureId)
			elseif node:IsA("ImageLabel") or node:IsA("ImageButton") then
				meta = " | Image=" .. tostring(node.Image)
			end
		end)

		local attrsStr = formatAttributes(node)
		table.insert(linesOut, string.format("%s%s[%s] %s%s%s", prefix, branch, node.ClassName, node.Name, meta, attrsStr))

		local okCh, children = pcall(function()
			return node:GetChildren()
		end)
		if okCh and type(children) == "table" then
			local nextPrefix = (depth == 0) and "" or (prefix .. (isLast and "    " or "│   "))
			for i, ch in ipairs(children) do
				walk(ch, depth + 1, nextPrefix, i == #children)
			end
		end
	end

	walk(rootObj, 0, "", true)
	return linesOut
end

local function logChunkedText(tag, prefixHeader, bigText)
	local chunkSize = 1500
	local str = tostring(bigText or "")
	if #str <= chunkSize then
		LogEvent(tag, prefixHeader .. str)
		return
	end
	local part = 0
	for i = 1, #str, chunkSize do
		part += 1
		LogEvent(tag, string.format("%s [part %d]\n%s", prefixHeader, part, string.sub(str, i, i + chunkSize - 1)))
	end
end

local function logOnceSignature(tag, msg)
	local sig = tostring(tag) .. "::" .. tostring(msg)
	if not loggedScanSignatures[sig] then
		loggedScanSignatures[sig] = true
		LogEvent(tag, msg)
	end
end

local function runTreesAndScriptsScan(isAutoTick)
	local allObjs = collectAllClientRoots()
	local wholeTrees = collectWholeTrees(allObjs)
	local allReadableScripts = {}
	local fullReportLines = {}

	table.insert(fullReportLines, "=================================================================")
	table.insert(fullReportLines, "WHOLE TREES DUMP (Sync, Item, Inventory, Module, Moduls) + SCRIPTS")
	table.insert(fullReportLines, "Player: " .. player.Name .. " | Time: " .. os.date("%Y-%m-%d %H:%M:%S"))
	table.insert(fullReportLines, "=================================================================")
	table.insert(fullReportLines, "")

	for _, obj in ipairs(allObjs) do
		if isReadableClientScript(obj) then
			local src, method, isReal = readClientScriptSource(obj)
			table.insert(allReadableScripts, {
				Instance = obj,
				Path = safeFullName(obj),
				ClassName = obj.ClassName,
				Source = src,
				Method = method,
				IsReal = isReal
			})
		end
	end

	local summaryMsg = string.format("Целых деревьев: %d | Клиентских скриптов: %d", #wholeTrees, #allReadableScripts)
	table.insert(fullReportLines, summaryMsg)
	table.insert(fullReportLines, "")

	if not isAutoTick then
		LogEvent("FULL_TREE", summaryMsg)
	else
		logOnceSignature("FULL_TREE", summaryMsg)
	end

	for idx, rootObj in ipairs(wholeTrees) do
		local pathStr = safeFullName(rootObj)
		local descCount = 0
		local okD, descList = pcall(function()
			return rootObj:GetDescendants()
		end)
		if okD and type(descList) == "table" then
			descCount = #descList
		end

		local treeHeader = string.format("════ ЦЕЛОЕ ДЕРЕВО #%d: %s [%s] (Узлов внутри: %d) ════", idx, pathStr, rootObj.ClassName, descCount)
		table.insert(fullReportLines, treeHeader)
		if not isAutoTick then
			LogEvent("FULL_TREE", treeHeader)
		else
			logOnceSignature("FULL_TREE", treeHeader)
		end

		local treeLines = buildWholeTreeLines(rootObj)
		for _, tLine in ipairs(treeLines) do
			table.insert(fullReportLines, tLine)
			if not isAutoTick then
				LogEvent("FULL_TREE", tLine)
			else
				logOnceSignature("FULL_TREE", pathStr .. " :: " .. tLine)
			end
		end

		local innerScripts = {}
		if isReadableClientScript(rootObj) then
			table.insert(innerScripts, rootObj)
		end
		if okD and type(descList) == "table" then
			for _, d in ipairs(descList) do
				if isReadableClientScript(d) then
					table.insert(innerScripts, d)
				end
			end
		end

		for sIdx, scr in ipairs(innerScripts) do
			local scrPath = safeFullName(scr)
			local src, method, isReal = readClientScriptSource(scr)
			local innerLine = string.format("[Tree#%d -> Script#%d] (%s via %s | readable=%s) %s", idx, sIdx, scr.ClassName, method, tostring(isReal), scrPath)
			table.insert(fullReportLines, innerLine)
			table.insert(fullReportLines, "--- SCRIPT CODE START ---")
			table.insert(fullReportLines, src)
			table.insert(fullReportLines, "--- SCRIPT CODE END ---")

			if not isAutoTick then
				LogEvent("TREE_SCRIPT", innerLine)
				LogEvent("SCRIPT_PATH", innerLine)
				logChunkedText("SCRIPT_SRC", "=== CODE: " .. scrPath .. " ===\n", src)
			else
				logOnceSignature("TREE_SCRIPT", innerLine)
				logOnceSignature("SCRIPT_PATH", innerLine)
				logOnceSignature("SCRIPT_SRC", scrPath .. "|" .. src)
			end
		end

		table.insert(fullReportLines, "")
	end

	table.insert(fullReportLines, string.format("=== ALL CLIENT SCRIPTS (%d) ===", #allReadableScripts))
	local readableCount = 0

	for i, entry in ipairs(allReadableScripts) do
		if entry.IsReal then
			readableCount += 1
		end
		local pathLine = string.format("#%d [%s | %s | readable=%s] %s", i, entry.ClassName, entry.Method, tostring(entry.IsReal), entry.Path)
		table.insert(fullReportLines, pathLine)
		if not isAutoTick then
			LogEvent("SCRIPT_PATH", pathLine)
		else
			logOnceSignature("SCRIPT_PATH", pathLine)
		end

		if entry.IsReal then
			table.insert(fullReportLines, "--- SOURCE START ---")
			table.insert(fullReportLines, entry.Source)
			table.insert(fullReportLines, "--- SOURCE END ---")
			if not isAutoTick then
				logChunkedText("SCRIPT_SRC", string.format("=== SOURCE #%d: %s ===\n", i, entry.Path), entry.Source)
			else
				logOnceSignature("SCRIPT_SRC", entry.Path .. "|" .. entry.Source)
			end
		end
	end

	lastFullDumpText = table.concat(fullReportLines, "\n")

	if not isAutoTick then
		if type(writefile) == "function" then
			pcall(writefile, "MM2_Whole_Trees_Dump_" .. tostring(os.time()) .. ".txt", lastFullDumpText)
		end
		copyToClipboard(lastFullDumpText, "WholeTrees")
		LogEvent("FULL_TREE", string.format("Готово! Целых деревьев: %d | Читаемых скриптов: %d/%d.", #wholeTrees, readableCount, #allReadableScripts))
	end
end

local function setAutoTreeScan(state)
	autoTreeScanEnabled = state
	TreeScanBtn.Text = state and "Scan0.2:ON" or "TreeScan"
	TreeScanBtn.BackgroundColor3 = state and Color3.fromRGB(38, 155, 90) or Color3.fromRGB(95, 55, 165)

	if state then
		table.clear(loggedScanSignatures)
		runTreesAndScriptsScan(false)
		if not autoTreeScanThread then
			autoTreeScanThread = task.spawn(function()
				while autoTreeScanEnabled do
					task.wait(0.2)
					if autoTreeScanEnabled and scanEnabled then
						runTreesAndScriptsScan(true)
					end
				end
				autoTreeScanThread = nil
			end)
		end
	end
end

TreeScanBtn.MouseButton1Click:Connect(function()
	setAutoTreeScan(not autoTreeScanEnabled)
end)

-- Автоподсветка ролей через Highlight
local playerRoles = {}
local highlights = {}

local function getRoleColor(role)
	if role == "Murderer" then
		return Color3.fromRGB(255, 50, 50)
	elseif role == "Sheriff" then
		return Color3.fromRGB(55, 145, 255)
	else
		return Color3.fromRGB(65, 215, 110)
	end
end

local function removeHighlight(nick)
	local hl = highlights[nick]
	if hl then
		pcall(function()
			hl:Destroy()
		end)
		highlights[nick] = nil
	end
end

local function applyHighlightForNick(nick)
	removeHighlight(nick)
	local info = playerRoles[nick]
	if not info or not info.Role or info.Dead == true then
		return
	end

	local plr = Players:FindFirstChild(nick)
	local char = plr and plr.Character
	if not char or not char.Parent then
		return
	end

	local color = getRoleColor(info.Role)
	local hl = Instance.new("Highlight")
	hl.Name = "RoleEspHighlight"
	hl.FillColor = color
	hl.OutlineColor = color
	hl.FillTransparency = 0.65
	hl.OutlineTransparency = 0.1
	hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	hl.Adornee = char
	hl.Parent = char
	highlights[nick] = hl
end

local function refreshAllHighlights()
	for nick in pairs(playerRoles) do
		applyHighlightForNick(nick)
	end
end

for _, plr in ipairs(Players:GetPlayers()) do
	plr.CharacterAdded:Connect(function()
		task.defer(applyHighlightForNick, plr.Name)
	end)
	plr.CharacterRemoving:Connect(function()
		removeHighlight(plr.Name)
	end)
end

Players.PlayerAdded:Connect(function(plr)
	plr.CharacterAdded:Connect(function()
		task.defer(applyHighlightForNick, plr.Name)
	end)
	plr.CharacterRemoving:Connect(function()
		removeHighlight(plr.Name)
	end)
end)

Players.PlayerRemoving:Connect(function(plr)
	playerRoles[plr.Name] = nil
	removeHighlight(plr.Name)
end)

local lastRoleSummary = ""
local function tryLogPlayerRoles(remoteName, ...)
	local foundEntries = {}
	local seenNicks = {}
	local updatedAny = false

	local function scanTable(tbl)
		if type(tbl) ~= "table" then
			return
		end
		for k, v in pairs(tbl) do
			if type(v) == "table" then
				local nick = v.PlayerName or v.Name or (type(k) == "string" and k) or nil
				local role = v.Role
				if nick and role then
					local nickStr = tostring(nick)
					local roleStr = tostring(role)
					local isDead = (v.Dead == true)
					playerRoles[nickStr] = { Role = roleStr, Dead = isDead }
					updatedAny = true

					if not seenNicks[nickStr] then
						seenNicks[nickStr] = true
						local deadTag = isDead and " [DEAD]" or ""
						table.insert(foundEntries, string.format("%s - %s%s", nickStr, roleStr, deadTag))
					end
				end
			end
		end
	end

	for i = 1, select("#", ...) do
		local arg = select(i, ...)
		if type(arg) == "table" then
			scanTable(arg)
		end
	end

	if updatedAny then
		refreshAllHighlights()
	end

	if #foundEntries > 0 then
		table.sort(foundEntries)
		local summary = table.concat(foundEntries, " | ")
		if summary ~= lastRoleSummary then
			lastRoleSummary = summary
			LogEvent("ROLE_LIST", string.format("(%s) %s", tostring(remoteName), summary))
		end
	elseif remoteName == "RoleSelect" then
		local myRole = select(1, ...)
		if myRole ~= nil then
			local nickStr = tostring(player.Name)
			local roleStr = tostring(myRole)
			playerRoles[nickStr] = { Role = roleStr, Dead = false }
			refreshAllHighlights()

			local singleSummary = string.format("%s - %s", nickStr, roleStr)
			if singleSummary ~= lastRoleSummary then
				lastRoleSummary = singleSummary
				LogEvent("ROLE_LIST", string.format("(RoleSelect) %s", singleSummary))
			end
		end
	end
end

local function getCombatSnapshot(...)
	local info = {}
	local cam = Workspace.CurrentCamera
	if cam then
		local cp = cam.CFrame.Position
		local cl = cam.CFrame.LookVector
		table.insert(info, string.format("CamPos=(%.2f,%.2f,%.2f) CamLook=(%.3f,%.3f,%.3f)", cp.X, cp.Y, cp.Z, cl.X, cl.Y, cl.Z))
	end

	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if hrp and hrp:IsA("BasePart") then
		local hp = hrp.Position
		local hl = hrp.CFrame.LookVector
		table.insert(info, string.format("HRP=(%.2f,%.2f,%.2f) HRPLook=(%.3f,%.3f,%.3f)", hp.X, hp.Y, hp.Z, hl.X, hl.Y, hl.Z))
	end

	return table.concat(info, " | ")
end

local hookedRemotes = {}
local hookedBindables = {}

local function hookRemoteEvent(rem)
	if not rem:IsA("RemoteEvent") or hookedRemotes[rem] then
		return
	end
	hookedRemotes[rem] = true
	watchAttributes(rem, "REM_ATTR")
	rem.OnClientEvent:Connect(function(...)
		if not scanEnabled then
			return
		end
		local fullName = safeFullName(rem)
		LogEvent("OnClientEvent", string.format("%s%s | Args: %s", fullName, formatAttributes(rem), formatArgs(...)))
		tryLogPlayerRoles(rem.Name, ...)
	end)
end

local function hookBindableEvent(bind)
	if not bind:IsA("BindableEvent") or hookedBindables[bind] then
		return
	end
	hookedBindables[bind] = true
	watchAttributes(bind, "BIND_ATTR")
	bind.Event:Connect(function(...)
		if not scanEnabled then
			return
		end
		LogEvent("BindableEvent", string.format("%s%s | Args: %s", safeFullName(bind), formatAttributes(bind), formatArgs(...)))
	end)
end

for _, obj in ipairs(game:GetDescendants()) do
	if obj:IsA("RemoteEvent") then
		hookRemoteEvent(obj)
	elseif obj:IsA("BindableEvent") then
		hookBindableEvent(obj)
	end
end

game.DescendantAdded:Connect(function(obj)
	if obj:IsA("RemoteEvent") then
		hookRemoteEvent(obj)
	elseif obj:IsA("BindableEvent") then
		hookBindableEvent(obj)
	end
end)

FilterBox:GetPropertyChangedSignal("Text"):Connect(refreshLogs)

BottomCopyBtn.MouseButton1Click:Connect(function()
	if #logs == 0 and #lastFullDumpText == 0 then
		notifyStatus("Nothing to copy")
		return
	end
	if #lastFullDumpText > 0 and FilterBox.Text == "" then
		copyToClipboard(lastFullDumpText, "FullDump")
		return
	end
	local allLines = table.create(#logs)
	for i, item in ipairs(logs) do
		allLines[i] = item.RawText
	end
	copyToClipboard(table.concat(allLines, "\n"), "All")
end)

CopyBtn.MouseButton1Click:Connect(function()
	local visibleLines = {}
	for _, item in ipairs(logs) do
		if item.Button.Visible then
			table.insert(visibleLines, item.RawText)
		end
	end
	if #visibleLines == 0 then
		notifyStatus("Nothing to copy")
		return
	end
	copyToClipboard(table.concat(visibleLines, "\n"), "Filtered")
end)

ClearBtn.MouseButton1Click:Connect(function()
	for _, item in ipairs(logs) do
		if item.Button then
			item.Button:Destroy()
		end
	end
	table.clear(logs)
	lastFullDumpText = ""
	lastRoleSummary = ""
end)

PulseBtn.MouseButton1Click:Connect(function()
	pulseEnabled = not pulseEnabled
	PulseBtn.Text = pulseEnabled and "Pulse:ON" or "Pulse:OFF"
	PulseBtn.BackgroundColor3 = pulseEnabled
		and Color3.fromRGB(165, 95, 25)
		or Color3.fromRGB(65, 65, 85)
end)

ScanBtn.MouseButton1Click:Connect(function()
	scanEnabled = not scanEnabled
	ScanBtn.Text = scanEnabled and "Scan:ON" or "Scan:OFF"
	ScanBtn.BackgroundColor3 = scanEnabled
		and Color3.fromRGB(38, 125, 75)
		or Color3.fromRGB(115, 45, 45)
end)

local minimized = false
ToggleBtn.MouseButton1Click:Connect(function()
	minimized = not minimized
	FilterBox.Visible = not minimized
	Scroll.Visible = not minimized
	BottomCopyBtn.Visible = not minimized
	TreeScanBtn.Visible = not minimized
	PulseBtn.Visible = not minimized
	ScanBtn.Visible = not minimized
	CopyBtn.Visible = not minimized
	ClearBtn.Visible = not minimized
	MainFrame.Size = minimized
		and UDim2.new(0.55, 0, 0, 32)
		or UDim2.new(0.94, 0, 0.5, 0)
	ToggleBtn.Text = minimized and "Max" or "Min"
end)

task.spawn(function()
	while true do
		task.wait(1.5)
		if scanEnabled and pulseEnabled then
			LogEvent("PULSE", getCombatSnapshot())
		end
	end
end)

if typeof(hookmetamethod) == "function" and typeof(getnamecallmethod) == "function" then
	local oldNamecall
	oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
		local method = getnamecallmethod()
		if not checkcaller() and typeof(self) == "Instance" then
			if (method == "FireServer" or method == "InvokeServer") and (self:IsA("RemoteEvent") or self:IsA("RemoteFunction")) then
				watchAttributes(self, "REM_ATTR")
				local fullName = safeFullName(self)
				task.defer(LogEvent, method, string.format("%s%s | Args: %s", fullName, formatAttributes(self), formatArgs(...)))
			elseif method == "Fire" and self:IsA("BindableEvent") then
				watchAttributes(self, "BIND_ATTR")
				local fullName = safeFullName(self)
				task.defer(LogEvent, "Bindable:Fire", string.format("%s%s | Args: %s", fullName, formatAttributes(self), formatArgs(...)))
			end
		end
		return oldNamecall(self, ...)
	end)
end

LogEvent("INIT", "MobileOmniLogger запущен. Нажми TreeScan для скана целых деревьев каждые 0.2с.")
