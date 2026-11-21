-- Scan (Tree & Scripts Dumper)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local StarterPlayer = game:GetService("StarterPlayer")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

local TREE_TARGETS = {
	"Inventory",
	"Item",
	"NewItem",
	"Modules",
	"MainGUI",
	"PlayerGui",
	"Claime",
}

local SCAN_ROOTS = {
	ReplicatedStorage,
	StarterGui,
	StarterPlayer,
	Workspace,
}

if LocalPlayer then
	local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
	if pg then
		table.insert(SCAN_ROOTS, 1, pg)
	end
end

local function getFullPath(inst)
	if not inst then return "nil" end
	local parts = {}
	local curr = inst
	while curr and curr ~= game do
		table.insert(parts, 1, curr.Name)
		curr = curr.Parent
	end
	if curr == game then
		table.insert(parts, 1, "game")
	end
	return table.concat(parts, ".")
end

local function isScriptInstance(inst)
	return inst:IsA("LocalScript") or inst:IsA("ModuleScript") or inst:IsA("Script")
end

local function copyToClipboard(text)
	if typeof(setclipboard) == "function" then
		pcall(setclipboard, text)
		return true
	elseif typeof(toclipboard) == "function" then
		pcall(toclipboard, text)
		return true
	end
	return false
end

local function dumpTreeLines(rootInst, maxDepth, maxLines)
	maxDepth = maxDepth or 3
	maxLines = maxLines or 45
	local out = {}
	local count = 0

	local function walk(node, depth, indent)
		if count >= maxLines then return end
		if depth > maxDepth then
			count += 1
			table.insert(out, indent .. "  ... (глубже)")
			return
		end
		local children = node:GetChildren()
		for i, ch in ipairs(children) do
			if count >= maxLines then
				table.insert(out, indent .. "  ... (лимит)")
				return
			end
			local branch = (i == #children) and "└─ " or "├─ "
			local clsTag = ""
			if ch:IsA("ModuleScript") then
				clsTag = " [ModuleScript]"
			elseif ch:IsA("LocalScript") then
				clsTag = " [LocalScript]"
			elseif ch:IsA("Script") then
				clsTag = " [Script]"
			end
			count += 1
			table.insert(out, indent .. branch .. ch.Name .. clsTag)
			walk(ch, depth + 1, indent .. ((i == #children) and "   " or "│  "))
		end
	end

	table.insert(out, "+ Дерево: " .. getFullPath(rootInst) .. " [" .. rootInst.ClassName .. "]")
	walk(rootInst, 1, "")
	return table.concat(out, "\n")
end

local function collectAllData()
	local targetLower = {}
	for _, name in ipairs(TREE_TARGETS) do
		targetLower[string.lower(name)] = name
	end

	local matchedTrees = {}
	local nearbyOrRelatedTrees = {}
	local databaseNodes = {}
	local modulesNodes = {}

	local seenTree = {}
	local seenRelated = {}
	local seenDb = {}
	local seenMod = {}

	local function inspectNode(inst)
		local lower = string.lower(inst.Name)

		if lower == "database" and not seenDb[inst] then
			seenDb[inst] = true
			table.insert(databaseNodes, inst)
		end

		if lower == "modules" and not seenMod[inst] then
			seenMod[inst] = true
			table.insert(modulesNodes, inst)
		end

		local exactTarget = targetLower[lower]
		if exactTarget and not seenTree[inst] then
			seenTree[inst] = true
			table.insert(matchedTrees, {
				target = exactTarget,
				inst = inst,
				path = getFullPath(inst),
			})

			if inst.Parent and inst.Parent ~= game and not seenRelated[inst.Parent] then
				seenRelated[inst.Parent] = true
				table.insert(nearbyOrRelatedTrees, {
					reason = "Parent of " .. inst.Name,
					inst = inst.Parent,
					path = getFullPath(inst.Parent),
				})
			end
			for _, ch in ipairs(inst:GetChildren()) do
				if #ch:GetChildren() > 0 and not targetLower[string.lower(ch.Name)] and not seenRelated[ch] then
					seenRelated[ch] = true
					table.insert(nearbyOrRelatedTrees, {
						reason = "Subtree in " .. inst.Name,
						inst = ch,
						path = getFullPath(ch),
					})
				end
			end
		elseif not exactTarget and not seenRelated[inst] then
			for _, tName in ipairs(TREE_TARGETS) do
				if string.find(lower, string.lower(tName), 1, true) then
					seenRelated[inst] = true
					table.insert(nearbyOrRelatedTrees, {
						reason = "Partial match (" .. tName .. ")",
						inst = inst,
						path = getFullPath(inst),
					})
					break
				end
			end
		end
	end

	for _, root in ipairs(SCAN_ROOTS) do
		if root then
			inspectNode(root)
			for _, desc in ipairs(root:GetDescendants()) do
				inspectNode(desc)
			end
		end
	end

	return matchedTrees, nearbyOrRelatedTrees, databaseNodes, modulesNodes
end

local function collectScriptsFromNodes(nodes, labelPrefix)
	local lines = {}
	local seen = {}
	local total = 0

	for _, node in ipairs(nodes) do
		for _, desc in ipairs(node:GetDescendants()) do
			if isScriptInstance(desc) and not seen[desc] then
				seen[desc] = true
				total += 1
				table.insert(lines, string.format("+ [%s] %s [%s]", labelPrefix, getFullPath(desc), desc.ClassName))
			end
		end
	end

	if total == 0 then
		table.insert(lines, "! Скрипты не найдены (" .. labelPrefix .. ")")
	else
		table.insert(lines, 1, "=== " .. labelPrefix .. " | Всего скриптов: " .. total .. " ===")
	end

	return table.concat(lines, "\n")
end

local function buildUI()
	local parentGui = nil
	pcall(function()
		if typeof(gethui) == "function" then
			parentGui = gethui()
		end
	end)
	if not parentGui then
		parentGui = CoreGui
	end
	if not parentGui and LocalPlayer then
		parentGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
	end

	local old = parentGui and parentGui:FindFirstChild("Scan")
	if old then old:Destroy() end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "Scan"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = parentGui

	local mainPanel = Instance.new("Frame")
	mainPanel.Name = "MainPanel"
	mainPanel.Size = UDim2.new(0.56, 0, 0.72, 0)
	mainPanel.Position = UDim2.new(0.42, 0, 0.16, 0)
	mainPanel.BackgroundColor3 = Color3.fromRGB(16, 16, 18)
	mainPanel.BackgroundTransparency = 0.05
	mainPanel.BorderSizePixel = 0
	mainPanel.Active = true
	mainPanel.Draggable = true
	mainPanel.Parent = screenGui
	Instance.new("UICorner", mainPanel).CornerRadius = UDim.new(0, 6)

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(45, 45, 52)
	stroke.Thickness = 1
	stroke.Parent = mainPanel

	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0, 34)
	header.BackgroundColor3 = Color3.fromRGB(22, 22, 25)
	header.BorderSizePixel = 0
	header.Parent = mainPanel
	Instance.new("UICorner", header).CornerRadius = UDim.new(0, 6)

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -46, 1, 0)
	title.Position = UDim2.new(0, 12, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "Scan"
	title.TextColor3 = Color3.fromRGB(235, 235, 240)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Font = Enum.Font.GothamBold
	title.TextSize = 13
	title.Parent = header

	local minBtn = Instance.new("TextButton")
	minBtn.Size = UDim2.new(0, 30, 0, 26)
	minBtn.Position = UDim2.new(1, -36, 0.5, -13)
	minBtn.BackgroundColor3 = Color3.fromRGB(32, 32, 38)
	minBtn.Text = "V"
	minBtn.TextColor3 = Color3.fromRGB(235, 235, 240)
	minBtn.Font = Enum.Font.GothamBold
	minBtn.TextSize = 12
	minBtn.Parent = header
	Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 4)

	local body = Instance.new("Frame")
	body.Size = UDim2.new(1, -16, 1, -44)
	body.Position = UDim2.new(0, 8, 0, 38)
	body.BackgroundTransparency = 1
	body.Parent = mainPanel

	local btnBar = Instance.new("Frame")
	btnBar.Size = UDim2.new(1, 0, 0, 30)
	btnBar.BackgroundTransparency = 1
	btnBar.Parent = body

	local function makeActionBtn(text, xScale, wScale)
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(wScale, -4, 1, 0)
		b.Position = UDim2.new(xScale, 2, 0, 0)
		b.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
		b.Text = text
		b.TextColor3 = Color3.fromRGB(235, 235, 240)
		b.TextTruncate = Enum.TextTruncate.AtEnd
		b.Font = Enum.Font.GothamBold
		b.TextSize = 10
		b.Parent = btnBar
		Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)
		local st = Instance.new("UIStroke")
		st.Color = Color3.fromRGB(55, 55, 65)
		st.Thickness = 1
		st.Parent = b
		return b
	end

	local btnTrees = makeActionBtn("Вывести деревья", 0, 0.25)
	local btnAllTreeScripts = makeActionBtn("Скрипты деревьев", 0.25, 0.25)
	local btnDbScripts = makeActionBtn("Скрипты Database", 0.50, 0.25)
	local btnModScripts = makeActionBtn("Скрипты Modules", 0.75, 0.25)

	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.new(1, 0, 1, -82)
	scroll.Position = UDim2.new(0, 0, 0, 36)
	scroll.BackgroundColor3 = Color3.fromRGB(12, 12, 14)
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 5
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.Parent = body
	Instance.new("UICorner", scroll).CornerRadius = UDim.new(0, 5)

	local outBox = Instance.new("TextBox")
	outBox.Size = UDim2.new(1, -12, 0, 200)
	outBox.Position = UDim2.new(0, 6, 0, 6)
	outBox.BackgroundTransparency = 1
	outBox.TextColor3 = Color3.fromRGB(220, 220, 228)
	outBox.Text = "Нажми одну из кнопок сверху, чтобы вывести деревья или скрипты."
	outBox.TextXAlignment = Enum.TextXAlignment.Left
	outBox.TextYAlignment = Enum.TextYAlignment.Top
	outBox.MultiLine = true
	outBox.ClearTextOnFocus = false
	outBox.TextEditable = false
	outBox.Font = Enum.Font.Code
	outBox.TextSize = 11
	outBox.TextWrapped = true
	outBox.Parent = scroll

	local copyBtn = Instance.new("TextButton")
	copyBtn.Size = UDim2.new(1, 0, 0, 38)
	copyBtn.Position = UDim2.new(0, 0, 1, -38)
	copyBtn.BackgroundColor3 = Color3.fromRGB(24, 118, 224)
	copyBtn.Text = "Скопировать в буфер"
	copyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	copyBtn.Font = Enum.Font.GothamBold
	copyBtn.TextSize = 13
	copyBtn.Parent = body
	Instance.new("UICorner", copyBtn).CornerRadius = UDim.new(0, 6)

	local function setOutput(str)
		outBox.Text = str
		local lineCount = select(2, string.gsub(str, "\n", "\n")) + 1
		local height = math.max(180, lineCount * 15 + 24)
		outBox.Size = UDim2.new(1, -12, 0, height)
		scroll.CanvasSize = UDim2.new(0, 0, 0, height + 12)
	end

	btnTrees.MouseButton1Click:Connect(function()
		local matched, related = collectAllData()
		local chunks = {}
		table.insert(chunks, "=== ЦЕЛЕВЫЕ ДЕРЕВЬЯ (" .. #matched .. ") ===")
		for _, item in ipairs(matched) do
			table.insert(chunks, dumpTreeLines(item.inst, 2, 25))
			table.insert(chunks, "")
		end

		table.insert(chunks, "=== СВЯЗАННЫЕ / БЕЗ ТОЧНОГО ИМЕНИ (" .. #related .. ") ===")
		for _, item in ipairs(related) do
			table.insert(chunks, "+ [" .. item.reason .. "] " .. item.path .. " [" .. item.inst.ClassName .. "]")
		end

		setOutput(table.concat(chunks, "\n"))
	end)

	btnAllTreeScripts.MouseButton1Click:Connect(function()
		local matched, related = collectAllData()
		local nodes = {}
		for _, item in ipairs(matched) do
			table.insert(nodes, item.inst)
		end
		for _, item in ipairs(related) do
			table.insert(nodes, item.inst)
		end
		setOutput(collectScriptsFromNodes(nodes, "TREE SCRIPT"))
	end)

	btnDbScripts.MouseButton1Click:Connect(function()
		local _, _, dbNodes = collectAllData()
		setOutput(collectScriptsFromNodes(dbNodes, "DATABASE"))
	end)

	btnModScripts.MouseButton1Click:Connect(function()
		local _, _, _, modNodes = collectAllData()
		setOutput(collectScriptsFromNodes(modNodes, "MODULES"))
	end)

	copyBtn.MouseButton1Click:Connect(function()
		local ok = copyToClipboard(outBox.Text)
		copyBtn.Text = ok and "Скопировано!" or "Буфер недоступен"
		copyBtn.BackgroundColor3 = ok and Color3.fromRGB(30, 155, 85) or Color3.fromRGB(165, 45, 55)
		task.delay(1.2, function()
			if copyBtn and copyBtn.Parent then
				copyBtn.Text = "Скопировать в буфер"
				copyBtn.BackgroundColor3 = Color3.fromRGB(24, 118, 224)
			end
		end)
	end)

	local minimized = false
	minBtn.MouseButton1Click:Connect(function()
		minimized = not minimized
		body.Visible = not minimized
		minBtn.Text = minimized and "^" or "V"
		mainPanel.Size = minimized and UDim2.new(0.56, 0, 0, 34) or UDim2.new(0.56, 0, 0.72, 0)
	end)
end

buildUI()
