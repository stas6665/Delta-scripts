local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local GUI_NAME = "ScanNewItemGui"
if playerGui:FindFirstChild(GUI_NAME) then
	playerGui[GUI_NAME]:Destroy()
end

local SEARCH_TERMS = {
	"box",
	"inventory",
	"newitem",
	"claim",
	"claimed",
	"itemtype",
	"itemname",
}

local lastTreeReport = ""
local isScanning = false

local function matchTerm(str)
	if type(str) ~= "string" or str == "" then
		return nil
	end
	local low = string.lower(str)
	for _, term in ipairs(SEARCH_TERMS) do
		if string.find(low, term, 1, true) then
			return term
		end
	end
	return nil
end

local function getExactPath(inst)
	local ok, full = pcall(function()
		return inst:GetFullName()
	end)
	if ok and type(full) == "string" then
		return full
	end
	return tostring(inst.Name)
end

local function formatRequiredValue(val, indent, depth, visited, outLines)
	indent = indent or "        "
	depth = depth or 1
	visited = visited or {}

	if depth > 4 then
		table.insert(outLines, indent .. "<max depth>")
		return
	end

	local t = typeof(val)
	if type(val) ~= "table" then
		local preview = tostring(val)
		if #preview > 300 then
			preview = string.sub(preview, 1, 300) .. "...<truncated>"
		end
		table.insert(outLines, string.format("%s(%s) %s", indent, t, preview))
		return
	end

	if visited[val] then
		table.insert(outLines, indent .. "<circular table>")
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
			formatRequiredValue(v, indent .. "  ", depth + 1, visited, outLines)
			table.insert(outLines, indent .. "}")
		else
			local valStr = (type(v) == "string") and string.format("%q", v) or tostring(v)
			if #valStr > 250 then
				valStr = string.sub(valStr, 1, 250) .. "...<truncated>"
			end
			table.insert(outLines, string.format("%s[%s] = %s", indent, kStr, valStr))
		end
	end

	visited[val] = nil
end

local function dumpScriptSource(scriptInst, outLines)
	if not scriptInst:IsA("LuaSourceContainer") then
		return
	end

	local exactPath = getExactPath(scriptInst)
	table.insert(outLines, string.format("      ========== SCRIPT: %s (%s) ==========", exactPath, scriptInst.ClassName))
	table.insert(outLines, "      ExactPath: " .. exactPath)

	local gotDecompile = false
	if type(decompile) == "function" then
		local okDec, src = pcall(decompile, scriptInst)
		if okDec and type(src) == "string" and src ~= "" then
			gotDecompile = true
			table.insert(outLines, "      --- DECOMPILED SOURCE START ---")
			for line in string.gmatch(src .. "\n", "(.-)\r?\n") do
				table.insert(outLines, "        " .. line)
			end
			table.insert(outLines, "      --- DECOMPILED SOURCE END ---")
		elseif okDec and type(src) == "string" then
			table.insert(outLines, "      [Decompile вернул пустую строку]")
		else
			table.insert(outLines, "      [Decompile ошибка/недоступно: " .. tostring(src) .. "]")
		end
	else
		table.insert(outLines, "      [Функция decompile отсутствует в окружении]")
	end

	if scriptInst:IsA("ModuleScript") then
		local okReq, modVal = pcall(require, scriptInst)
		if okReq and modVal ~= nil then
			table.insert(outLines, "      --- MODULE REQUIRE DATA START ---")
			formatRequiredValue(modVal, "        ", 1, {}, outLines)
			table.insert(outLines, "      --- MODULE REQUIRE DATA END ---")
		elseif not okReq then
			table.insert(outLines, "      [Require ошибка: " .. tostring(modVal) .. "]")
		end
	end

	if not gotDecompile and not scriptInst:IsA("ModuleScript") then
		table.insert(outLines, "      [Исходник скрипта недоступен на клиенте]")
	end
end

local function formatFullInstance(inst, prefix)
	local exactPath = getExactPath(inst)
	local parts = {
		string.format("%sPath: %s", prefix or "", exactPath),
		string.format("Class: %s", inst.ClassName),
		string.format("Name: %q", tostring(inst.Name)),
	}

	if inst.Parent then
		table.insert(parts, string.format("ParentPath: %s", getExactPath(inst.Parent)))
	end

	if inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox") then
		table.insert(parts, string.format("Text=%q", tostring(inst.Text)))
		table.insert(parts, "Visible=" .. tostring(inst.Visible))
	elseif inst:IsA("ImageLabel") or inst:IsA("ImageButton") then
		table.insert(parts, string.format("Image=%q", tostring(inst.Image)))
		table.insert(parts, "Visible=" .. tostring(inst.Visible))
	elseif inst:IsA("GuiObject") then
		table.insert(parts, "Visible=" .. tostring(inst.Visible))
	elseif inst:IsA("ValueBase") then
		table.insert(parts, "Value=" .. tostring(inst.Value))
	end

	local okAttrs, attrs = pcall(function()
		return inst:GetAttributes()
	end)
	if okAttrs and type(attrs) == "table" then
		local attrList = {}
		for ak, av in pairs(attrs) do
			table.insert(attrList, string.format("%s=%s", tostring(ak), tostring(av)))
		end
		if #attrList > 0 then
			table.sort(attrList)
			table.insert(parts, "Attrs={" .. table.concat(attrList, ", ") .. "}")
		end
	end

	return table.concat(parts, " | ")
end

local function dumpSubtreeWithScripts(rootInst, outLines, printedSet, stepCounter)
	if not rootInst or printedSet[rootInst] then
		return
	end

	local ok, descendants = pcall(function()
		return rootInst:GetDescendants()
	end)
	descendants = (ok and descendants) or {}

	local foundScripts = {}
	if rootInst:IsA("LuaSourceContainer") then
		table.insert(foundScripts, rootInst)
	end
	for _, child in ipairs(descendants) do
		if child:IsA("LuaSourceContainer") then
			table.insert(foundScripts, child)
		end
	end

	table.insert(outLines, "    --- ТОЧНЫЕ ПУТИ ВЕТКИ ---")
	table.insert(outLines, "      " .. getExactPath(rootInst) .. " (" .. rootInst.ClassName .. ")")
	for _, child in ipairs(descendants) do
		table.insert(outLines, "      " .. getExactPath(child) .. " (" .. child.ClassName .. ")")
	end

	if #foundScripts > 0 then
		table.insert(outLines, string.format("    --- СКРИПТЫ В ВЕТКЕ (%d) ---", #foundScripts))
		for _, scr in ipairs(foundScripts) do
			dumpScriptSource(scr, outLines)
		end
	end

	table.insert(outLines, "    --- ВСЕ ОБЪЕКТЫ ВЕТКИ ---")
	if not printedSet[rootInst] then
		printedSet[rootInst] = true
		table.insert(outLines, "      " .. formatFullInstance(rootInst, "[ROOT] "))
	end

	for i, child in ipairs(descendants) do
		if i % 250 == 0 then
			stepCounter.count += 1
			if stepCounter.count % 6 == 0 then
				task.wait()
			end
		end
		if not printedSet[child] then
			printedSet[child] = true
			table.insert(outLines, "      " .. formatFullInstance(child, "[CHILD] "))
		end
	end
end

local function scanServiceTree(root, rootLabel, outLines, printedSet, stepCounter)
	if not root then
		return 0
	end

	local ok, descendants = pcall(function()
		return root:GetDescendants()
	end)
	if not ok or not descendants then
		return 0
	end

	local matches = 0
	local ownGui = playerGui:FindFirstChild(GUI_NAME)

	for i, inst in ipairs(descendants) do
		if i % 250 == 0 then
			stepCounter.count += 1
			if stepCounter.count % 6 == 0 then
				task.wait()
			end
		end

		if inst.Name ~= GUI_NAME and not (ownGui and inst:IsDescendantOf(ownGui)) then
			local hitTerm = matchTerm(inst.Name)
			if not hitTerm and (inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox")) then
				hitTerm = matchTerm(inst.Text)
			end

			if hitTerm then
				matches += 1
				table.insert(
					outLines,
					string.format(
						"  [%s | TERM:%s] Точный путь: %s",
						rootLabel,
						string.upper(hitTerm),
						getExactPath(inst)
					)
				)
				dumpSubtreeWithScripts(inst, outLines, printedSet, stepCounter)
			end
		end
	end

	table.insert(outLines, string.format("-- %s: совпадений %d --", rootLabel, matches))
	return matches
end

local function buildAllTreesReport(onProgress)
	local outLines = {
		"=== FULL TREES + SCRIPTS DUMP: Box, Inventory, NewItem, Claim, Claimed, ItemType, ItemName ===",
	}
	local printedSet = {}
	local stepCounter = { count = 0 }
	local totalMatches = 0

	local roots = {
		{ playerGui, "PlayerGui" },
		{ StarterGui, "StarterGui" },
		{ ReplicatedStorage, "ReplicatedStorage" },
		{ Workspace, "Workspace" },
	}

	local okCore, coreGui = pcall(function()
		return game:GetService("CoreGui")
	end)
	if okCore and coreGui then
		table.insert(roots, { coreGui, "CoreGui" })
	end

	for idx, entry in ipairs(roots) do
		if onProgress then
			onProgress(string.format("Сканирую деревья и скрипты в %s (%d/%d)...", entry[2], idx, #roots))
		end
		totalMatches += scanServiceTree(entry[1], entry[2], outLines, printedSet, stepCounter)
		task.wait()
	end

	table.insert(outLines, 2, "Всего совпадений (с точными путями, деревьями и скриптами): " .. tostring(totalMatches))
	table.insert(outLines, 3, "Всего строк в дампе: " .. tostring(#outLines))
	return table.concat(outLines, "\n"), totalMatches, #outLines
end

local function copyReportToClipboard(reportText)
	if not reportText or reportText == "" then
		return false, "Сначала нажми «начать сканирование»"
	end

	if type(setclipboard) == "function" then
		local ok = pcall(setclipboard, reportText)
		if ok then
			return true, string.format("Скопировано в буфер: %d симв.", #reportText)
		end
	end

	local CHUNK = 3500
	for i = 1, #reportText, CHUNK do
		print(string.sub(reportText, i, i + CHUNK - 1))
	end
	return false, "setclipboard недоступен — весь дамп выведен в консоль"
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = GUI_NAME
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 326, 0, 314)
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
startScanBtn.Size = UDim2.new(1, 0, 0, 34)
startScanBtn.Position = UDim2.new(0, 0, 0, 0)
startScanBtn.BackgroundColor3 = Color3.fromRGB(210, 155, 25)
startScanBtn.Text = "начать сканирование"
startScanBtn.TextColor3 = Color3.fromRGB(15, 15, 19)
startScanBtn.Font = Enum.Font.GothamBold
startScanBtn.TextSize = 13
startScanBtn.Parent = bodyFrame

Instance.new("UICorner", startScanBtn).CornerRadius = UDim.new(0, 7)

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
resultBox.Text = "Показывает точные пути, полные деревья и внутренность найденных скриптов"
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

startScanBtn.MouseButton1Click:Connect(function()
	if isScanning then
		return
	end
	isScanning = true
	startScanBtn.Text = "сканирование..."
	resultBox.TextColor3 = Color3.fromRGB(255, 220, 120)
	resultBox.Text = "Сканирую деревья и выгружаю скрипты..."

	task.spawn(function()
		local report, totalMatches, totalLines = buildAllTreesReport(function(progressMsg)
			resultBox.Text = progressMsg
		end)
		lastTreeReport = report
		getgenv().LastAllTreesDump = report

		isScanning = false
		startScanBtn.Text = "начать сканирование"
		resultBox.TextColor3 = Color3.fromRGB(190, 255, 210)
		resultBox.Text = string.format(
			"Готово! Совпадений: %d | Строк: %d\n\n%s",
			totalMatches,
			totalLines,
			string.sub(report, 1, 900)
		)
	end)
end)

copyTreeBtn.MouseButton1Click:Connect(function()
	local ok, msg = copyReportToClipboard(lastTreeReport)
	resultBox.TextColor3 = ok and Color3.fromRGB(140, 255, 195) or Color3.fromRGB(255, 215, 110)
	resultBox.Text = msg .. (lastTreeReport ~= "" and ("\n\n" .. string.sub(lastTreeReport, 1, 750)) or "")
end)

local minimized = false
minBtn.MouseButton1Click:Connect(function()
	minimized = not minimized
	bodyFrame.Visible = not minimized
	mainFrame.Size = minimized and UDim2.new(0, 326, 0, 34) or UDim2.new(0, 326, 0, 314)
	minBtn.Text = minimized and "+" or "-"
end)

closeBtn.MouseButton1Click:Connect(function()
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
