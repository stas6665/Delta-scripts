local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local UIS = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local LoadingGui = Instance.new("ScreenGui")
LoadingGui.Name = "MM2LoadingScreen"
LoadingGui.ResetOnSpawn = false
LoadingGui.IgnoreGuiInset = true
LoadingGui.Parent = PlayerGui

local Background = Instance.new("Frame")
Background.Size = UDim2.fromScale(1, 1)
Background.BackgroundColor3 = Color3.fromRGB(12, 12, 15)
Background.BorderSizePixel = 0
Background.Parent = LoadingGui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 50)
Title.Position = UDim2.new(0, 0, 0.42, 0)
Title.BackgroundTransparency = 1
Title.Text = "MM2 HUB"
Title.TextColor3 = Color3.fromRGB(220, 220, 220)
Title.TextSize = 30
Title.Font = Enum.Font.GothamBold
Title.Parent = Background

local Percent = Instance.new("TextLabel")
Percent.Size = UDim2.new(1, 0, 0, 30)
Percent.Position = UDim2.new(0, 0, 0.52, 0)
Percent.BackgroundTransparency = 1
Percent.Text = "1%"
Percent.TextColor3 = Color3.fromRGB(255, 255, 255)
Percent.TextSize = 18
Percent.Font = Enum.Font.GothamMedium
Percent.Parent = Background

local Track = Instance.new("Frame")
Track.Size = UDim2.new(0, 300, 0, 8)
Track.Position = UDim2.new(0.5, -150, 0.58, 0)
Track.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
Track.BorderSizePixel = 0
Track.Parent = Background

local TrackCorner = Instance.new("UICorner", Track)
TrackCorner.CornerRadius = UDim.new(1, 0)

local Fill = Instance.new("Frame")
Fill.Size = UDim2.new(0.01, 0, 1, 0)
Fill.BackgroundColor3 = Color3.fromRGB(160, 25, 45)
Fill.BorderSizePixel = 0
Fill.Parent = Track

local FillCorner = Instance.new("UICorner", Fill)
FillCorner.CornerRadius = UDim.new(1, 0)

local FillTween = TweenService:Create(
	Fill,
	TweenInfo.new(2, Enum.EasingStyle.Linear),
	{Size = UDim2.new(1, 0, 1, 0)}
)

FillTween:Play()

local percentThread = task.spawn(function()
	for i = 1, 100 do
		Percent.Text = i .. "%"
		task.wait(0.02)
	end
end)

FillTween.Completed:Wait()
pcall(task.cancel, percentThread)

local Fade = TweenService:Create(
	Background,
	TweenInfo.new(0.25),
	{BackgroundTransparency = 1}
)

Fade:Play()
Fade.Completed:Wait()
LoadingGui:Destroy()

local Old = PlayerGui:FindFirstChild("MM2UltimateUI")
if Old then
	Old:Destroy()
end

local GUI
local Connections = {}
local Threads = {}
local Alive = true
local ActiveESPObjects = {}
local RoundRolesCache = {} -- [playerName] = { Role = string, Dead = boolean }
local HeroPlayers = {}
local TrackedDrops = {}

local function Connect(signal, callback)
	local connection = signal:Connect(callback)
	table.insert(Connections, connection)
	return connection
end

local function TrackThread(thread)
	table.insert(Threads, thread)
	return thread
end

local function SpawnTracked(fn)
	return TrackThread(task.spawn(fn))
end

local function DelayTracked(delaySeconds, fn)
	return TrackThread(task.delay(delaySeconds, fn))
end

local Colors = {
	Red = Color3.fromRGB(220, 45, 55),
	Blue = Color3.fromRGB(45, 115, 230),
	Green = Color3.fromRGB(50, 190, 105),
	Yellow = Color3.fromRGB(235, 195, 45),
	Purple = Color3.fromRGB(145, 75, 220),
	Pink = Color3.fromRGB(230, 90, 165),
	Orange = Color3.fromRGB(235, 125, 45),
	Cyan = Color3.fromRGB(55, 190, 220),
}

local ColorNames = {
	"Red", "Blue", "Green", "Yellow", "Purple", "Pink", "Orange", "Cyan", "Rainbow"
}

local ColorValues = {
	["Red"] = Colors.Red,
	["Blue"] = Colors.Blue,
	["Green"] = Colors.Green,
	["Yellow"] = Colors.Yellow,
	["Purple"] = Colors.Purple,
	["Pink"] = Colors.Pink,
	["Orange"] = Colors.Orange,
	["Cyan"] = Colors.Cyan,
}

local ThemeColors = {
	["Red"] = Color3.fromRGB(65, 25, 30),
	["Blue"] = Color3.fromRGB(23, 38, 65),
	["Green"] = Color3.fromRGB(24, 53, 39),
	["Yellow"] = Color3.fromRGB(60, 52, 25),
	["Purple"] = Color3.fromRGB(46, 30, 65),
	["Pink"] = Color3.fromRGB(65, 30, 48),
	["Orange"] = Color3.fromRGB(65, 40, 24),
	["Cyan"] = Color3.fromRGB(25, 52, 62),
}

local Accent = Colors.Red
local OutlineColor = Colors.Red

local RainbowOutline = false
local RainbowTheme = false

local ToggleRecords = {}
local AccordionRecords = {}

local ESP_Settings = {
	Sheriff = false,
	Murderer = false,
	Innocent = false,
	Hero = false
}

local AimbotSettings = {
	Enabled = false
}

local ShootButtonSettings = {
	Enabled = false
}

local AutoGrabSettings = {
	Enabled = false
}

local TrollSettings = {
	Enabled = false,
	TargetPlayer = nil,
	Speed = 18
}

GUI = Instance.new("ScreenGui")
GUI.Name = "MM2UltimateUI"
GUI.ResetOnSpawn = false
GUI.IgnoreGuiInset = true
GUI.DisplayOrder = 999
GUI.Parent = PlayerGui

local function RemoveESP(p)
	if ActiveESPObjects[p] then
		if ActiveESPObjects[p].Highlight then ActiveESPObjects[p].Highlight:Destroy() end
		if ActiveESPObjects[p].Billboard then ActiveESPObjects[p].Billboard:Destroy() end
		ActiveESPObjects[p] = nil
	end
end

local function ClearAllESP()
	for p, _ in pairs(ActiveESPObjects) do
		RemoveESP(p)
	end
	-- Страховка на случай, если объекты остались на персонажах
	for _, p in ipairs(Players:GetPlayers()) do
		local char = p.Character
		if char then
			for _, child in ipairs(char:GetChildren()) do
				if child:IsA("Highlight") then
					child:Destroy()
				end
			end
			local head = char:FindFirstChild("Head")
			local hrp = char:FindFirstChild("HumanoidRootPart")
			if head then
				for _, child in ipairs(head:GetChildren()) do
					if child:IsA("BillboardGui") then
						child:Destroy()
					end
				end
			end
			if hrp then
				for _, child in ipairs(hrp:GetChildren()) do
					if child:IsA("BillboardGui") then
						child:Destroy()
					end
				end
			end
		end
	end
end

local function ResetForNewMap()
	table.clear(RoundRolesCache)
	table.clear(HeroPlayers)
	table.clear(TrackedDrops)
	ClearAllESP()
end

local function Cleanup()
	if not Alive then return end
	Alive = false

	for _, thread in ipairs(Threads) do
		if coroutine.status(thread) ~= "dead" then
			pcall(task.cancel, thread)
		end
	end
	table.clear(Threads)

	for _, connection in ipairs(Connections) do
		if connection.Connected then
			connection:Disconnect()
		end
	end
	table.clear(Connections)

	ClearAllESP()

	if GUI then
		GUI:Destroy()
	end
end

local function New(class, properties, parent)
	local obj = Instance.new(class)
	for key, value in pairs(properties) do
		obj[key] = value
	end
	obj.Parent = parent
	return obj
end

local function Corner(parent, radius)
	New("UICorner", {CornerRadius = UDim.new(0, radius)}, parent)
end

local function Stroke(parent, color, thickness)
	return New("UIStroke", {
		Color = color,
		Thickness = thickness,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	}, parent)
end

local Crosshair = New("Frame", {
	Size = UDim2.fromOffset(8, 8),
	Position = UDim2.new(0.5, -4, 0.5, -4),
	BackgroundColor3 = Color3.fromRGB(220, 45, 55),
	BorderSizePixel = 0,
	Visible = false,
	ZIndex = 1000
}, GUI)
Corner(Crosshair, 50)

local ShootButton = New("TextButton", {
	Size = UDim2.fromOffset(190, 114),
	Position = UDim2.new(0.8, -95, 0.7, -57),
	BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	Text = "Shoot Murderer",
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 16,
	Font = Enum.Font.GothamBold,
	Visible = false,
	Active = true,
	Draggable = true,
	ZIndex = 1001
}, GUI)
Corner(ShootButton, 10)
Stroke(ShootButton, Color3.fromRGB(220, 45, 55), 3.5)

local Main = New("Frame", {
	Name = "MainWindow",
	Size = UDim2.fromOffset(480, 390),
	Position = UDim2.new(0.5, -240, 0.5, -195),
	BackgroundColor3 = Color3.fromRGB(24, 24, 28),
	BackgroundTransparency = 0,
	BorderSizePixel = 0
}, GUI)

Corner(Main, 14)
local MainStroke = Stroke(Main, OutlineColor, 2.5)

local Header = New("Frame", {
	Size = UDim2.new(1, 0, 0, 54),
	BackgroundColor3 = Color3.fromRGB(17, 17, 20),
	BackgroundTransparency = 0,
	BorderSizePixel = 0,
	ZIndex = 5
}, Main)

Corner(Header, 14)

local HeaderCover = New("Frame", {
	Size = UDim2.new(1, 0, 0, 14),
	Position = UDim2.new(0, 0, 1, -14),
	BackgroundColor3 = Header.BackgroundColor3,
	BorderSizePixel = 0,
	ZIndex = 5
}, Header)

local TitleLabel = New("TextLabel", {
	Size = UDim2.new(1, -150, 1, 0),
	Position = UDim2.fromOffset(16, 0),
	BackgroundTransparency = 1,
	Text = "MM2 Ultimate Hub",
	TextColor3 = Color3.new(1, 1, 1),
	TextSize = 19,
	Font = Enum.Font.GothamBold,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 6
}, Header)

local function HeaderButton(text, x, color)
	local button = New("TextButton", {
		Size = UDim2.fromOffset(36, 36),
		Position = UDim2.new(1, x, 0, 9),
		BackgroundColor3 = Color3.fromRGB(38, 38, 43),
		BackgroundTransparency = 0,
		Text = text,
		TextColor3 = color or Color3.new(1, 1, 1),
		TextSize = 20,
		Font = Enum.Font.GothamBold,
		BorderSizePixel = 0,
		ZIndex = 7
	}, Header)
	Corner(button, 9)
	return button
end

local MinimizeButton = HeaderButton("−", -126)
local SettingsButton = HeaderButton("⚙", -84)
local CloseButton = HeaderButton("×", -42, Color3.fromRGB(255, 90, 90))

local Body = New("Frame", {
	Name = "Body",
	Position = UDim2.fromOffset(0, 54),
	Size = UDim2.new(1, 0, 1, -54),
	BackgroundColor3 = Main.BackgroundColor3,
	BackgroundTransparency = 0,
	BorderSizePixel = 0
}, Main)

local Sidebar = New("Frame", {
	Size = UDim2.new(0, 130, 1, 0),
	BackgroundColor3 = Color3.fromRGB(19, 19, 23),
	BackgroundTransparency = 0,
	BorderSizePixel = 0
}, Body)

local function SidebarButton(text, yPos)
	local btn = New("TextButton", {
		Size = UDim2.new(1, -16, 0, 40),
		Position = UDim2.fromOffset(8, yPos),
		BackgroundColor3 = Color3.fromRGB(28, 28, 34),
		BackgroundTransparency = 0,
		Text = text,
		TextColor3 = Color3.new(1, 1, 1),
		TextSize = 15,
		Font = Enum.Font.GothamBold,
		BorderSizePixel = 0
	}, Sidebar)
	Corner(btn, 9)
	return btn
end

local EspTab = SidebarButton("◉  ESP", 16)
local SheriffTab = SidebarButton("🛡 Sheriff", 64)
local TrollTab = SidebarButton("🤪 Troll", 112)

local Content = New("Frame", {
	Position = UDim2.fromOffset(130, 0),
	Size = UDim2.new(1, -130, 1, 0),
	BackgroundTransparency = 1
}, Body)

local function Page(name)
	return New("ScrollingFrame", {
		Name = name,
		Size = UDim2.new(1, -16, 1, -16),
		Position = UDim2.fromOffset(8, 8),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = Accent,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		Visible = false,
		CanvasPosition = Vector2.new(0, 0)
	}, Content)
end

local EspPage = Page("ESP")
local SheriffPage = Page("SheriffPage")
local TrollPage = Page("TrollPage")
local SettingsPage = Page("Settings")
EspPage.Visible = true

local function AddLayout(page)
	local layout = New("UIListLayout", {
		Padding = UDim.new(0, 12),
		SortOrder = Enum.SortOrder.LayoutOrder
	}, page)
	Connect(layout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
		page.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 16)
	end)
	return layout
end

local EspLayout = AddLayout(EspPage)
local SheriffLayout = AddLayout(SheriffPage)
local TrollLayout = AddLayout(TrollPage)
local SettingsLayout = AddLayout(SettingsPage)

local function Label(parent, text)
	return New("TextLabel", {
		Size = UDim2.new(1, -6, 0, 34),
		BackgroundTransparency = 1,
		Text = text,
		TextColor3 = Color3.fromRGB(235, 235, 235),
		TextSize = 17,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left
	}, parent)
end

local function UpdateToggleAppearance(record)
	if RainbowTheme then
		record.Button.BackgroundColor3 = record.Enabled and Accent or Color3.fromRGB(0, 0, 0)
	else
		record.Button.BackgroundColor3 = record.Enabled and Accent or Color3.fromRGB(65, 65, 70)
	end
	record.Stroke.Color = Color3.fromRGB(0, 0, 0)
	record.Stroke.Transparency = 0
end

local function Toggle(parent, name, callback)
	local row = New("Frame", {
		Size = UDim2.new(1, -6, 0, 52),
		BackgroundColor3 = Color3.fromRGB(34, 34, 39),
		BackgroundTransparency = 0,
		BorderSizePixel = 0
	}, parent)
	Corner(row, 10)

	New("TextLabel", {
		Size = UDim2.new(1, -85, 1, 0),
		Position = UDim2.fromOffset(14, 0),
		BackgroundTransparency = 1,
		Text = name,
		TextColor3 = Color3.new(1, 1, 1),
		TextSize = 15,
		Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Left
	}, row)

	local enabled = false
	local button = New("TextButton", {
		Size = UDim2.fromOffset(54, 28),
		Position = UDim2.new(1, -64, 0.5, -14),
		BackgroundColor3 = Color3.fromRGB(65, 65, 70),
		BackgroundTransparency = 0,
		Text = "",
		BorderSizePixel = 0
	}, row)
	Corner(button, 14)
	local toggleStroke = Stroke(button, Color3.fromRGB(0, 0, 0), 1.5)

	local knob = New("Frame", {
		Size = UDim2.fromOffset(22, 22),
		Position = UDim2.fromOffset(3, 3),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0
	}, button)
	Corner(knob, 12)

	local record = {Button = button, Row = row, Stroke = toggleStroke, Knob = knob, Enabled = false}
	table.insert(ToggleRecords, record)

	Connect(button.Activated, function()
		enabled = not enabled
		record.Enabled = enabled
		TweenService:Create(knob, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Position = enabled and UDim2.new(1, -25, 0, 3) or UDim2.fromOffset(3, 3)
		}):Play()
		UpdateToggleAppearance(record)
		if callback then callback(enabled) end
	end)
	return button
end

local UpdateESP -- forward declaration

Label(EspPage, "ROLE ESP")
Toggle(EspPage, "ESP Murderer", function(state) ESP_Settings.Murderer = state; if UpdateESP then UpdateESP() end end)
Toggle(EspPage, "ESP Sheriff", function(state) ESP_Settings.Sheriff = state; if UpdateESP then UpdateESP() end end)
Toggle(EspPage, "ESP Innocent", function(state) ESP_Settings.Innocent = state; if UpdateESP then UpdateESP() end end)
Toggle(EspPage, "ESP Hero", function(state) ESP_Settings.Hero = state; if UpdateESP then UpdateESP() end end)

Label(SheriffPage, "SHERIFF COMBAT")
Toggle(SheriffPage, "AimBot", function(state) AimbotSettings.Enabled = state; Crosshair.Visible = state end)
Toggle(SheriffPage, "Shoot Murderer button", function(state) ShootButtonSettings.Enabled = state; ShootButton.Visible = state end)
Toggle(SheriffPage, "Auto Grab Gun", function(state) AutoGrabSettings.Enabled = state end)

Label(TrollPage, "TROLL ACTIONS")

-- Auto-updating target selection accordion
local TrollTargetContainer, TrollTargetHead
do
	local baseHeight = 48
	local itemHeight = 34
	local spacing = 6
	local defaultItems = 1
	local expandedHeight = baseHeight + (defaultItems * itemHeight) + ((defaultItems - 1) * spacing) + 16

	TrollTargetContainer = New("Frame", {
		Size = UDim2.new(1, -6, 0, baseHeight),
		BackgroundColor3 = Color3.fromRGB(34, 34, 39),
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		ClipsDescendants = true
	}, TrollPage)
	Corner(TrollTargetContainer, 10)

	TrollTargetHead = New("TextButton", {
		Size = UDim2.new(1, 0, 0, baseHeight),
		BackgroundTransparency = 1,
		Text = "Select Target: Auto (Murderer)     ▼",
		TextColor3 = Color3.new(1, 1, 1),
		TextSize = 15,
		Font = Enum.Font.GothamBold
	}, TrollTargetContainer)

	local listFrame = New("Frame", {
		Position = UDim2.fromOffset(12, baseHeight),
		Size = UDim2.new(1, -24, 0, 0),
		BackgroundTransparency = 1
	}, TrollTargetContainer)

	New("UIListLayout", {
		Padding = UDim.new(0, spacing),
		SortOrder = Enum.SortOrder.LayoutOrder
	}, listFrame)

	local open = false
	table.insert(AccordionRecords, {Container = TrollTargetContainer, Head = TrollTargetHead})

	local function RefreshPlayerList()
		for _, child in ipairs(listFrame:GetChildren()) do
			if child:IsA("TextButton") then
				child:Destroy()
			end
		end

		local playersList = Players:GetPlayers()
		local count = 0

		local autoBtn = New("TextButton", {
			Size = UDim2.new(1, 0, 0, itemHeight),
			BackgroundColor3 = Color3.fromRGB(44, 44, 50),
			BackgroundTransparency = 0,
			Text = "Auto (Murderer)",
			TextColor3 = Color3.new(1, 1, 1),
			TextSize = 14,
			Font = Enum.Font.GothamMedium,
			BorderSizePixel = 0
		}, listFrame)
		Corner(autoBtn, 8)
		Connect(autoBtn.Activated, function()
			TrollSettings.TargetPlayer = nil
			TrollTargetHead.Text = "Select Target: Auto (Murderer)     ▼"
		end)
		count = count + 1

		for _, p in ipairs(playersList) do
			if p ~= Player then
				local pBtn = New("TextButton", {
					Size = UDim2.new(1, 0, 0, itemHeight),
					BackgroundColor3 = Color3.fromRGB(44, 44, 50),
					BackgroundTransparency = 0,
					Text = p.Name,
					TextColor3 = Color3.new(1, 1, 1),
					TextSize = 14,
					Font = Enum.Font.GothamMedium,
					BorderSizePixel = 0
				}, listFrame)
				Corner(pBtn, 8)
				Connect(pBtn.Activated, function()
					TrollSettings.TargetPlayer = p
					TrollTargetHead.Text = "Select Target: " .. p.Name .. "     ▼"
				end)
				count = count + 1
			end
		end

		expandedHeight = baseHeight + (count * itemHeight) + ((count - 1) * spacing) + 16
		listFrame.Size = UDim2.new(1, -24, 0, expandedHeight - baseHeight - 12)
		if open then
			TrollTargetContainer.Size = UDim2.new(1, -6, 0, expandedHeight)
			TrollPage.CanvasSize = UDim2.new(0, 0, 0, TrollLayout.AbsoluteContentSize.Y + 16)
		end
	end

	Connect(Players.PlayerAdded, RefreshPlayerList)
	Connect(Players.PlayerRemoving, function(p)
		if TrollSettings.TargetPlayer == p then
			TrollSettings.TargetPlayer = nil
			TrollTargetHead.Text = "Select Target: Auto (Murderer)     ▼"
		end
		RefreshPlayerList()
	end)

	Connect(TrollTargetHead.Activated, function()
		open = not open
		if open then RefreshPlayerList() end
		local targetHeight = open and expandedHeight or baseHeight

		TweenService:Create(TrollTargetContainer, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Size = UDim2.new(1, -6, 0, targetHeight)
		}):Play()

		TrollTargetHead.Text = (TrollSettings.TargetPlayer and ("Select Target: " .. TrollSettings.TargetPlayer.Name) or "Select Target: Auto (Murderer)") .. (open and "     ▲" or "     ▼")
		DelayTracked(0, function()
			if not Alive then return end
			TrollPage.CanvasSize = UDim2.new(0, 0, 0, TrollLayout.AbsoluteContentSize.Y + 16)
		end)
	end)
end

-- "Blowjob" toggle
Toggle(TrollPage, "Blowjob", function(state) TrollSettings.Enabled = state end)

-- Speed slider (range 16 to 60, default 18)
local SpeedLabel = Label(TrollPage, "Speed: 18")

local TrollSlider = New("Frame", {
	Size = UDim2.new(1, -6, 0, 10),
	BackgroundColor3 = Color3.fromRGB(55, 55, 60),
	BackgroundTransparency = 0,
	BorderSizePixel = 0,
	ClipsDescendants = false
}, TrollPage)
Corner(TrollSlider, 10)

local defaultPercent = (18 - 16) / (60 - 16)

local TrollSliderFill = New("Frame", {
	Size = UDim2.new(defaultPercent, 0, 1, 0),
	BackgroundColor3 = Accent,
	BackgroundTransparency = 0,
	BorderSizePixel = 0,
	ZIndex = 2
}, TrollSlider)
Corner(TrollSliderFill, 10)

local TrollSliderKnob = New("Frame", {
	Size = UDim2.fromOffset(20, 20),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(defaultPercent, 0, 0.5, 0),
	BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	BackgroundTransparency = 0,
	BorderSizePixel = 0,
	ZIndex = 4
}, TrollSlider)
Corner(TrollSliderKnob, 50)

local TrollSliderButton = New("TextButton", {
	Size = UDim2.new(1, 0, 0, 34),
	Position = UDim2.new(0, 0, 0.5, -17),
	BackgroundTransparency = 1,
	Text = "",
	Active = true,
	ZIndex = 5
}, TrollSlider)

local draggingTrollSlider = false

local function UpdateTrollSlider(x)
	local width = TrollSlider.AbsoluteSize.X
	if width <= 0 then return end
	local percent = math.clamp((x - TrollSlider.AbsolutePosition.X) / width, 0, 1)

	TrollSettings.Speed = math.floor(16 + (percent * (60 - 16)))

	TweenService:Create(TrollSliderFill, TweenInfo.new(0.08), {Size = UDim2.new(percent, 0, 1, 0)}):Play()
	TweenService:Create(TrollSliderKnob, TweenInfo.new(0.08), {Position = UDim2.new(percent, 0, 0.5, 0)}):Play()
	SpeedLabel.Text = "Speed: " .. TrollSettings.Speed
end

Connect(TrollSliderButton.InputBegan, function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		draggingTrollSlider = true
		UpdateTrollSlider(input.Position.X)
	end
end)

Connect(UIS.InputChanged, function(input)
	if draggingTrollSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		UpdateTrollSlider(input.Position.X)
	end
end)

Connect(UIS.InputEnded, function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		draggingTrollSlider = false
	end
end)

Label(SettingsPage, "GENERAL SETTINGS")
local TransparencyLabel = Label(SettingsPage, "Window Transparency: 0%")

local Slider = New("Frame", {
	Size = UDim2.new(1, -10, 0, 10),
	BackgroundColor3 = Color3.fromRGB(55, 55, 60),
	BackgroundTransparency = 0,
	BorderSizePixel = 0,
	ClipsDescendants = false
}, SettingsPage)
Corner(Slider, 10)

local SliderFill = New("Frame", {
	Size = UDim2.new(0, 0, 1, 0),
	BackgroundColor3 = Accent,
	BackgroundTransparency = 0,
	BorderSizePixel = 0,
	ZIndex = 2
}, Slider)
Corner(SliderFill, 10)

local SliderKnob = New("Frame", {
	Size = UDim2.fromOffset(20, 20),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0, 0, 0.5, 0),
	BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	BackgroundTransparency = 0,
	BorderSizePixel = 0,
	ZIndex = 4
}, Slider)
Corner(SliderKnob, 50)

local SliderButton = New("TextButton", {
	Size = UDim2.new(1, 0, 0, 34),
	Position = UDim2.new(0, 0, 0.5, -17),
	BackgroundTransparency = 1,
	Text = "",
	Active = true,
	ZIndex = 5
}, Slider)

local draggingSlider = false
local transparencyValue = 0

local function ApplyTransparency()
	local transparency = transparencyValue / 100
	Main.BackgroundTransparency = transparency
	Body.BackgroundTransparency = transparency
	Sidebar.BackgroundTransparency = transparency
	Header.BackgroundTransparency = 0
	HeaderCover.BackgroundTransparency = 0
	MainStroke.Transparency = 0
end

local function ApplyNormalTheme()
	local background = Color3.fromRGB(24, 24, 28)
	Main.BackgroundColor3 = background
	Body.BackgroundColor3 = background
	Header.BackgroundColor3 = Color3.fromRGB(17, 17, 20)
	HeaderCover.BackgroundColor3 = Header.BackgroundColor3
	Sidebar.BackgroundColor3 = Color3.fromRGB(19, 19, 23)
end

local function UpdateTransparency(x)
	local width = Slider.AbsoluteSize.X
	if width <= 0 then return end
	local percent = math.clamp((x - Slider.AbsolutePosition.X) / width, 0, 1)
	transparencyValue = math.floor(percent * 80)
	TweenService:Create(SliderFill, TweenInfo.new(0.08), {Size = UDim2.new(percent, 0, 1, 0)}):Play()
	TweenService:Create(SliderKnob, TweenInfo.new(0.08), {Position = UDim2.new(percent, 0, 0.5, 0)}):Play()
	TransparencyLabel.Text = "Window Transparency: " .. transparencyValue .. "%"
	ApplyTransparency()
end

Connect(SliderButton.InputBegan, function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		draggingSlider = true
		UpdateTransparency(input.Position.X)
	end
end)

Connect(UIS.InputChanged, function(input)
	if draggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		UpdateTransparency(input.Position.X)
	end
end)

Connect(UIS.InputEnded, function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		draggingSlider = false
	end
end)

local function Accordion(parent, title, callback)
	local baseHeight = 48
	local itemHeight = 34
	local spacing = 6
	local totalItems = #ColorNames
	local expandedHeight = baseHeight + (totalItems * itemHeight) + ((totalItems - 1) * spacing) + 16

	local container = New("Frame", {
		Size = UDim2.new(1, -6, 0, baseHeight),
		BackgroundColor3 = Color3.fromRGB(34, 34, 39),
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		ClipsDescendants = true
	}, parent)

	Corner(container, 10)

	local head = New("TextButton", {
		Size = UDim2.new(1, 0, 0, baseHeight),
		BackgroundTransparency = 1,
		Text = title .. "     ▼",
		TextColor3 = Color3.new(1, 1, 1),
		TextSize = 15,
		Font = Enum.Font.GothamBold
	}, container)

	local list = New("Frame", {
		Position = UDim2.fromOffset(12, baseHeight),
		Size = UDim2.new(1, -24, 0, expandedHeight - baseHeight - 12),
		BackgroundTransparency = 1
	}, container)

	New("UIListLayout", {
		Padding = UDim.new(0, spacing),
		SortOrder = Enum.SortOrder.LayoutOrder
	}, list)

	local open = false
	table.insert(AccordionRecords, {Container = container, Head = head})

	for _, colorName in ipairs(ColorNames) do
		local button = New("TextButton", {
			Size = UDim2.new(1, 0, 0, itemHeight),
			BackgroundColor3 = Color3.fromRGB(44, 44, 50),
			BackgroundTransparency = 0,
			Text = colorName,
			TextColor3 = Color3.new(1, 1, 1),
			TextSize = 14,
			Font = Enum.Font.GothamMedium,
			BorderSizePixel = 0
		}, list)

		Corner(button, 8)

		Connect(button.MouseEnter, function()
			TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(60, 60, 70)}):Play()
		end)
		Connect(button.MouseLeave, function()
			TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(44, 44, 50)}):Play()
		end)

		Connect(button.Activated, function()
			callback(colorName)
		end)
	end

	Connect(head.Activated, function()
		open = not open
		local targetHeight = open and expandedHeight or baseHeight

		TweenService:Create(container, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Size = UDim2.new(1, -6, 0, targetHeight)
		}):Play()

		head.Text = title .. (open and "     ▲" or "     ▼")
		DelayTracked(0, function()
			if not Alive then return end
			SettingsPage.CanvasSize = UDim2.new(0, 0, 0, SettingsLayout.AbsoluteContentSize.Y + 16)
		end)
	end)
end

Accordion(SettingsPage, "Outline Color", function(colorName)
	if colorName == "Rainbow" then
		RainbowOutline = true
	else
		RainbowOutline = false
		OutlineColor = ColorValues[colorName]
		MainStroke.Color = OutlineColor
	end
end)

Accordion(SettingsPage, "Window Theme", function(colorName)
	if colorName == "Rainbow" then
		RainbowTheme = true
	else
		RainbowTheme = false
		Accent = ColorValues[colorName]
		ApplyNormalTheme()

		local background = ThemeColors[colorName]
		Main.BackgroundColor3 = background
		Body.BackgroundColor3 = background
		EspTab.BackgroundColor3 = Accent
		SheriffTab.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
		TrollTab.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
		SliderFill.BackgroundColor3 = Accent

		for _, record in ipairs(ToggleRecords) do
			UpdateToggleAppearance(record)
		end

		for _, record in ipairs(AccordionRecords) do
			record.Head.TextColor3 = Color3.new(1, 1, 1)
		end

		MainStroke.Color = OutlineColor
		ApplyTransparency()
	end
end)

local function ShowPage(pageName)
	EspPage.Visible = (pageName == "ESP")
	SheriffPage.Visible = (pageName == "Sheriff")
	TrollPage.Visible = (pageName == "Troll")
	SettingsPage.Visible = (pageName == "Settings")

	Sidebar.Visible = true
	Content.Position = UDim2.fromOffset(130, 0)
	Content.Size = UDim2.new(1, -130, 1, 0)

	TweenService:Create(EspTab, TweenInfo.new(0.2), {BackgroundColor3 = (pageName == "ESP") and Accent or Color3.fromRGB(28, 28, 34)}):Play()
	TweenService:Create(SheriffTab, TweenInfo.new(0.2), {BackgroundColor3 = (pageName == "Sheriff") and Accent or Color3.fromRGB(28, 28, 34)}):Play()
	TweenService:Create(TrollTab, TweenInfo.new(0.2), {BackgroundColor3 = (pageName == "Troll") and Accent or Color3.fromRGB(28, 28, 34)}):Play()
end

Connect(EspTab.Activated, function() ShowPage("ESP") end)
Connect(SheriffTab.Activated, function() ShowPage("Sheriff") end)
Connect(TrollTab.Activated, function() ShowPage("Troll") end)

local settingsOpen = false
Connect(SettingsButton.Activated, function()
	settingsOpen = not settingsOpen
	if settingsOpen then
		ShowPage("Settings")
	else
		ShowPage("ESP")
	end
end)

local minimized = false
local function SetMinimized(state)
	minimized = state
	if minimized then
		Body.Visible = true
		TweenService:Create(Main, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Size = UDim2.fromOffset(480, 54)
		}):Play()
		DelayTracked(0.25, function()
			if Alive and minimized then Body.Visible = false end
		end)
	else
		Body.Visible = true
		TweenService:Create(Main, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Size = UDim2.fromOffset(480, 390)
		}):Play()
	end
end

Connect(MinimizeButton.Activated, function()
	SetMinimized(not minimized)
end)

local function HasKnife(p)
	if not p.Character then return false end
	for _, item in ipairs(p.Character:GetChildren()) do
		if item:IsA("Tool") and item.Name == "Knife" then return true end
	end
	local backpack = p:FindFirstChildOfClass("Backpack")
	if backpack then
		for _, item in ipairs(backpack:GetChildren()) do
			if item:IsA("Tool") and item.Name == "Knife" then return true end
		end
	end
	return false
end

local function HasGun(p)
	if not p.Character then return false end
	for _, item in ipairs(p.Character:GetChildren()) do
		if item:IsA("Tool") and item.Name == "Gun" then return true end
	end
	local backpack = p:FindFirstChildOfClass("Backpack")
	if backpack then
		for _, item in ipairs(backpack:GetChildren()) do
			if item:IsA("Tool") and item.Name == "Gun" then return true end
		end
	end
	return false
end

local function IsHoldingKnife(p)
	if not p.Character then return false end
	for _, item in ipairs(p.Character:GetChildren()) do
		if item:IsA("Tool") and item.Name == "Knife" then return true end
	end
	return false
end

local function IsSheriffDead()
	for _, entry in pairs(RoundRolesCache) do
		if entry.Role == "Sheriff" and entry.Dead then
			return true
		end
	end
	return false
end

-- Для ESP: роль берётся только из данных раунда и состояния дропа револьвера
local function GetPlayerRole(p)
	local entry = RoundRolesCache[p.Name]
	if entry and entry.Dead then
		return nil
	end

	if entry and entry.Role then
		if entry.Role == "Sheriff" then
			return "Sheriff"
		elseif entry.Role == "Murderer" then
			return "Murderer"
		elseif entry.Role == "Innocent" then
			if HeroPlayers[p] and IsSheriffDead() then
				return "Hero"
			end
			return "Innocent"
		end
	end

	return nil
end

-- Для аимбота и стрельбы: поиск цели по ножу
local function FindKnifeMurdererTarget()
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= Player and HasKnife(p) and p.Character then
			local targetPart = p.Character:FindFirstChild("Head") or p.Character:FindFirstChild("HumanoidRootPart")
			if targetPart then
				return p, targetPart
			end
		end
	end
	return nil, nil
end

-- Подписки на события раунда из лога
local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
local gameplayFolder = remotesFolder and remotesFolder:FindFirstChild("Gameplay")

local function IngestRolesTable(data, replaceAll)
	if type(data) ~= "table" then return end

	if replaceAll then
		table.clear(RoundRolesCache)
		table.clear(HeroPlayers)
	end

	for playerName, info in pairs(data) do
		if type(info) == "table" and info.Role then
			RoundRolesCache[playerName] = {
				Role = tostring(info.Role),
				Dead = info.Dead == true
			}
		end
	end

	for playerName in pairs(RoundRolesCache) do
		if not Players:FindFirstChild(playerName) then
			RoundRolesCache[playerName] = nil
		end
	end

	if UpdateESP then
		UpdateESP()
	end
end

if gameplayFolder then
	local loadingMapEvent = gameplayFolder:FindFirstChild("LoadingMap")
	if loadingMapEvent and loadingMapEvent:IsA("RemoteEvent") then
		Connect(loadingMapEvent.OnClientEvent, function()
			ResetForNewMap()
		end)
	end

	local fadeEvent = gameplayFolder:FindFirstChild("Fade")
	if fadeEvent and fadeEvent:IsA("RemoteEvent") then
		Connect(fadeEvent.OnClientEvent, function(data)
			IngestRolesTable(data, true)
		end)
	end

	local playerDataChangedEvent = gameplayFolder:FindFirstChild("PlayerDataChanged")
	if playerDataChangedEvent and playerDataChangedEvent:IsA("RemoteEvent") then
		Connect(playerDataChangedEvent.OnClientEvent, function(data)
			IngestRolesTable(data, false)
		end)
	end

	local roundStartEvent = gameplayFolder:FindFirstChild("RoundStart")
	if roundStartEvent and roundStartEvent:IsA("RemoteEvent") then
		Connect(roundStartEvent.OnClientEvent, function(_, data)
			IngestRolesTable(data, true)
		end)
	end
end

SpawnTracked(function()
	while Alive do
		task.wait(0.5)
		local hasAnyGunDrop = false
		for _, obj in ipairs(Workspace:GetDescendants()) do
			if obj.Name == "GunDrop" and obj:IsA("BasePart") then
				hasAnyGunDrop = true
				if not TrackedDrops[obj] then
					TrackedDrops[obj] = true
					Connect(obj.Touched, function(hit)
						if not Alive then return end
						local char = hit.Parent
						local hum = char and char:FindFirstChildOfClass("Humanoid")
						if hum then
							local p = Players:GetPlayerFromCharacter(char)
							local roleEntry = p and RoundRolesCache[p.Name]
							if p and roleEntry and roleEntry.Role == "Innocent" and not roleEntry.Dead then
								HeroPlayers[p] = true
								if UpdateESP then UpdateESP() end
							end
						end
					end)
				end
			end
		end

		if not hasAnyGunDrop then
			table.clear(TrackedDrops)
			for p, _ in pairs(HeroPlayers) do
				local roleEntry = RoundRolesCache[p.Name]
				if not roleEntry or roleEntry.Dead or roleEntry.Role ~= "Innocent" then
					HeroPlayers[p] = nil
				end
			end
		end
	end
end)

SpawnTracked(function()
	while Alive do
		local gunDrop = nil
		while Alive and not gunDrop do
			for _, obj in ipairs(Workspace:GetChildren()) do
				if obj.Name == "GunDrop" and obj:IsA("BasePart") then
					gunDrop = obj
					break
				end
			end
			if not gunDrop then
				task.wait(0.2)
			end
		end

		if Alive and AutoGrabSettings.Enabled and gunDrop and Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
			local myRole = GetPlayerRole(Player)
			if myRole == "Innocent" and not HasGun(Player) then
				local hrp = Player.Character.HumanoidRootPart
				local originalCFrame = hrp.CFrame

				hrp.CFrame = gunDrop.CFrame + Vector3.new(0, 2, 0)

				DelayTracked(0, function()
					if Alive and hrp and originalCFrame then
						hrp.CFrame = originalCFrame
					end
				end)

				while Alive and gunDrop and gunDrop.Parent do
					task.wait(0.1)
				end
			end
		end

		task.wait(0.1)
	end
end)

local lastEquipTick = 0
local lastShootTick = 0

local function ShootAtMurderer()
	if tick() - lastShootTick < 0.4 then return end
	lastShootTick = tick()

	if not Player.Character or not Player.Character:FindFirstChild("HumanoidRootPart") then return end
	local char = Player.Character
	local hrp = char:FindFirstChild("HumanoidRootPart")
	local gunTool = nil
	local hasGunInHand = false

	for _, item in ipairs(char:GetChildren()) do
		if item:IsA("Tool") and item.Name == "Gun" then
			gunTool = item
			hasGunInHand = true
			break
		end
	end

	if not hasGunInHand then
		local backpack = Player:FindFirstChildOfClass("Backpack")
		if backpack then
			for _, item in ipairs(backpack:GetChildren()) do
				if item:IsA("Tool") and item.Name == "Gun" then
					gunTool = item
					break
				end
			end
		end
		if gunTool and char:FindFirstChildOfClass("Humanoid") then
			char.Humanoid:EquipTool(gunTool)
			task.wait(0.15)
		end
	end

	hasGunInHand = false
	for _, item in ipairs(char:GetChildren()) do
		if item:IsA("Tool") and item.Name == "Gun" then
			hasGunInHand = true
			gunTool = item
			break
		end
	end

	if not hasGunInHand then return end

	local _, targetPart = FindKnifeMurdererTarget()
	if targetPart then
		local targetPos = targetPart.Position
		local attachment = hrp:FindFirstChild("GunRaycastAttachment")
		local attachmentCFrame = attachment and attachment.WorldCFrame or hrp.CFrame

		local shootEvent = gunTool:FindFirstChild("Shoot")
		if shootEvent and shootEvent:IsA("RemoteEvent") then
			shootEvent:FireServer(attachmentCFrame, targetPos)
		else
			gunTool:Activate()
		end
	end
end

Connect(ShootButton.Activated, function() ShootAtMurderer() end)

UpdateESP = function()
	if not Alive then return end

	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= Player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
			local roleType = GetPlayerRole(p)
			local isEnabledForRole =
				(roleType == "Murderer" and ESP_Settings.Murderer) or
				(roleType == "Hero" and ESP_Settings.Hero) or
				(roleType == "Sheriff" and ESP_Settings.Sheriff) or
				(roleType == "Innocent" and ESP_Settings.Innocent)

			if isEnabledForRole and roleType then
				if not ActiveESPObjects[p] or ActiveESPObjects[p].Role ~= roleType or ActiveESPObjects[p].Highlight.Parent ~= p.Character then
					RemoveESP(p)
					local highlight = Instance.new("Highlight")
					highlight.Adornee = p.Character
					highlight.Parent = p.Character
					highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
					highlight.OutlineColor = Color3.new(1, 1, 1)
					highlight.OutlineTransparency = 0
					highlight.FillTransparency = 0.55

					local billboard = Instance.new("BillboardGui")
					billboard.Size = UDim2.fromOffset(260, 30)
					billboard.StudsOffset = Vector3.new(0, 3, 0)
					billboard.AlwaysOnTop = true
					billboard.Adornee = p.Character:FindFirstChild("Head") or p.Character.HumanoidRootPart
					billboard.Parent = p.Character

					local label = Instance.new("TextLabel")
					label.Size = UDim2.new(1, 0, 1, 0)
					label.BackgroundTransparency = 1
					label.TextSize = 15
					label.Font = Enum.Font.GothamBold
					label.TextStrokeTransparency = 0.2
					label.Parent = billboard

					ActiveESPObjects[p] = {
						Highlight = highlight,
						Billboard = billboard,
						Label = label,
						Role = roleType
					}
				end

				local espData = ActiveESPObjects[p]
				espData.Highlight.OutlineColor = Color3.new(1, 1, 1)

				if roleType == "Murderer" then
					local espColor = Colors.Red
					espData.Highlight.FillColor = espColor
					espData.Label.Text = IsHoldingKnife(p) and "[Murderer equips knife]" or "[Murderer]"
					espData.Label.TextColor3 = espColor
				elseif roleType == "Sheriff" then
					local espColor = Colors.Blue
					espData.Highlight.FillColor = espColor
					espData.Label.Text = "[Sheriff]"
					espData.Label.TextColor3 = espColor
				elseif roleType == "Hero" then
					local espColor = Colors.Yellow
					espData.Highlight.FillColor = espColor
					espData.Label.Text = "[Hero]"
					espData.Label.TextColor3 = espColor
				elseif roleType == "Innocent" then
					local espColor = Colors.Green
					espData.Highlight.FillColor = espColor
					espData.Label.Text = "[Innocent]"
					espData.Label.TextColor3 = espColor
				end
			else
				RemoveESP(p)
			end
		else
			RemoveESP(p)
		end
	end
end

SpawnTracked(function()
	while Alive do
		task.wait(0.15)
		UpdateESP()
	end
end)

-- RenderStepped: Aimbot, Theme and troll movement logic
Connect(RunService.RenderStepped, function(dt)
	if not Alive then return end

	local rainbow = Color3.fromHSV((tick() * 0.25) % 1, 0.85, 1)
	if RainbowOutline then
		MainStroke.Color = rainbow
	end

	if RainbowTheme then
		local darkRainbow = rainbow:Lerp(Color3.fromRGB(15, 15, 20), 0.45)
		local darkerRainbow = rainbow:Lerp(Color3.fromRGB(10, 10, 15), 0.65)

		Main.BackgroundColor3 = darkRainbow
		Body.BackgroundColor3 = darkRainbow
		Header.BackgroundColor3 = rainbow
		HeaderCover.BackgroundColor3 = rainbow
		Sidebar.BackgroundColor3 = darkerRainbow
		EspTab.BackgroundColor3 = rainbow
		SheriffTab.BackgroundColor3 = rainbow
		TrollTab.BackgroundColor3 = rainbow
		TrollSliderFill.BackgroundColor3 = rainbow
		SliderFill.BackgroundColor3 = rainbow
		MinimizeButton.BackgroundColor3 = darkerRainbow
		SettingsButton.BackgroundColor3 = darkerRainbow
		CloseButton.BackgroundColor3 = darkerRainbow

		for _, record in ipairs(ToggleRecords) do
			record.Row.BackgroundColor3 = darkRainbow
			if record.Enabled then
				record.Button.BackgroundColor3 = rainbow
			else
				record.Button.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
			end
			record.Stroke.Color = Color3.fromRGB(0, 0, 0)
			record.Stroke.Transparency = 0
		end

		for _, record in ipairs(AccordionRecords) do
			record.Container.BackgroundColor3 = darkRainbow
		end
	end

	-- 1. "Blowjob" toggle logic with target lock and speed slider
	if TrollSettings.Enabled and Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
		local hrp = Player.Character.HumanoidRootPart
		local target = nil

		if TrollSettings.TargetPlayer and TrollSettings.TargetPlayer.Character then
			target = TrollSettings.TargetPlayer.Character
		else
			for _, p in ipairs(Players:GetPlayers()) do
				if p ~= Player and GetPlayerRole(p) == "Murderer" and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
					target = p.Character
					break
				end
			end
			if not target then
				for _, p in ipairs(Players:GetPlayers()) do
					if p ~= Player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
						target = p.Character
						break
					end
				end
			end
		end

		if target and target:FindFirstChild("HumanoidRootPart") then
			local targetHRP = target.HumanoidRootPart
			local offsetMultiplier = 0.8 + math.sin(tick() * TrollSettings.Speed) * 0.45
			local desiredCFrame = targetHRP.CFrame * CFrame.new(0, -0.5, offsetMultiplier) * CFrame.Angles(math.rad(75), math.rad(180), 0)
			hrp.CFrame = hrp.CFrame:Lerp(desiredCFrame, math.clamp(dt * 30, 0, 1))
		end
	end

	-- 2. Aimbot with weapon check and knife-carrier target search
	local currentCamera = Workspace.CurrentCamera
	if AimbotSettings.Enabled and Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") and currentCamera then
		local char = Player.Character
		local hasGunInHand = false

		for _, item in ipairs(char:GetChildren()) do
			if item:IsA("Tool") and item.Name == "Gun" then
				hasGunInHand = true
				break
			end
		end

		if not hasGunInHand then
			local gunTool = nil
			local backpack = Player:FindFirstChildOfClass("Backpack")
			if backpack then
				for _, item in ipairs(backpack:GetChildren()) do
					if item:IsA("Tool") and item.Name == "Gun" then
						gunTool = item
						break
					end
				end
			end

			if gunTool and char:FindFirstChildOfClass("Humanoid") then
				if tick() - lastEquipTick > 0.4 then
					lastEquipTick = tick()
					char.Humanoid:EquipTool(gunTool)
				end
			end
		end

		if hasGunInHand then
			local _, targetPart = FindKnifeMurdererTarget()
			if targetPart then
				currentCamera.CFrame = CFrame.new(currentCamera.CFrame.Position, targetPart.Position)
			end
		end
	end
end)

local dragging = false
local dragStart
local startPosition
local dragInput

Connect(Header.InputBegan, function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPosition = Main.Position
		dragInput = input
	end
end)

Connect(UIS.InputChanged, function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStart
		Main.Position = UDim2.new(
			startPosition.X.Scale, startPosition.X.Offset + delta.X,
			startPosition.Y.Scale, startPosition.Y.Offset + delta.Y
		)
	end
end)

Connect(UIS.InputEnded, function(input)
	if input == dragInput or input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
		dragInput = nil
	end
end)

local function SetupPlayer(p)
	Connect(p.CharacterRemoving, function()
		RemoveESP(p)
		HeroPlayers[p] = nil
		if TrollSettings.TargetPlayer == p then
			TrollSettings.TargetPlayer = nil
			TrollTargetHead.Text = "Select Target: Auto (Murderer)     ▼"
		end
	end)
	Connect(p.CharacterAdded, function()
		RemoveESP(p)
		HeroPlayers[p] = nil
		DelayTracked(0.1, function()
			if Alive and UpdateESP then UpdateESP() end
		end)
	end)
end

for _, p in ipairs(Players:GetPlayers()) do SetupPlayer(p) end
Connect(Players.PlayerAdded, function(p) SetupPlayer(p) end)
Connect(Players.PlayerRemoving, function(p)
	RemoveESP(p)
	RoundRolesCache[p.Name] = nil
	HeroPlayers[p] = nil
	if TrollSettings.TargetPlayer == p then
		TrollSettings.TargetPlayer = nil
		TrollTargetHead.Text = "Select Target: Auto (Murderer)     ▼"
	end
end)

Connect(CloseButton.Activated, function() Cleanup() end)

ApplyTransparency()
ApplyNormalTheme()
