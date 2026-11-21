-- Scan (Crash-safe copy + chunks + manual select fallback)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local StarterGui = game:GetService("StarterGui")
local StarterPlayer = game:GetService("StarterPlayer")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local Chat = game:GetService("Chat")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

local SEARCH_QUERIES = {
	"Inventory",
	"Item",
	"NewItem",
	"Modules",
	"MainGUI",
	"PlayerGui",
	"Claime",
	"Box",
}

local CHUNK_SIZE = 25000
local MAX_SCRIPT_CHARS = 15000

local function getScanRoots()
	local roots = {
		ReplicatedStorage,
		ReplicatedFirst,
		StarterGui,
		StarterPlayer,
		Workspace,
		Lighting,
		SoundService,
		Chat,
	}
	if LocalPlayer then
		local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
		if pg then
			table.insert(roots, 1, pg)
		end
	end
	return roots
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
	elseif #parts == 0 then
		return "[nil] " .. inst.Name
	end
	return table.concat(parts, ".")
end

local function isScriptInstance(inst)
	return inst:IsA("LocalScript") or inst:IsA("ModuleScript") or inst:IsA("Script")
end

local function trimText(str, maxLen, suffixNote)
	if type(str) ~= "string" then return "" end
	if #str <= maxLen then return str end
	return string.sub(str, 1, maxLen) .. (suffixNote or "\n... [Обрезано]")
end

local function splitIntoChunks(text, chunkSize)
	if type(text) ~= "string" or #text == 0 then
		return { "" }
	end
	local chunks = {}
	local len = #text
	for i = 1, len, chunkSize do
		table.insert(chunks, string.sub(text, i, math.min(i + chunkSize - 1, len)))
	end
	return chunks
end

local function tryExecutorClipboard(text)
	if type(text) ~= "string" or #text == 0 then
		return false
	end
	local safeStr = string.sub(text, 1, CHUNK_SIZE)
	if typeof(setclipboard) == "function" then
		local ok = pcall(setclipboard, safeStr)
		if ok then return true end
	end
	if typeof(toclipboard) == "function" then
		local ok = pcall(toclipboard, safeStr)
		if ok then return true end
	end
	return false
end

local function serializeValue(val, depth, seenTables)
	depth = depth or 0
	seenTables = seenTables or {}
	local t = typeof(val)

	if t == "string" then
		return string.format("%q", val)
	elseif t == "number" or t == "boolean" then
		return tostring(val)
	elseif t == "nil" then
		return "nil"
	elseif t == "Instance" then
		return getFullPath(val) .. " [" .. val.ClassName .. "]"
	elseif t == "table" then
		if depth >= 2 then
			return "{ ... }"
		end
		if seenTables[val] then
			return "{ ... (цикл) }"
		end
		seenTables[val] = true

		local parts = {}
		local count = 0
		for k, v in pairs(val) do
			count += 1
			if count > 20 then
				table.insert(parts, "  ... (ещё ключи)")
				break
			end
			local keyStr = (type(k) == "string") and k or ("[" .. tostring(k) .. "]")
			table.insert(parts, string.rep("  ", depth + 1) .. keyStr .. " = " .. serializeValue(v, depth + 1, seenTables))
		end
		seenTables[val] = nil

		if #parts == 0 then
			return "{}"
		end
		return "{\n" .. table.concat(parts, "\n") .. "\n" .. string.rep("  ", depth) .. "}"
	end

	return tostring(val) .. " (" .. t .. ")"
end

local function getScriptContent(scr)
	if typeof(decompile) == "function" then
		local ok, res = pcall(decompile, scr)
		if ok and type(res) == "string" and #res > 0 then
			return trimText(res, MAX_SCRIPT_CHARS, "\n-- [Код обрезан]")
		end
	end

	local okSrc, src = pcall(function()
		return scr.Source
	end)
	if okSrc and type(src) == "string" and #src > 0 then
		return trimText(src, MAX_SCRIPT_CHARS, "\n-- [Source обрезан]")
	end

	if scr:IsA("ModuleScript") and typeof(require) == "function" then
		local okReq, modData = pcall(require, scr)
		if okReq then
			local serialized = serializeValue(modData, 0, {})
			return trimText("-- [Returned from require]\n" .. serialized, MAX_SCRIPT_CHARS, "\n-- [Таблица обрезана]")
		end
	end

	return "-- [Внутренность скрипта недоступна]"
end

local function formatScriptBlock(scr, index, prefix)
	local bodyText = getScriptContent(scr)
	return string.format(
		"--- [%s #%d] %s (Имя: %s | Тип: %s) ---\n%s\n",
		prefix or "SCRIPT",
		index or 1,
		getFullPath(scr),
		scr.Name,
		scr.ClassName,
		bodyText
	)
end

local function getScriptsInsideTree(rootInst)
	local found = {}
	local seen = {}

	if isScriptInstance(rootInst) and not seen[rootInst] then
		seen[rootInst] = true
		table.insert(found, rootInst)
	end

	local okDesc, descList = pcall(function()
		return rootInst:GetDescendants()
	end)
	if okDesc and descList then
		for _, desc in ipairs(descList) do
			if isScriptInstance(desc) and not seen[desc] then
				seen[desc] = true
				table.insert(found, desc)
			end
		end
	end

	return found
end

local function dumpFullTree(rootInst)
	local out = {}

	local function walk(node, indent)
		local okCh, children = pcall(function()
			return node:GetChildren()
		end)
		if not okCh or not children then return end

		for i, ch in ipairs(children) do
			local isLast = (i == #children)
			local branch = isLast and "└─ " or "├─ "
			table.insert(out, indent .. branch .. ch.Name .. " [" .. ch.ClassName .. "]")
			walk(ch, indent .. (isLast and "   " or "│  "))
		end
	end

	table.insert(out, "+ [" .. rootInst.Name .. "] " .. getFullPath(rootInst) .. " (" .. rootInst.ClassName .. ")")
	walk(rootInst, "")

	local treeScripts = getScriptsInsideTree(rootInst)
	if #treeScripts > 0 then
		table.insert(out, "\n[Скрипты в этом дереве: " .. #treeScripts .. "]")
		for idx, scr in ipairs(treeScripts) do
			table.insert(out, formatScriptBlock(scr, idx, "IN TREE"))
		end
	else
		table.insert(out, "[Скрипты в этом дереве: 0]")
	end

	return table.concat(out, "\n")
end

local function searchByQueries()
	local resultsByQuery = {}
	local allFoundTrees = {}
	local databaseNodes = {}
	local modulesNodes = {}
	local seenGlobalTree = {}
	local seenDb = {}
	local seenMod = {}

	local candidates = {}
	local seenCand = {}

	local function addCandidate(inst)
		if typeof(inst) ~= "Instance" or seenCand[inst] then return end
		seenCand[inst] = true
		table.insert(candidates, inst)

		local okName, name = pcall(function() return inst.Name end)
		if okName and type(name) == "string" then
			local lower = string.lower(name)
			if lower == "database" and not seenDb[inst] then
				seenDb[inst] = true
				table.insert(databaseNodes, inst)
			end
			if lower == "modules" and not seenMod[inst] then
				seenMod[inst] = true
				table.insert(modulesNodes, inst)
			end
		end
	end

	for _, root in ipairs(getScanRoots()) do
		if root then
			addCandidate(root)
			local okDesc, descList = pcall(function() return root:GetDescendants() end)
			if okDesc and descList then
				for _, desc in ipairs(descList) do
					addCandidate(desc)
				end
			end
		end
	end

	if typeof(getnilinstances) == "function" then
		local okNil, nilList = pcall(getnilinstances)
		if okNil and type(nilList) == "table" then
			for _, inst in ipairs(nilList) do
				addCandidate(inst)
			end
		end
	end

	for _, query in ipairs(SEARCH_QUERIES) do
		local qLower = string.lower(query)
		local matches = {}

		for _, inst in ipairs(candidates) do
			local okName, name = pcall(function() return inst.Name end)
			if okName and type(name) == "string" then
				if string.find(string.lower(name), qLower, 1, true) then
					table.insert(matches, inst)
					if not seenGlobalTree[inst] then
						seenGlobalTree[inst] = true
						table.insert(allFoundTrees, inst)
					end
				end
			end
		end

		table.insert(resultsByQuery, {
			query = query,
			matches = matches,
		})
	end

	return resultsByQuery, allFoundTrees, databaseNodes, modulesNodes
end

local function collectScriptsWithContents(nodes, labelPrefix)
	local blocks = {}
	local seen = {}
	local total = 0

	local function processScript(scr)
		if not isScriptInstance(scr) or seen[scr] then return end
		seen[scr] = true
		total += 1
		table.insert(blocks, formatScriptBlock(scr, total, labelPrefix))
	end

	for _, node in ipairs(nodes) do
		processScript(node)
		local okDesc, descList = pcall(function() return node:GetDescendants() end)
		if okDesc and descList then
			for _, desc in ipairs(descList) do
				processScript(desc)
			end
		end
	end

	if total == 0 then
		return "! Скрипты не найдены (" .. labelPrefix .. ")"
	end

	table.insert(blocks, 1, "=== " .. labelPrefix .. " | Всего скриптов: " .. total .. " ===\n")
	return table.concat(blocks, "\n")
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
	mainPanel.Size = UDim2.new(0.62, 0, 0.76, 0)
	mainPanel.Position = UDim2.new(0.36, 0, 0.12, 0)
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
	scroll.Size = UDim2.new(1, 0, 1, -84)
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
	outBox.Text = "Нажми кнопку сверху. Для копирования без вылета используй «Выделить» или «След. кусок»."
	outBox.TextXAlignment = Enum.TextXAlignment.Left
	outBox.TextYAlignment = Enum.TextYAlignment.Top
	outBox.MultiLine = true
	outBox.ClearTextOnFocus = false
	outBox.TextEditable = false
	outBox.Font = Enum.Font.Code
	outBox.TextSize = 11
	outBox.TextWrapped = true
	outBox.Parent = scroll

	-- Нижняя панель: Выделить / След. кусок / Копировать
	local bottomBar = Instance.new("Frame")
	bottomBar.Size = UDim2.new(1, 0, 0, 38)
	bottomBar.Position = UDim2.new(0, 0, 1, -38)
	bottomBar.BackgroundTransparency = 1
	bottomBar.Parent = body

	local selectBtn = Instance.new("TextButton")
	selectBtn.Size = UDim2.new(0.26, -3, 1, 0)
	selectBtn.Position = UDim2.new(0, 0, 0, 0)
	selectBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 56)
	selectBtn.Text = "Выделить"
	selectBtn.TextColor3 = Color3.fromRGB(240, 240, 248)
	selectBtn.Font = Enum.Font.GothamBold
	selectBtn.TextSize = 11
	selectBtn.Parent = bottomBar
	Instance.new("UICorner", selectBtn).CornerRadius = UDim.new(0, 6)

	local nextChunkBtn = Instance.new("TextButton")
	nextChunkBtn.Size = UDim2.new(0.28, -3, 1, 0)
	nextChunkBtn.Position = UDim2.new(0.26, 2, 0, 0)
	nextChunkBtn.BackgroundColor3 = Color3.fromRGB(36, 36, 46)
	nextChunkBtn.Text = "Кусок 1/1"
	nextChunkBtn.TextColor3 = Color3.fromRGB(220, 220, 235)
	nextChunkBtn.Font = Enum.Font.GothamBold
	nextChunkBtn.TextSize = 11
	nextChunkBtn.Parent = bottomBar
	Instance.new("UICorner", nextChunkBtn).CornerRadius = UDim.new(0, 6)

	local copyBtn = Instance.new("TextButton")
	copyBtn.Size = UDim2.new(0.46, 0, 1, 0)
	copyBtn.Position = UDim2.new(0.54, 2, 0, 0)
	copyBtn.BackgroundColor3 = Color3.fromRGB(24, 118, 224)
	copyBtn.Text = "Скопировать кусок"
	copyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	copyBtn.Font = Enum.Font.GothamBold
	copyBtn.TextSize = 12
	copyBtn.Parent = bottomBar
	Instance.new("UICorner", copyBtn).CornerRadius = UDim.new(0, 6)

	local chunks = { "" }
	local chunkIndex = 1

	local function renderCurrentChunk()
		local currentText = chunks[chunkIndex] or ""
		if #currentText > 120000 then
			currentText = string.sub(currentText, 1, 120000)
		end
		outBox.Text = currentText
		nextChunkBtn.Text = string.format("Кусок %d/%d", chunkIndex, #chunks)

		local lineCount = select(2, string.gsub(currentText, "\n", "\n")) + 1
		local estWrappedLines = math.ceil(#currentText / 55)
		local totalLines = math.max(lineCount, estWrappedLines)
		local height = math.max(220, totalLines * 15 + 32)
		outBox.Size = UDim2.new(1, -12, 0, height)
		scroll.CanvasSize = UDim2.new(0, 0, 0, height + 16)
		scroll.CanvasPosition = Vector2.new(0, 0)
	end

	local function setOutput(str)
		chunks = splitIntoChunks(str or "", CHUNK_SIZE)
		chunkIndex = 1
		renderCurrentChunk()
	end

	btnTrees.MouseButton1Click:Connect(function()
		local resultsByQuery = searchByQueries()
		local parts = {}

		for _, entry in ipairs(resultsByQuery) do
			table.insert(parts, "=== ПОИСК: " .. entry.query .. " (" .. #entry.matches .. ") ===")
			for _, treeInst in ipairs(entry.matches) do
				table.insert(parts, dumpFullTree(treeInst))
				table.insert(parts, "")
			end
		end

		setOutput(table.concat(parts, "\n"))
	end)

	btnAllTreeScripts.MouseButton1Click:Connect(function()
		local _, allFoundTrees = searchByQueries()
		setOutput(collectScriptsWithContents(allFoundTrees, "TREE SCRIPT"))
	end)

	btnDbScripts.MouseButton1Click:Connect(function()
		local _, _, dbNodes = searchByQueries()
		setOutput(collectScriptsWithContents(dbNodes, "DATABASE"))
	end)

	btnModScripts.MouseButton1Click:Connect(function()
		local _, _, _, modNodes = searchByQueries()
		setOutput(collectScriptsWithContents(modNodes, "MODULES"))
	end)

	nextChunkBtn.MouseButton1Click:Connect(function()
		if #chunks > 1 then
			chunkIndex = (chunkIndex % #chunks) + 1
			renderCurrentChunk()
		end
	end)

	selectBtn.MouseButton1Click:Connect(function()
		outBox.TextEditable = true
		outBox:CaptureFocus()
		selectBtn.Text = "Выделено"
		task.delay(2, function()
			if outBox and outBox.Parent then
				outBox.TextEditable = false
			end
			if selectBtn and selectBtn.Parent then
				selectBtn.Text = "Выделить"
			end
		end)
	end)

	copyBtn.MouseButton1Click:Connect(function()
		local textToCopy = chunks[chunkIndex] or outBox.Text
		task.spawn(function()
			local ok = tryExecutorClipboard(textToCopy)
			if copyBtn and copyBtn.Parent then
				copyBtn.Text = ok and ("Кусок " .. chunkIndex .. " скопирован!") or "Нажми «Выделить»"
				copyBtn.BackgroundColor3 = ok and Color3.fromRGB(30, 155, 85) or Color3.fromRGB(165, 45, 55)
			end
			task.wait(1.2)
			if copyBtn and copyBtn.Parent then
				copyBtn.Text = "Скопировать кусок"
				copyBtn.BackgroundColor3 = Color3.fromRGB(24, 118, 224)
			end
		end)
	end)

	local minimized = false
	minBtn.MouseButton1Click:Connect(function()
		minimized = not minimized
		body.Visible = not minimized
		minBtn.Text = minimized and "^" or "V"
		mainPanel.Size = minimized and UDim2.new(0.62, 0, 0, 34) or UDim2.new(0.62, 0, 0.76, 0)
	end)
end

buildUI()
