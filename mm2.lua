local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local MAX_CHARS = 160000
local TRUNCATE_NOTICE = "\n\n[ОСТАНОВЛЕНО: лимит 160000 символов]"

local oldGui = playerGui:FindFirstChild("MM2SafeScannerUI")
if oldGui then
	oldGui:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MM2SafeScannerUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 324, 0, 340)
mainFrame.Position = UDim2.new(0.5, -162, 0.5, -170)
mainFrame.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 10)
mainCorner.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(95, 165, 255)
mainStroke.Thickness = 1.5
mainStroke.Parent = mainFrame

local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 34)
topBar.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
topBar.BorderSizePixel = 0
topBar.Parent = mainFrame

local topCorner = Instance.new("UICorner")
topCorner.CornerRadius = UDim.new(0, 10)
topCorner.Parent = topBar

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -80, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.Text = "MM2 Scanner (Auto + 160k)"
title.TextColor3 = Color3.fromRGB(240, 240, 250)
title.Font = Enum.Font.GothamBold
title.TextSize = 13
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = topBar

local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 28, 0, 24)
minBtn.Position = UDim2.new(1, -64, 0.5, -12)
minBtn.BackgroundColor3 = Color3.fromRGB(36, 36, 46)
minBtn.Text = "-"
minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 15
minBtn.Parent = topBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 28, 0, 24)
closeBtn.Position = UDim2.new(1, -32, 0.5, -12)
closeBtn.BackgroundColor3 = Color3.fromRGB(190, 45, 65)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 13
closeBtn.Parent = topBar

local body = Instance.new("Frame")
body.Size = UDim2.new(1, -16, 1, -42)
body.Position = UDim2.new(0, 8, 0, 38)
body.BackgroundTransparency = 1
body.Parent = mainFrame

local filterBox = Instance.new("TextBox")
filterBox.Size = UDim2.new(1, 0, 0, 30)
filterBox.BackgroundColor3 = Color3.fromRGB(26, 26, 34)
filterBox.TextColor3 = Color3.fromRGB(255, 255, 255)
filterBox.PlaceholderText = "Фильтр (claim, newitem, count, christmas)"
filterBox.PlaceholderColor3 = Color3.fromRGB(130, 130, 150)
filterBox.Text = ""
filterBox.ClearTextOnFocus = false
filterBox.Font = Enum.Font.Gotham
filterBox.TextSize = 11
filterBox.Parent = body

local scanBtn = Instance.new("TextButton")
scanBtn.Size = UDim2.new(0.48, 0, 0, 32)
scanBtn.Position = UDim2.new(0, 0, 0, 36)
scanBtn.BackgroundColor3 = Color3.fromRGB(45, 125, 225)
scanBtn.Text = "Сканировать"
scanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
scanBtn.Font = Enum.Font.GothamBold
scanBtn.TextSize = 12
scanBtn.Parent = body

local copyBtn = Instance.new("TextButton")
copyBtn.Size = UDim2.new(0.48, 0, 0, 32)
copyBtn.Position = UDim2.new(0.52, 0, 0, 36)
copyBtn.BackgroundColor3 = Color3.fromRGB(45, 165, 95)
copyBtn.Text = "Копировать всё"
copyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
copyBtn.Font = Enum.Font.GothamBold
copyBtn.TextSize = 12
copyBtn.Parent = body

local infoBtn = Instance.new("TextButton")
infoBtn.Size = UDim2.new(1, 0, 0, 22)
infoBtn.Position = UDim2.new(0, 0, 0, 72)
infoBtn.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
infoBtn.Text = "Прозрачность: 0% | Символов: 0 / 160000"
infoBtn.TextColor3 = Color3.fromRGB(215, 215, 230)
infoBtn.Font = Enum.Font.Gotham
infoBtn.TextSize = 10
infoBtn.Parent = body

local outputBox = Instance.new("TextBox")
outputBox.Size = UDim2.new(1, 0, 1, -100)
outputBox.Position = UDim2.new(0, 0, 0, 98)
outputBox.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
outputBox.TextColor3 = Color3.fromRGB(220, 235, 255)
outputBox.Text = "Запускаю поиск..."
outputBox.TextXAlignment = Enum.TextXAlignment.Left
outputBox.TextYAlignment = Enum.TextYAlignment.Top
outputBox.TextWrapped = true
outputBox.MultiLine = true
outputBox.ClearTextOnFocus = false
outputBox.Font = Enum.Font.Code
outputBox.TextSize = 10
outputBox.Parent = body

local KEYWORDS = {
	"claim", "newitem", "new_item", "count", "amount", "qty",
	"quantity", "stack", "christmas", "halloween", "rarity", "event"
}

local function matchesQuery(inst, queryLower)
	local nameLower = string.lower(inst.Name)
	local textLower = (inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox"))
		and string.lower(inst.Text) or ""

	if queryLower ~= "" then
		return string.find(nameLower, queryLower, 1, true) ~= nil
			or (textLower ~= "" and string.find(textLower, queryLower, 1, true) ~= nil)
	end

	for _, kw in ipairs(KEYWORDS) do
		if string.find(nameLower, kw, 1, true) ~= nil
			or (textLower ~= "" and string.find(textLower, kw, 1, true) ~= nil)
		then
			return true
		end
	end
	return false
end

local function capTo160k(str)
	if typeof(str) ~= "string" then
		return ""
	end
	if #str <= MAX_CHARS then
		return str
	end
	local keepLen = math.max(0, MAX_CHARS - #TRUNCATE_NOTICE)
	return string.sub(str, 1, keepLen) .. TRUNCATE_NOTICE
end

local currentAlphaPercent = 0
local lastReport = ""
local isScanning = false

local function updateInfoBar(charCount)
	infoBtn.Text = string.format("Прозрачность: %d%% | Символов: %d / %d", currentAlphaPercent, charCount, MAX_CHARS)
end

local function runScan()
	if isScanning then
		return
	end
	isScanning = true
	scanBtn.Text = "Поиск..."

	local ok, err = pcall(function()
		local queryLower = string.lower(filterBox.Text:match("^%s*(.-)%s*$") or "")
		local chunks = {}
		local currentLen = 0
		local foundCount = 0
		local stoppedByLimit = false

		local header = "=== РЕЗУЛЬТАТ СКАНИРОВАНИЯ ===\n"
		table.insert(chunks, header)
		currentLen += #header

		local roots = {
			{ label = "PlayerGui", root = playerGui },
			{ label = "ReplicatedStorage", root = ReplicatedStorage },
		}

		for _, entry in ipairs(roots) do
			if stoppedByLimit then
				break
			end

			local descendants = entry.root:GetDescendants()
			for i, desc in ipairs(descendants) do
				-- Небольшая пауза каждые 1500 объектов, чтобы телефон не подвисал
				if i % 1500 == 0 then
					task.wait()
				end

				if desc.Name ~= "MM2SafeScannerUI" and not desc:IsDescendantOf(screenGui) then
					if matchesQuery(desc, queryLower) then
						foundCount += 1

						local extra = ""
						if desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox") then
							extra = ' | Text="' .. tostring(desc.Text) .. '" | Vis=' .. tostring(desc.Visible)
						elseif desc:IsA("GuiObject") then
							extra = " | Vis=" .. tostring(desc.Visible)
						end

						local line = string.format("[%s] %s (%s)%s\n", entry.label, desc:GetFullName(), desc.ClassName, extra)

						if currentLen + #line + #TRUNCATE_NOTICE > MAX_CHARS then
							local remaining = MAX_CHARS - currentLen - #TRUNCATE_NOTICE
							if remaining > 0 then
								table.insert(chunks, string.sub(line, 1, remaining))
								currentLen += remaining
							end
							table.insert(chunks, TRUNCATE_NOTICE)
							currentLen += #TRUNCATE_NOTICE
							stoppedByLimit = true
							break
						else
							table.insert(chunks, line)
							currentLen += #line
						end
					end
				end
			end
		end

		if foundCount == 0 then
			lastReport = capTo160k("Ничего не найдено по текущему фильтру.")
		else
			local summaryPrefix = "Найдено совпадений: " .. tostring(foundCount) .. "\n"
			lastReport = capTo160k(summaryPrefix .. table.concat(chunks, ""))
		end

		outputBox.Text = lastReport
		updateInfoBar(#lastReport)
	end)

	if not ok then
		lastReport = capTo160k("Ошибка при сканировании: " .. tostring(err))
		outputBox.Text = lastReport
		updateInfoBar(#lastReport)
	end

	isScanning = false
	scanBtn.Text = "Сканировать"
end

local function safeCopyAll()
	local textToCopy = capTo160k(lastReport ~= "" and lastReport or outputBox.Text)
	if textToCopy == "" then
		textToCopy = "Пусто"
	end

	local copied = false
	if typeof(setclipboard) == "function" then
		local ok = pcall(setclipboard, textToCopy)
		copied = ok
	elseif typeof(toclipboard) == "function" then
		local ok = pcall(toclipboard, textToCopy)
		copied = ok
	end

	copyBtn.Text = copied and "Скопировано!" or "Не удалось"
	task.delay(1.2, function()
		if copyBtn and copyBtn.Parent then
			copyBtn.Text = "Копировать всё"
		end
	end)
end

local minimized = false
minBtn.MouseButton1Click:Connect(function()
	minimized = not minimized
	body.Visible = not minimized
	mainFrame.Size = minimized and UDim2.new(0, 324, 0, 34) or UDim2.new(0, 324, 0, 340)
	minBtn.Text = minimized and "+" or "-"
end)

closeBtn.MouseButton1Click:Connect(function()
	screenGui:Destroy()
end)

infoBtn.MouseButton1Click:Connect(function()
	currentAlphaPercent = (currentAlphaPercent + 20) % 80
	mainFrame.BackgroundTransparency = currentAlphaPercent / 100
	updateInfoBar(#lastReport)
end)

scanBtn.MouseButton1Click:Connect(function()
	task.spawn(runScan)
end)

copyBtn.MouseButton1Click:Connect(safeCopyAll)

-- Автозапуск поиска сразу при запуске скрипта
task.defer(function()
	task.spawn(runScan)
end)
