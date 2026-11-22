local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local StarterPack = game:GetService("StarterPack")
local StarterPlayer = game:GetService("StarterPlayer")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local DEFAULT_KEYWORDS = {
	"Inventory",
	"NewItem",
	"Claim",
	"Claimed",
	"TextName",
	"Button",
	"Item",
	"MainGUI",
	"PlayerGui",
	"StarterPlayer",
	"StarterPack",
}

local SIMILAR_MAP = {
	inventory = { "inv", "inventory", "inventory2", "weapons", "items", "backpack", "bag", "storage", "container", "vault", "locker" },
	newitem = { "newitem", "itempopup", "popup", "drop", "unbox", "case", "crate", "reward", "received", "gift" },
	claim = { "claim", "claimed", "redeem", "collect", "take", "accept", "confirm", "ok", "close" },
	claimed = { "claimed", "claim", "redeemed", "collected", "taken" },
	textname = { "textname", "itemname", "weaponname", "name", "title", "label", "text", "header" },
	button = { "button", "btn", "textbutton", "imagebutton", "guibutton", "click", "trigger" },
	item = { "item", "items", "itemframe", "weapon", "weapons", "card", "slot", "entry", "sync", "itemservice", "tool", "tools" },
	maingui = { "maingui", "main", "gui", "screengui", "gamegui", "game", "hud", "menu", "interface", "ui" },
	playergui = { "playergui", "player", "gui", "screengui", "startergui", "clientgui", "ui" },
	starterplayer = { "starterplayer", "starterplayerscripts", "startercharacterscripts", "player", "playerscripts", "characterscripts", "client" },
	starterpack = { "starterpack", "backpack", "tool", "tools", "weapon", "weapons", "gear", "item", "items" },
}

local CHUNK_LIMIT = 160000
local MAX_TOTAL_LINES = 8000
local MAX_TREE_DEPTH = 25

local lastReportText = "-- Нажми Scan All для поиска всех деревьев и объектов --"
local reportChunks = {}
local currentChunkIndex = 1

local function splitIntoChunks(text, limit)
	local chunks = {}
	local str = tostring(text or "")
	local len = #str
	if len == 0 then
		return { "" }
	end

	local pos = 1
	while pos <= len do
		local rawEnd = math.min(pos + limit - 1, len)
		local cutEnd = rawEnd

		if rawEnd < len then
			local searchStart = math.max(pos, rawEnd - 4000)
			local sub = string.sub(str, searchStart, rawEnd)
			local lastNewline = string.match(sub, ".*()\n")
			if lastNewline then
				cutEnd = searchStart + lastNewline - 1
			end
		end

		table.insert(chunks, string.sub(str, pos, cutEnd))
		pos = cutEnd + 1
	end

	return chunks
end

local function rebuildChunks()
	reportChunks = splitIntoChunks(lastReportText, CHUNK_LIMIT)
	if #reportChunks == 0 then
		reportChunks = { "" }
	end
	currentChunkIndex = 1
end

local function copyChunkByIndex(index)
	if type(setclipboard) ~= "function" then
		return false, "setclipboard недоступен"
	end

	if #reportChunks == 0 then
		rebuildChunks()
	end

	local total = #reportChunks
	local idx = ((index - 1) % total) + 1
	currentChunkIndex = idx

	local header = string.format("=== PART %d/%d (limit %d) ===\n", idx, total, CHUNK_LIMIT)
	local payload = header .. reportChunks[idx]

	local ok = pcall(function()
		setclipboard(payload)
	end)

	if ok then
		local nextIdx = (idx % total) + 1
		return true, string.format("Скопировано %d/%d (%d симв.). Далее: %d/%d", idx, total, #payload, nextIdx, total)
	end
	return false, "Ошибка при копировании части " .. tostring(idx)
end

local function safePath(inst)
	local ok, res = pcall(function()
		return inst:GetFullName()
	end)
	return ok and res or tostring(inst)
end

local function safeChildren(inst)
	local ok, ch = pcall(function()
		return inst:GetChildren()
	end)
	return (ok and type(ch) == "table") and ch or {}
end

local function trim(s)
	return string.match(tostring(s or ""), "^%s*(.-)%s*$") or ""
end

local function splitQueries(rawInput)
	local cleaned = trim(rawInput)
	if cleaned == "" then
		return DEFAULT_KEYWORDS
	end
	local list = {}
	for part in string.gmatch(cleaned, "[^,;]+") do
		local p = trim(part)
		if p ~= "" then
			table.insert(list, p)
		end
	end
	if #list == 0 then
		return DEFAULT_KEYWORDS
	end
	return list
end

local function buildExpandedTokens(queryList)
	local tokens = {}
	local seen = {}

	local function addToken(tok)
		local t = string.lower(trim(tok))
		if t ~= "" and not seen[t] then
			seen[t] = true
			table.insert(tokens, t)
		end
	end

	for _, q in ipairs(queryList) do
		local ql = string.lower(q)
		addToken(ql)

		for word in string.gmatch(ql, "[%a%d]+") do
			addToken(word)
		end

		if SIMILAR_MAP[ql] then
			for _, sim in ipairs(SIMILAR_MAP[ql]) do
				addToken(sim)
			end
		end

		for key, sims in pairs(SIMILAR_MAP) do
			if string.find(ql, key, 1, true) or string.find(key, ql, 1, true) then
				addToken(key)
				for _, sim in ipairs(sims) do
					addToken(sim)
				end
			end
		end
	end

	return tokens
end

local function getInstanceText(inst)
	local ok, txt = pcall(function()
		if inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox") then
			return inst.Text
		end
		return ""
	end)
	return ok and tostring(txt or "") or ""
end

local function getInstanceImage(inst)
	local ok, img = pcall(function()
		if inst:IsA("ImageLabel") or inst:IsA("ImageButton") then
			return inst.Image
		end
		return ""
	end)
	return ok and tostring(img or "") or ""
end

local function isSimilarMatch(inst, tokens)
	local nameL = string.lower(tostring(inst.Name or ""))
	local classL = string.lower(tostring(inst.ClassName or ""))
	local pathL = string.lower(safePath(inst))
	local textL = string.lower(getInstanceText(inst))

	for _, tok in ipairs(tokens) do
		if #tok >= 2 then
			if string.find(nameL, tok, 1, true)
				or string.find(classL, tok, 1, true)
				or string.find(pathL, tok, 1, true)
				or (textL ~= "" and string.find(textL, tok, 1, true))
			then
				return true, tok
			end
		end
	end
	return false, nil
end

local function formatObjectDetails(inst)
	local parts = { "[" .. inst.ClassName .. "]", inst.Name }

	local txt = getInstanceText(inst)
	if txt ~= "" then
		local singleLine = string.gsub(txt, "[\r\n]+", " ")
		if #singleLine > 60 then
			singleLine = string.sub(singleLine, 1, 60) .. "..."
		end
		table.insert(parts, 'Text="' .. singleLine .. '"')
	end

	local img = getInstanceImage(inst)
	if img ~= "" then
		table.insert(parts, 'Img="' .. img .. '"')
	end

	if inst:IsA("GuiObject") then
		table.insert(parts, "Vis=" .. tostring(inst.Visible))
	end

	return table.concat(parts, " | ")
end

local function dumpFullSubtree(rootInst, lines, maxDepth)
	local function walk(cur, depth)
		if #lines >= MAX_TOTAL_LINES or depth > maxDepth then return end
		local indent = string.rep("  ", depth)
		table.insert(lines, indent .. "- " .. formatObjectDetails(cur))
		for _, ch in ipairs(safeChildren(cur)) do
			if #lines >= MAX_TOTAL_LINES then break end
			walk(ch, depth + 1)
		end
	end

	table.insert(lines, ">>> ДЕРЕВО ЦЕЛИКОМ: " .. safePath(rootInst) .. " (" .. rootInst.ClassName .. ")")
	for _, ch in ipairs(safeChildren(rootInst)) do
		if #lines >= MAX_TOTAL_LINES then break end
		walk(ch, 1)
	end
end

local function runMegaScanner(rawQueries, onProgress)
	local queryList = splitQueries(rawQueries)
	local tokens = buildExpandedTokens(queryList)

	local lines = {
		"MEGA ALL-OBJECTS & FULL-TREES SCANNER",
		"Запросы: " .. table.concat(queryList, ", "),
		"Схожие токены (" .. #tokens .. "): " .. table.concat(tokens, ", "),
		"Время: " .. os.date("%H:%M:%S"),
		"========================================",
	}

	local roots = {
		PlayerGui,
		ReplicatedStorage,
		StarterGui,
		StarterPack,
		StarterPlayer,
	}

	local matchedTreeRoots = {}
	local seenMatched = {}

	local framesAll, labelsAll, boxesAll, buttonsAll, imagesAll, otherAll = {}, {}, {}, {}, {}, {}
	local totalVisited = 0

	local function scanNode(inst, depth)
		if depth > MAX_TREE_DEPTH then return end
		totalVisited += 1
		if totalVisited % 350 == 0 then
			if onProgress then
				onProgress("Проверено объектов: " .. totalVisited .. "...")
			end
			task.wait()
		end

		local matched, matchedTok = isSimilarMatch(inst, tokens)
		if matched and not seenMatched[inst] then
			seenMatched[inst] = true
			table.insert(matchedTreeRoots, { inst = inst, tok = matchedTok })
		end

		if matched then
			local info = formatObjectDetails(inst) .. "  -->  " .. safePath(inst)
			if inst:IsA("Frame") or inst:IsA("ScrollingFrame") or inst:IsA("CanvasGroup") or inst:IsA("ViewportFrame") then
				table.insert(framesAll, info)
			elseif inst:IsA("TextLabel") then
				table.insert(labelsAll, info)
			elseif inst:IsA("TextBox") then
				table.insert(boxesAll, info)
			elseif inst:IsA("GuiButton") or inst:IsA("TextButton") or inst:IsA("ImageButton") then
				table.insert(buttonsAll, info)
			elseif inst:IsA("ImageLabel") then
				table.insert(imagesAll, info)
			else
				table.insert(otherAll, info)
			end
		end

		for _, ch in ipairs(safeChildren(inst)) do
			scanNode(ch, depth + 1)
		end
	end

	for _, r in ipairs(roots) do
		if r then
			scanNode(r, 1)
		end
	end

	table.insert(lines, "")
	table.insert(lines, "=== НАЙДЕННЫЕ ДЕРЕВЬЯ ЦЕЛИКОМ (" .. #matchedTreeRoots .. ") ===")

	for idx, entry in ipairs(matchedTreeRoots) do
		if #lines >= MAX_TOTAL_LINES then
			table.insert(lines, "[Достигнут лимит строк отчёта: " .. MAX_TOTAL_LINES .. "]")
			break
		end
		table.insert(lines, "")
		table.insert(lines, string.format("[%d] Совпадение по: %s", idx, tostring(entry.tok)))
		dumpFullSubtree(entry.inst, lines, 8)
		if idx % 8 == 0 then
			task.wait()
		end
	end

	local function appendCategory(title, list)
		if #lines >= MAX_TOTAL_LINES then return end
		table.insert(lines, "")
		table.insert(lines, "=== " .. title .. " (" .. #list .. ") ===")
		for _, item in ipairs(list) do
			if #lines >= MAX_TOTAL_LINES then
				table.insert(lines, "  ... [лимит строк]")
				break
			end
			table.insert(lines, "  " .. item)
		end
	end

	appendCategory("FRAMES / SCROLLING / CANVAS", framesAll)
	appendCategory("TEXTLABELS", labelsAll)
	appendCategory("TEXTBOXES", boxesAll)
	appendCategory("BUTTONS (TextButton / ImageButton / GuiButton)", buttonsAll)
	appendCategory("IMAGES (ImageLabel)", imagesAll)
	appendCategory("OTHER OBJECTS (Folders, Remotes, Modules, Values, Tools, Scripts, etc.)", otherAll)

	local reportText = table.concat(lines, "\n")
	lastReportText = reportText
	rebuildChunks()

	warn(string.format(
		"[MegaScanner] Visited=%d | Trees=%d | Chunks=%d (limit %d) | F=%d | Lbl=%d | Box=%d | Btn=%d | Img=%d | Other=%d",
		totalVisited, #matchedTreeRoots, #reportChunks, CHUNK_LIMIT, #framesAll, #labelsAll, #boxesAll, #buttonsAll, #imagesAll, #otherAll
	))

	return reportText, {
		trees = #matchedTreeRoots,
		frames = #framesAll,
		labels = #labelsAll,
		buttons = #buttonsAll,
		images = #imagesAll,
		other = #otherAll,
		chunks = #reportChunks,
	}
end

local function buildMegaScannerUI()
	local old = PlayerGui:FindFirstChild("MegaAllScannerUI")
	if old then old:Destroy() end

	local sg = Instance.new("ScreenGui")
	sg.Name = "MegaAllScannerUI"
	sg.ResetOnSpawn = false
	sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	sg.Parent = PlayerGui

	local main = Instance.new("Frame")
	main.Name = "MainFrame"
	main.Size = UDim2.new(0, 308, 0, 276)
	main.Position = UDim2.new(0.5, -154, 0.2, -138)
	main.BackgroundColor3 = Color3.fromRGB(13, 13, 18)
	main.BackgroundTransparency = 0.05
	main.BorderSizePixel = 0
	main.Active = true
	main.Draggable = true
	main.Parent = sg

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = main

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(130, 85, 240)
	stroke.Thickness = 1.5
	stroke.Parent = main

	local topBar = Instance.new("Frame")
	topBar.Size = UDim2.new(1, 0, 0, 32)
	topBar.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
	topBar.BorderSizePixel = 0
	topBar.Parent = main

	local topCorner = Instance.new("UICorner")
	topCorner.CornerRadius = UDim.new(0, 10)
	topCorner.Parent = topBar

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -66, 1, 0)
	title.Position = UDim2.new(0, 10, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "Mega Scanner (160k chunks)"
	title.TextColor3 = Color3.fromRGB(245, 242, 255)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Font = Enum.Font.GothamBold
	title.TextSize = 13
	title.Parent = topBar

	local collapseBtn = Instance.new("TextButton")
	collapseBtn.Size = UDim2.new(0, 26, 0, 24)
	collapseBtn.Position = UDim2.new(1, -32, 0.5, -12)
	collapseBtn.BackgroundColor3 = Color3.fromRGB(36, 36, 48)
	collapseBtn.Text = "-"
	collapseBtn.TextColor3 = Color3.fromRGB(235, 235, 245)
	collapseBtn.Font = Enum.Font.GothamBold
	collapseBtn.TextSize = 15
	collapseBtn.Parent = topBar

	local colCorner = Instance.new("UICorner")
	colCorner.CornerRadius = UDim.new(0, 6)
	colCorner.Parent = collapseBtn

	local body = Instance.new("Frame")
	body.Size = UDim2.new(1, -16, 1, -40)
	body.Position = UDim2.new(0, 8, 0, 36)
	body.BackgroundTransparency = 1
	body.Parent = main

	local queryBox = Instance.new("TextBox")
	queryBox.Name = "QueryInput"
	queryBox.Size = UDim2.new(1, 0, 0, 34)
	queryBox.Position = UDim2.new(0, 0, 0, 0)
	queryBox.BackgroundColor3 = Color3.fromRGB(24, 24, 34)
	queryBox.Text = table.concat(DEFAULT_KEYWORDS, ",")
	queryBox.PlaceholderText = "Inventory,NewItem,Claim,Claimed,TextName,Button,Item,MainGUI,PlayerGui,StarterPlayer,StarterPack"
	queryBox.PlaceholderColor3 = Color3.fromRGB(130, 135, 155)
	queryBox.TextColor3 = Color3.fromRGB(255, 255, 255)
	queryBox.ClearTextOnFocus = false
	queryBox.Font = Enum.Font.Gotham
	queryBox.TextSize = 11
	queryBox.Parent = body

	local qbCorner = Instance.new("UICorner")
	qbCorner.CornerRadius = UDim.new(0, 7)
	qbCorner.Parent = queryBox

	local statusLbl = Instance.new("TextLabel")
	statusLbl.Size = UDim2.new(1, 0, 0, 26)
	statusLbl.Position = UDim2.new(0, 0, 0, 38)
	statusLbl.BackgroundTransparency = 1
	statusLbl.Text = "Лимит части: 160000 символов"
	statusLbl.TextColor3 = Color3.fromRGB(175, 165, 215)
	statusLbl.TextWrapped = true
	statusLbl.Font = Enum.Font.Gotham
	statusLbl.TextSize = 10
	statusLbl.Parent = body

	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.new(1, 0, 0, 108)
	scroll.Position = UDim2.new(0, 0, 0, 66)
	scroll.BackgroundColor3 = Color3.fromRGB(18, 18, 25)
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 4
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.Parent = body

	local scCorner = Instance.new("UICorner")
	scCorner.CornerRadius = UDim.new(0, 7)
	scCorner.Parent = scroll

	local reportLabel = Instance.new("TextLabel")
	reportLabel.Size = UDim2.new(1, -8, 0, 0)
	reportLabel.Position = UDim2.new(0, 4, 0, 4)
	reportLabel.BackgroundTransparency = 1
	reportLabel.Text = lastReportText
	reportLabel.TextColor3 = Color3.fromRGB(215, 220, 238)
	reportLabel.TextXAlignment = Enum.TextXAlignment.Left
	reportLabel.TextYAlignment = Enum.TextYAlignment.Top
	reportLabel.TextWrapped = true
	reportLabel.AutomaticSize = Enum.AutomaticSize.Y
	reportLabel.Font = Enum.Font.Code
	reportLabel.TextSize = 10
	reportLabel.Parent = scroll

	reportLabel:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		scroll.CanvasSize = UDim2.new(0, 0, 0, reportLabel.AbsoluteSize.Y + 12)
	end)

	local scanBtn = Instance.new("TextButton")
	scanBtn.Size = UDim2.new(0.44, -3, 0, 34)
	scanBtn.Position = UDim2.new(0, 0, 0, 182)
	scanBtn.BackgroundColor3 = Color3.fromRGB(115, 65, 215)
	scanBtn.Text = "Scan All"
	scanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	scanBtn.Font = Enum.Font.GothamBold
	scanBtn.TextSize = 12
	scanBtn.Parent = body

	local sbCorner = Instance.new("UICorner")
	sbCorner.CornerRadius = UDim.new(0, 7)
	sbCorner.Parent = scanBtn

	local copyBtn = Instance.new("TextButton")
	copyBtn.Size = UDim2.new(0.34, -3, 0, 34)
	copyBtn.Position = UDim2.new(0.44, 3, 0, 182)
	copyBtn.BackgroundColor3 = Color3.fromRGB(45, 55, 80)
	copyBtn.Text = "Copy 1/1"
	copyBtn.TextColor3 = Color3.fromRGB(235, 240, 255)
	copyBtn.Font = Enum.Font.GothamBold
	copyBtn.TextSize = 11
	copyBtn.Parent = body

	local cpCorner = Instance.new("UICorner")
	cpCorner.CornerRadius = UDim.new(0, 7)
	cpCorner.Parent = copyBtn

	local nextPartBtn = Instance.new("TextButton")
	nextPartBtn.Size = UDim2.new(0.22, -2, 0, 34)
	nextPartBtn.Position = UDim2.new(0.78, 2, 0, 182)
	nextPartBtn.BackgroundColor3 = Color3.fromRGB(36, 36, 50)
	nextPartBtn.Text = "Next>"
	nextPartBtn.TextColor3 = Color3.fromRGB(220, 220, 245)
	nextPartBtn.Font = Enum.Font.GothamBold
	nextPartBtn.TextSize = 11
	nextPartBtn.Parent = body

	local npCorner = Instance.new("UICorner")
	npCorner.CornerRadius = UDim.new(0, 7)
	npCorner.Parent = nextPartBtn

	local function refreshCopyButtonText()
		local total = math.max(1, #reportChunks)
		copyBtn.Text = string.format("Copy %d/%d", currentChunkIndex, total)
	end

	local collapsed = false
	collapseBtn.MouseButton1Click:Connect(function()
		collapsed = not collapsed
		body.Visible = not collapsed
		collapseBtn.Text = collapsed and "+" or "-"
		TweenService:Create(main, TweenInfo.new(0.18), {
			Size = collapsed and UDim2.new(0, 308, 0, 32) or UDim2.new(0, 308, 0, 276)
		}):Play()
	end)

	local scanning = false
	scanBtn.MouseButton1Click:Connect(function()
		if scanning then return end
		scanning = true
		scanBtn.Text = "..."
		task.spawn(function()
			local rep, stats = runMegaScanner(queryBox.Text, function(msg)
				statusLbl.Text = msg
			end)
			reportLabel.Text = rep
			refreshCopyButtonText()
			statusLbl.Text = string.format(
				"Trees:%d | Parts:%d (160k) | F:%d Lbl:%d Btn:%d",
				stats.trees, stats.chunks, stats.frames, stats.labels, stats.buttons
			)
			scanBtn.Text = "Scan All"
			scanning = false
		end)
	end)

	copyBtn.MouseButton1Click:Connect(function()
		local ok, msg = copyChunkByIndex(currentChunkIndex)
		statusLbl.Text = msg
		if ok then
			local total = math.max(1, #reportChunks)
			currentChunkIndex = (currentChunkIndex % total) + 1
			refreshCopyButtonText()
		end
	end)

	nextPartBtn.MouseButton1Click:Connect(function()
		local total = math.max(1, #reportChunks)
		currentChunkIndex = (currentChunkIndex % total) + 1
		refreshCopyButtonText()
		statusLbl.Text = string.format("Выбрана часть %d/%d (нажми Copy)", currentChunkIndex, total)
	end)
end

buildMegaScannerUI()
