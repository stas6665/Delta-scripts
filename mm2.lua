local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPack = game:GetService("StarterPack")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local State = {
	SearchQuery = "",
	Matches = {},
	SelectedItem = nil,
	scanEnabled = true,
	pulseEnabled = false,
	hookEnabled = true,
	ActiveTab = "Tree",
	Minimized = false,
	SettingsOpen = false,
	ColorAccordionOpen = false,
	TargetMode = "Window",
	ThemeName = "Yellow",
	Transparency = 0.12,
	WindowColor = Color3.fromRGB(16, 16, 20),
	BorderColor = Color3.fromRGB(255, 204, 0),
	Logs = {},
	WatchedBackpacks = {},
	WatchedAttrObjects = {}
}

local ColorPalette = {
	{ Name = "Yellow", Color = Color3.fromRGB(255, 204, 0) },
	{ Name = "Blue", Color = Color3.fromRGB(56, 139, 255) },
	{ Name = "Orange", Color = Color3.fromRGB(255, 128, 0) },
	{ Name = "Green", Color = Color3.fromRGB(46, 204, 113) },
	{ Name = "Red", Color = Color3.fromRGB(235, 64, 52) },
	{ Name = "Purple", Color = Color3.fromRGB(155, 89, 182) },
	{ Name = "White", Color = Color3.fromRGB(240, 240, 245) },
	{ Name = "Pink", Color = Color3.fromRGB(255, 105, 180) },
	{ Name = "Orange-Purple", Color = Color3.fromRGB(205, 92, 155) },
	{ Name = "Rainbow", Color = Color3.fromRGB(255, 0, 128) },
}

local function isServerObject(obj)
	if not obj then return true end
	if obj:IsA("Script") and not obj:IsA("LocalScript") then
		return true
	end
	local full = obj:GetFullName()
	if full:find("ServerScriptService") or full:find("ServerStorage") then
		return true
	end
	return false
end

local function formatSingleArg(v, depth)
	depth = depth or 0
	local t = typeof(v)
	if t == "Instance" then
		return string.format("%s(%s)", v.Name, v.ClassName)
	elseif t == "Vector3" then
		return string.format("V3(%.1f, %.1f, %.1f)", v.X, v.Y, v.Z)
	elseif t == "CFrame" then
		local p = v.Position
		return string.format("CF(%.1f, %.1f, %.1f)", p.X, p.Y, p.Z)
	elseif t == "table" then
		if depth >= 2 then return "{...}" end
		local parts = {}
		local count = 0
		for k, val in pairs(v) do
			count += 1
			if count > 6 then
				table.insert(parts, "...")
				break
			end
			table.insert(parts, tostring(k) .. "=" .. formatSingleArg(val, depth + 1))
		end
		return "{" .. table.concat(parts, ", ") .. "}"
	end
	return tostring(v)
end

local function formatArgs(...)
	local n = select("#", ...)
	if n == 0 then return "none" end
	local out = {}
	for i = 1, n do
		table.insert(out, formatSingleArg(select(i, ...), 0))
	end
	return table.concat(out, ", ")
end

local function formatAttributes(inst)
	if not inst or typeof(inst) ~= "Instance" then return "" end
	local ok, attrs = pcall(function() return inst:GetAttributes() end)
	if not ok or type(attrs) ~= "table" then return "" end
	local list = {}
	for k, v in pairs(attrs) do
		table.insert(list, tostring(k) .. "=" .. formatSingleArg(v, 1))
	end
	if #list == 0 then return "" end
	return " [Attr: " .. table.concat(list, ", ") .. "]"
end

local refreshOutput

local function LogEvent(tag, message)
	local stamp = os.date("%X")
	table.insert(State.Logs, 1, string.format("[%s] [%s] %s", stamp, tostring(tag), tostring(message)))
	if #State.Logs > 120 then
		table.remove(State.Logs)
	end
	if refreshOutput and State.ActiveTab == "Events" and not State.Minimized then
		refreshOutput()
	end
end

local function watchAttributes(inst, tag)
	if not inst or typeof(inst) ~= "Instance" or State.WatchedAttrObjects[inst] then return end
	State.WatchedAttrObjects[inst] = true
	inst.AttributeChanged:Connect(function(attrName)
		if State.hookEnabled then
			local val = inst:GetAttribute(attrName)
			LogEvent(tag, string.format("%s.%s = %s", inst:GetFullName(), tostring(attrName), formatSingleArg(val, 1)))
		end
	end)
end

local function getRayAndAimSnapshot(...)
	local cam = Workspace.CurrentCamera
	local char = LocalPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local camPos = cam and cam.CFrame.Position or Vector3.zero
	local camLook = cam and cam.CFrame.LookVector or Vector3.zAxis
	local hrpPos = hrp and hrp.Position or Vector3.zero
	local argsSummary = formatArgs(...)
	return string.format("HRP=(%.1f,%.1f,%.1f) Cam=(%.1f,%.1f,%.1f) Look=(%.2f,%.2f,%.2f) Args=[%s]",
		hrpPos.X, hrpPos.Y, hrpPos.Z,
		camPos.X, camPos.Y, camPos.Z,
		camLook.X, camLook.Y, camLook.Z,
		argsSummary
	)
end

local function watchBackpack(bp)
	if not bp or State.WatchedBackpacks[bp] then return end
	State.WatchedBackpacks[bp] = true
	LogEvent("BACKPACK", "Підключено відстеження " .. bp:GetFullName())

	bp.ChildAdded:Connect(function(child)
		if State.scanEnabled then
			watchAttributes(child, "ITEM_ATTR")
			LogEvent("BP_ADD", string.format("%s [%s]%s", child.Name, child.ClassName, formatAttributes(child)))
		end
	end)

	for _, item in ipairs(bp:GetChildren()) do
		watchAttributes(item, "ITEM_ATTR")
	end
end

local function searchByItemName(query)
	local clean = (query or ""):gsub("^%s+", ""):gsub("%s+$", ""):lower()
	local results = {}
	local seen = {}

	local roots = {
		LocalPlayer.Character,
		LocalPlayer:FindFirstChild("Backpack"),
		StarterPack,
		ReplicatedStorage,
		Workspace
	}

	local function checkInstance(inst)
		if not inst or seen[inst] or isServerObject(inst) then return end
		local nameLow = inst.Name:lower()
		local match = (clean == "" and inst:IsA("Tool")) or (clean ~= "" and nameLow:find(clean, 1, true) ~= nil)
		if match then
			seen[inst] = true
			table.insert(results, inst)
		end
	end

	for _, root in ipairs(roots) do
		if root and not isServerObject(root) then
			checkInstance(root)
			for _, desc in ipairs(root:GetDescendants()) do
				if not isServerObject(desc) then
					checkInstance(desc)
				end
			end
		end
	end

	return results
end

local function buildFullTreeReport(target)
	if not target or not target.Parent then
		return "Предмет не знайдено або він видалений. Введіть назву та натисніть Search Tree."
	end

	local lines = {}
	table.insert(lines, "=== ОБ'ЄКТ ===")
	table.insert(lines, "Назва: " .. target.Name .. " [" .. target.ClassName .. "]")
	table.insert(lines, "Шлях: " .. target:GetFullName() .. formatAttributes(target))

	local clientScripts = {}
	local eventsInside = {}

	local function walk(node, depth)
		if isServerObject(node) then return end
		local indent = string.rep("  ", depth)
		table.insert(lines, string.format("%s- %s [%s] -> %s%s", indent, node.Name, node.ClassName, node:GetFullName(), formatAttributes(node)))

		if node:IsA("LocalScript") or node:IsA("ModuleScript") then
			table.insert(clientScripts, string.format("[%s] %s", node.ClassName, node:GetFullName()))
		elseif node:IsA("RemoteEvent") or node:IsA("RemoteFunction") or node:IsA("BindableEvent") then
			table.insert(eventsInside, string.format("[%s] %s", node.ClassName, node:GetFullName()))
		end

		for _, child in ipairs(node:GetChildren()) do
			walk(child, depth + 1)
		end
	end

	table.insert(lines, "\n=== ПОВНЕ ДЕРЕВО ===")
	walk(target, 0)

	table.insert(lines, "\n=== СКРИПТИ (КРІМ СЕРВЕРНИХ) ===")
	if #clientScripts == 0 then
		table.insert(lines, "Клієнтських скриптів у дереві не знайдено.")
	else
		for _, sPath in ipairs(clientScripts) do
			table.insert(lines, "• " .. sPath)
		end
	end

	table.insert(lines, "\n=== ІВЕНТИ В ДЕРЕВІ ===")
	if #eventsInside == 0 then
		table.insert(lines, "Івентів усередині дерева немає.")
	else
		for _, evPath in ipairs(eventsInside) do
			table.insert(lines, "• " .. evPath)
		end
	end

	return table.concat(lines, "\n")
end

local bp = LocalPlayer:FindFirstChild("Backpack")
if bp then
	watchBackpack(bp)
end
LocalPlayer.ChildAdded:Connect(function(child)
	if child.Name == "Backpack" then
		watchBackpack(child)
	end
end)

task.spawn(function()
	while true do
		task.wait(1.5)
		if State.scanEnabled and State.pulseEnabled then
			LogEvent("PULSE", getRayAndAimSnapshot())
		end
	end
end)

if typeof(hookmetamethod) == "function" and typeof(getnamecallmethod) == "function" then
	local oldNamecall
	oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
		local method = getnamecallmethod()
		if State.hookEnabled and (not checkcaller or not checkcaller()) and typeof(self) == "Instance" and not isServerObject(self) then
			if (method == "FireServer" or method == "InvokeServer") and (self:IsA("RemoteEvent") or self:IsA("RemoteFunction")) then
				watchAttributes(self, "REM_ATTR")
				local fullName = self:GetFullName()
				local argsStr = formatArgs(...)
				task.defer(LogEvent, method, string.format("%s%s | Args: %s", fullName, formatAttributes(self), argsStr))
				if string.find(fullName, "Shoot", 1, true) or string.find(fullName:lower(), "gun", 1, true) or string.find(fullName:lower(), "knife", 1, true) then
					task.defer(LogEvent, "RAY_SHOT", method .. " " .. fullName .. " | " .. getRayAndAimSnapshot(...))
				end
			elseif method == "Fire" and self:IsA("BindableEvent") then
				watchAttributes(self, "BIND_ATTR")
				local fullName = self:GetFullName()
				local argsStr = formatArgs(...)
				task.defer(LogEvent, "Bindable:Fire", string.format("%s%s | Args: %s", fullName, formatAttributes(self), argsStr))
			end
		end
		return oldNamecall(self, ...)
	end)
	LogEvent("INIT", "Логгер запущено з __namecall хуком (Backpack, PULSE, RAY_SHOT, атрибути).")
else
	LogEvent("INIT", "Логгер запущено без __namecall хука.")
end

if PlayerGui:FindFirstChild("MM2_Name_Tree_Logger_UI") then
	PlayerGui.MM2_Name_Tree_Logger_UI:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MM2_Name_Tree_Logger_UI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 320, 0, 395)
MainFrame.Position = UDim2.new(0.03, 0, 0.11, 0)
MainFrame.BackgroundColor3 = State.WindowColor
MainFrame.BackgroundTransparency = State.Transparency
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim2.new(0, 10)

local MainStroke = Instance.new("UIStroke")
MainStroke.Thickness = 1.8
MainStroke.Color = State.BorderColor
MainStroke.Parent = MainFrame

local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 36)
TopBar.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
TopBar.BackgroundTransparency = State.Transparency
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame
Instance.new("UICorner", TopBar).CornerRadius = UDim2.new(0, 10)

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -80, 1, 0)
TitleLabel.Position = UDim2.new(0, 10, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "MM2 TREE & EVENT TRACER"
TitleLabel.TextColor3 = Color3.fromRGB(245, 245, 250)
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 12
TitleLabel.Parent = TopBar

local GearBtn = Instance.new("TextButton")
GearBtn.Size = UDim2.new(0, 30, 0, 28)
GearBtn.Position = UDim2.new(1, -66, 0.5, -14)
GearBtn.BackgroundColor3 = Color3.fromRGB(38, 38, 46)
GearBtn.Text = "⚙"
GearBtn.TextColor3 = Color3.fromRGB(240, 240, 245)
GearBtn.Font = Enum.Font.GothamBold
GearBtn.TextSize = 15
GearBtn.Parent = TopBar
Instance.new("UICorner", GearBtn).CornerRadius = UDim2.new(0, 6)

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 30, 0, 28)
MinBtn.Position = UDim2.new(1, -33, 0.5, -14)
MinBtn.BackgroundColor3 = Color3.fromRGB(38, 38, 46)
MinBtn.Text = "-"
MinBtn.TextColor3 = Color3.fromRGB(240, 240, 245)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 16
MinBtn.Parent = TopBar
Instance.new("UICorner", MinBtn).CornerRadius = UDim2.new(0, 6)

local BodyFrame = Instance.new("Frame")
BodyFrame.Size = UDim2.new(1, -12, 1, -44)
BodyFrame.Position = UDim2.new(0, 6, 0, 40)
BodyFrame.BackgroundTransparency = 1
BodyFrame.Parent = MainFrame

local SearchRow = Instance.new("Frame")
SearchRow.Size = UDim2.new(1, 0, 0, 32)
SearchRow.BackgroundTransparency = 1
SearchRow.Parent = BodyFrame

local NameBox = Instance.new("TextBox")
NameBox.Size = UDim2.new(0.66, -4, 1, 0)
NameBox.BackgroundColor3 = Color3.fromRGB(26, 26, 34)
NameBox.PlaceholderText = "Назва предмета..."
NameBox.PlaceholderColor3 = Color3.fromRGB(130, 130, 145)
NameBox.Text = ""
NameBox.TextColor3 = Color3.fromRGB(255, 255, 255)
NameBox.Font = Enum.Font.GothamSemibold
NameBox.TextSize = 11
NameBox.ClearTextOnFocus = false
NameBox.Parent = SearchRow
Instance.new("UICorner", NameBox).CornerRadius = UDim2.new(0, 6)

local SearchBtn = Instance.new("TextButton")
SearchBtn.Size = UDim2.new(0.34, 0, 1, 0)
SearchBtn.Position = UDim2.new(0.66, 0, 0, 0)
SearchBtn.BackgroundColor3 = Color3.fromRGB(42, 42, 54)
SearchBtn.Text = "Search Tree"
SearchBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SearchBtn.Font = Enum.Font.GothamBold
SearchBtn.TextSize = 11
SearchBtn.Parent = SearchRow
Instance.new("UICorner", SearchBtn).CornerRadius = UDim2.new(0, 6)

local ModesRow = Instance.new("Frame")
ModesRow.Size = UDim2.new(1, 0, 0, 28)
ModesRow.Position = UDim2.new(0, 0, 0, 36)
ModesRow.BackgroundTransparency = 1
ModesRow.Parent = BodyFrame

local HookToggleBtn = Instance.new("TextButton")
HookToggleBtn.Size = UDim2.new(0.32, -2, 1, 0)
HookToggleBtn.BackgroundColor3 = Color3.fromRGB(35, 78, 52)
HookToggleBtn.Text = "Hook: ON"
HookToggleBtn.TextColor3 = Color3.fromRGB(240, 240, 245)
HookToggleBtn.Font = Enum.Font.GothamBold
HookToggleBtn.TextSize = 10
HookToggleBtn.Parent = ModesRow
Instance.new("UICorner", HookToggleBtn).CornerRadius = UDim2.new(0, 6)

local PulseToggleBtn = Instance.new("TextButton")
PulseToggleBtn.Size = UDim2.new(0.34, -2, 1, 0)
PulseToggleBtn.Position = UDim2.new(0.33, 0, 0, 0)
PulseToggleBtn.BackgroundColor3 = Color3.fromRGB(32, 32, 40)
PulseToggleBtn.Text = "Pulse: OFF"
PulseToggleBtn.TextColor3 = Color3.fromRGB(240, 240, 245)
PulseToggleBtn.Font = Enum.Font.GothamBold
PulseToggleBtn.TextSize = 10
PulseToggleBtn.Parent = ModesRow
Instance.new("UICorner", PulseToggleBtn).CornerRadius = UDim2.new(0, 6)

local ClearLogBtn = Instance.new("TextButton")
ClearLogBtn.Size = UDim2.new(0.32, 0, 1, 0)
ClearLogBtn.Position = UDim2.new(0.68, 0, 0, 0)
ClearLogBtn.BackgroundColor3 = Color3.fromRGB(32, 32, 40)
ClearLogBtn.Text = "Clear Logs"
ClearLogBtn.TextColor3 = Color3.fromRGB(240, 240, 245)
ClearLogBtn.Font = Enum.Font.GothamBold
ClearLogBtn.TextSize = 10
ClearLogBtn.Parent = ModesRow
Instance.new("UICorner", ClearLogBtn).CornerRadius = UDim2.new(0, 6)

local MatchesScroll = Instance.new("ScrollingFrame")
MatchesScroll.Size = UDim2.new(1, 0, 0, 56)
MatchesScroll.Position = UDim2.new(0, 0, 0, 68)
MatchesScroll.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
MatchesScroll.ScrollBarThickness = 3
MatchesScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
MatchesScroll.Parent = BodyFrame
Instance.new("UICorner", MatchesScroll).CornerRadius = UDim2.new(0, 6)

local MatchesLayout = Instance.new("UIListLayout")
MatchesLayout.Padding = UDim2.new(0, 3)
MatchesLayout.Parent = MatchesScroll

local TabsRow = Instance.new("Frame")
TabsRow.Size = UDim2.new(1, 0, 0, 26)
TabsRow.Position = UDim2.new(0, 0, 0, 128)
TabsRow.BackgroundTransparency = 1
TabsRow.Parent = BodyFrame

local TreeTabBtn = Instance.new("TextButton")
TreeTabBtn.Size = UDim2.new(0.49, 0, 1, 0)
TreeTabBtn.BackgroundColor3 = Color3.fromRGB(48, 48, 62)
TreeTabBtn.Text = "Tree & Scripts"
TreeTabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
TreeTabBtn.Font = Enum.Font.GothamBold
TreeTabBtn.TextSize = 10
TreeTabBtn.Parent = TabsRow
Instance.new("UICorner", TreeTabBtn).CornerRadius = UDim2.new(0, 6)

local EventsTabBtn = Instance.new("TextButton")
EventsTabBtn.Size = UDim2.new(0.49, 0, 1, 0)
EventsTabBtn.Position = UDim2.new(0.51, 0, 0, 0)
EventsTabBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
EventsTabBtn.Text = "Events Log"
EventsTabBtn.TextColor3 = Color3.fromRGB(220, 220, 230)
EventsTabBtn.Font = Enum.Font.GothamBold
EventsTabBtn.TextSize = 10
EventsTabBtn.Parent = TabsRow
Instance.new("UICorner", EventsTabBtn).CornerRadius = UDim2.new(0, 6)

local OutputScroll = Instance.new("ScrollingFrame")
OutputScroll.Size = UDim2.new(1, 0, 1, -158)
OutputScroll.Position = UDim2.new(0, 0, 0, 158)
OutputScroll.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
OutputScroll.ScrollBarThickness = 4
OutputScroll.CanvasSize = UDim2.new(0, 0, 0, 600)
OutputScroll.Parent = BodyFrame
Instance.new("UICorner", OutputScroll).CornerRadius = UDim2.new(0, 6)

local OutputText = Instance.new("TextLabel")
OutputText.Size = UDim2.new(1, -10, 0, 600)
OutputText.Position = UDim2.new(0, 5, 0, 4)
OutputText.BackgroundTransparency = 1
OutputText.Text = "Введіть назву предмета та натисніть Search Tree."
OutputText.TextColor3 = Color3.fromRGB(225, 230, 235)
OutputText.TextXAlignment = Enum.TextXAlignment.Left
OutputText.TextYAlignment = Enum.TextYAlignment.Top
OutputText.TextWrapped = true
OutputText.Font = Enum.Font.Code
OutputText.TextSize = 10
OutputText.Parent = OutputScroll

local SettingsPanel = Instance.new("ScrollingFrame")
SettingsPanel.Size = UDim2.new(1, -12, 1, -44)
SettingsPanel.Position = UDim2.new(0, 6, 0, 40)
SettingsPanel.BackgroundTransparency = 1
SettingsPanel.ScrollBarThickness = 3
SettingsPanel.CanvasSize = UDim2.new(0, 0, 0, 340)
SettingsPanel.Visible = false
SettingsPanel.Parent = MainFrame

local SettingsList = Instance.new("UIListLayout")
SettingsList.Padding = UDim2.new(0, 6)
SettingsList.SortOrder = Enum.SortOrder.LayoutOrder
SettingsList.Parent = SettingsPanel

local TransBox = Instance.new("Frame")
TransBox.Size = UDim2.new(1, 0, 0, 44)
TransBox.LayoutOrder = 1
TransBox.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
TransBox.Parent = SettingsPanel
Instance.new("UICorner", TransBox).CornerRadius = UDim2.new(0, 7)

local TransLabel = Instance.new("TextLabel")
TransLabel.Size = UDim2.new(1, -12, 0, 18)
TransLabel.Position = UDim2.new(0, 6, 0, 2)
TransLabel.BackgroundTransparency = 1
TransLabel.Text = "Transparency: " .. string.format("%.2f", State.Transparency)
TransLabel.TextColor3 = Color3.fromRGB(235, 235, 240)
TransLabel.TextXAlignment = Enum.TextXAlignment.Left
TransLabel.Font = Enum.Font.GothamSemibold
TransLabel.TextSize = 11
TransLabel.Parent = TransBox

local SliderTrack = Instance.new("Frame")
SliderTrack.Size = UDim2.new(1, -16, 0, 10)
SliderTrack.Position = UDim2.new(0, 8, 0, 25)
SliderTrack.BackgroundColor3 = Color3.fromRGB(55, 55, 68)
SliderTrack.Parent = TransBox
Instance.new("UICorner", SliderTrack).CornerRadius = UDim2.new(1, 0)

local SliderFill = Instance.new("Frame")
SliderFill.Size = UDim2.new(State.Transparency / 0.85, 0, 1, 0)
SliderFill.BackgroundColor3 = State.BorderColor
SliderFill.Parent = SliderTrack
Instance.new("UICorner", SliderFill).CornerRadius = UDim2.new(1, 0)

local SliderBtn = Instance.new("TextButton")
SliderBtn.Size = UDim2.new(1, 0, 1, 12)
SliderBtn.Position = UDim2.new(0, 0, 0, -6)
SliderBtn.BackgroundTransparency = 1
SliderBtn.Text = ""
SliderBtn.Parent = SliderTrack

local TargetBtn = Instance.new("TextButton")
TargetBtn.Size = UDim2.new(1, 0, 0, 30)
TargetBtn.LayoutOrder = 2
TargetBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
TargetBtn.Text = "Target: " .. State.TargetMode
TargetBtn.TextColor3 = Color3.fromRGB(240, 240, 245)
TargetBtn.Font = Enum.Font.GothamSemibold
TargetBtn.TextSize = 12
TargetBtn.Parent = SettingsPanel
Instance.new("UICorner", TargetBtn).CornerRadius = UDim2.new(0, 7)

local AccordionBtn = Instance.new("TextButton")
AccordionBtn.Size = UDim2.new(1, 0, 0, 30)
AccordionBtn.LayoutOrder = 3
AccordionBtn.BackgroundColor3 = Color3.fromRGB(34, 34, 42)
AccordionBtn.Text = "▸ Colors (" .. State.ThemeName .. ")"
AccordionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
AccordionBtn.Font = Enum.Font.GothamBold
AccordionBtn.TextSize = 12
AccordionBtn.Parent = SettingsPanel
Instance.new("UICorner", AccordionBtn).CornerRadius = UDim2.new(0, 7)

local ColorListFrame = Instance.new("Frame")
ColorListFrame.Size = UDim2.new(1, 0, 0, 210)
ColorListFrame.LayoutOrder = 4
ColorListFrame.BackgroundTransparency = 1
ColorListFrame.Visible = false
ColorListFrame.Parent = SettingsPanel

local ColorGrid = Instance.new("UIGridLayout")
ColorGrid.CellSize = UDim2.new(0.48, 0, 0, 26)
ColorGrid.CellPadding = UDim2.new(0.04, 0, 0, 5)
ColorGrid.Parent = ColorListFrame

refreshOutput = function()
	local text = ""
	if State.ActiveTab == "Tree" then
		text = buildFullTreeReport(State.SelectedItem)
	else
		text = (#State.Logs == 0)
			and "Подій ще немає."
			or table.concat(State.Logs, "\n\n")
	end

	OutputText.Text = text
	local h = math.max(180, (#text / 42) * 14 + 30)
	OutputText.Size = UDim2.new(1, -10, 0, h)
	OutputScroll.CanvasSize = UDim2.new(0, 0, 0, h)
end

local function applyTheme()
	MainFrame.BackgroundTransparency = State.Transparency
	TopBar.BackgroundTransparency = State.Transparency
	SliderFill.BackgroundColor3 = State.BorderColor
	if State.TargetMode == "Window" then
		MainFrame.BackgroundColor3 = State.WindowColor
	else
		MainStroke.Color = State.BorderColor
	end
end

for _, item in ipairs(ColorPalette) do
	local cBtn = Instance.new("TextButton")
	cBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
	cBtn.Text = item.Name
	cBtn.TextColor3 = item.Color
	cBtn.Font = Enum.Font.GothamBold
	cBtn.TextSize = 11
	cBtn.Parent = ColorListFrame
	Instance.new("UICorner", cBtn).CornerRadius = UDim2.new(0, 6)

	local cStroke = Instance.new("UIStroke")
	cStroke.Thickness = 1
	cStroke.Color = item.Color
	cStroke.Parent = cBtn

	cBtn.Activated:Connect(function()
		State.ThemeName = item.Name
		AccordionBtn.Text = (State.ColorAccordionOpen and "▾ Colors (" or "▸ Colors (") .. State.ThemeName .. ")"
		if State.TargetMode == "Window" then
			State.WindowColor = item.Color:Lerp(Color3.fromRGB(15, 15, 18), 0.75)
		else
			State.BorderColor = item.Color
		end
		applyTheme()
	end)
end

local function runSearch()
	State.SearchQuery = NameBox.Text
	State.Matches = searchByItemName(State.SearchQuery)

	for _, child in ipairs(MatchesScroll:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	for i, inst in ipairs(State.Matches) do
		local mBtn = Instance.new("TextButton")
		mBtn.Size = UDim2.new(1, -6, 0, 22)
		mBtn.BackgroundColor3 = (State.SelectedItem == inst) and Color3.fromRGB(52, 52, 68) or Color3.fromRGB(30, 30, 38)
		mBtn.Text = string.format("%d. %s [%s] -> %s", i, inst.Name, inst.ClassName, inst.Parent and inst.Parent.Name or "nil")
		mBtn.TextColor3 = Color3.fromRGB(240, 240, 245)
		mBtn.TextXAlignment = Enum.TextXAlignment.Left
		mBtn.Font = Enum.Font.GothamSemibold
		mBtn.TextSize = 10
		mBtn.Parent = MatchesScroll
		Instance.new("UICorner", mBtn).CornerRadius = UDim2.new(0, 5)

		mBtn.Activated:Connect(function()
			State.SelectedItem = inst
			runSearch()
			refreshOutput()
		end)
	end

	MatchesScroll.CanvasSize = UDim2.new(0, 0, 0, #State.Matches * 25 + 6)

	if #State.Matches > 0 then
		if not State.SelectedItem or not table.find(State.Matches, State.SelectedItem) then
			State.SelectedItem = State.Matches[1]
		end
		refreshOutput()
	else
		State.SelectedItem = nil
		OutputText.Text = "За запитом '" .. tostring(State.SearchQuery) .. "' нічого не знайдено."
	end
end

SearchBtn.Activated:Connect(runSearch)
NameBox.FocusLost:Connect(function(enterPressed)
	if enterPressed then
		runSearch()
	end
end)

HookToggleBtn.Activated:Connect(function()
	State.hookEnabled = not State.hookEnabled
	HookToggleBtn.Text = "Hook: " .. (State.hookEnabled and "ON" or "OFF")
	HookToggleBtn.BackgroundColor3 = State.hookEnabled and Color3.fromRGB(35, 78, 52) or Color3.fromRGB(32, 32, 40)
end)

PulseToggleBtn.Activated:Connect(function()
	State.pulseEnabled = not State.pulseEnabled
	PulseToggleBtn.Text = "Pulse: " .. (State.pulseEnabled and "ON" or "OFF")
	PulseToggleBtn.BackgroundColor3 = State.pulseEnabled and Color3.fromRGB(35, 78, 52) or Color3.fromRGB(32, 32, 40)
end)

ClearLogBtn.Activated:Connect(function()
	table.clear(State.Logs)
	refreshOutput()
end)

TreeTabBtn.Activated:Connect(function()
	State.ActiveTab = "Tree"
	TreeTabBtn.BackgroundColor3 = Color3.fromRGB(48, 48, 62)
	EventsTabBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
	refreshOutput()
end)

EventsTabBtn.Activated:Connect(function()
	State.ActiveTab = "Events"
	EventsTabBtn.BackgroundColor3 = Color3.fromRGB(48, 48, 62)
	TreeTabBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
	refreshOutput()
end)

MinBtn.Activated:Connect(function()
	State.Minimized = not State.Minimized
	MinBtn.Text = State.Minimized and "+" or "-"
	BodyFrame.Visible = not State.Minimized and not State.SettingsOpen
	SettingsPanel.Visible = not State.Minimized and State.SettingsOpen
	MainFrame.Size = State.Minimized and UDim2.new(0, 320, 0, 36) or UDim2.new(0, 320, 0, 395)
end)

GearBtn.Activated:Connect(function()
	if State.Minimized then return end
	State.SettingsOpen = not State.SettingsOpen
	BodyFrame.Visible = not State.SettingsOpen
	SettingsPanel.Visible = State.SettingsOpen
end)

TargetBtn.Activated:Connect(function()
	State.TargetMode = (State.TargetMode == "Window") and "Border" or "Window"
	TargetBtn.Text = "Target: " .. State.TargetMode
end)

AccordionBtn.Activated:Connect(function()
	State.ColorAccordionOpen = not State.ColorAccordionOpen
	ColorListFrame.Visible = State.ColorAccordionOpen
	AccordionBtn.Text = (State.ColorAccordionOpen and "▾ Colors (" or "▸ Colors (") .. State.ThemeName .. ")"
end)

local draggingSlider = false
SliderBtn.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingSlider = true
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingSlider = false
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if draggingSlider and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType.MouseMovement) then
		local relX = math.clamp((input.Position.X - SliderTrack.AbsolutePosition.X) / SliderTrack.AbsoluteSize.X, 0, 1)
		State.Transparency = relX * 0.85
		SliderFill.Size = UDim2.new(relX, 0, 1, 0)
		TransLabel.Text = "Transparency: " .. string.format("%.2f", State.Transparency)
		applyTheme()
	end
end)

task.spawn(function()
	while task.wait(0.25) do
		if State.ThemeName == "Rainbow" and not State.Minimized then
			local hue = (os.clock() * 0.25) % 1
			local rainbowCol = Color3.fromHSV(hue, 0.85, 1)
			if State.TargetMode == "Window" then
				State.WindowColor = rainbowCol:Lerp(Color3.fromRGB(15, 15, 18), 0.75)
			else
				State.BorderColor = rainbowCol
			end
			applyTheme()
		end
	end
end)

applyTheme()
refreshOutput()
