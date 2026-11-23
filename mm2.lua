local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer

local CONFIG = {
	DefaultRoot = "PlayerGui", -- "PlayerGui" | "ReplicatedStorage" | "Backpack"
	MaxResults = 60,           -- Макс. совпадений в выпадающем списке
	MaxVisited = 150000,       -- Предохранитель обхода без ограничения глубины
	NodesPerYield = 1500,      -- Пауза для плавности на мобильном устройстве
	MinSimilarity = 0.42,      -- Порог схожести (0..1)
	OnlyBranches = true,       -- true = показывать ветки (с потомками)
}

local function getUiParent(): Instance
	local ok, res = pcall(function()
		return gethui and gethui()
	end)
	if ok and typeof(res) == "Instance" then
		return res
	end
	local okCore, core = pcall(function()
		return CoreGui
	end)
	if okCore and core then
		return core
	end
	return player:WaitForChild("PlayerGui")
end

local function resolveRoot(target: string): Instance?
	if target == "PlayerGui" then
		return player:FindFirstChild("PlayerGui") or player:WaitForChild("PlayerGui")
	elseif target == "ReplicatedStorage" then
		return ReplicatedStorage
	elseif target == "Backpack" then
		return player:FindFirstChild("Backpack")
	end
	return game:FindFirstChild(target)
end

local function normalizeName(str: string): string
	local lower = string.lower(str)
	return string.gsub(lower, "[%s_%-%.]+", "")
end

local function similarity(a: string, b: string): number
	if a == "" or b == "" then
		return 0
	end
	if a == b then
		return 1
	end
	if string.find(a, b, 1, true) or string.find(b, a, 1, true) then
		return 0.85
	end

	local function getBigrams(s: string)
		local map = {}
		local count = 0
		for i = 1, #s - 1 do
			local bg = string.sub(s, i, i + 1)
			map[bg] = (map[bg] or 0) + 1
			count += 1
		end
		return map, count
	end

	local mapA, countA = getBigrams(a)
	local mapB, countB = getBigrams(b)
	if countA == 0 or countB == 0 then
		return 0
	end

	local intersection = 0
	for bg, cA in pairs(mapA) do
		local cB = mapB[bg]
		if cB then
			intersection += math.min(cA, cB)
		end
	end

	return (2 * intersection) / (countA + countB)
end

-- Разбиваем строку ввода на несколько ключевых слов (через запятую, пробел, точку с запятой или /)
local function parseQueries(rawText: string): { string }
	local list = {}
	for token in string.gmatch(rawText, "[^,;/]+") do
		local trimmed = string.match(token, "^%s*(.-)%s*$")
		if trimmed and trimmed ~= "" then
			table.insert(list, trimmed)
		end
	end
	return list
end

local function matchSingleQuery(rawName: string, normName: string, lowerName: string, q: string)
	local lowerQ = string.lower(q)
	local normQ = normalizeName(q)

	if lowerName == lowerQ or (normQ ~= "" and normName == normQ) then
		return "ТОЧНОЕ", 1.0
	end

	if (lowerQ ~= "" and string.find(lowerName, lowerQ, 1, true))
		or (normQ ~= "" and string.find(normName, normQ, 1, true)) then
		return "ПОДСТРОКА", 0.90
	end

	local score = similarity(normName, normQ)
	if score >= CONFIG.MinSimilarity then
		return "СХОЖЕЕ", score
	end

	return nil, 0
end

local function scoreInstance(inst: Instance, queries: { string })
	local rawName = inst.Name
	local normName = normalizeName(rawName)
	local lowerName = string.lower(rawName)

	local bestKind, bestScore, bestQuery = nil, 0, nil
	for _, q in ipairs(queries) do
		local kind, sc = matchSingleQuery(rawName, normName, lowerName, q)
		if kind and sc > bestScore then
			bestKind = kind
			bestScore = sc
			bestQuery = q
		end
	end

	return bestKind, bestScore, bestQuery
end

-- Находим связанные ветки: родитель, соседи в той же ветке и похожие ветки рядом
local function collectRelated(entry, allEntries)
	local inst: Instance = entry.instance
	local related = {}
	local seen = { [inst] = true }

	local parent = inst.Parent
	if parent and parent ~= game then
		seen[parent] = true
		table.insert(related, string.format("[РОДИТЕЛЬ] %s (%s)", parent:GetFullName(), parent.ClassName))

		for _, sib in ipairs(parent:GetChildren()) do
			if not seen[sib] and #sib:GetChildren() > 0 then
				local sibKind, sibScore = scoreInstance(sib, { entry.query })
				if sibKind or similarity(normalizeName(sib.Name), normalizeName(inst.Name)) >= 0.45 then
					seen[sib] = true
					table.insert(related, string.format(
						"[СВЯЗАННАЯ ВЕТКА] %s (%s, детей: %d)",
						sib:GetFullName(),
						sib.ClassName,
						#sib:GetChildren()
					))
				end
			end
		end
	end

	local targetNorm = normalizeName(inst.Name)
	for _, other in ipairs(allEntries) do
		if other.instance ~= inst and not seen[other.instance] then
			local sim = similarity(targetNorm, normalizeName(other.instance.Name))
			if sim >= 0.55 then
				seen[other.instance] = true
				table.insert(related, string.format(
					"[ПОХОЖАЯ %.2f] %s (%s, детей: %d)",
					sim,
					other.path,
					other.className,
					other.childrenCount
				))
			end
		end
		if #related >= 14 then
			break
		end
	end

	local childrenLines = {}
	for _, ch in ipairs(inst:GetChildren()) do
		table.insert(childrenLines, string.format("  • %s [%s] (детей: %d)", ch.Name, ch.ClassName, #ch:GetChildren()))
		if #childrenLines >= 20 then
			table.insert(childrenLines, "  ... ещё дети скрыты")
			break
		end
	end

	return related, childrenLines
end

local function runScan(rawQuery: string, rootName: string, onDone: (boolean, string, { any }) -> ())
	local queries = parseQueries(rawQuery)
	if #queries == 0 then
		onDone(false, "Введи ключевое слово (например: NewItem, Inventory)", {})
		return
	end

	local root = resolveRoot(rootName)
	if not root then
		onDone(false, "Корень не найден: " .. tostring(rootName), {})
		return
	end

	local results = {}
	local visitedObjects = {}
	local visitedCount = 0
	local stoppedByLimit = false

	local function walk(inst: Instance)
		if #results >= CONFIG.MaxResults or visitedCount >= CONFIG.MaxVisited then
			if visitedCount >= CONFIG.MaxVisited then
				stoppedByLimit = true
			end
			return
		end

		for _, child in ipairs(inst:GetChildren()) do
			if #results >= CONFIG.MaxResults or visitedCount >= CONFIG.MaxVisited then
				if visitedCount >= CONFIG.MaxVisited then
					stoppedByLimit = true
				end
				break
			end

			if not visitedObjects[child] then
				visitedObjects[child] = true
				visitedCount += 1

				if visitedCount % CONFIG.NodesPerYield == 0 then
					task.wait()
				end

				local children = child:GetChildren()
				local hasChildren = #children > 0

				if not CONFIG.OnlyBranches or hasChildren then
					local kind, score, matchedQuery = scoreInstance(child, queries)
					if kind then
						table.insert(results, {
							instance = child,
							kind = kind,
							score = score,
							query = matchedQuery,
							path = child:GetFullName(),
							name = child.Name,
							className = child.ClassName,
							childrenCount = #children,
						})
					end
				end

				if hasChildren and #results < CONFIG.MaxResults and not stoppedByLimit then
					walk(child)
				end
			end
		end
	end

	walk(root)

	table.sort(results, function(a, b)
		if a.score == b.score then
			return a.path < b.path
		end
		return a.score > b.score
	end)

	local status = string.format(
		"%s | Проверено: %d | Найдено: %d%s",
		rootName,
		visitedCount,
		#results,
		stoppedByLimit and " [лимит]" or ""
	)
	onDone(true, status, results)
end

-- Построение мобильного окна поиска с выпадающим списком
local oldGui = getUiParent():FindFirstChild("BranchFinderUI")
if oldGui then
	oldGui:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "BranchFinderUI"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = getUiParent()

local main = Instance.new("Frame")
main.Size = UDim2.new(0.92, 0, 0.78, 0)
main.Position = UDim2.new(0.04, 0, 0.11, 0)
main.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
main.BorderSizePixel = 0
main.Parent = gui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 10)
mainCorner.Parent = main

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(65, 65, 82)
mainStroke.Thickness = 1
mainStroke.Parent = main

local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 38)
topBar.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
topBar.BorderSizePixel = 0
topBar.Parent = main

local topCorner = Instance.new("UICorner")
topCorner.CornerRadius = UDim.new(0, 10)
topCorner.Parent = topBar

local titleLbl = Instance.new("TextLabel")
titleLbl.Size = UDim2.new(1, -80, 1, 0)
titleLbl.Position = UDim2.new(0, 10, 0, 0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text = "Поиск веток и связанных"
titleLbl.TextColor3 = Color3.fromRGB(235, 235, 245)
titleLbl.TextSize = 14
titleLbl.Font = Enum.Font.GothamBold
titleLbl.TextXAlignment = Enum.TextXAlignment.Left
titleLbl.Parent = topBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 34, 0, 26)
closeBtn.Position = UDim2.new(1, -40, 0.5, -13)
closeBtn.BackgroundColor3 = Color3.fromRGB(145, 38, 48)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 13
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = topBar

Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)
closeBtn.MouseButton1Click:Connect(function()
	gui:Destroy()
end)

local currentRoot = CONFIG.DefaultRoot
local rootBtn = Instance.new("TextButton")
rootBtn.Size = UDim2.new(1, -16, 0, 30)
rootBtn.Position = UDim2.new(0, 8, 0, 44)
rootBtn.BackgroundColor3 = Color3.fromRGB(30, 32, 42)
rootBtn.Text = "Корень: " .. currentRoot .. " (нажми для смены)"
rootBtn.TextColor3 = Color3.fromRGB(165, 205, 255)
rootBtn.TextSize = 12
rootBtn.Font = Enum.Font.GothamMedium
rootBtn.Parent = main
Instance.new("UICorner", rootBtn).CornerRadius = UDim.new(0, 6)

local rootsOrder = { "PlayerGui", "ReplicatedStorage", "Backpack" }
rootBtn.MouseButton1Click:Connect(function()
	local idx = table.find(rootsOrder, currentRoot) or 1
	currentRoot = rootsOrder[(idx % #rootsOrder) + 1]
	rootBtn.Text = "Корень: " .. currentRoot .. " (нажми для смены)"
end)

local inputBox = Instance.new("TextBox")
inputBox.Size = UDim2.new(1, -86, 0, 34)
inputBox.Position = UDim2.new(0, 8, 0, 80)
inputBox.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
inputBox.PlaceholderText = "Ключи: NewItem, Inventory..."
inputBox.PlaceholderColor3 = Color3.fromRGB(125, 125, 145)
inputBox.Text = ""
inputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
inputBox.TextSize = 13
inputBox.Font = Enum.Font.Gotham
inputBox.ClearTextOnFocus = false
inputBox.Parent = main
Instance.new("UICorner", inputBox).CornerRadius = UDim.new(0, 6)

local searchBtn = Instance.new("TextButton")
searchBtn.Size = UDim2.new(0, 66, 0, 34)
searchBtn.Position = UDim2.new(1, -74, 0, 80)
searchBtn.BackgroundColor3 = Color3.fromRGB(52, 110, 215)
searchBtn.Text = "Найти"
searchBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
searchBtn.TextSize = 13
searchBtn.Font = Enum.Font.GothamBold
searchBtn.Parent = main
Instance.new("UICorner", searchBtn).CornerRadius = UDim.new(0, 6)

local statusLbl = Instance.new("TextLabel")
statusLbl.Size = UDim2.new(1, -16, 0, 20)
statusLbl.Position = UDim2.new(0, 8, 0, 118)
statusLbl.BackgroundTransparency = 1
statusLbl.Text = "Введи слово и нажми «Найти» или Enter"
statusLbl.TextColor3 = Color3.fromRGB(170, 175, 195)
statusLbl.TextSize = 11
statusLbl.Font = Enum.Font.Gotham
statusLbl.TextXAlignment = Enum.TextXAlignment.Left
statusLbl.TextTruncate = Enum.TextTruncate.AtEnd
statusLbl.Parent = main

-- Выпадающий список найденных веток
local dropdownFrame = Instance.new("ScrollingFrame")
dropdownFrame.Size = UDim2.new(1, -16, 0.44, -68)
dropdownFrame.Position = UDim2.new(0, 8, 0, 142)
dropdownFrame.BackgroundColor3 = Color3.fromRGB(21, 21, 27)
dropdownFrame.BorderSizePixel = 0
dropdownFrame.ScrollBarThickness = 5
dropdownFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
dropdownFrame.Parent = main
Instance.new("UICorner", dropdownFrame).CornerRadius = UDim.new(0, 6)

local dropLayout = Instance.new("UIListLayout")
dropLayout.Padding = UDim.new(0, 4)
dropLayout.Parent = dropdownFrame

-- Панель связанных веток и прямых детей выбранной ветки
local detailsFrame = Instance.new("ScrollingFrame")
detailsFrame.Size = UDim2.new(1, -16, 0.56, -86)
detailsFrame.Position = UDim2.new(0, 8, 0.44, 80)
detailsFrame.BackgroundColor3 = Color3.fromRGB(21, 21, 27)
detailsFrame.BorderSizePixel = 0
detailsFrame.ScrollBarThickness = 5
detailsFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
detailsFrame.Parent = main
Instance.new("UICorner", detailsFrame).CornerRadius = UDim.new(0, 6)

local detailsText = Instance.new("TextLabel")
detailsText.Size = UDim2.new(1, -12, 0, 20)
detailsText.Position = UDim2.new(0, 6, 0, 6)
detailsText.BackgroundTransparency = 1
detailsText.Text = "Выбери ветку в списке сверху, чтобы увидеть связанные ветки и детей."
detailsText.TextColor3 = Color3.fromRGB(215, 220, 235)
detailsText.TextSize = 12
detailsText.Font = Enum.Font.Code
detailsText.TextXAlignment = Enum.TextXAlignment.Left
detailsText.TextYAlignment = Enum.TextYAlignment.Top
detailsText.TextWrapped = true
detailsText.Parent = detailsFrame

local function updateCanvas(scroll: ScrollingFrame, contentHeight: number)
	scroll.CanvasSize = UDim2.new(0, 0, 0, contentHeight + 14)
end

local function clearDropdown()
	for _, ch in ipairs(dropdownFrame:GetChildren()) do
		if ch:IsA("TextButton") then
			ch:Destroy()
		end
	end
	updateCanvas(dropdownFrame, 0)
end

local function showEntryDetails(entry, allEntries)
	local related, childrenLines = collectRelated(entry, allEntries)
	local lines = {
		string.format("ВЕТКА: %s", entry.path),
		string.format("Класс: %s | Тип: %s (%.2f) | Детей: %d", entry.className, entry.kind, entry.score, entry.childrenCount),
		"",
		"--- СВЯЗАННЫЕ ВЕТКИ ---",
	}
	if #related > 0 then
		for _, r in ipairs(related) do
			table.insert(lines, r)
		end
	else
		table.insert(lines, "Явных связанных веток рядом не найдено.")
	end

	table.insert(lines, "")
	table.insert(lines, "--- ПРЯМЫЕ ДЕТИ ---")
	if #childrenLines > 0 then
		for _, c in ipairs(childrenLines) do
			table.insert(lines, c)
		end
	else
		table.insert(lines, "Потомков нет.")
	end

	local fullText = table.concat(lines, "\n")
	detailsText.Text = fullText
	detailsText.Size = UDim2.new(1, -12, 0, math.max(120, #lines * 16))
	updateCanvas(detailsFrame, detailsText.Size.Y.Offset + 12)
	print(fullText)
end

local busy = false
local function triggerSearch()
	if busy then
		return
	end
	busy = true
	clearDropdown()
	statusLbl.Text = "Ищу ветки без ограничения глубины..."

	runScan(inputBox.Text, currentRoot, function(ok, statusMsg, entries)
		busy = false
		statusLbl.Text = statusMsg
		if not ok or #entries == 0 then
			return
		end

		local totalH = 0
		for i, item in ipairs(entries) do
			local btn = Instance.new("TextButton")
			btn.Size = UDim2.new(1, -8, 0, 34)
			btn.BackgroundColor3 = Color3.fromRGB(32, 34, 45)
			btn.Text = string.format("%d. [%s] %s (%s, детей:%d)", i, item.kind, item.name, item.className, item.childrenCount)
			btn.TextColor3 = Color3.fromRGB(235, 240, 255)
			btn.TextSize = 11
			btn.Font = Enum.Font.Gotham
			btn.TextXAlignment = Enum.TextXAlignment.Left
			btn.TextTruncate = Enum.TextTruncate.AtEnd
			btn.Parent = dropdownFrame
			Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)

			btn.MouseButton1Click:Connect(function()
				showEntryDetails(item, entries)
			end)
			totalH += 38
		end

		updateCanvas(dropdownFrame, totalH)
	end)
end

searchBtn.MouseButton1Click:Connect(triggerSearch)
inputBox.FocusLost:Connect(function(enterPressed)
	if enterPressed then
		triggerSearch()
	end
end)
