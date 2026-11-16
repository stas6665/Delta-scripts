local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- Loading Screen
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
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Position = UDim2.new(0, 0, 0.42, 0)
Title.BackgroundTransparency = 1
Title.Text = "MM2 HUB"
Title.TextColor3 = Color3.fromRGB(220, 220, 220)
Title.TextSize = 25
Title.Font = Enum.Font.GothamBold
Title.Parent = Background

local Percent = Instance.new("TextLabel")
Percent.Size = UDim2.new(1, 0, 0, 25)
Percent.Position = UDim2.new(0, 0, 0.52, 0)
Percent.BackgroundTransparency = 1
Percent.Text = "1%"
Percent.TextColor3 = Color3.fromRGB(255, 255, 255)
Percent.TextSize = 14
Percent.Font = Enum.Font.GothamMedium
Percent.Parent = Background

local Track = Instance.new("Frame")
Track.Size = UDim2.new(0, 240, 0, 6)
Track.Position = UDim2.new(0.5, -120, 0.58, 0)
Track.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
Track.BorderSizePixel = 0
Track.Parent = Background

Instance.new("UICorner", Track).CornerRadius = UDim.new(1, 0)

local Fill = Instance.new("Frame")
Fill.Size = UDim2.new(0.01, 0, 1, 0)
Fill.BackgroundColor3 = Color3.fromRGB(160, 25, 45)
Fill.BorderSizePixel = 0
Fill.Parent = Track

Instance.new("UICorner", Fill).CornerRadius = UDim.new(1, 0)

local FillTween = TweenService:Create(
    Fill,
    TweenInfo.new(2, Enum.EasingStyle.Linear),
    {Size = UDim2.new(1, 0, 1, 0)}
)

FillTween:Play()

task.spawn(function()
    for i = 1, 100 do
        Percent.Text = i .. "%"
        task.wait(0.02)
    end
end)

FillTween.Completed:Wait()

local Fade = TweenService:Create(
    Background,
    TweenInfo.new(0.25),
    {BackgroundTransparency = 1}
)

Fade:Play()
Fade.Completed:Wait()
LoadingGui:Destroy()

-- Cleanup old GUI if exists
local Old = PlayerGui:FindFirstChild("MM2UltimateUI")
if Old then
    Old:Destroy()
end

local GUI
local Connections = {}
local Alive = true

local function Connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(Connections, connection)
    return connection
end

local function Cleanup()
    if not Alive then return end
    Alive = false

    for _, connection in ipairs(Connections) do  
        if connection.Connected then  
            connection:Disconnect()  
        end  
    end  

    table.clear(Connections)  

    if GUI then  
        GUI:Destroy()  
    end
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
    Innocent = false
}

GUI = Instance.new("ScreenGui")
GUI.Name = "MM2UltimateUI"
GUI.ResetOnSpawn = false
GUI.IgnoreGuiInset = true
GUI.DisplayOrder = 999
GUI.Parent = PlayerGui

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

local Main = New("Frame", {
    Name = "MainWindow",
    Size = UDim2.fromOffset(390, 285),
    Position = UDim2.new(0.5, -195, 0.5, -142),
    BackgroundColor3 = Color3.fromRGB(24, 24, 28),
    BackgroundTransparency = 0,
    BorderSizePixel = 0
}, GUI)

Corner(Main, 12)
local MainStroke = Stroke(Main, OutlineColor, 2)

local Header = New("Frame", {
    Size = UDim2.new(1, 0, 0, 43),
    BackgroundColor3 = Color3.fromRGB(17, 17, 20),
    BackgroundTransparency = 0,
    BorderSizePixel = 0,
    ZIndex = 5
}, Main)

Corner(Header, 12)

local HeaderCover = New("Frame", {
    Size = UDim2.new(1, 0, 0, 12),
    Position = UDim2.new(0, 0, 1, -12),
    BackgroundColor3 = Header.BackgroundColor3,
    BorderSizePixel = 0,
    ZIndex = 5
}, Header)

local TitleLabel = New("TextLabel", {
    Size = UDim2.new(1, -120, 1, 0),
    Position = UDim2.fromOffset(13, 0),
    BackgroundTransparency = 1,
    Text = "MM2 Ultimate Hub",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 16,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 6
}, Header)

local function HeaderButton(text, x, color)
    local button = New("TextButton", {
        Size = UDim2.fromOffset(30, 29),
        Position = UDim2.new(1, x, 0, 7),
        BackgroundColor3 = Color3.fromRGB(38, 38, 43),
        BackgroundTransparency = 0,
        Text = text,
        TextColor3 = color or Color3.new(1, 1, 1),
        TextSize = 17,
        Font = Enum.Font.GothamBold,
        BorderSizePixel = 0,
        ZIndex = 7
    }, Header)
    Corner(button, 7)  
    return button
end

local MinimizeButton = HeaderButton("−", -105)
local SettingsButton = HeaderButton("⚙", -68)
local CloseButton = HeaderButton("×", -34, Color3.fromRGB(255, 90, 90))

local Body = New("Frame", {
    Name = "Body",
    Position = UDim2.fromOffset(0, 43),
    Size = UDim2.new(1, 0, 1, -43),
    BackgroundColor3 = Main.BackgroundColor3,
    BackgroundTransparency = 0,
    BorderSizePixel = 0
}, Main)

local Sidebar = New("Frame", {
    Size = UDim2.new(0, 105, 1, 0),
    BackgroundColor3 = Color3.fromRGB(19, 19, 23),
    BackgroundTransparency = 0,
    BorderSizePixel = 0
}, Body)

local EspTab = New("TextButton", {
    Size = UDim2.new(1, -12, 0, 38),
    Position = UDim2.fromOffset(6, 12),
    BackgroundColor3 = Accent,
    BackgroundTransparency = 0,
    Text = "◉  ESP",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 14,
    Font = Enum.Font.GothamBold,
    BorderSizePixel = 0
}, Sidebar)

Corner(EspTab, 7)

local Content = New("Frame", {
    Position = UDim2.fromOffset(105, 0),
    Size = UDim2.new(1, -105, 1, 0),
    BackgroundTransparency = 1
}, Body)

local function Page(name)
    return New("ScrollingFrame", {
        Name = name,
        Size = UDim2.new(1, -12, 1, -12),
        Position = UDim2.fromOffset(6, 6),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        Visible = false
    }, Content)
end

local EspPage = Page("ESP")
local SettingsPage = Page("Settings")
EspPage.Visible = true

local function AddLayout(page)
    local layout = New("UIListLayout", {
        Padding = UDim.new(0, 9),
        SortOrder = Enum.SortOrder.LayoutOrder
    }, page)

    Connect(layout:GetPropertyChangedSignal("AbsoluteContentSize"), function()  
        page.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 12)  
    end)  
    return layout
end

local EspLayout = AddLayout(EspPage)
local SettingsLayout = AddLayout(SettingsPage)

local function Label(parent, text)
    return New("TextLabel", {
        Size = UDim2.new(1, -5, 0, 28),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = Color3.fromRGB(235, 235, 235),
        TextSize = 15,
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
        Size = UDim2.new(1, -5, 0, 43),
        BackgroundColor3 = Color3.fromRGB(34, 34, 39),
        BackgroundTransparency = 0,
        BorderSizePixel = 0
    }, parent)

    Corner(row, 8)  

    New("TextLabel", {  
        Size = UDim2.new(1, -70, 1, 0),  
        Position = UDim2.fromOffset(11, 0),  
        BackgroundTransparency = 1,  
        Text = name,  
        TextColor3 = Color3.new(1, 1, 1),  
        TextSize = 13,  
        Font = Enum.Font.GothamMedium,  
        TextXAlignment = Enum.TextXAlignment.Left  
    }, row)  

    local enabled = false  

    local button = New("TextButton", {  
        Size = UDim2.fromOffset(43, 23),  
        Position = UDim2.new(1, -53, 0.5, -11),  
        BackgroundColor3 = Color3.fromRGB(65, 65, 70),  
        BackgroundTransparency = 0,  
        Text = "",  
        BorderSizePixel = 0  
    }, row)  

    Corner(button, 15)  

    local toggleStroke = Stroke(button, Color3.fromRGB(0, 0, 0), 1.5)  

    local knob = New("Frame", {  
        Size = UDim2.fromOffset(17, 17),  
        Position = UDim2.fromOffset(3, 3),  
        BackgroundColor3 = Color3.new(1, 1, 1),  
        BorderSizePixel = 0  
    }, button)  

    Corner(knob, 12)  

    local record = {  
        Button = button,  
        Row = row,  
        Stroke = toggleStroke,  
        Knob = knob,  
        Enabled = false  
    }  

    table.insert(ToggleRecords, record)  

    Connect(button.Activated, function()  
        enabled = not enabled  
        record.Enabled = enabled  

        knob.Position = enabled and UDim2.new(1, -20, 0, 3) or UDim2.fromOffset(3, 3)  
        UpdateToggleAppearance(record)  
        
        if callback then  
            callback(enabled)  
        end  
    end)  

    return button
end

Label(EspPage, "ROLE ESP")

Toggle(EspPage, "ESP Sheriff", function(state)
    ESP_Settings.Sheriff = state
end)

Toggle(EspPage, "ESP Murderer", function(state)
    ESP_Settings.Murderer = state
end)

Toggle(EspPage, "ESP Innocent", function(state)
    ESP_Settings.Innocent = state
end)

Label(SettingsPage, "GENERAL SETTINGS")

local TransparencyLabel = Label(SettingsPage, "Window Transparency: 0%")

local Slider = New("Frame", {
    Size = UDim2.new(1, -8, 0, 8),
    BackgroundColor3 = Color3.fromRGB(55, 55, 60),
    BackgroundTransparency = 0,
    BorderSizePixel = 0,
    ClipsDescendants = false
}, SettingsPage)

Corner(Slider, 8)

local SliderFill = New("Frame", {
    Size = UDim2.new(0, 0, 1, 0),
    BackgroundColor3 = Accent,
    BackgroundTransparency = 0,
    BorderSizePixel = 0,
    ZIndex = 2
}, Slider)

Corner(SliderFill, 8)

local SliderKnob = New("Frame", {
    Size = UDim2.fromOffset(16, 16),
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0, 0, 0.5, 0),
    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
    BackgroundTransparency = 0,
    BorderSizePixel = 0,
    ZIndex = 4
}, Slider)

Corner(SliderKnob, 50)

local SliderButton = New("TextButton", {
    Size = UDim2.new(1, 0, 0, 28),
    Position = UDim2.new(0, 0, 0.5, -14),
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
    MinimizeButton.BackgroundTransparency = 0  
    SettingsButton.BackgroundTransparency = 0  
    CloseButton.BackgroundTransparency = 0
end

local function UpdateTransparency(x)
    local width = Slider.AbsoluteSize.X
    if width <= 0 then return end
    local percent = math.clamp((x - Slider.AbsolutePosition.X) / width, 0, 1)  
    transparencyValue = math.floor(percent * 80)  
    SliderFill.Size = UDim2.new(percent, 0, 1, 0)  
    SliderKnob.Position = UDim2.new(percent, 0, 0.5, 0)  
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
    local container = New("Frame", {
        Size = UDim2.new(1, -5, 0, 40),
        BackgroundColor3 = Color3.fromRGB(34, 34, 39),
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        ClipsDescendants = true
    }, parent)

    Corner(container, 8)  

    local head = New("TextButton", {  
        Size = UDim2.new(1, 0, 0, 40),  
        BackgroundTransparency = 1,  
        Text = title .. "     ▼",  
        TextColor3 = Color3.new(1, 1, 1),  
        TextSize = 13,  
        Font = Enum.Font.GothamBold  
    }, container)  

    local list = New("Frame", {  
        Position = UDim2.fromOffset(5, 43),  
        Size = UDim2.new(1, -10, 0, 0),  
        BackgroundTransparency = 1  
    }, container)  

    New("UIGridLayout", {  
        CellSize = UDim2.new(0.5, -5, 0, 30),  
        CellPadding = UDim2.fromOffset(7, 6),  
        SortOrder = Enum.SortOrder.LayoutOrder  
    }, list)  

    local open = false  
    table.insert(AccordionRecords, {Container = container, Head = head})  

    for _, colorName in ipairs(ColorNames) do  
        local button = New("TextButton", {  
            BackgroundColor3 = ColorValues[colorName] or Color3.fromRGB(130, 80, 180),  
            BackgroundTransparency = 0,  
            Text = colorName,  
            TextColor3 = Color3.new(1, 1, 1),  
            TextSize = 11,  
            Font = Enum.Font.GothamBold,  
            BorderSizePixel = 0  
        }, list)  

        Corner(button, 6)  
        Connect(button.Activated, function()  
            callback(colorName)  
        end)  
    end  

    Connect(head.Activated, function()  
        open = not open  
        local height = open and 190 or 40  
        container.Size = UDim2.new(1, -5, 0, height)  
        list.Size = UDim2.new(1, -10, 0, open and 140 or 0)  
        head.Text = title .. (open and "     ▲" or "     ▼")  
        task.defer(function()  
            SettingsPage.CanvasSize = UDim2.new(0, 0, 0, SettingsLayout.AbsoluteContentSize.Y + 12)  
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

local function ApplyNormalTheme()
    local background = Color3.fromRGB(24, 24, 28)
    Main.BackgroundColor3 = background  
    Body.BackgroundColor3 = background  
    Header.BackgroundColor3 = Color3.fromRGB(17, 17, 20)  
    HeaderCover.BackgroundColor3 = Header.BackgroundColor3  
    Sidebar.BackgroundColor3 = Color3.fromRGB(19, 19, 23)  
    MinimizeButton.BackgroundColor3 = Color3.fromRGB(38, 38, 43)  
    SettingsButton.BackgroundColor3 = Color3.fromRGB(38, 38, 43)  
    CloseButton.BackgroundColor3 = Color3.fromRGB(38, 38, 43)  

    for _, record in ipairs(ToggleRecords) do  
        record.Row.BackgroundColor3 = Color3.fromRGB(34, 34, 39)  
        UpdateToggleAppearance(record)  
    end  

    for _, record in ipairs(AccordionRecords) do  
        record.Container.BackgroundColor3 = Color3.fromRGB(34, 34, 39)  
    end
end

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

local function ShowPage(page)
    EspPage.Visible = page == "ESP"
    SettingsPage.Visible = page == "Settings"
    Sidebar.Visible = page == "ESP"  
    Content.Position = page == "ESP" and UDim2.fromOffset(105, 0) or UDim2.fromOffset(0, 0)  
    Content.Size = page == "ESP" and UDim2.new(1, -105, 1, 0) or UDim2.new(1, 0, 1, 0)  
    EspTab.BackgroundColor3 = Accent
end

Connect(EspTab.Activated, function()
    ShowPage("ESP")
end)

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
    Body.Visible = not state  
    Main.Size = state and UDim2.fromOffset(240, 43) or UDim2.fromOffset(390, 285)
end

Connect(MinimizeButton.Activated, function()
    SetMinimized(not minimized)
end)

Connect(TitleLabel.InputBegan, function(input)
    if minimized and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
        SetMinimized(false)
    end
end)

local dragging = false
local dragStart
local startPosition
local dragInput

Connect(Header.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        local target = input.Target  
        if target == MinimizeButton or target == SettingsButton or target == CloseButton then  
            return  
        end  
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

-- ИНТЕГРАЦИЯ С CurrentRoundClient ДЛЯ ТОЧНОГО ОПРЕДЕЛЕНИЯ РОЛЕЙ
local CurrentRoundClient = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("CurrentRoundClient"))

local function GetPlayerRole(p)
    local playerData = CurrentRoundClient.PlayerData
    if typeof(playerData) == "table" then
        for _, data in pairs(playerData) do
            if data.Player == p or data.Instance == p or (typeof(data.Player) == "string" and data.Player == p.Name) then
                return data.Role or "Innocent"
            end
        end
    end
    return "Innocent"
end

-- ESP SYSTEM
local ActiveESPObjects = {}

local function RemoveESP(p)
    if ActiveESPObjects[p] then
        if ActiveESPObjects[p].Highlight then
            ActiveESPObjects[p].Highlight:Destroy()
        end
        if ActiveESPObjects[p].Billboard then
            ActiveESPObjects[p].Billboard:Destroy()
        end
        ActiveESPObjects[p] = nil
    end
end

Connect(RunService.RenderStepped, function()
    if not Alive then return end

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local role = GetPlayerRole(p)
            local shouldShow = false

            if role == "Sheriff" and ESP_Settings.Sheriff then
                shouldShow = true
            elseif role == "Murderer" and ESP_Settings.Murderer then
                shouldShow = true
            elseif role == "Innocent" and ESP_Settings.Innocent then
                shouldShow = true
            end

            if shouldShow then
                if not ActiveESPObjects[p] then
                    local highlight = Instance.new("Highlight")
                    highlight.Adornee = p.Character
                    highlight.Parent = p.Character
                    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

                    local billboard = Instance.new("BillboardGui")
                    billboard.Size = UDim2.fromOffset(100, 40)
                    billboard.StudsOffset = Vector3.new(0, 3, 0)
                    billboard.AlwaysOnTop = true
                    billboard.Adornee = p.Character:FindFirstChild("Head") or p.Character.HumanoidRootPart
                    billboard.Parent = p.Character

                    local nameLabel = Instance.new("TextLabel")
                    nameLabel.Size = UDim2.new(1, 0, 1, 0)
                    nameLabel.BackgroundTransparency = 1
                    nameLabel.TextSize = 14
                    nameLabel.Font = Enum.Font.GothamBold
                    nameLabel.TextColor3 = Color3.new(1, 1, 1)
                    nameLabel.TextStrokeTransparency = 0
                    nameLabel.Parent = billboard

                    ActiveESPObjects[p] = {Highlight = highlight, Billboard = billboard, NameLabel = nameLabel}
                end

                local espData = ActiveESPObjects[p]
                local espColor = Color3.new(1, 1, 1)

                if role == "Sheriff" then
                    espColor = Color3.fromRGB(45, 115, 230)
                elseif role == "Murderer" then
                    espColor = Color3.fromRGB(220, 45, 55)
                elseif role == "Innocent" then
                    espColor = Color3.fromRGB(50, 190, 105)
                end

                espData.Highlight.FillColor = espColor
                espData.Highlight.OutlineColor = Color3.new(1, 1, 1)
                espData.NameLabel.Text = p.Name .. " [" .. role .. "]"
                espData.NameLabel.TextColor3 = espColor
            else
                RemoveESP(p)
            end
        else
            RemoveESP(p)
        end
    end
end)

for _, p in ipairs(Players:GetPlayers()) do
    Connect(p.CharacterRemoving, function()
        RemoveESP(p)
    end)
end

Connect(Players.PlayerRemoving, function(p)
    RemoveESP(p)
end)

-- Rainbow Visual Effects
local hue = 0
Connect(RunService.RenderStepped, function(dt)
    if not Alive then return end
    hue = (hue + dt * 0.25) % 1  
    local rainbow = Color3.fromHSV(hue, 0.85, 1)  

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
end)

Connect(CloseButton.Activated, function()
    Cleanup()
end)

ApplyTransparency()
ApplyNormalTheme()

print("MM2 Ultimate Hub loaded successfully with CurrentRoundClient integration")
