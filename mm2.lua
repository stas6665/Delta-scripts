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
    Size = UDim2.fromOffset(480, 350),
    Position = UDim2.new(0.5, -240, 0.5, -175),
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

    Connect(button.MouseEnter, function()  
        TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(55, 55, 62)}):Play()  
    end)  
    Connect(button.MouseLeave, function()  
        TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(38, 38, 43)}):Play()  
    end)  

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

local EspTab = New("TextButton", {
    Size = UDim2.new(1, -16, 0, 46),
    Position = UDim2.fromOffset(8, 16),
    BackgroundColor3 = Accent,
    BackgroundTransparency = 0,
    Text = "◉  ESP",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 16,
    Font = Enum.Font.GothamBold,
    BorderSizePixel = 0
}, Sidebar)

Corner(EspTab, 9)

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

        TweenService:Create(knob, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {  
            Position = enabled and UDim2.new(1, -25, 0, 3) or UDim2.fromOffset(3, 3)  
        }):Play()  

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
    MinimizeButton.BackgroundTransparency = 0
    SettingsButton.BackgroundTransparency = 0
    CloseButton.BackgroundTransparency = 0
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
        task.defer(function()    
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
    local targetEspVisible = (page == "ESP")

    if targetEspVisible then  
        EspPage.Visible = true  
        SettingsPage.Visible = false  
    else  
        SettingsPage.Visible = true  
        EspPage.Visible = false  
    end  

    Sidebar.Visible = true    
    Content.Position = targetEspVisible and UDim2.fromOffset(130, 0) or UDim2.fromOffset(0, 0)    
    Content.Size = targetEspVisible and UDim2.new(1, -130, 1, 0) or UDim2.new(1, 0, 1, 0)    
      
    TweenService:Create(EspTab, TweenInfo.new(0.2), {BackgroundColor3 = Accent}):Play()
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

    if minimized then  
        Body.Visible = true  
        TweenService:Create(Main, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {  
            Size = UDim2.fromOffset(480, 54)  
        }):Play()  
        task.delay(0.25, function()  
            if minimized then Body.Visible = false end  
        end)  
    else  
        Body.Visible = true  
        TweenService:Create(Main, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {  
            Size = UDim2.fromOffset(480, 350)  
        }):Play()  
    end
end

Connect(MinimizeButton.Activated, function()
    SetMinimized(not minimized)
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

-- ИСПРАВЛЕННАЯ ИНТЕГРАЦИЯ С CurrentRoundClient
local CurrentRoundClient
pcall(function()
    CurrentRoundClient = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("CurrentRoundClient"))
end)

local function GetPlayerRole(p)
    if not CurrentRoundClient then
        pcall(function()
            CurrentRoundClient = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("CurrentRoundClient"))
        end)
        if not CurrentRoundClient then return "Innocent" end
    end

    local success, role = pcall(function()
        -- Проверка стандартного расположения таблиц ролей в MM2
        local playerData = CurrentRoundClient.PlayerData or CurrentRoundClient.Roles
        if type(playerData) == "table" then
            for key, val in pairs(playerData) do
                local targetPlayer = nil
                local targetRole = nil
                
                if typeof(key) == "Instance" and key:IsA("Player") then
                    targetPlayer = key
                    targetRole = val
                elseif type(val) == "table" then
                    targetPlayer = val.Player or val.Instance or val.Name or val[1]
                    targetRole = val.Role or val.Value or val[2]
                elseif type(key) == "string" and (val == "Sheriff" or val == "Murderer" or val == "Innocent") then
                    if key == p.Name then return val end
                end

                if targetPlayer == p or (typeof(targetPlayer) == "string" and targetPlayer == p.Name) then
                    if type(targetRole) == "string" then
                        return targetRole
                    end
                end
            end
        end
    end)

    if success and role then
        return role
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

print("MM2 Ultimate Hub loaded successfully with smooth animations!")
