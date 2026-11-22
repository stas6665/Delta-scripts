local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local GUI_NAME = "ScanNewItemGui"
if playerGui:FindFirstChild(GUI_NAME) then
	playerGui[GUI_NAME]:Destroy()
end

local NAME_TARGETS = {
	"newitem",
	"claimed",
	"claim",
	"inventory2",
	"inventory",
}

local lastTreeReport = ""
local copyChunks = {}
local nextChunkIndex = 1
local isScanning = false
local scanToken = 0

local function matchByName(inst)
	if not inst then
		return nil
	end
	local nameStr = tostring(inst.Name or "")
	if nameStr == "" then
		return nil
	end
	local low = string.lower(nameStr)
	for _, term in ipairs(NAME_TARGETS) do
		if string.find(low, term, 1, true) then
			return term
		end
	end
	return nil
end

local function safePath(inst)
	local ok, res = pcall(function()
		return inst:GetFullName()
	end)
	return ok and tostring(res) or tostring(inst.Name)
end

local function formatNode(inst, tag)
	local extra = ""
	if inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox") then
		extra = string.format(" | Text=%q | Visible=%s", tostring(inst.Text), tostring(inst.Visible))
	elseif inst:IsA("ImageLabel") or inst:IsA("ImageButton") then
		extra = string.format(" | Image=%q | Visible=%s", tostring(inst.Image), tostring(inst.Visible))
	elseif inst:IsA("GuiObject") then
		extra = string.format(" | Visible=%s", tostring(inst.Visible))
	elseif inst:IsA("ValueBase") then
		extra = string.format(" | Value=%s", tostring(inst.Value))
	end

	local okAttrs, attrs = pcall(function()
		return inst:GetAttributes()
	end)
	if okAttrs and type(attrs) == "table" then
		local list = {}
		for k, v in pairs(attrs) do
			table.insert(list, tostring(k) .. "=" .. tostring(v))
		end
		if #list > 0 then
			table.sort(list)
			extra = extra .. " | Attrs={" .. table.concat(list, ", ") .. "}"
		end
	end

	return string.format("    %sPath: %s | Class: %s | Name: %q%s", tag or "", safePath(inst), inst.ClassName, tostring(inst.Name), extra)
end

local function dumpModuleValue(val, indent, depth, visited, outLines)
	if depth > 4 then
		table.insert(outLines, indent .. "<max depth>")
		return
	end
	if type(val) ~= "table" then
		local s = tostring(val)
		if #s > 300 then
			s = string.sub(s, 1, 300) .. "..."
		end
		table.insert(outLines, string.format("%s(%s) %s", indent, typeof(val), s))
		return
	end
	if visited[val] then
		table.insert(outLines, indent .. "<circular>")
		return
	end
	visited[val] = true

	local keys = {}
	for k in pairs(val) do
		table.insert(keys, k)
	end
	table.sort(keys, function(a, b)
		return tostring(a) < tostring(b)
	end)

	for _, k in ipairs(keys) do
		local v = val[k]
		local kStr = tostring(k)
		if type(v) == "table" then
			table.insert(outLines, string.format("%s[%s] = {", indent, kStr))
			dumpModuleValue(v, indent .. "  ", depth + 1, visited, outLines)
			table.insert(outLines, indent .. "}")
		else
			local vStr = (type(v) == "string") and string.format("%q", v) or tostring(v)
			if #vStr > 250 then
				vStr = string.sub(vStr, 1, 250) .. "..."
			end
			table.insert(outLines, string.format("%s[%s] = %s", indent, kStr, vStr))
		end
	end

	visited[val] = nil
end

local function dumpScriptInsideTree(scr, outLines)
	if not scr:IsA("LuaSourceContainer") then
		return
	end

	table.insert(outLines, string.format("      [SCRIPT] Path: %s | Class: %s", safePath(scr), scr.ClassName))

	if type(decompile) == "function" then
		local okDec, src = pcall(decompile, scr)
		if okDec and type(src) == "string" and src ~= "" then
			if #src > 14000 then
				src = string.sub(src, 1, 14000) .. "\n-- ...<обрезано для защиты памяти>..."
			end
			table.insert(outLines, "      --- DECOMPILE START ---")
			for line in string.gmatch(src .. "\n", "(.-)\r?\n") do
				table.insert(outLines, "        " .. line)
			end
			table.insert(outLines, "      --- DECOMPILE END ---")
		else
			table.insert(outLines, "      [decompile пропущен/ошибка: " .. tostring(src) .. "]")
		end
	else
		table.insert(outLines, "      [функция decompile недоступна]")
	end

	if scr:IsA("ModuleScript") then
		local okReq, mod = pcall(require, scr)
		if okReq and mod ~= nil then
			table.insert(outLines, "      --- MODULE REQUIRE START ---")
			dumpModuleValue(mod, "        ", 1, {}, outLines)
			table.insert(outLines, "      --- MODULE REQUIRE END ---")
		end
	end
end

local function dumpWholeTreeAndScripts(rootInst, outLines, seen, token, includeScripts)
	if not rootInst or seen[rootInst] or token ~= scanToken then
		return
	end
	seen[rootInst] = true

	local ok, desc = pcall(function()
		return rootInst:GetDescendants()
	end)
	desc = (ok and type(desc) == "table") and desc or {}

	local scriptsInTree = {}
	if rootInst:IsA("LuaSourceContainer") then
		table.insert(scriptsInTree, rootInst)
	end
	for _, child in ipairs(desc) do
		if child:IsA("LuaSourceContainer") then
			table.insert(scriptsInTree, child)
		end
	end

	table.insert(outLines, formatNode(rootInst, "[ROOT] "))
	if rootInst:IsA("LuaSourceContainer") and includeScripts then
		dumpScriptInsideTree(rootInst, outLines)
	end

	table.insert(outLines, string.format("    --- ВСЕ ОБЪЕКТЫ ДЕРЕВА (%d) ---", #desc))
	for i, child in ipairs(desc) do
		if token ~= scanToken then
			return
		end
		if i % 400 == 0 then
			task.wait()
		end
		if not seen[child] then
			seen[child] = true
			table.insert(outLines, formatNode(child, "[CHILD] "))
		end
	end

	if #scriptsInTree > 0 then
		table.insert(outLines, string.format("    --- ВСЕ СКРИПТЫ В ДЕРЕВЕ (%d) ---", #scriptsInTree))
		for _, scr in ipairs(scriptsInTree) do
			if token ~= scanToken then
				return
			end
			if includeScripts then
				dumpScriptInsideTree(scr, outLines)
			else
				table.insert(outLines, string.format("      [SCRIPT FOUND] %s (%s)", safePath(scr), scr.ClassName))
			end
		end
	end
end

local function scanRootByName(root, rootLabel, outLines, seen, token, includeScripts)
	if not root or token ~= scanToken then
		return 0
	end

	local ok, desc = pcall(function()
		return root:GetDescendants()
	end)
	if not ok or type(desc) ~= "table" then
		table.insert(outLines, string.format("-- %s: ошибка GetDescendants --", rootLabel))
		return 0
	end

	local foundTrees = 0
	local ownGui = playerGui:FindFirstChild(GUI_NAME)

	for i, inst in ipairs(desc) do
		if token ~= scanToken then
			return foundTrees
		end
		if i % 400 == 0 then
			task.wait()
		end

		if inst.Name ~= GUI_NAME and not (ownGui and inst:IsDescendantOf(ownGui)) and not seen[inst] then
			local matchedName = matchByName(inst)
			if matchedName then
				foundTrees += 1
				table.insert(
					outLines,
					string.format(
						"  [%s | NAME:%s] ДЕРЕВО: %s",
						rootLabel,
						string.upper(matchedName),
						safePath(inst)
					)
				)
				dumpWholeTreeAndScripts(inst, outLines, seen, token, includeScripts)
			end
		end
	end

	table.insert(outLines, string.format("-- %s: найдено деревьев по имени %d --", rootLabel, foundTrees))
	return foundTrees
end

local function runNameTreesScan(onProgress, includeScripts)
	scanToken += 1
	local myToken = scanToken
	local lines = {
		"=== BY NAME WHOLE TREES: NewItem, Claim, Claimed, Inventory, Inventory2 ===",
	}
	local seen = {}
	local totalTrees = 0

	local roots = {
		{ playerGui, "PlayerGui" },
		{ StarterGui, "StarterGui" },
		{ ReplicatedStorage, "ReplicatedStorage" },
	}

	for idx, entry in ipairs(roots) do
		if myToken ~= scanToken then
			return "", 0
		end
		if onProgress then
			onProgress(string.format("Ищу деревья по имени в %s (%d/%d)...", entry[2], idx, #roots))
		end
		totalTrees += scanRootByName(entry[1], entry[2], lines, seen, myToken, includeScripts)
		task.wait()
	end

	table.insert(lines, 2, "Всего найдено деревьев по названиям: " .. tostring(totalTrees))
	table.insert(lines, 3, "Всего строк в дампе: " .. tostring(#lines))
	return table.concat(lines, "\n"), totalTrees
end

local function prepareChunks(reportText)
	copyChunks = {}
	nextChunkIndex = 1
	if not reportText or reportText == "" then
		return
	end

	local CHUNK_SIZE = 50000
	local totalParts = math.ceil(#reportText / CHUNK_SIZE)
	for part = 1, totalParts do
		local startPos = (part - 1) * CHUNK_SIZE + 1
		local endPos = math.min(part * CHUNK_SIZE, #reportText)
		local piece = string.format(
			"[ЧАСТЬ %d/%d]\n%s",
			part,
			totalParts,
			string.sub(reportText, startPos, endPos)
		)
		table.insert(copyChunks, piece)
	end
end

local function copyNextChunk()
	if #copyChunks == 0 then
		return false, "Сначала нажми «начать сканирование»"
	end

	local idx = nextChunkIndex
	local piece = copyChunks[idx]
	nextChunkIndex += 1
	if nextChunkIndex > #copyChunks then
		nextChunkIndex = 1
	end

	if type(setclipboard) == "function" then
		local ok = pcall(setclipboard, piece)
		if ok then
			return true, string.format(
				"Скопирована часть %d/%d (%d симв.). Вставь в заметки/чат и нажми ещё раз для следующей части.",
				idx,
				#copyChunks,
				#piece
			)
		end
	end

	print(piece)
	return false, string.format("setclipboard недоступен — часть %d/%d выведена в консоль", idx, #copyChunks)
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = GUI_NAME
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 326, 0, 324)
mainFrame.Position = UDim2.new(0.5, -163, 0.14, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 19)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui

Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 10)
local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(220, 175, 45)
mainStroke.Thickness = 1.5
mainStroke.Parent = mainFrame

local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 34)
topBar.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
topBar.BorderSizePixel = 0
topBar.Parent = mainFrame
Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 10)

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -76, 1, 0)
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "scan NewItem"
titleLabel.TextColor3 = Color3.fromRGB(255, 215, 90)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 14
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = topBar

local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 28, 0, 24)
minBtn.Position = UDim2.new(1, -64, 0.5, -12)
minBtn.BackgroundColor3 = Color3.fromRGB(38, 38, 48)
minBtn.Text = "-"
minBtn.TextColor3 = Color3.fromRGB(235, 235, 245)
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 16
minBtn.Parent = topBar
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 6)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 28, 0, 24)
closeBtn.Position = UDim2.new(1, -32, 0.5, -12)
closeBtn.BackgroundColor3 = Color3.fromRGB(155, 38, 52)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 13
closeBtn.Parent = topBar
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

local bodyFrame = Instance.new("Frame")
bodyFrame.Size = UDim2.new(1, -16, 1, -42)
bodyFrame.Position = UDim2.new(0, 8, 0, 38)
bodyFrame.BackgroundTransparency = 1
bodyFrame.Parent = mainFrame

local startScanBtn = Instance.new("TextButton")
startScanBtn.Size = UDim2.new(0.68, -4, 0, 34)
startScanBtn.Position = UDim2.new(0, 0, 0, 0)
startScanBtn.BackgroundColor3 = Color3.fromRGB(210, 155, 25)
startScanBtn.Text = "начать сканирование"
startScanBtn.TextColor3 = Color3.fromRGB(15, 15, 19)
startScanBtn.Font = Enum.Font.GothamBold
startScanBtn.TextSize = 12
startScanBtn.Parent = bodyFrame
Instance.new("UICorner", startScanBtn).CornerRadius = UDim.new(0, 7)

local scriptsToggleBtn = Instance.new("TextButton")
scriptsToggleBtn.Size = UDim2.new(0.32, -4, 0, 34)
scriptsToggleBtn.Position = UDim2.new(0.68, 4, 0, 0)
scriptsToggleBtn.BackgroundColor3 = Color3.fromRGB(92, 62, 195)
scriptsToggleBtn.Text = "Скрипты: ON"
scriptsToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
scriptsToggleBtn.Font = Enum.Font.GothamBold
scriptsToggleBtn.TextSize = 11
scriptsToggleBtn.Parent = bodyFrame
Instance.new("UICorner", scriptsToggleBtn).CornerRadius = UDim.new(0, 7)

local copyTreeBtn = Instance.new("TextButton")
copyTreeBtn.Size = UDim2.new(1, 0, 0, 34)
copyTreeBtn.Position = UDim2.new(0, 0, 0, 40)
copyTreeBtn.BackgroundColor3 = Color3.fromRGB(36, 118, 86)
copyTreeBtn.Text = "скопировать все в буфер из дерева"
copyTreeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
copyTreeBtn.Font = Enum.Font.GothamBold
copyTreeBtn.TextSize = 12
copyTreeBtn.Parent = bodyFrame
Instance.new("UICorner", copyTreeBtn).CornerRadius = UDim.new(0, 7)

local resultBox = Instance.new("TextBox")
resultBox.Size = UDim2.new(1, 0, 1, -80)
resultBox.Position = UDim2.new(0, 0, 0, 80)
resultBox.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
resultBox.TextColor3 = Color3.fromRGB(190, 255, 210)
resultBox.Text = "Копирует отчёт частями по 50000 символов."
resultBox.TextWrapped = true
resultBox.MultiLine = true
resultBox.TextEditable = false
resultBox.ClearTextOnFocus = false
resultBox.TextXAlignment = Enum.TextXAlignment.Left
resultBox.TextYAlignment = Enum.TextYAlignment.Top
resultBox.Font = Enum.Font.Code
resultBox.TextSize = 10
resultBox.Parent = bodyFrame
Instance.new("UICorner", resultBox).CornerRadius = UDim.new(0, 7)

local includeScripts = true
scriptsToggleBtn.MouseButton1Click:Connect(function()
	includeScripts = not includeScripts
	scriptsToggleBtn.Text = includeScripts and "Скрипты: ON" or "Скрипты: OFF"
	scriptsToggleBtn.BackgroundColor3 = includeScripts and Color3.fromRGB(92, 62, 195) or Color3.fromRGB(52, 52, 66)
end)

startScanBtn.MouseButton1Click:Connect(function()
	if isScanning then
		scanToken += 1
		isScanning = false
		startScanBtn.Text = "начать сканирование"
		resultBox.TextColor3 = Color3.fromRGB(255, 215, 110)
		resultBox.Text = "Сканирование остановлено"
		return
	end

	isScanning = true
	startScanBtn.Text = "стоп"
	resultBox.TextColor3 = Color3.fromRGB(255, 220, 120)
	resultBox.Text = "Сканирую деревья по названиям..."

	task.spawn(function()
		local ok, report, total = pcall(function()
			return runNameTreesScan(function(msg)
				resultBox.Text = msg
			end, includeScripts)
		end)

		isScanning = false
		startScanBtn.Text = "начать сканирование"

		if not ok then
			resultBox.TextColor3 = Color3.fromRGB(255, 110, 120)
			resultBox.Text = "Ошибка сканирования: " .. tostring(report)
			return
		end

		lastTreeReport = report
		getgenv().LastNameTreesReport = report
		prepareChunks(report)

		resultBox.TextColor3 = Color3.fromRGB(190, 255, 210)
		resultBox.Text = string.format(
			"Готово! Деревьев: %d | Частей (по 50000): %d\n\n%s",
			total,
			#copyChunks,
			string.sub(report, 1, 700)
		)
	end)
end)

copyTreeBtn.MouseButton1Click:Connect(function()
	local ok, msg = copyNextChunk()
	resultBox.TextColor3 = ok and Color3.fromRGB(140, 255, 195) or Color3.fromRGB(255, 215, 110)
	resultBox.Text = msg
end)

local minimized = false
minBtn.MouseButton1Click:Connect(function()
	minimized = not minimized
	bodyFrame.Visible = not minimized
	mainFrame.Size = minimized and UDim2.new(0, 326, 0, 34) or UDim2.new(0, 326, 0, 324)
	minBtn.Text = minimized and "+" or "-"
end)

closeBtn.MouseButton1Click:Connect(function()
	scanToken += 1
	screenGui:Destroy()
end)

do
	local dragging = false
	local dragInput, dragStart, startPos

	topBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = mainFrame.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	topBar.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - dragStart
			mainFrame.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end
	end)
end
