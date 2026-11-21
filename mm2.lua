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

local TrackCorner = Instance.new("UIC corner", Track)
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

local function FindGunDrop()
	for _, obj in ipairs(Workspace:GetDescendants()) do
		if obj.Name == "GunDrop" and obj:IsA("BasePart") and obj.Parent then
			return obj
		end
	end
	return nil
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

local MurdererCombatSettings = {
	KillAllButtonEnabled = false,
	KillAllTriggered = false
}

local BASE_SPEED = 16
local MIN_SPEED = 1
local MAX_SPEED = 60

local MIN_FARM_SPEED = 1
local MAX_FARM_SPEED = 45
local UNDERGROUND_Y_OFFSET = -2.2

local FarmingSettings = {
	AutoFarmCoin = false,
	UndergroundMode = false,
	FarmSpeed = BASE_SPEED,
	FlingMurdererWhenFullBag = false,
	ShootMurdererWhenFullBag = false,
	KillAllWhenFullBag = false
}

local TrollSettings = {
	TargetPlayer = nil,
	Speed = BASE_SPEED,
	EvilSpeed = BASE_SPEED,
	SmileEnabled = false,
	EvilSmileEnabled = false
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

local function CmToPx(cm)
	return math.floor((cm * 37.7952755906) + 0.5)
end

local DRAG_THRESHOLD_PX = 8

local function MakeDraggableActionButton(button, onShortClick)
	button.Active = true
	button.Draggable = false

	local activeInput = nil
	local dragStartPos = nil
	local buttonStartPos = nil
	local isDragging = false

	Connect(button.InputBegan, function(input)
		if activeInput ~= nil then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			activeInput = input
			dragStartPos = input.Position
			buttonStartPos = button.Position
			isDragging = false
		end
	end)

	Connect(UIS.InputChanged, function(input)
		if activeInput == nil or input ~= activeInput then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			local delta = input.Position - dragStartPos
			if not isDragging and delta.Magnitude >= DRAG_THRESHOLD_PX then
				isDragging = true
			end

			if isDragging then
				button.Position = UDim2.new(
					buttonStartPos.X.Scale,
					buttonStartPos.X.Offset + delta.X,
					buttonStartPos.Y.Scale,
					buttonStartPos.Y.Offset + delta.Y
				)
			end
		end
	end)

	Connect(UIS.InputEnded, function(input)
		if activeInput == nil or input ~= activeInput then return end
		local wasDragging = isDragging
		activeInput = nil
		dragStartPos = nil
		buttonStartPos = nil
		isDragging = false

		if not wasDragging and onShortClick then
			onShortClick()
		end
	end)
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

local StopCoinFarmFlight -- forward declaration
local StopManualKillAll -- forward declaration

local function Cleanup()
	if not Alive then return end
	Alive = false
	FarmingSettings.AutoFarmCoin = false
	FarmingSettings.FlingMurdererWhenFullBag = false
	FarmingSettings.ShootMurdererWhenFullBag = false
	FarmingSettings.KillAllWhenFullBag = false
	MurdererCombatSettings.KillAllButtonEnabled = false
	MurdererCombatSettings.KillAllTriggered = false

	if StopManualKillAll then
		StopManualKillAll()
	end

	if StopCoinFarmFlight then
		StopCoinFarmFlight()
	end

	if Crosshair then
		Crosshair.Visible = false
	end

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
	ZIndex = 1001
}, GUI)
Corner(ShootButton, 10)
Stroke(ShootButton, Color3.fromRGB(220, 45, 55), 3.5)

local killAllBtnW = CmToPx(5)
local killAllBtnH = CmToPx(3)

local KillAllActionButton = New("TextButton", {
	Name = "KillAllActionButton",
	Size = UDim2.fromOffset(killAllBtnW, killAllBtnH),
	Position = UDim2.new(0.8, -math.floor(killAllBtnW / 2), 0.5, -math.floor(killAllBtnH / 2)),
	BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	BackgroundTransparency = 0,
	Text = "Kill all",
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 18,
	Font = Enum.Font.GothamBold,
	BorderSizePixel = 0,
	Visible = false,
	Active = true,
	ZIndex = 1002
}, GUI)
Corner(KillAllActionButton, 10)
Stroke(KillAllActionButton, Color3.fromRGB(220, 45, 55), 3.5)

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

local FarmingTab = SidebarButton("🪙 Farming", 16)
local EspTab = SidebarButton("◉  ESP", 64)
local SheriffTab = SidebarButton("🛡 Sheriff", 112)
local MurdererTab = SidebarButton("🔪 Murderer", 160)
local TrollTab = SidebarButton("🤪 Troll", 208)

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

local FarmingPage = Page("FarmingPage")
local EspPage = Page("ESP")
local SheriffPage = Page("SheriffPage")
local MurdererPage = Page("MurdererPage")
local TrollPage = Page("TrollPage")
local SettingsPage = Page("Settings")
FarmingPage.Visible = true

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

local FarmingLayout = AddLayout(FarmingPage)
local EspLayout = AddLayout(EspPage)
local SheriffLayout = AddLayout(SheriffPage)
local MurdererLayout = AddLayout(MurdererPage)
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
local FindKnifeMurdererTarget -- forward declaration
local GetPlayerRole -- forward declaration
local RestoreStaticModelState -- forward declaration
local UpdateAimbotState -- forward declaration

Label(FarmingPage, "FARMING")
Toggle(FarmingPage, "Auto Farm Coin", function(state)
	FarmingSettings.AutoFarmCoin = state
	if not state and StopCoinFarmFlight then
		StopCoinFarmFlight()
	end
end)
Toggle(FarmingPage, "Underground Coin Farm", function(state)
	FarmingSettings.UndergroundMode = state
end)
Toggle(FarmingPage, "Fling Murderer (When Full Bag)", function(state)
	FarmingSettings.FlingMurdererWhenFullBag = state
	if not state and StopCoinFarmFlight then
		StopCoinFarmFlight()
	end
end)
Toggle(FarmingPage, "Shoot Murderer (When Full Bag)", function(state)
	FarmingSettings.ShootMurdererWhenFullBag = state
end)
Toggle(FarmingPage, "Kill All (When Full Bag)", function(state)
	FarmingSettings.KillAllWhenFullBag = state
	if not state and StopCoinFarmFlight then
		StopCoinFarmFlight()
	end
end)

local FarmSpeedSliderFill
do
	local sliderLabel = Label(FarmingPage, "Farm Speed: " .. FarmingSettings.FarmSpeed)

	local sliderFrame = New("Frame", {
		Size = UDim2.new(1, -6, 0, 10),
		BackgroundColor3 = Color3.fromRGB(55, 55, 60),
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		ClipsDescendants = false
	}, FarmingPage)
	Corner(sliderFrame, 10)

	local initPercent = (FarmingSettings.FarmSpeed - MIN_FARM_SPEED) / (MAX_FARM_SPEED - MIN_FARM_SPEED)

	FarmSpeedSliderFill = New("Frame", {
		Size = UDim2.new(initPercent, 0, 1, 0),
		BackgroundColor3 = Accent,
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		ZIndex = 2
	}, sliderFrame)
	Corner(FarmSpeedSliderFill, 10)

	local knobFrame = New("Frame", {
		Size = UDim2.fromOffset(20, 20),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(initPercent, 0, 0.5, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		ZIndex = 4
	}, sliderFrame)
	Corner(knobFrame, 50)

	local hitButton = New("TextButton", {
		Size = UDim2.new(1, 0, 0, 34),
		Position = UDim2.new(0, 0, 0.5, -17),
		BackgroundTransparency = 1,
		Text = "",
		Active = true,
		ZIndex = 5
	}, sliderFrame)

	local dragging = false

	local function UpdateFarmSpeed(x)
		local width = sliderFrame.AbsoluteSize.X
		if width <= 0 then return end
		local percent = math.clamp((x - sliderFrame.AbsolutePosition.X) / width, 0, 1)
		local val = math.clamp(math.floor(MIN_FARM_SPEED + (percent * (MAX_FARM_SPEED - MIN_FARM_SPEED))), MIN_FARM_SPEED, MAX_FARM_SPEED)

		TweenService:Create(FarmSpeedSliderFill, TweenInfo.new(0.08), {Size = UDim2.new(percent, 0, 1, 0)}):Play()
		TweenService:Create(knobFrame, TweenInfo.new(0.08), {Position = UDim2.new(percent, 0, 0.5, 0)}):Play()
		sliderLabel.Text = "Farm Speed: " .. val
		FarmingSettings.FarmSpeed = val
	end

	Connect(hitButton.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			UpdateFarmSpeed(input.Position.X)
		end
	end)

	Connect(UIS.InputChanged, function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			UpdateFarmSpeed(input.Position.X)
		end
	end)

	Connect(UIS.InputEnded, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
end

Label(EspPage, "ROLE ESP")
Toggle(EspPage, "ESP Murderer", function(state) ESP_Settings.Murderer = state; if UpdateESP then UpdateESP() end end)
Toggle(EspPage, "ESP Sheriff", function(state) ESP_Settings.Sheriff = state; if UpdateESP then UpdateESP() end end)
Toggle(EspPage, "ESP Innocent", function(state) ESP_Settings.Innocent = state; if UpdateESP then UpdateESP() end end)
Toggle(EspPage, "ESP Hero", function(state) ESP_Settings.Hero = state; if UpdateESP then UpdateESP() end end)

Label(SheriffPage, "SHERIFF COMBAT")
Toggle(SheriffPage, "AimBot", function(state)
	AimbotSettings.Enabled = state
	if UpdateAimbotState then
		UpdateAimbotState(state)
	else
		Crosshair.Visible = false
	end
end)
Toggle(SheriffPage, "Shoot Murderer button", function(state) ShootButtonSettings.Enabled = state; ShootButton.Visible = state end)
Toggle(SheriffPage, "Auto Grab Gun", function(state) AutoGrabSettings.Enabled = state end)

Label(MurdererPage, "MURDERER COMBAT")
Toggle(MurdererPage, "Kill all button", function(state)
	MurdererCombatSettings.KillAllButtonEnabled = state
	KillAllActionButton.Visible = state
	if not state and StopManualKillAll then
		StopManualKillAll()
	end
end)

Label(TrollPage, "TROLL ACTIONS")
Toggle(TrollPage, ":)", function(state)
	TrollSettings.SmileEnabled = state
	if not state and not TrollSettings.EvilSmileEnabled and RestoreStaticModelState then
		RestoreStaticModelState()
	end
end)
Toggle(TrollPage, ">:)", function(state)
	TrollSettings.EvilSmileEnabled = state
	if not state and not TrollSettings.SmileEnabled and RestoreStaticModelState then
		RestoreStaticModelState()
	end
end)

-- Auto-updating target selection accordion (never resets automatically)
local TrollTargetContainer, TrollTargetHead
local RefreshTrollTargetList
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

	local function GetHeaderArrow()
		return open and "     ▲" or "     ▼"
	end

	local function UpdateHeaderText()
		local name = TrollSettings.TargetPlayer and TrollSettings.TargetPlayer.Name or "Auto (Murderer)"
		TrollTargetHead.Text = "Select Target: " .. name .. GetHeaderArrow()
	end

	RefreshTrollTargetList = function()
		if not Alive then return end
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
			UpdateHeaderText()
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
					UpdateHeaderText()
				end)
				count = count + 1
			end
		end

		expandedHeight = baseHeight + (count * itemHeight) + ((count - 1) * spacing) + 16
		listFrame.Size = UDim2.new(1, -24, 0, expandedHeight - baseHeight - 12)
		if open then
			TrollTargetContainer.Size = UDim2.new(1, -6, 0, expandedHeight)
			DelayTracked(0, function()
				if not Alive then return end
				TrollPage.CanvasSize = UDim2.new(0, 0, 0, TrollLayout.AbsoluteContentSize.Y + 16)
			end)
		end
	end

	RefreshTrollTargetList()

	Connect(Players.PlayerAdded, function()
		RefreshTrollTargetList()
	end)

	Connect(Players.PlayerRemoving, function()
		RefreshTrollTargetList()
	end)

	Connect(TrollTargetHead.Activated, function()
		open = not open
		if open then RefreshTrollTargetList() end
		local targetHeight = open and expandedHeight or baseHeight

		TweenService:Create(TrollTargetContainer, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Size = UDim2.new(1, -6, 0, targetHeight)
		}):Play()

		UpdateHeaderText()
		DelayTracked(0, function()
			if not Alive then return end
			TrollPage.CanvasSize = UDim2.new(0, 0, 0, TrollLayout.AbsoluteContentSize.Y + 16)
		end)
	end)
end

local function CreateTrollSpeedSlider(labelText, initialValue, onChanged)
	local sliderLabel = Label(TrollPage, labelText .. ": " .. initialValue)

	local sliderFrame = New("Frame", {
		Size = UDim2.new(1, -6, 0, 10),
		BackgroundColor3 = Color3.fromRGB(55, 55, 60),
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		ClipsDescendants = false
	}, TrollPage)
	Corner(sliderFrame, 10)

	local initPercent = (initialValue - MIN_SPEED) / (MAX_SPEED - MIN_SPEED)

	local fillFrame = New("Frame", {
		Size = UDim2.new(initPercent, 0, 1, 0),
		BackgroundColor3 = Accent,
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		ZIndex = 2
	}, sliderFrame)
	Corner(fillFrame, 10)

	local knobFrame = New("Frame", {
		Size = UDim2.fromOffset(20, 20),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(initPercent, 0, 0.5, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		ZIndex = 4
	}, sliderFrame)
	Corner(knobFrame, 50)

	local hitButton = New("TextButton", {
		Size = UDim2.new(1, 0, 0, 34),
		Position = UDim2.new(0, 0, 0.5, -17),
		BackgroundTransparency = 1,
		Text = "",
		Active = true,
		ZIndex = 5
	}, sliderFrame)

	local dragging = false

	local function UpdateValue(x)
		local width = sliderFrame.AbsoluteSize.X
		if width <= 0 then return end
		local percent = math.clamp((x - sliderFrame.AbsolutePosition.X) / width, 0, 1)
		local val = math.clamp(math.floor(MIN_SPEED + (percent * (MAX_SPEED - MIN_SPEED))), MIN_SPEED, MAX_SPEED)

		TweenService:Create(fillFrame, TweenInfo.new(0.08), {Size = UDim2.new(percent, 0, 1, 0)}):Play()
		TweenService:Create(knobFrame, TweenInfo.new(0.08), {Position = UDim2.new(percent, 0, 0.5, 0)}):Play()
		sliderLabel.Text = labelText .. ": " .. val
		if onChanged then
			onChanged(val)
		end
	end

	Connect(hitButton.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			UpdateValue(input.Position.X)
		end
	end)

	Connect(UIS.InputChanged, function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			UpdateValue(input.Position.X)
		end
	end)

	Connect(UIS.InputEnded, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	return fillFrame
end

local TrollSliderFill = CreateTrollSpeedSlider(":) Speed", BASE_SPEED, function(val)
	TrollSettings.Speed = val
end)

local EvilTrollSliderFill = CreateTrollSpeedSlider(">:) Speed", BASE_SPEED, function(val)
	TrollSettings.EvilSpeed = val
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
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType.Touch then
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
		FarmingTab.BackgroundColor3 = Accent
		EspTab.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
		SheriffTab.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
		MurdererTab.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
		TrollTab.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
		if FarmSpeedSliderFill then
			FarmSpeedSliderFill.BackgroundColor3 = Accent
		end
		TrollSliderFill.BackgroundColor3 = Accent
		EvilTrollSliderFill.BackgroundColor3 = Accent
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
	FarmingPage.Visible = (pageName == "Farming")
	EspPage.Visible = (pageName == "ESP")
	SheriffPage.Visible = (pageName == "Sheriff")
	MurdererPage.Visible = (pageName == "Murderer")
	TrollPage.Visible = (pageName == "Troll")
	SettingsPage.Visible = (pageName == "Settings")

	Sidebar.Visible = true
	Content.Position = UDim2.fromOffset(130, 0)
	Content.Size = UDim2.new(1, -130, 1, 0)

	TweenService:Create(FarmingTab, TweenInfo.new(0.2), {BackgroundColor3 = (pageName == "Farming") and Accent or Color3.fromRGB(28, 28, 34)}):Play()
	TweenService:Create(EspTab, TweenInfo.new(0.2), {BackgroundColor3 = (pageName == "ESP") and Accent or Color3.fromRGB(28, 28, 34)}):Play()
	TweenService:Create(SheriffTab, TweenInfo.new(0.2), {BackgroundColor3 = (pageName == "Sheriff") and Accent or Color3.fromRGB(28, 28, 34)}):Play()
	TweenService:Create(MurdererTab, TweenInfo.new(0.2), {BackgroundColor3 = (pageName == "Murderer") and Accent or Color3.fromRGB(28, 28, 34)}):Play()
	TweenService:Create(TrollTab, TweenInfo.new(0.2), {BackgroundColor3 = (pageName == "Troll") and Accent or Color3.fromRGB(28, 28, 34)}):Play()
end

Connect(FarmingTab.Activated, function() ShowPage("Farming") end)
Connect(EspTab.Activated, function() ShowPage("ESP") end)
Connect(SheriffTab.Activated, function() ShowPage("Sheriff") end)
Connect(MurdererTab.Activated, function() ShowPage("Murderer") end)
Connect(TrollTab.Activated, function() ShowPage("Troll") end)

local settingsOpen = false
Connect(SettingsButton.Activated, function()
	settingsOpen = not settingsOpen
	if settingsOpen then
		ShowPage("Settings")
	else
		ShowPage("Farming")
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

local function PlayerHasKnife(p)
	if p.Character then
		for _, item in ipairs(p.Character:GetChildren()) do
			if item:IsA("Tool") and (item.Name == "Knife" or item:GetAttribute("IsKnife") == true) then
				return true
			end
		end
	end

	local backpack = p:FindFirstChildOfClass("Backpack")
	if backpack then
		for _, item in ipairs(backpack:GetChildren()) do
			if item:IsA("Tool") and (item.Name == "Knife" or item:GetAttribute("IsKnife") == true) then
				return true
			end
		end
	end

	return false
end

local function GetGunState()
	local char = Player.Character
	if char then
		for _, item in ipairs(char:GetChildren()) do
			if item:IsA("Tool") and (item.Name == "Gun" or item:GetAttribute("IsGun") == true) then
				return "Equipped", item
			end
		end
	end

	local backpack = Player:FindFirstChildOfClass("Backpack")
	if backpack then
		for _, item in ipairs(backpack:GetChildren()) do
			if item:IsA("Tool") and (item.Name == "Gun" or item:GetAttribute("IsGun") == true) then
				return "Backpack", item
			end
		end
	end

	return "None", nil
end

local function FindGunTool()
	if not Player.Character then return nil, false end
	for _, item in ipairs(Player.Character:GetChildren()) do
		if item:IsA("Tool") and (item.Name == "Gun" or item:GetAttribute("IsGun") == true) then
			return item, true
		end
	end

	local backpack = Player:FindFirstChildOfClass("Backpack")
	if backpack then
		for _, item in ipairs(backpack:GetChildren()) do
			if item:IsA("Tool") and (item.Name == "Gun" or item:GetAttribute("IsGun") == true) then
				return item, false
			end
		end
	end

	return nil, false
end

local function HasGun(p)
	if p.Character then
		for _, item in ipairs(p.Character:GetChildren()) do
			if item:IsA("Tool") and (item.Name == "Gun" or item:GetAttribute("IsGun") == true) then
				return true
			end
		end
	end
	local backpack = p:FindFirstChildOfClass("Backpack")
	if backpack then
		for _, item in ipairs(backpack:GetChildren()) do
			if item:IsA("Tool") and (item.Name == "Gun" or item:GetAttribute("IsGun") == true) then
				return true
			end
		end
	end
	return false
end

local function IsHoldingKnife(p)
	if not p.Character then return false end
	for _, item in ipairs(p.Character:GetChildren()) do
		if item:IsA("Tool") and (item.Name == "Knife" or item:GetAttribute("IsKnife") == true) then
			return true
		end
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

local function SyncHeroStates()
	for p, _ in pairs(HeroPlayers) do
		local entry = RoundRolesCache[p.Name]
		if not p.Parent or not entry or entry.Dead or (entry.Role ~= "Innocent" and entry.Role ~= "Hero") then
			HeroPlayers[p] = nil
		end
	end
end

GetPlayerRole = function(p)
	local entry = RoundRolesCache[p.Name]
	if entry and entry.Dead then
		HeroPlayers[p] = nil
		return nil
	end

	if entry and entry.Role then
		if entry.Role == "Sheriff" then
			return "Sheriff"
		elseif entry.Role == "Murderer" then
			return "Murderer"
		elseif entry.Role == "Hero" then
			return "Hero"
		elseif entry.Role == "Innocent" then
			if HeroPlayers[p] and IsSheriffDead() then
				return "Hero"
			end
			return "Innocent"
		end
	end

	return nil
end

local function IsPlayerAliveInRound()
	local entry = RoundRolesCache[Player.Name]
	if not entry then
		return false
	end
	if entry.Dead == true then
		return false
	end
	return entry.Role ~= nil and entry.Role ~= ""
end

FindKnifeMurdererTarget = function()
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= Player and p.Character and PlayerHasKnife(p) then
			local hum = p.Character:FindFirstChildOfClass("Humanoid")
			if not hum or hum.Health > 0 then
				local targetPart = p.Character:FindFirstChild("HumanoidRootPart")
					or p.Character:FindFirstChild("Head")
				if targetPart and targetPart:IsA("BasePart") then
					return p, targetPart
				end
			end
		end
	end
	return nil, nil
end

local function GetMurdererAimPart(char)
	if not char then return nil end
	return char:FindFirstChild("UpperTorso")
		or char:FindFirstChild("Torso")
		or char:FindFirstChild("HumanoidRootPart")
		or char:FindFirstChild("Head")
end

local function FindMurdererShootTarget()
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= Player and p.Character and GetPlayerRole(p) == "Murderer" then
			local hum = p.Character:FindFirstChildOfClass("Humanoid")
			if not hum or hum.Health > 0 then
				local targetPart = GetMurdererAimPart(p.Character)
				if targetPart and targetPart:IsA("BasePart") then
					return p, targetPart
				end
			end
		end
	end

	return FindKnifeMurdererTarget()
end

local function ComputePredictedTargetPosition(targetPart, originPos)
	local basePos = targetPart.Position
	local vel = targetPart.AssemblyLinearVelocity or Vector3.zero
	local dist = (basePos - originPos).Magnitude
	local leadTime = math.clamp(dist / 160, 0, 0.16)
	return basePos + (vel * leadTime)
end

local function FindMurdererFlingTarget()
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= Player and p.Character and GetPlayerRole(p) == "Murderer" then
			local hum = p.Character:FindFirstChildOfClass("Humanoid")
			if not hum or hum.Health > 0 then
				local targetPart = p.Character:FindFirstChild("HumanoidRootPart")
					or p.Character:FindFirstChild("Torso")
					or p.Character:FindFirstChild("UpperTorso")
					or p.Character:FindFirstChild("Head")
				if targetPart and targetPart:IsA("BasePart") then
					return p, targetPart
				end
			end
		end
	end

	local knifePlayer, knifePart = FindKnifeMurdererTarget()
	if knifePlayer and knifePart then
		return knifePlayer, knifePart
	end

	return nil, nil
end

local function GetGunRaycastOrigin(gunTool, hrp)
	if gunTool then
		local attach = gunTool:FindFirstChild("GunRaycastAttachment", true)
		if attach and attach:IsA("Attachment") then
			return attach.WorldCFrame
		end
	end
	if hrp then
		return hrp.CFrame
	end
	return CFrame.identity
end

local lastEquipTick = 0
local lastShootTick = 0

UpdateAimbotState = function(allowEquip)
	if not Alive or not Crosshair then return nil, false end

	if not AimbotSettings.Enabled then
		Crosshair.Visible = false
		return nil, false
	end

	local gunLocation, gunTool = GetGunState()
	if gunLocation == "Equipped" then
		Crosshair.Visible = true
		return gunTool, true
	elseif gunLocation == "Backpack" then
		Crosshair.Visible = false
		if allowEquip and gunTool and Player.Character then
			local hum = Player.Character:FindFirstChildOfClass("Humanoid")
			if hum and hum.Health > 0 and (tick() - lastEquipTick >= 0.35) then
				lastEquipTick = tick()
				hum:EquipTool(gunTool)
			end
		end
		return gunTool, false
	else
		Crosshair.Visible = false
		return nil, false
	end
end

local function GetSelectedTrollHead()
	local target = TrollSettings.TargetPlayer
	if not target then
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= Player and GetPlayerRole(p) == "Murderer" and p.Character then
				target = p
				break
			end
		end
		if not target then
			local knifeTarget = FindKnifeMurdererTarget()
			target = knifeTarget
		end
	end

	if target and target ~= Player and target.Parent and target.Character then
		local head = target.Character:FindFirstChild("Head")
		if head and head:IsA("BasePart") then
			return head
		end
	end
	return nil
end

local staticModelActive = false
local savedPartCollisions = {}
local savedAnimateDisabled = nil
local smilePhase = 0
local evilPhase = 0

local function ApplyStaticModelState(char, hum)
	if not char or not hum then return end

	if not staticModelActive then
		staticModelActive = true
		table.clear(savedPartCollisions)
		for _, part in ipairs(char:GetDescendants()) do
			if part:IsA("BasePart") then
				savedPartCollisions[part] = part.CanCollide
				part.CanCollide = false
			end
		end

		local animateScript = char:FindFirstChild("Animate")
		if animateScript and animateScript:IsA("LocalScript") then
			savedAnimateDisabled = animateScript.Disabled
			animateScript.Disabled = true
		end
	end

	hum.PlatformStand = true
	hum.AutoRotate = false
	hum.WalkSpeed = 0
	hum.JumpPower = 0
	hum.JumpHeight = 0

	local animator = hum:FindFirstChildOfClass("Animator")
	if animator then
		for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
			track:Stop(0)
		end
	end
end

RestoreStaticModelState = function()
	if not staticModelActive then return end
	staticModelActive = false
	smilePhase = 0
	evilPhase = 0

	local char = Player.Character
	if char then
		for part, wasCollidable in pairs(savedPartCollisions) do
			if part and part.Parent then
				part.CanCollide = wasCollidable
			end
		end

		local animateScript = char:FindFirstChild("Animate")
		if animateScript and animateScript:IsA("LocalScript") and savedAnimateDisabled ~= nil then
			animateScript.Disabled = savedAnimateDisabled
		end

		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.PlatformStand = false
			hum.AutoRotate = true
			hum.WalkSpeed = BASE_SPEED
		end
	end

	table.clear(savedPartCollisions)
	savedAnimateDisabled = nil
end

local function GetCycleAngularSpeed(speedValue)
	local baseRate = 6.0
	if speedValue <= BASE_SPEED then
		local ratio = math.clamp(speedValue / BASE_SPEED, 0.05, 1)
		return baseRate * ratio
	else
		local bonus = (speedValue - BASE_SPEED) / (MAX_SPEED - BASE_SPEED)
		return baseRate * (1 + (bonus * 3.0))
	end
end

local function UpdateTrollModes(dt, advancePhase)
	local anyEnabled = TrollSettings.SmileEnabled or TrollSettings.EvilSmileEnabled
	if not anyEnabled or not Player.Character then
		if staticModelActive then
			RestoreStaticModelState()
		end
		return
	end

	local myHRP = Player.Character:FindFirstChild("HumanoidRootPart")
	local myHum = Player.Character:FindFirstChildOfClass("Humanoid")
	local targetHead = GetSelectedTrollHead()
	if not myHRP or not myHum or not targetHead then
		if staticModelActive then
			RestoreStaticModelState()
		end
		return
	end

	ApplyStaticModelState(Player.Character, myHum)

	local stepDt = math.clamp(dt or (1 / 60), 0, 0.1)
	local activeCFrame = nil

	if TrollSettings.EvilSmileEnabled then
		if advancePhase ~= false then
			local evilAngularSpeed = GetCycleAngularSpeed(TrollSettings.EvilSpeed)
			evilPhase = (evilPhase + stepDt * evilAngularSpeed) % (math.pi * 2)
		end

		local pullBackOffset = ((1 - math.cos(evilPhase)) * 0.5) * 1.0
		local flatLook = Vector3.new(targetHead.CFrame.LookVector.X, 0, targetHead.CFrame.LookVector.Z)
		if flatLook.Magnitude < 0.001 then
			flatLook = Vector3.new(0, 0, -1)
		else
			flatLook = flatLook.Unit
		end

		local backDirection = -flatLook
		local horizPos = Vector3.new(targetHead.Position.X, 0, targetHead.Position.Z) + (backDirection * (0.55 + pullBackOffset))
		local headLevelPos = Vector3.new(horizPos.X, targetHead.Position.Y + 0.15, horizPos.Z)
		local lookTargetPos = Vector3.new(targetHead.Position.X, headLevelPos.Y, targetHead.Position.Z)
		activeCFrame = CFrame.lookAt(headLevelPos, lookTargetPos)
	elseif TrollSettings.SmileEnabled then
		if advancePhase ~= false then
			local smileAngularSpeed = GetCycleAngularSpeed(TrollSettings.Speed)
			smilePhase = (smilePhase + stepDt * smileAngularSpeed) % (math.pi * 2)
		end

		local pullOutOffset = ((1 - math.cos(smilePhase)) * 0.5) * 1.0
		local flatLook = Vector3.new(targetHead.CFrame.LookVector.X, 0, targetHead.CFrame.LookVector.Z)
		if flatLook.Magnitude < 0.001 then
			flatLook = Vector3.new(0, 0, -1)
		else
			flatLook = flatLook.Unit
		end

		local horizPos = Vector3.new(targetHead.Position.X, 0, targetHead.Position.Z) + (flatLook * (0.55 + pullOutOffset))
		local headLevelPos = Vector3.new(horizPos.X, targetHead.Position.Y + 0.15, horizPos.Z)
		local lookTargetPos = Vector3.new(targetHead.Position.X, headLevelPos.Y, targetHead.Position.Z)
		activeCFrame = CFrame.lookAt(headLevelPos, lookTargetPos)
	end

	if activeCFrame then
		myHRP.AssemblyLinearVelocity = Vector3.zero
		myHRP.AssemblyAngularVelocity = Vector3.zero
		myHRP.CFrame = activeCFrame
	end
end

-- Auto Farm Coin & Murderer Kill All: body collision disabled strictly during coin flight and restored when not flying to coin
local coinFlightNoClipActive = false
local coinFlightCollisions = {}
local coinFlightMassless = {}
local coinFlightAnimateState = nil
local lockedCoinVisual = nil
local flingPhase = 0

local lastKnifeEquipTick = 0
local lastKnifeAttackTick = 0
local killAllAnchorCFrame = nil
local manualKillAllActive = false
local manualKillAllAnchorCFrame = nil

local function ClearLockedCoin()
	lockedCoinVisual = nil
end

local function StopCoinAnimations(hum)
	if not hum then return end
	local animator = hum:FindFirstChildOfClass("Animator")
	if animator then
		for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
			track:Stop(0)
		end
	end
end

local function ZeroCharacterMomentum(char, hrp)
	if hrp and hrp:IsA("BasePart") then
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero
	end
	if char then
		for _, part in ipairs(char:GetDescendants()) do
			if part:IsA("BasePart") then
				part.AssemblyLinearVelocity = Vector3.zero
				part.AssemblyAngularVelocity = Vector3.zero
			end
		end
	end
end

local function ApplyCoinFlightBodyNoClip(char)
	if not char then return end
	if not coinFlightNoClipActive then
		coinFlightNoClipActive = true
		table.clear(coinFlightCollisions)
		table.clear(coinFlightMassless)

		local animateScript = char:FindFirstChild("Animate")
		if animateScript and animateScript:IsA("LocalScript") then
			coinFlightAnimateState = animateScript.Disabled
			animateScript.Disabled = true
		end
	end

	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") then
			if coinFlightCollisions[part] == nil then
				coinFlightCollisions[part] = part.CanCollide
			end
			part.CanCollide = false
			if part.Name ~= "HumanoidRootPart" and coinFlightMassless[part] == nil then
				coinFlightMassless[part] = part.Massless
				pcall(function()
					part.Massless = true
				end)
			end
		end
	end
end

local function RestoreCoinFlightBodyCollision(char)
	if not coinFlightNoClipActive then return end
	coinFlightNoClipActive = false

	if char then
		for part, wasCollidable in pairs(coinFlightCollisions) do
			if part and part.Parent then
				part.CanCollide = wasCollidable
			end
		end

		for part, wasMassless in pairs(coinFlightMassless) do
			if part and part.Parent then
				pcall(function()
					part.Massless = wasMassless
				end)
			end
		end

		local animateScript = char:FindFirstChild("Animate")
		if animateScript and animateScript:IsA("LocalScript") and coinFlightAnimateState ~= nil then
			animateScript.Disabled = coinFlightAnimateState
		end
	end

	table.clear(coinFlightCollisions)
	table.clear(coinFlightMassless)
	coinFlightAnimateState = nil
end

local function LockCharacterPhysicsForFlight(char, hrp, hum)
	if hum then
		hum.AutoRotate = false
		hum.PlatformStand = false
		hum.Sit = false
		pcall(function()
			hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
			hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
			hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
			hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
		end)
		StopCoinAnimations(hum)
	end
	ZeroCharacterMomentum(char, hrp)
end

local function RestoreCharacterPhysicsAfterFlight(char, hum)
	RestoreCoinFlightBodyCollision(char)
	if hum then
		hum.AutoRotate = true
		hum.PlatformStand = false
		hum.WalkSpeed = BASE_SPEED
		pcall(function()
			hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
			hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
			hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
			hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, true)
			if hum:GetState() == Enum.HumanoidStateType.Physics then
				hum:ChangeState(Enum.HumanoidStateType.Running)
			end
		end)
	end
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	ZeroCharacterMomentum(char, hrp)
end

StopCoinFarmFlight = function()
	ClearLockedCoin()
	flingPhase = 0
	killAllAnchorCFrame = nil
	lastKnifeAttackTick = 0
	local char = Player.Character
	if char then
		local hum = char:FindFirstChildOfClass("Humanoid")
		RestoreCharacterPhysicsAfterFlight(char, hum)
	else
		RestoreCoinFlightBodyCollision(nil)
	end
end

StopManualKillAll = function()
	MurdererCombatSettings.KillAllTriggered = false
	manualKillAllActive = false
	manualKillAllAnchorCFrame = nil
	lastKnifeAttackTick = 0
	if not FarmingSettings.AutoFarmCoin and StopCoinFarmFlight then
		StopCoinFarmFlight()
	end
end

local function FindFullBagIcon()
	local mainGui = PlayerGui:FindFirstChild("MainGUI")
	if not mainGui then return nil end

	local gameFrame = mainGui:FindFirstChild("Game")
	local coinBags = gameFrame and gameFrame:FindFirstChild("CoinBags")
	if not coinBags then
		coinBags = mainGui:FindFirstChild("CoinBags", true)
	end
	if not coinBags then return nil end

	local coinFolder = coinBags:FindFirstChild("Coin")
	if coinFolder then
		local icon = coinFolder:FindFirstChild("FullBagIcon", true)
		if icon then return icon end
	end

	return coinBags:FindFirstChild("FullBagIcon", true)
end

local function IsGuiObjectTrulyVisible(obj)
	if not obj or not obj.Parent then return false end
	if obj:IsA("GuiObject") and not obj.Visible then
		return false
	end

	local current = obj.Parent
	while current and current ~= PlayerGui do
		if current:IsA("ScreenGui") and not current.Enabled then
			return false
		end
		if current:IsA("GuiObject") and not current.Visible then
			return false
		end
		current = current.Parent
	end

	return true
end

local function IsCoinBagFull()
	local fullBagIcon = FindFullBagIcon()
	if not fullBagIcon then
		return false
	end
	return IsGuiObjectTrulyVisible(fullBagIcon)
end

local function IsKnifeUsable(knifeTool)
	if not knifeTool or not knifeTool:IsA("Tool") or not knifeTool.Parent then
		return false
	end
	if knifeTool:GetAttribute("Disabled") == true then
		return false
	end
	return true
end

local function GetKnifeCooldown(knifeTool)
	local defaultCooldown = 0.25

	if knifeTool then
		for _, attrName in ipairs({ "Cooldown", "AttackCooldown", "KnifeCooldown", "StabCooldown", "SwingCooldown" }) do
			local attrVal = knifeTool:GetAttribute(attrName)
			if type(attrVal) == "number" and attrVal > 0 and attrVal <= 5 then
				defaultCooldown = attrVal
				break
			end
		end

		if defaultCooldown == 0.25 then
			for _, obj in ipairs(knifeTool:GetDescendants()) do
				if (obj:IsA("NumberValue") or obj:IsA("IntValue")) then
					local lowerName = string.lower(obj.Name)
					if string.find(lowerName, "cooldown") or string.find(lowerName, "delay") then
						if obj.Value > 0 and obj.Value <= 5 then
							defaultCooldown = obj.Value
							break
						end
					end
				end
			end
		end

		if knifeTool:GetAttribute("EquippedPerk") == "Sleight" then
			defaultCooldown = math.max(0.12, defaultCooldown * 0.7)
		end
	end

	return math.clamp(defaultCooldown, 0.08, 3)
end

local function FindUsableKnifeTool()
	local backpack = Player:FindFirstChildOfClass("Backpack")
	if backpack then
		for _, item in ipairs(backpack:GetChildren()) do
			if item:IsA("Tool") and (item.Name == "Knife" or item:GetAttribute("IsKnife") == true) and IsKnifeUsable(item) then
				return item, false
			end
		end
	end

	if Player.Character then
		for _, item in ipairs(Player.Character:GetChildren()) do
			if item:IsA("Tool") and (item.Name == "Knife" or item:GetAttribute("IsKnife") == true) and IsKnifeUsable(item) then
				return item, true
			end
		end
	end

	return nil, false
end

local function TriggerKnifeStab(knifeTool, targetPart)
	if not knifeTool or not targetPart or not IsKnifeUsable(knifeTool) then return end

	knifeTool:Activate()

	local eventsFolder = knifeTool:FindFirstChild("Events")
	local stabEvent = eventsFolder and eventsFolder:FindFirstChild("KnifeStabbed")
		or knifeTool:FindFirstChild("KnifeStabbed", true)
	if stabEvent and stabEvent:IsA("RemoteEvent") then
		pcall(function()
			stabEvent:FireServer()
		end)
	end

	local handleTouchedEvent = eventsFolder and eventsFolder:FindFirstChild("HandleTouched")
		or knifeTool:FindFirstChild("HandleTouched", true)
	if handleTouchedEvent and handleTouchedEvent:IsA("RemoteEvent") then
		pcall(function()
			handleTouchedEvent:FireServer(targetPart)
		end)
	end

	local handle = knifeTool:FindFirstChild("Handle")
	if handle and handle:IsA("BasePart") and typeof(firetouchinterest) == "function" then
		pcall(function()
			firetouchinterest(handle, targetPart, 0)
			firetouchinterest(handle, targetPart, 1)
		end)
	end
end

local function CollectAliveTargets()
	local aliveTargets = {}

	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= Player and p.Parent and p.Character then
			local entry = RoundRolesCache[p.Name]
			local isDeadInRound = entry and entry.Dead == true
			local invalidRoleInActiveRound = next(RoundRolesCache) ~= nil and (not entry or not entry.Role or entry.Role == "")

			if not isDeadInRound and not invalidRoleInActiveRound then
				local hum = p.Character:FindFirstChildOfClass("Humanoid")
				local hrp = p.Character:FindFirstChild("HumanoidRootPart")
				local part = hrp
					or p.Character:FindFirstChild("UpperTorso")
					or p.Character:FindFirstChild("Torso")
					or p.Character:FindFirstChild("Head")

				if hum and hum.Health > 0 and part and part:IsA("BasePart") then
					table.insert(aliveTargets, {
						Player = p,
						Humanoid = hum,
						HRP = hrp,
						Part = part
					})
				end
			end
		end
	end

	return aliveTargets
end

local function IsTargetStillAlive(entry)
	if not entry or not entry.Player or not entry.Player.Parent or not entry.Player.Character then
		return false
	end
	local roleEntry = RoundRolesCache[entry.Player.Name]
	if roleEntry and roleEntry.Dead == true then
		return false
	end
	if not entry.Humanoid or entry.Humanoid.Health <= 0 then
		return false
	end
	if not entry.Part or not entry.Part.Parent then
		return false
	end
	return true
end

local function ExecuteKnifeKillAllLoop(char, hrp, hum, anchorCFrame)
	local knifeTool, equipped = FindUsableKnifeTool()
	if not knifeTool then
		return false, false
	end

	local targets = CollectAliveTargets()
	if #targets == 0 then
		if anchorCFrame and hrp and hrp.Parent then
			hrp.CFrame = anchorCFrame
			ZeroCharacterMomentum(char, hrp)
		end
		return false, true
	end

	RestoreCoinFlightBodyCollision(char)
	LockCharacterPhysicsForFlight(char, hrp, hum)

	if not equipped then
		if tick() - lastKnifeEquipTick >= 0.08 then
			lastKnifeEquipTick = tick()
			hum:EquipTool(knifeTool)
		end
		return true, false
	end

	local knifeCooldown = GetKnifeCooldown(knifeTool)
	if tick() - lastKnifeAttackTick < knifeCooldown then
		return true, false
	end

	local strikePoint = anchorCFrame.Position + (anchorCFrame.LookVector * 1.8)
	hrp.CFrame = CFrame.lookAt(anchorCFrame.Position, strikePoint)
	ZeroCharacterMomentum(char, hrp)

	local handle = knifeTool and knifeTool:FindFirstChild("Handle")
	if handle and handle:IsA("BasePart") and not handle.Anchored then
		handle.CFrame = CFrame.lookAt(strikePoint, strikePoint + anchorCFrame.LookVector)
	end

	local didAttackThisCycle = false

	for _, entry in ipairs(targets) do
		if IsTargetStillAlive(entry) and IsKnifeUsable(knifeTool) then
			local targetPart = entry.Part
			local targetRoot = entry.HRP or targetPart

			pcall(function()
				if targetRoot and targetRoot:IsA("BasePart") and not targetRoot.Anchored then
					targetRoot.CFrame = CFrame.new(strikePoint)
					targetRoot.AssemblyLinearVelocity = Vector3.zero
					targetRoot.AssemblyAngularVelocity = Vector3.zero
				end
			end)

			TriggerKnifeStab(knifeTool, targetPart)
			didAttackThisCycle = true
		end
	end

	if didAttackThisCycle then
		lastKnifeAttackTick = tick()
	end

	if #CollectAliveTargets() == 0 and anchorCFrame then
		hrp.CFrame = anchorCFrame
		ZeroCharacterMomentum(char, hrp)
		return false, true
	end

	return true, false
end

local function TryManualKillAll(char, hrp, hum)
	if not MurdererCombatSettings.KillAllButtonEnabled or not MurdererCombatSettings.KillAllTriggered then
		if manualKillAllActive then
			StopManualKillAll()
		end
		return false
	end

	local knifeTool = FindUsableKnifeTool()
	if not knifeTool then
		StopManualKillAll()
		return false
	end

	if not manualKillAllAnchorCFrame then
		manualKillAllAnchorCFrame = hrp.CFrame
	end

	manualKillAllActive = true
	local keepGoing, finishedAll = ExecuteKnifeKillAllLoop(char, hrp, hum, manualKillAllAnchorCFrame)
	if finishedAll or not keepGoing then
		StopManualKillAll()
		return false
	end

	return true
end

local function TryKillAllWhenFullBag(char, hrp, hum)
	if not FarmingSettings.KillAllWhenFullBag then
		killAllAnchorCFrame = nil
		return false
	end

	local knifeTool = FindUsableKnifeTool()
	if not knifeTool then
		killAllAnchorCFrame = nil
		lastKnifeAttackTick = 0
		return false
	end

	if not killAllAnchorCFrame then
		killAllAnchorCFrame = hrp.CFrame
	end

	local keepGoing, finishedAll = ExecuteKnifeKillAllLoop(char, hrp, hum, killAllAnchorCFrame)
	if finishedAll or not keepGoing then
		killAllAnchorCFrame = nil
		return false
	end

	return true
end

local function FireGunAtPosition(gunTool, hrp, aimPos)
	local originCFrame = GetGunRaycastOrigin(gunTool, hrp)
	local targetCFrame = CFrame.new(aimPos)

	if hrp and hrp:IsA("BasePart") then
		local flatTarget = Vector3.new(aimPos.X, hrp.Position.Y, aimPos.Z)
		if (flatTarget - Vector3.new(hrp.Position.X, hrp.Position.Y, hrp.Position.Z)).Magnitude > 0.01 then
			hrp.CFrame = CFrame.lookAt(hrp.Position, flatTarget)
			hrp.AssemblyLinearVelocity = Vector3.zero
			hrp.AssemblyAngularVelocity = Vector3.zero
		end
	end

	local shootEvent = gunTool:FindFirstChild("Shoot", true)
	if shootEvent and shootEvent:IsA("RemoteEvent") then
		shootEvent:FireServer(originCFrame, targetCFrame)
	else
		gunTool:Activate()
	end
end

local function TryAutoShootMurdererWhenFullBag(char, hrp, hum)
	if not FarmingSettings.ShootMurdererWhenFullBag then
		return false
	end

	local _, targetPart = FindMurdererShootTarget()
	if not targetPart then
		return false
	end

	local gunTool, equipped = FindGunTool()
	if not gunTool then
		return false
	end

	if not equipped then
		if tick() - lastEquipTick >= 0.2 then
			lastEquipTick = tick()
			hum:EquipTool(gunTool)
		end
		return true
	end

	if tick() - lastShootTick < 0.35 then
		return true
	end

	lastShootTick = tick()
	local originPos = GetGunRaycastOrigin(gunTool, hrp).Position
	local predictedAimPos = ComputePredictedTargetPosition(targetPart, originPos)
	FireGunAtPosition(gunTool, hrp, predictedAimPos)

	return true
end

local function UpdateFlingMurderer(char, hrp, hum, dt)
	local targetPlayer, targetPart = FindMurdererFlingTarget()
	if not targetPlayer or not targetPart then
		return false
	end

	local stepDt = math.clamp(dt or (1 / 60), 0, 0.1)
	flingPhase = (flingPhase + stepDt * 40) % (math.pi * 2)

	RestoreCoinFlightBodyCollision(char)
	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = true
		end
	end

	hum.AutoRotate = false
	hum.PlatformStand = false
	StopCoinAnimations(hum)

	local targetHRP = targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart")
	local targetVel = targetHRP and targetHRP.AssemblyLinearVelocity or Vector3.zero

	local leadPos = targetPart.Position + (targetVel * 0.08)
	local offset = Vector3.new(
		math.cos(flingPhase) * 0.9,
		math.sin(flingPhase * 2) * 0.35,
		math.sin(flingPhase) * 0.9
	)

	hrp.CFrame = CFrame.lookAt(leadPos + offset, targetPart.Position)
	hrp.AssemblyAngularVelocity = Vector3.new(2500, 2500, 2500)
	hrp.AssemblyLinearVelocity = Vector3.new(
		math.cos(flingPhase) * 180,
		120,
		math.sin(flingPhase) * 180
	)

	return true
end

local function IsValidCoinVisual(visual)
	return visual ~= nil
		and typeof(visual) == "Instance"
		and visual:IsA("BasePart")
		and visual.Parent ~= nil
		and visual:IsDescendantOf(Workspace)
end

local function FindCoinVisualPart(entry)
	if not entry or not entry.Parent or not entry:IsDescendantOf(Workspace) then
		return nil
	end

	if entry:IsA("BasePart") and entry.Name == "CoinVisual" then
		return entry
	end

	local visual = entry:FindFirstChild("CoinVisual", true)
	if visual and visual:IsA("BasePart") and visual.Parent and visual:IsDescendantOf(Workspace) then
		return visual
	end

	return nil
end

local function GetSortedCoinVisuals(fromPos)
	local entries = {}
	local seen = {}

	local function AddVisual(visual)
		if IsValidCoinVisual(visual) and not seen[visual] then
			seen[visual] = true
			table.insert(entries, {
				Part = visual,
				Dist = (visual.Position - fromPos).Magnitude
			})
		end
	end

	for _, obj in ipairs(Workspace:GetDescendants()) do
		if obj.Name == "CoinContainer" then
			for _, child in ipairs(obj:GetChildren()) do
				if child.Name == "Coin_Server" or child:FindFirstChild("CoinVisual", true) then
					AddVisual(FindCoinVisualPart(child))
				end
			end
		elseif obj.Name == "Coin_Server" then
			AddVisual(FindCoinVisualPart(obj))
		end
	end

	table.sort(entries, function(a, b)
		return a.Dist < b.Dist
	end)

	return entries
end

local function UpdateCoinAutoFarm(dt)
	if not FarmingSettings.AutoFarmCoin or not Alive or not Player.Character then
		StopCoinFarmFlight()
		return
	end

	if TrollSettings.SmileEnabled or TrollSettings.EvilSmileEnabled then
		StopCoinFarmFlight()
		return
	end

	if not IsPlayerAliveInRound() then
		StopCoinFarmFlight()
		return
	end

	local char = Player.Character
	local hrp = char:FindFirstChild("HumanoidRootPart")
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum or hum.Health <= 0 then
		StopCoinFarmFlight()
		return
	end

	if IsCoinBagFull() then
		ClearLockedCoin()
		RestoreCoinFlightBodyCollision(char)
		local didKillAll = TryKillAllWhenFullBag(char, hrp, hum)
		if didKillAll then
			return
		end

		local didShoot = TryAutoShootMurdererWhenFullBag(char, hrp, hum)
		if FarmingSettings.FlingMurdererWhenFullBag then
			if not didShoot and not UpdateFlingMurderer(char, hrp, hum, dt) then
				StopCoinFarmFlight()
			end
		elseif not didShoot then
			StopCoinFarmFlight()
		end
		return
	end

	flingPhase = 0
	killAllAnchorCFrame = nil

	if not IsValidCoinVisual(lockedCoinVisual) then
		local sortedCoins = GetSortedCoinVisuals(hrp.Position)
		local targetEntry = sortedCoins[1]
		lockedCoinVisual = targetEntry and targetEntry.Part or nil
	end

	if not IsValidCoinVisual(lockedCoinVisual) then
		ClearLockedCoin()
		RestoreCoinFlightBodyCollision(char)
		return
	end

	-- Активный полёт к целевой монете: отключаем коллизию всего тела только на время этого полёта
	ApplyCoinFlightBodyNoClip(char)
	LockCharacterPhysicsForFlight(char, hrp, hum)

	local stepDt = math.clamp(dt or (1 / 60), 0, 0.1)
	local currentPos = hrp.Position
	local baseCoinPos = lockedCoinVisual.Position
	local targetPos = FarmingSettings.UndergroundMode
		and (baseCoinPos + Vector3.new(0, UNDERGROUND_Y_OFFSET, 0))
		or baseCoinPos

	local delta = targetPos - currentPos
	local distance = delta.Magnitude

	local flightSpeed = FarmingSettings.FarmSpeed or BASE_SPEED
	hum.WalkSpeed = flightSpeed
	local stepDist = flightSpeed * stepDt

	local reachedCoin = false
	local nextPos
	local touchRadius = FarmingSettings.UndergroundMode and 1.8 or 1.5
	if distance <= touchRadius or distance <= stepDist then
		nextPos = FarmingSettings.UndergroundMode and baseCoinPos or targetPos
		reachedCoin = true
	else
		nextPos = currentPos + (delta.Unit * stepDist)
	end

	if FarmingSettings.UndergroundMode then
		local lookAhead = nextPos + Vector3.new(0, 1, 0)
		hrp.CFrame = CFrame.lookAt(nextPos, lookAhead)
	else
		local moveDir = baseCoinPos - nextPos
		if moveDir.Magnitude > 0.001 then
			hrp.CFrame = CFrame.lookAt(nextPos, nextPos + moveDir.Unit)
		else
			hrp.CFrame = CFrame.new(nextPos)
		end
	end

	ZeroCharacterMomentum(char, hrp)

	if reachedCoin then
		ClearLockedCoin()
		RestoreCoinFlightBodyCollision(char)
	end
end

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
			local roleStr = tostring(info.Role)
			local isDead = info.Dead == true
			RoundRolesCache[playerName] = {
				Role = roleStr,
				Dead = isDead
			}

			local p = Players:FindFirstChild(playerName)
			if p then
				if isDead or (roleStr ~= "Innocent" and roleStr ~= "Hero") then
					HeroPlayers[p] = nil
				elseif roleStr == "Hero" then
					HeroPlayers[p] = true
				end
			end
		end
	end

	for playerName in pairs(RoundRolesCache) do
		local p = Players:FindFirstChild(playerName)
		if not p then
			RoundRolesCache[playerName] = nil
		end
	end

	SyncHeroStates()

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
			if obj.Name == "GunDrop" and obj:IsA("BasePart") and obj.Parent then
				hasAnyGunDrop = true
				if not TrackedDrops[obj] then
					TrackedDrops[obj] = true
					Connect(obj.Touched, function(hit)
						if not Alive then return end
						local char = hit.Parent
						local hum = char and char:FindFirstChildOfClass("Humanoid")
						if hum and hum.Health > 0 then
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
		end
		SyncHeroStates()
	end
end)

SpawnTracked(function()
	while Alive do
		local gunDrop = FindGunDrop()
		if not gunDrop then
			task.wait(0.2)
		else
			if AutoGrabSettings.Enabled and gunDrop.Parent and Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
				local myRole = GetPlayerRole(Player)
				if myRole == "Innocent" and not HasGun(Player) then
					local hrp = Player.Character.HumanoidRootPart
					local originalCFrame = hrp.CFrame

					hrp.CFrame = gunDrop.CFrame + Vector3.new(0, 2, 0)

					DelayTracked(0.1, function()
						if Alive and hrp and hrp.Parent and originalCFrame then
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
	end
end)

local function ShootAtMurderer()
	if tick() - lastShootTick < 0.35 then return end

	if not Player.Character then return end
	local char = Player.Character
	local hrp = char:FindFirstChild("HumanoidRootPart")
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum or hum.Health <= 0 then return end

	local gunTool, equipped = FindGunTool()
	if not gunTool then return end

	if not equipped then
		if tick() - lastEquipTick >= 0.2 then
			lastEquipTick = tick()
			hum:EquipTool(gunTool)
		end
		task.wait(0.1)
		gunTool, equipped = FindGunTool()
		if not gunTool or not equipped then return end
	end

	local _, targetPart = FindMurdererShootTarget()
	if not targetPart then return end

	lastShootTick = tick()
	local originPos = GetGunRaycastOrigin(gunTool, hrp).Position
	local predictedAimPos = ComputePredictedTargetPosition(targetPart, originPos)
	FireGunAtPosition(gunTool, hrp, predictedAimPos)
end

MakeDraggableActionButton(KillAllActionButton, function()
	if not MurdererCombatSettings.KillAllButtonEnabled then return end
	MurdererCombatSettings.KillAllTriggered = true
end)

MakeDraggableActionButton(ShootButton, function()
	ShootAtMurderer()
end)

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

Connect(RunService.Heartbeat, function(dt)
	if not Alive then return end
	UpdateTrollModes(dt, true)

	local didManualKillAll = false
	if MurdererCombatSettings.KillAllButtonEnabled and MurdererCombatSettings.KillAllTriggered and Player.Character then
		local char = Player.Character
		local hrp = char:FindFirstChild("HumanoidRootPart")
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hrp and hum and hum.Health > 0 then
			didManualKillAll = TryManualKillAll(char, hrp, hum)
		end
	end

	if not didManualKillAll then
		UpdateCoinAutoFarm(dt)
	end
end)

Connect(RunService.RenderStepped, function(dt)
	if not Alive then return end

	UpdateTrollModes(dt, false)

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
		FarmingTab.BackgroundColor3 = rainbow
		EspTab.BackgroundColor3 = rainbow
		SheriffTab.BackgroundColor3 = rainbow
		MurdererTab.BackgroundColor3 = rainbow
		TrollTab.BackgroundColor3 = rainbow
		if FarmSpeedSliderFill then
			FarmSpeedSliderFill.BackgroundColor3 = rainbow
		end
		TrollSliderFill.BackgroundColor3 = rainbow
		EvilTrollSliderFill.BackgroundColor3 = rainbow
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

	local currentCamera = Workspace.CurrentCamera
	local _, hasGunInHand = UpdateAimbotState(true)
	if AimbotSettings.Enabled and hasGunInHand and Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") and currentCamera then
		local _, targetPart = FindMurdererShootTarget()
		if targetPart then
			currentCamera.CFrame = CFrame.new(currentCamera.CFrame.Position, targetPart.Position)
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
		if p == Player then
			if StopManualKillAll then StopManualKillAll() end
			if StopCoinFarmFlight then StopCoinFarmFlight() end
		end
		RemoveESP(p)
		HeroPlayers[p] = nil
	end)
	Connect(p.CharacterAdded, function()
		if p == Player then
			if StopManualKillAll then StopManualKillAll() end
			if StopCoinFarmFlight then StopCoinFarmFlight() end
		end
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
end)

Connect(CloseButton.Activated, function() Cleanup() end)

ApplyTransparency()
ApplyNormalTheme()
