local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local LocalPlayer = Players.LocalPlayer

local CHUNK_SIZE = 170000
local COPY_DELAY = 2.0 -- Пауза между автоматическими кусками (сек)

local KEYWORDS = {
	"inventory",
	"box",
	"newitem",
	"claim",
	"claimed",
	"itemtype",
	"itemname",
	"item",
}

local ATTR_KEYWORDS = {
	"inventory",
	"item",
}

local fullReport = ""
local isScanning = false
local isAutoCopying = false

local function matchKeyword(text, keywords)
	if type(text) ~= "string" or text == "" then
		return false, nil
	end
	local lower = string.lower(text)
	for _, kw in ipairs(keywords) do
		if string.find(lower, kw, 1, true) then
			return true, kw
		end
	end
	return false, nil
end

local function safeFullName(inst)
	local ok, res = pcall(function()
		return inst:GetFullName()
	end)
	return ok and res or inst.Name
end

local function collectAttrs(inst)
	local ok, attrs = pcall(function()
		return inst:GetAttributes()
	end)
	if not ok or type(attrs) ~= "table" then
		return {}, {}
	end
	local matched = {}
	local allPairs = {}
	for k, v in pairs(attrs) do
		local pairText = string.format("%s=%s (%s)", tostring(k), tostring(v), typeof(v))
		table.insert(allPairs, pairText)
		if matchKeyword(tostring(k), ATTR_KEYWORDS) or matchKeyword(tostring(v), ATTR_KEYWORDS) then
			table.insert(matched, pairText)
		end
	end
	return matched, allPairs
end

local function gatherRoots()
	local roots = {}
	local seen = {}
	local function add(obj)
		if obj and not seen[obj] then
			seen[obj] = true
			table.insert(roots, obj)
		end
	end

	add(LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui"))
	add(ReplicatedStorage)
	add(LocalPlayer and LocalPlayer:FindFirstChildOfClass("Backpack"))
	add(LocalPlayer and LocalPlayer.Character)

	for _, srv in ipairs(game:GetChildren()) do
		local nameLower = string.lower(srv.Name)
		if nameLower == "startergui" or nameLower == "starterpack" or nameLower == "workspace" then
			add(srv)
		end
	end

	return roots
end

local function splitIntoChunks(text, chunkSize)
	local chunks = {}
	local totalLen = #text
	if totalLen == 0 then
		return chunks
	end

	local index = 1
	local partNum = 1
	local totalParts = math.ceil(totalLen / chunkSize)

	while index <= totalLen do
		local stopPos = math.min(index + chunkSize - 1, totalLen)
		local rawPart = string.sub(text, index, stopPos)
		local header = string.format("--- [ЧАСТЬ %d/%d | %d СИМВ.] ---\n", partNum, totalParts, #rawPart)
		table.insert(chunks, header .. rawPart)
		index = stopPos + 1
		partNum += 1
	end

	return chunks
end

local function createAutoCopyScannerUI()
	local pg = LocalPlayer:WaitForChild("PlayerGui")
	local old = pg:FindFirstChild("MM2AutoChunkScannerGUI")
	if old then
		old:Destroy()
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "MM2AutoChunkScannerGUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = pg

	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainPanel"
	mainFrame.Size = UDim2.new(0, 316, 0, 180)
	mainFrame.Position = UDim2.new(0.5, -158, 0.2, 0)
	mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 19)
	mainFrame.BorderSizePixel = 0
	mainFrame.Active = true
	mainFrame.Draggable = true
	mainFrame.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = mainFrame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(95, 95, 125)
	stroke.Thickness = 1.5
	stroke.Parent = mainFrame

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -16, 0, 26)
	titleLabel.Position = UDim2.new(0, 8, 0, 6)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "MM2 Auto-Chunk Scanner"
	titleLabel.TextColor3 = Color3.fromRGB(242, 242, 248)
	titleLabel.TextSize = 15
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = mainFrame

	local statusLabel = Instance.new("TextLabel")
	statusLabel.Size = UDim2.new(1, -16, 0, 46)
	statusLabel.Position = UDim2.new(0, 8, 0, 36)
	statusLabel.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
	statusLabel.BorderSizePixel = 0
	statusLabel.Text = "Нажми Start Scan, затем Copy All."
	statusLabel.TextColor3 = Color3.fromRGB(190, 195, 210)
	statusLabel.TextSize = 12
	statusLabel.Font = Enum.Font.Gotham
	statusLabel.TextWrapped = true
	statusLabel.Parent = mainFrame

	local statusCorner = Instance.new("UICorner")
	statusCorner.CornerRadius = UDim.new(0, 6)
	statusCorner.Parent = statusLabel

	local startBtn = Instance.new("TextButton")
	startBtn.Name = "StartScanBtn"
	startBtn.Size = UDim2.new(0.48, -10, 0, 42)
	startBtn.Position = UDim2.new(0, 8, 0, 92)
	startBtn.BackgroundColor3 = Color3.fromRGB(45, 125, 210)
	startBtn.BorderSizePixel = 0
	startBtn.Text = "Start Scan"
	startBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	startBtn.TextSize = 14
	startBtn.Font = Enum.Font.GothamBold
	startBtn.Parent = mainFrame

	local startCorner = Instance.new("UICorner")
	startCorner.CornerRadius = UDim.new(0, 8)
	startCorner.Parent = startBtn

	local copyBtn = Instance.new("TextButton")
	copyBtn.Name = "CopyAllBtn"
	copyBtn.Size = UDim2.new(0.48, -10, 0, 42)
	copyBtn.Position = UDim2.new(0.52, 2, 0, 92)
	copyBtn.BackgroundColor3 = Color3.fromRGB(48, 150, 90)
	copyBtn.BorderSizePixel = 0
	copyBtn.Text = "Copy All"
	copyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	copyBtn.TextSize = 14
	copyBtn.Font = Enum.Font.GothamBold
	copyBtn.Parent = mainFrame

	local copyCorner = Instance.new("UICorner")
	copyCorner.CornerRadius = UDim.new(0, 8)
	copyCorner.Parent = copyBtn

	local infoLabel = Instance.new("TextLabel")
	infoLabel.Size = UDim2.new(1, -16, 0, 24)
	infoLabel.Position = UDim2.new(0, 8, 0, 144)
	infoLabel.BackgroundTransparency = 1
	infoLabel.Text = "Символов: 0 | Лимит куска: 170000"
	infoLabel.TextColor3 = Color3.fromRGB(145, 150, 165)
	infoLabel.TextSize = 11
	infoLabel.Font = Enum.Font.Gotham
	infoLabel.TextXAlignment = Enum.TextXAlignment.Left
	infoLabel.Parent = mainFrame

	local function runDeepScan()
		if isScanning or isAutoCopying then return end
		isScanning = true
		startBtn.Text = "Scanning..."
		startBtn.BackgroundColor3 = Color3.fromRGB(185, 120, 30)
		statusLabel.Text = "Сканирую PlayerGui, MainGUI и доступные ветки..."

		local lines = {}
		local function addLine(s)
			table.insert(lines, s)
		end

		addLine("=== MM2 AUTO-CHUNK TREE & ATTRIBUTES SCAN ===")
		local roots = gatherRoots()
		local visited = {}
		local checked = 0
		local serverRefs = 0
		local clientHits = 0
		local treeHits = 0
		local attrHits = 0

		for _, root in ipairs(roots) do
			if visited[root] then continue end

			local okDesc, desc = pcall(function()
				return root:GetDescendants()
			end)

			local queue = { root }
			if okDesc and type(desc) == "table" then
				for _, d in ipairs(desc) do
					table.insert(queue, d)
				end
			end

			for _, inst in ipairs(queue) do
				if visited[inst] then continue end
				visited[inst] = true
				checked += 1

				local fullName = safeFullName(inst)
				local nameHit, nameKw = matchKeyword(inst.Name, KEYWORDS)
				local pathHit, pathKw = matchKeyword(fullName, KEYWORDS)
				local matchedAttrs, allAttrs = collectAttrs(inst)

				local metaParts = {}
				if inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox") then
					local txt = tostring(inst.Text or "")
					if txt ~= "" and matchKeyword(txt, KEYWORDS) then
						table.insert(metaParts, "Text='" .. txt .. "'")
					end
				elseif inst:IsA("ValueBase") then
					local valStr = tostring(inst.Value)
					if matchKeyword(valStr, KEYWORDS) then
						table.insert(metaParts, "Value=" .. valStr .. " (" .. typeof(inst.Value) .. ")")
					end
				end

				local okTags, tags = pcall(function()
					return CollectionService:GetTags(inst)
				end)
				if okTags and type(tags) == "table" then
					for _, tag in ipairs(tags) do
						if matchKeyword(tostring(tag), KEYWORDS) then
							table.insert(metaParts, "Tag=" .. tostring(tag))
						end
					end
				end

				local isServerScript = (inst.ClassName == "Script")
				local isClientScript = inst:IsA("LocalScript") or inst:IsA("ModuleScript")

				if isServerScript and (nameHit or pathHit or #allAttrs > 0) then
					serverRefs += 1
					addLine(string.format("[SERVER_SCRIPT_REF #%d] %s [Script]", serverRefs, fullName))
				elseif isClientScript and (nameHit or pathHit or #allAttrs > 0 or #metaParts > 0) then
					clientHits += 1
					local extra = {}
					if #allAttrs > 0 then table.insert(extra, "Attrs: " .. table.concat(allAttrs, ", ")) end
					if #metaParts > 0 then table.insert(extra, table.concat(metaParts, ", ")) end
					addLine(string.format("[CLIENT_SCRIPT #%d] %s [%s]%s",
						clientHits, fullName, inst.ClassName,
						#extra > 0 and (" | " .. table.concat(extra, " | ")) or ""
					))
				elseif nameHit or pathHit or #metaParts > 0 then
					treeHits += 1
					local reason = (nameHit and ("Name:" .. tostring(nameKw)))
						or (pathHit and ("Path:" .. tostring(pathKw)))
						or "Meta"
					local extra = {}
					if #allAttrs > 0 then table.insert(extra, "Attrs: " .. table.concat(allAttrs, ", ")) end
					if #metaParts > 0 then table.insert(extra, table.concat(metaParts, ", ")) end
					addLine(string.format("[TREE #%d] (%s) %s [%s]%s",
						treeHits, reason, fullName, inst.ClassName,
						#extra > 0 and (" | " .. table.concat(extra, " | ")) or ""
					))
				end

				if #matchedAttrs > 0 then
					attrHits += 1
					addLine(string.format("[ATTR #%d] %s [%s] -> %s",
						attrHits, fullName, inst.ClassName, table.concat(matchedAttrs, " | ")
					))
				end

				if checked % 450 == 0 then
					statusLabel.Text = string.format("Проверено: %d | TREE:%d ATTR:%d SCRIPTS:%d",
						checked, treeHits, attrHits, clientHits + serverRefs)
					task.wait()
				end
			end
		end

		addLine(string.format(
			"=== ИТОГ: проверено=%d | SERVER_REF=%d | CLIENT_SCRIPT=%d | TREE=%d | ATTR=%d ===",
			checked, serverRefs, clientHits, treeHits, attrHits
		))

		fullReport = table.concat(lines, "\n")

		if type(writefile) == "function" then
			pcall(function()
				writefile("MM2_AutoChunk_Report.txt", fullReport)
			end)
		end

		local totalChunks = math.max(1, math.ceil(#fullReport / CHUNK_SIZE))
		statusLabel.Text = string.format("Готово! Кусков по 170000: %d. Жми Copy All.", totalChunks)
		infoLabel.Text = string.format("Символов: %d | Кусков: %d", #fullReport, totalChunks)

		startBtn.Text = "Start Scan"
		startBtn.BackgroundColor3 = Color3.fromRGB(45, 125, 210)
		isScanning = false
	end

	local function copyAllChunksAutomatically()
		if isAutoCopying or isScanning then return end
		if #fullReport == 0 then
			statusLabel.Text = "Сначала нажми Start Scan — отчёт пуст."
			return
		end
		if type(setclipboard) ~= "function" then
			statusLabel.Text = "setclipboard недоступен в этом экзекуторе."
			return
		end

		local chunks = splitIntoChunks(fullReport, CHUNK_SIZE)
		if #chunks == 0 then return end

		isAutoCopying = true
		copyBtn.BackgroundColor3 = Color3.fromRGB(185, 120, 30)

		task.spawn(function()
			for i, chunkText in ipairs(chunks) do
				copyBtn.Text = string.format("Auto %d/%d", i, #chunks)
				local ok = pcall(function()
					setclipboard(chunkText)
				end)

				statusLabel.Text = ok
					and string.format("Авто-копирование: кусок %d из %d (пауза %.1fс)", i, #chunks, COPY_DELAY)
					or string.format("Ошибка на куске %d из %d", i, #chunks)

				print(string.format("[AutoCopyAll] Отправлен кусок %d/%d (%d символов).", i, #chunks, #chunkText))

				if i < #chunks then
					task.wait(COPY_DELAY)
				end
			end

			statusLabel.Text = string.format("Все %d кусков автоматически отправлены в буфер!", #chunks)
			copyBtn.Text = "Copy All"
			copyBtn.BackgroundColor3 = Color3.fromRGB(48, 150, 90)
			isAutoCopying = false
		end)
	end

	startBtn.MouseButton1Click:Connect(runDeepScan)
	copyBtn.MouseButton1Click:Connect(copyAllChunksAutomatically)
end

createAutoCopyScannerUI()
