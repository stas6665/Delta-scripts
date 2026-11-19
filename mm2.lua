local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local parentGui = player:WaitForChild("PlayerGui")

if parentGui:FindFirstChild("MobileEventLogger") then
	parentGui.MobileEventLogger:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MobileEventLogger"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = parentGui

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0.92, 0, 0.48, 0)
MainFrame.Position = UDim2.new(0.04, 0, 0.05, 0)
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
TitleLabel.Size = UDim2.new(0.38, -8, 1, 0)
TitleLabel.Position = UDim2.new(0, 8, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "Gun + Char + Attr"
TitleLabel.TextColor3 = Color3.fromRGB(235, 235, 245)
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 12
TitleLabel.Parent = TopBar

local ScanBtn = Instance.new("TextButton")
ScanBtn.Size = UDim2.new(0, 52, 0, 22)
ScanBtn.Position = UDim2.new(1, -234, 0.5, -11)
ScanBtn.BackgroundColor3 = Color3.fromRGB(38, 125, 75)
ScanBtn.Text = "Scan:ON"
ScanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ScanBtn.Font = Enum.Font.GothamBold
ScanBtn.TextSize = 10
ScanBtn.Parent = TopBar
Instance.new("UICorner", ScanBtn).CornerRadius = UDim.new(0, 6)

local CopyBtn = Instance.new("TextButton")
CopyBtn.Size = UDim2.new(0, 50, 0, 22)
CopyBtn.Position = UDim2.new(1, -176, 0.5, -11)
CopyBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 58)
CopyBtn.Text = "Filter"
CopyBtn.TextColor3 = Color3.fromRGB(230, 230, 240)
CopyBtn.Font = Enum.Font.GothamBold
CopyBtn.TextSize = 10
CopyBtn.Parent = TopBar
Instance.new("UICorner", CopyBtn).CornerRadius = UDim.new(0, 6)

local ClearBtn = Instance.new("TextButton")
ClearBtn.Size = UDim2.new(0, 52, 0, 22)
ClearBtn.Position = UDim2.new(1, -120, 0.5, -11)
ClearBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 58)
ClearBtn.Text = "Clear"
ClearBtn.TextColor3 = Color3.fromRGB(230, 230, 240)
ClearBtn.Font = Enum.Font.GothamBold
ClearBtn.TextSize = 10
ClearBtn.Parent = TopBar
Instance.new("UICorner", ClearBtn).CornerRadius = UDim.new(0, 6)

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0, 52, 0, 22)
ToggleBtn.Position = UDim2.new(1, -60, 0.5, -11)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 58)
ToggleBtn.Text = "Min"
ToggleBtn.TextColor3 = Color3.fromRGB(230, 230, 240)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 10
ToggleBtn.Parent = TopBar
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 6)

local FilterBox = Instance.new("TextBox")
FilterBox.Size = UDim2.new(1, -16, 0, 28)
FilterBox.Position = UDim2.new(0, 8, 0, 38)
FilterBox.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
FilterBox.PlaceholderText = "Фильтр (например: CHAR_ATTR, GUN, Shoot, FireServer)..."
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

local copyFn = (typeof(setclipboard) == "function" and setclipboard)
	or (typeof(toclipboard) == "function" and toclipboard)
	or (typeof(set_clipboard) == "function" and set_clipboard)

local statusToken = 0
local function notifyStatus(msg)
	statusToken += 1
	local currentToken = statusToken
	TitleLabel.Text = msg
	task.delay(1.8, function()
		if statusToken == currentToken then
			TitleLabel.Text = "Gun + Char + Attr"
		end
	end)
end

local function copyToClipboard(text, labelForStatus)
	if copyFn then
		pcall(copyFn, tostring(text))
		notifyStatus(labelForStatus or "Copied!")
		return true
	else
		notifyStatus("Clipboard N/A")
		warn("[Logger] Clipboard:\n" .. tostring(text))
		return false
	end
end

local logs = {}
local maxLogs = 220
local logOrder = 0

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

local function formatValue(val)
	local t = typeof(val)
	if t == "Vector3" then
		return string.format("V3(%.2f, %.2f, %.2f)", val.X, val.Y, val.Z)
	elseif t == "CFrame" then
		local p = val.Position
		return string.format("CF(%.2f, %.2f, %.2f)", p.X, p.Y, p.Z)
	elseif t == "Color3" then
		return string.format("RGB(%d, %d, %d)", math.round(val.R * 255), math.round(val.G * 255), math.round(val.B * 255))
	elseif t == "Instance" then
		return string.format("%s [%s]", val:GetFullName(), val.ClassName)
	elseif t == "table" then
		return "table"
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

local function formatArgs(...)
	local parts = {}
	for i = 1, select("#", ...) do
		local arg = select(i, ...)
		local s = formatValue(arg)
		if typeof(arg) == "Instance" then
			s = s .. formatAttributes(arg)
		end
		parts[i] = s
	end
	return table.concat(parts, ", ")
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
		copyToClipboard(fullText, "Copied line!")
	end)

	table.insert(logs, {
		RawText = fullText,
		Button = btn,
	})

	task.defer(function()
		Scroll.CanvasPosition = Vector2.new(0, Scroll.AbsoluteCanvasSize.Y)
	end)
end

FilterBox:GetPropertyChangedSignal("Text"):Connect(refreshLogs)

BottomCopyBtn.MouseButton1Click:Connect(function()
	if #logs == 0 then
		notifyStatus("Nothing to copy")
		return
	end
	local allLines = table.create(#logs)
	for i, item in ipairs(logs) do
		allLines[i] = item.RawText
	end
	copyToClipboard(table.concat(allLines, "\n"), string.format("Copied all (%d)", #allLines))
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
	copyToClipboard(table.concat(visibleLines, "\n"), string.format("Copied (%d)", #visibleLines))
end)

ClearBtn.MouseButton1Click:Connect(function()
	for _, item in ipairs(logs) do
		if item.Button then
			item.Button:Destroy()
		end
	end
	table.clear(logs)
end)

local scanEnabled = true
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
	ScanBtn.Visible = not minimized
	CopyBtn.Visible = not minimized
	ClearBtn.Visible = not minimized
	MainFrame.Size = minimized
		and UDim2.new(0.55, 0, 0, 32)
		or UDim2.new(0.92, 0, 0.48, 0)
	ToggleBtn.Text = minimized and "Max" or "Min"
end)

-- Отслеживание всех RemoteEvent (OnClientEvent)
local hookedRemotes = {}
local function hookRemoteEvent(rem)
	if not rem:IsA("RemoteEvent") or hookedRemotes[rem] then
		return
	end
	hookedRemotes[rem] = true
	rem.OnClientEvent:Connect(function(...)
		if not scanEnabled then
			return
		end
		LogEvent("OnClientEvent", string.format("%s%s | Args: %s", rem:GetFullName(), formatAttributes(rem), formatArgs(...)))
	end)
end

for _, obj in ipairs(game:GetDescendants()) do
	if obj:IsA("RemoteEvent") then
		hookRemoteEvent(obj)
	end
end
game.DescendantAdded:Connect(function(obj)
	if obj:IsA("RemoteEvent") then
		hookRemoteEvent(obj)
	end
end)

-- Подписка на изменения атрибутов у объекта
local attrWatched = {}
local function watchAttributes(inst, tagPrefix)
	if typeof(inst) ~= "Instance" or attrWatched[inst] then
		return
	end
	attrWatched[inst] = true

	local initAttrs = formatAttributes(inst)
	if initAttrs ~= "" then
		LogEvent(tagPrefix or "ATTR", string.format("%s [%s]%s", inst:GetFullName(), inst.ClassName, initAttrs))
	end

	inst.AttributeChanged:Connect(function(attrName)
		if not scanEnabled then
			return
		end
		local newVal = inst:GetAttribute(attrName)
		LogEvent(
			tagPrefix or "ATTR",
			string.format("%s [%s] -> %s = %s", inst:GetFullName(), inst.ClassName, tostring(attrName), formatValue(newVal))
		)
	end)
end

-- Отслеживание всех атрибутов персонажа и его частей
local function watchCharacterAttributes(char)
	if not char then
		return
	end
	watchAttributes(char, "CHAR_ATTR")
	for _, desc in ipairs(char:GetDescendants()) do
		watchAttributes(desc, "CHAR_ATTR")
	end
	char.DescendantAdded:Connect(function(desc)
		watchAttributes(desc, "CHAR_ATTR")
	end)
end

if player.Character then
	watchCharacterAttributes(player.Character)
end
player.CharacterAdded:Connect(function(char)
	watchCharacterAttributes(char)
end)

-- Подробное наблюдение за инструментом Gun, его дочерними объектами и атрибутами
local watchedGuns = {}
local function watchGunTool(tool)
	if not tool:IsA("Tool") or tool.Name ~= "Gun" or watchedGuns[tool] then
		return
	end
	watchedGuns[tool] = true

	watchAttributes(tool, "GUN_ATTR")
	for _, desc in ipairs(tool:GetDescendants()) do
		watchAttributes(desc, "GUN_ATTR")
		if desc:IsA("RemoteEvent") then
			hookRemoteEvent(desc)
		end
	end

	local childrenList = {}
	for _, ch in ipairs(tool:GetChildren()) do
		table.insert(childrenList, ch.Name .. "[" .. ch.ClassName .. "]" .. formatAttributes(ch))
	end
	LogEvent("GUN_INIT", string.format("%s | Children: %s", tool:GetFullName(), table.concat(childrenList, ", ")))

	tool.Equipped:Connect(function()
		if scanEnabled then
			LogEvent("GUN_EVT", "Equipped: " .. tool:GetFullName() .. formatAttributes(tool))
		end
	end)

	tool.Unequipped:Connect(function()
		if scanEnabled then
			LogEvent("GUN_EVT", "Unequipped: " .. tool:GetFullName() .. formatAttributes(tool))
		end
	end)

	tool.Activated:Connect(function()
		if scanEnabled then
			LogEvent("GUN_EVT", "Activated: " .. tool:GetFullName() .. formatAttributes(tool))
		end
	end)

	tool.DescendantAdded:Connect(function(desc)
		watchAttributes(desc, "GUN_ATTR")
		if scanEnabled then
			LogEvent("GUN+Child", string.format("%s [%s] in %s%s", desc.Name, desc.ClassName, desc:GetFullName(), formatAttributes(desc)))
		end
		if desc:IsA("RemoteEvent") then
			hookRemoteEvent(desc)
		end
	end)

	tool.DescendantRemoving:Connect(function(desc)
		if scanEnabled then
			LogEvent("GUN-Child", string.format("%s [%s] from %s%s", desc.Name, desc.ClassName, tool:GetFullName(), formatAttributes(desc)))
		end
	end)
end

local function checkContainerForGuns(container)
	if not container then
		return
	end
	for _, item in ipairs(container:GetDescendants()) do
		if item:IsA("Tool") and item.Name == "Gun" then
			watchGunTool(item)
		end
	end
	container.DescendantAdded:Connect(function(item)
		if item:IsA("Tool") and item.Name == "Gun" then
			watchGunTool(item)
		end
	end)
end

checkContainerForGuns(player:FindFirstChild("Backpack"))
if player.Character then
	checkContainerForGuns(player.Character)
end
player.CharacterAdded:Connect(function(char)
	checkContainerForGuns(char)
	checkContainerForGuns(player:FindFirstChild("Backpack"))
end)

-- Сканирование всего workspace каждые 0.2 секунды
task.spawn(function()
	local known = {}
	local initialized = false

	while true do
		task.wait(0.2)
		if not scanEnabled then
			continue
		end

		local current = {}
		local descendants = Workspace:GetDescendants()
		local addedCount = 0
		local removedCount = 0
		local sampleAdded = {}
		local sampleRemoved = {}

		for _, obj in ipairs(descendants) do
			if obj and obj.Parent then
				current[obj] = {
					Name = obj.Name,
					ClassName = obj.ClassName,
					Path = obj:GetFullName(),
					Attrs = formatAttributes(obj),
				}

				if obj:IsA("Tool") and obj.Name == "Gun" then
					watchGunTool(obj)
				end

				if not known[obj] then
					addedCount += 1
					if #sampleAdded < 5 then
						table.insert(sampleAdded, string.format("%s [%s] (%s)%s", obj.Name, obj.ClassName, obj:GetFullName(), formatAttributes(obj)))
					end
				end
			end
		end

		for oldObj, info in pairs(known) do
			if not current[oldObj] then
				removedCount += 1
				if #sampleRemoved < 5 then
					table.insert(sampleRemoved, string.format("%s [%s] (%s)%s", info.Name, info.ClassName, info.Path, info.Attrs or ""))
				end
			end
		end

		if not initialized then
			initialized = true
			LogEvent("WS", string.format("Скан workspace (0.2s) активен. Объектов: %d", #descendants))
		else
			if addedCount > 0 then
				local extra = addedCount > 5 and string.format(" (+ещё %d)", addedCount - 5) or ""
				LogEvent("WS+", string.format("+%d: %s%s", addedCount, table.concat(sampleAdded, "; "), extra))
			end
			if removedCount > 0 then
				local extra = removedCount > 5 and string.format(" (+ещё %d)", removedCount - 5) or ""
				LogEvent("WS-", string.format("-%d: %s%s", removedCount, table.concat(sampleRemoved, "; "), extra))
			end
		end

		known = current
	end
end)

-- Перехват исходящих FireServer / InvokeServer
if typeof(hookmetamethod) == "function" and typeof(getnamecallmethod) == "function" then
	local oldNamecall
	oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
		local method = getnamecallmethod()
		if not checkcaller() and (method == "FireServer" or method == "InvokeServer") then
			if typeof(self) == "Instance" and (self:IsA("RemoteEvent") or self:IsA("RemoteFunction")) then
				local argsStr = formatArgs(...)
				task.defer(LogEvent, method, string.format("%s%s | Args: %s", self:GetFullName(), formatAttributes(self), argsStr))
			end
		end
		return oldNamecall(self, ...)
	end)
	LogEvent("INIT", "Запущено: FireServer/InvokeServer, OnClientEvent, Gun+Char+Атрибуты и WS-скан (0.2s).")
else
	LogEvent("INIT", "Запущено: OnClientEvent, Gun+Char+Атрибуты и WS-скан (0.2s) [без __namecall хука].")
end
