local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

local ParentGui = (gethui and gethui()) or CoreGui or LocalPlayer:WaitForChild("PlayerGui")
if ParentGui:FindFirstChild("MM2LuaHub") then
    ParentGui.MM2LuaHub:Destroy()
end

local State = {
    AutoFarm = false,
    FlingMurder = false,
    Minimized = false,
    SettingsOpen = false,
    FlySpeed = 16,
    WindowTransparency = 0,
    Running = true,
    IsFlying = false,
    EspSheriff = false,
    EspMurderer = false,
    EspInnocent = false
}

local Theme = {
    Background = Color3.fromRGB(10, 10, 12),
    TopBar = Color3.fromRGB(18, 18, 22),
    Sidebar = Color3.fromRGB(14, 14, 17),
    Text = Color3.fromRGB(240, 240, 245),
    SubText = Color3.fromRGB(140, 140, 150),
    ToggleOff = Color3.fromRGB(28, 28, 35),
    ToggleOn = Color3.fromRGB(255, 255, 255),
    CloseBtn = Color3.fromRGB(180, 40, 40),
    SliderBg = Color3.fromRGB(25, 25, 30),
    SliderFill = Color3.fromRGB(200, 200, 210),
    SliderHandle = Color3.fromRGB(255, 255, 255)
}

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MM2LuaHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = ParentGui

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 440, 0, 310)
MainFrame.Position = UDim2.new(0.5, -220, 0.5, -155)
MainFrame.BackgroundColor3 = Theme.Background
MainFrame.BackgroundTransparency = 0
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Name = "MainStroke"
MainStroke.Color = Color3.fromRGB(40, 40, 48)
MainStroke.Thickness = 1.2
MainStroke.Parent = MainFrame

local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 38)
TopBar.BackgroundColor3 = Theme.TopBar
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame

local TopCorner = Instance.new("UICorner")
TopCorner.CornerRadius = UDim.new(0, 10)
TopCorner.Parent = TopBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "Title"
TitleLabel.Size = UDim2.new(1, -125, 1, 0)
TitleLabel.Position = UDim2.new(0, 14, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "mm2 lua"
TitleLabel.TextColor3 = Theme.Text
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 15
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TopBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Name = "CloseBtn"
CloseBtn.Size = UDim2.new(0, 28, 0, 28)
CloseBtn.Position = UDim2.new(1, -34, 0.5, -14)
CloseBtn.BackgroundColor3 = Theme.CloseBtn
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Theme.Text
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 14
CloseBtn.AutoButtonColor = false
CloseBtn.Parent = TopBar

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseBtn

local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Name = "MinimizeBtn"
MinimizeBtn.Size = UDim2.new(0, 28, 0, 28)
MinimizeBtn.Position = UDim2.new(1, -66, 0.5, -14)
MinimizeBtn.BackgroundColor3 = Theme.ToggleOff
MinimizeBtn.Text = "-"
MinimizeBtn.TextColor3 = Theme.Text
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.TextSize = 18
MinimizeBtn.AutoButtonColor = false
MinimizeBtn.Parent = TopBar

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 6)
MinCorner.Parent = MinimizeBtn

local SettingsBtn = Instance.new("TextButton")
SettingsBtn.Name = "SettingsBtn"
SettingsBtn.Size = UDim2.new(0, 28, 0, 28)
SettingsBtn.Position = UDim2.new(1, -98, 0.5, -14)
SettingsBtn.BackgroundColor3 = Theme.ToggleOff
SettingsBtn.Text = "⚙"
SettingsBtn.TextColor3 = Theme.Text
SettingsBtn.Font = Enum.Font.GothamBold
SettingsBtn.TextSize = 15
SettingsBtn.AutoButtonColor = false
SettingsBtn.Parent = TopBar

local SettingsCorner = Instance.new("UICorner")
SettingsCorner.CornerRadius = UDim.new(0, 6)
SettingsCorner.Parent = SettingsBtn

local BodyContainer = Instance.new("Frame")
BodyContainer.Name = "BodyContainer"
BodyContainer.Size = UDim2.new(1, 0, 1, -38)
BodyContainer.Position = UDim2.new(0, 0, 0, 38)
BodyContainer.BackgroundTransparency = 1
BodyContainer.Parent = MainFrame

local Sidebar = Instance.new("Frame")
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0, 120, 1, 0)
Sidebar.BackgroundColor3 = Theme.Sidebar
Sidebar.BorderSizePixel = 0
Sidebar.Parent = BodyContainer

local SidebarListLayout = Instance.new("UIListLayout")
SidebarListLayout.Padding = UDim.new(0, 6)
SidebarListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
SidebarListLayout.SortOrder = Enum.SortOrder.LayoutOrder
SidebarListLayout.Parent = Sidebar

local SidebarPadding = Instance.new("UIPadding")
SidebarPadding.PaddingTop = UDim.new(0, 10)
SidebarPadding.Parent = Sidebar

local ContentArea = Instance.new("Frame")
ContentArea.Name = "ContentArea"
ContentArea.Size = UDim2.new(1, -120, 1, 0)
ContentArea.Position = UDim2.new(0, 120, 0, 0)
ContentArea.BackgroundTransparency = 1
ContentArea.Parent = BodyContainer

local function CreatePage()
    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.new(1, -20, 1, -20)
    page.Position = UDim2.new(0, 10, 0, 10)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 2
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.Visible = false
    page.Parent = ContentArea

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = page
    return page
end

local FarmingPage = CreatePage()
FarmingPage.Visible = true
local EspPage = CreatePage()
local DancePage = CreatePage()

local function CreateSidebarTab(name, targetPage)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 104, 0, 32)
    btn.BackgroundColor3 = targetPage.Visible and Theme.ToggleOff or Color3.fromRGB(12, 12, 15)
    btn.Text = name
    btn.TextColor3 = targetPage.Visible and Theme.Text or Theme.SubText
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 13
    btn.AutoButtonColor = false
    btn.Parent = Sidebar

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn

    btn.MouseButton1Click:Connect(function()
        FarmingPage.Visible = false
        EspPage.Visible = false
        DancePage.Visible = false

        for _, child in ipairs(Sidebar:GetChildren()) do
            if child:IsA("TextButton") then
                child.BackgroundColor3 = Color3.fromRGB(12, 12, 15)
                child.TextColor3 = Theme.SubText
            end
        end

        targetPage.Visible = true
        btn.BackgroundColor3 = Theme.ToggleOff
        btn.TextColor3 = Theme.Text
    end)
end

CreateSidebarTab("Farming", FarmingPage)
CreateSidebarTab("ESP", EspPage)
CreateSidebarTab("Dance", DancePage)

local SettingsPopup = Instance.new("ScrollingFrame")
SettingsPopup.Name = "SettingsPopup"
SettingsPopup.Size = UDim2.new(1, -16, 1, -16)
SettingsPopup.Position = UDim2.new(0, 8, 0, 8)
SettingsPopup.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
SettingsPopup.BackgroundTransparency = 0.05
SettingsPopup.BorderSizePixel = 0
SettingsPopup.ScrollBarThickness = 2
SettingsPopup.CanvasSize = UDim2.new(0, 0, 0, 0)
SettingsPopup.AutomaticCanvasSize = Enum.AutomaticSize.Y
SettingsPopup.Visible = false
SettingsPopup.ZIndex = 10
SettingsPopup.Parent = BodyContainer

local PopupCorner = Instance.new("UICorner")
PopupCorner.CornerRadius = UDim.new(0, 8)
PopupCorner.Parent = SettingsPopup

local PopupLayout = Instance.new("UIListLayout")
PopupLayout.Padding = UDim.new(0, 8)
PopupLayout.SortOrder = Enum.SortOrder.LayoutOrder
PopupLayout.Parent = SettingsPopup

local PopupPadding = Instance.new("UIPadding")
PopupPadding.PaddingTop = UDim.new(0, 8)
PopupPadding.PaddingLeft = UDim.new(0, 8)
PopupPadding.PaddingRight = UDim.new(0, 8)
PopupPadding.PaddingBottom = UDim.new(0, 8)
PopupPadding.Parent = SettingsPopup

local originalCollisions = {}
local activeDanceTrack = nil
local activeDanceButton = nil

local function StopCurrentDance()
    if activeDanceTrack then
        pcall(function()
            activeDanceTrack:Stop(0.15)
            activeDanceTrack:Destroy()
        end)
        activeDanceTrack = nil
    end
    if activeDanceButton and activeDanceButton.Parent then
        activeDanceButton.BackgroundColor3 = Theme.ToggleOff
        activeDanceButton.TextColor3 = Theme.SubText
    end
    activeDanceButton = nil
end

local function SetFlyingState(isFlying)
    if State.IsFlying == isFlying then return end
    State.IsFlying = isFlying

    local char = LocalPlayer.Character
    if not char then 
        originalCollisions = {}
        return 
    end

    if isFlying then
        originalCollisions = {}
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                originalCollisions[part] = part.CanCollide
                part.CanCollide = false
            end
        end
    else
        for part, origState in pairs(originalCollisions) do
            if part and part.Parent then
                part.CanCollide = origState
            end
        end
        originalCollisions = {}
    end
end

local charAddedConn = LocalPlayer.CharacterAdded:Connect(function()
    State.IsFlying = false
    originalCollisions = {}
    StopCurrentDance()
end)

local function UpdateTransparency(transparency)
    State.WindowTransparency = transparency
    MainFrame.BackgroundTransparency = transparency
    Sidebar.BackgroundTransparency = transparency
    TopBar.BackgroundTransparency = transparency
end

local function CreateToggle(parent, text, callback)
    local Holder = Instance.new("Frame")
    Holder.Size = UDim2.new(1, 0, 0, 42)
    Holder.BackgroundColor3 = Theme.TopBar
    Holder.BorderSizePixel = 0
    Holder.Parent = parent

    local HolderCorner = Instance.new("UICorner")
    HolderCorner.CornerRadius = UDim.new(0, 8)
    HolderCorner.Parent = Holder

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -65, 1, 0)
    Label.Position = UDim2.new(0, 12, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = Theme.Text
    Label.Font = Enum.Font.GothamMedium
    Label.TextSize = 13
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Holder

    local SwitchBg = Instance.new("TextButton")
    SwitchBg.Size = UDim2.new(0, 42, 0, 22)
    SwitchBg.Position = UDim2.new(1, -52, 0.5, -11)
    SwitchBg.BackgroundColor3 = Theme.ToggleOff
    SwitchBg.Text = ""
    SwitchBg.AutoButtonColor = false
    SwitchBg.Parent = Holder

    local SwitchCorner = Instance.new("UICorner")
    SwitchCorner.CornerRadius = UDim.new(1, 0)
    SwitchCorner.Parent = SwitchBg

    local Knob = Instance.new("Frame")
    Knob.Size = UDim2.new(0, 16, 0, 16)
    Knob.Position = UDim2.new(0, 3, 0.5, -8)
    Knob.BackgroundColor3 = Theme.SubText
    Knob.Parent = SwitchBg

    local KnobCorner = Instance.new("UICorner")
    KnobCorner.CornerRadius = UDim.new(1, 0)
    KnobCorner.Parent = Knob

    local enabled = false
    SwitchBg.MouseButton1Click:Connect(function()
        enabled = not enabled
        local targetPos = enabled and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
        local targetColor = enabled and Theme.ToggleOn or Theme.ToggleOff
        local knobColor = enabled and Theme.Background or Theme.SubText
        
        TweenService:Create(Knob, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {Position = targetPos, BackgroundColor3 = knobColor}):Play()
        TweenService:Create(SwitchBg, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {BackgroundColor3 = targetColor}):Play()
        callback(enabled)
    end)
end

local function CreateSlider(parent, text, min, max, default, callback)
    local Holder = Instance.new("Frame")
    Holder.Size = UDim2.new(1, 0, 0, 56)
    Holder.BackgroundColor3 = Theme.TopBar
    Holder.BorderSizePixel = 0
    Holder.Parent = parent

    local HolderCorner = Instance.new("UICorner")
    HolderCorner.CornerRadius = UDim.new(0, 8)
    HolderCorner.Parent = Holder

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -24, 0, 22)
    Label.Position = UDim2.new(0, 12, 0, 6)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = Theme.Text
    Label.Font = Enum.Font.GothamMedium
    Label.TextSize = 13
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Holder

    local ValueLabel = Instance.new("TextLabel")
    ValueLabel.Size = UDim2.new(0, 50, 0, 22)
    ValueLabel.Position = UDim2.new(1, -62, 0, 6)
    ValueLabel.BackgroundTransparency = 1
    ValueLabel.Text = tostring(default)
    ValueLabel.TextColor3 = Theme.SubText
    ValueLabel.Font = Enum.Font.GothamBold
    ValueLabel.TextSize = 13
    ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
    ValueLabel.Parent = Holder

    local SliderBar = Instance.new("TextButton")
    SliderBar.Size = UDim2.new(1, -24, 0, 6)
    SliderBar.Position = UDim2.new(0, 12, 0, 38)
    SliderBar.BackgroundColor3 = Theme.SliderBg
    SliderBar.Text = ""
    SliderBar.AutoButtonColor = false
    SliderBar.Parent = Holder

    local BarCorner = Instance.new("UICorner")
    BarCorner.CornerRadius = UDim.new(1, 0)
    BarCorner.Parent = SliderBar

    local FillBar = Instance.new("Frame")
    FillBar.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    FillBar.BackgroundColor3 = Theme.SliderFill
    FillBar.BorderSizePixel = 0
    FillBar.Parent = SliderBar

    local FillCorner = Instance.new("UICorner")
    FillCorner.CornerRadius = UDim.new(1, 0)
    FillCorner.Parent = FillBar

    local Handle = Instance.new("Frame")
    Handle.Size = UDim2.new(0, 14, 0, 14)
    Handle.Position = UDim2.new((default - min) / (max - min), -7, 0.5, -7)
    Handle.BackgroundColor3 = Theme.SliderHandle
    Handle.BorderSizePixel = 0
    Handle.Parent = SliderBar

    local HandleCorner = Instance.new("UICorner")
    HandleCorner.CornerRadius = UDim.new(1, 0)
    HandleCorner.Parent = Handle

    local draggingSlider = false

    local function UpdateInput(input)
        local pos = math.clamp((input.Position.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1)
        local val = math.floor(min + (max - min) * pos)
        FillBar.Size = UDim2.new(pos, 0, 1, 0)
        Handle.Position = UDim2.new(pos, -7, 0.5, -7)
        ValueLabel.Text = tostring(val)
        callback(val)
    end

    SliderBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingSlider = true
            UpdateInput(input)
        end
    end)

    Handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingSlider = true
            UpdateInput(input)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingSlider = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if draggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            UpdateInput(input)
        end
    end)
end

-- Вкладка Farming
CreateToggle(FarmingPage, "Auto farm Candy", function(value)
    State.AutoFarm = value
    if not value then
        SetFlyingState(false)
    end
end)

CreateSlider(FarmingPage, "Farm Speed", 16, 40, 16, function(value)
    State.FlySpeed = value
end)

CreateToggle(FarmingPage, "Fling Murder (when Full bag)", function(value)
    State.FlingMurder = value
end)

-- Вкладка ESP
CreateToggle(EspPage, "ESP Sheriff", function(value)
    State.EspSheriff = value
end)

CreateToggle(EspPage, "ESP Murderer", function(value)
    State.EspMurderer = value
end)

CreateToggle(EspPage, "ESP Innocent", function(value)
    State.EspInnocent = value
end)

-- Вкладка Dance
local function CreateDanceAccordion(parent)
    local AccordionHolder = Instance.new("Frame")
    AccordionHolder.Size = UDim2.new(1, 0, 0, 42)
    AccordionHolder.BackgroundColor3 = Theme.TopBar
    AccordionHolder.BorderSizePixel = 0
    AccordionHolder.ClipsDescendants = true
    AccordionHolder.Parent = parent

    local HolderCorner = Instance.new("UICorner")
    HolderCorner.CornerRadius = UDim.new(0, 8)
    HolderCorner.Parent = AccordionHolder

    local AccordionBtn = Instance.new("TextButton")
    AccordionBtn.Size = UDim2.new(1, 0, 0, 42)
    AccordionBtn.BackgroundTransparency = 1
    AccordionBtn.Text = "  Dances (Accordion)"
    AccordionBtn.TextColor3 = Theme.Text
    AccordionBtn.Font = Enum.Font.GothamMedium
    AccordionBtn.TextSize = 13
    AccordionBtn.TextXAlignment = Enum.TextXAlignment.Left
    AccordionBtn.Parent = AccordionHolder

    local DanceListFrame = Instance.new("ScrollingFrame")
    DanceListFrame.Size = UDim2.new(1, -16, 0, 140)
    DanceListFrame.Position = UDim2.new(0, 8, 0, 44)
    DanceListFrame.BackgroundTransparency = 1
    DanceListFrame.BorderSizePixel = 0
    DanceListFrame.ScrollBarThickness = 2
    DanceListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    DanceListFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    DanceListFrame.Parent = AccordionHolder

    local ListLayout = Instance.new("UIListLayout")
    ListLayout.Padding = UDim.new(0, 4)
    ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ListLayout.Parent = DanceListFrame

    local dancesList = {
        {Name = "Vibey Back", Id = "14548619594"},
        {Name = "I Want Money", Id = "15951590426"},
        {Name = "Electro Shuffle", Id = "3344673811"},
        {Name = "Boombox Dance", Id = "282763536"},
        {Name = "Russian Dance", Id = "282761884"}
    }

    local isOpen = false
    AccordionBtn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        local expandedHeight = math.min(50 + (#dancesList * 34), 190)
        local targetSize = isOpen and UDim2.new(1, 0, 0, expandedHeight) or UDim2.new(1, 0, 0, 42)
        TweenService:Create(AccordionHolder, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Size = targetSize}):Play()
    end)

    for _, dance in ipairs(dancesList) do
        local DanceBtn = Instance.new("TextButton")
        DanceBtn.Size = UDim2.new(1, 0, 0, 30)
        DanceBtn.BackgroundColor3 = Theme.ToggleOff
        DanceBtn.Text = "  " .. dance.Name
        DanceBtn.TextColor3 = Theme.SubText
        DanceBtn.Font = Enum.Font.GothamSemibold
        DanceBtn.TextSize = 12
        DanceBtn.TextXAlignment = Enum.TextXAlignment.Left
        DanceBtn.AutoButtonColor = false
        DanceBtn.Parent = DanceListFrame

        local BtnCorner = Instance.new("UICorner")
        BtnCorner.CornerRadius = UDim.new(0, 6)
        BtnCorner.Parent = DanceBtn

        DanceBtn.MouseButton1Click:Connect(function()
            local wasThisActive = (activeDanceButton == DanceBtn)
            StopCurrentDance()

            if wasThisActive then
                return
            end

            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if not hum or hum.Health <= 0 then return end

            local anim = Instance.new("Animation")
            anim.AnimationId = "rbxassetid://" .. dance.Id

            local animator = hum:FindFirstChildOfClass("Animator")
            local ok, track = pcall(function()
                if animator then
                    return animator:LoadAnimation(anim)
                else
                    return hum:LoadAnimation(anim)
                end
            end)

            anim:Destroy()

            if ok and track then
                pcall(function()
                    track.Priority = Enum.AnimationPriority.Action
                    track.Looped = true
                    track:Play(0.15)
                    activeDanceTrack = track
                    activeDanceButton = DanceBtn
                    DanceBtn.BackgroundColor3 = Theme.ToggleOn
                    DanceBtn.TextColor3 = Theme.Background
                end)
            end
        end)
    end
end

CreateDanceAccordion(DancePage)

-- Меню настроек
CreateSlider(SettingsPopup, "Window Transparency (%)", 0, 100, 0, function(val)
    UpdateTransparency(val / 100)
end)

local rainbowConnections = {}

local function CreateColorAccordion(parent, titleText, isOutline)
    local AccordionHolder = Instance.new("Frame")
    AccordionHolder.Size = UDim2.new(1, 0, 0, 42)
    AccordionHolder.BackgroundColor3 = Theme.TopBar
    AccordionHolder.BorderSizePixel = 0
    AccordionHolder.ClipsDescendants = true
    AccordionHolder.Parent = parent

    local HolderCorner = Instance.new("UICorner")
    HolderCorner.CornerRadius = UDim.new(0, 8)
    HolderCorner.Parent = AccordionHolder

    local AccordionBtn = Instance.new("TextButton")
    AccordionBtn.Size = UDim2.new(1, 0, 0, 42)
    AccordionBtn.BackgroundTransparency = 1
    AccordionBtn.Text = "  " .. titleText
    AccordionBtn.TextColor3 = Theme.Text
    AccordionBtn.Font = Enum.Font.GothamMedium
    AccordionBtn.TextSize = 13
    AccordionBtn.TextXAlignment = Enum.TextXAlignment.Left
    AccordionBtn.Parent = AccordionHolder

    local ColorsListFrame = Instance.new("ScrollingFrame")
    ColorsListFrame.Size = UDim2.new(1, -16, 0, 210)
    ColorsListFrame.Position = UDim2.new(0, 8, 0, 44)
    ColorsListFrame.BackgroundTransparency = 1
    ColorsListFrame.BorderSizePixel = 0
    ColorsListFrame.ScrollBarThickness = 2
    ColorsListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    ColorsListFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    ColorsListFrame.Parent = AccordionHolder

    local ListLayout = Instance.new("UIListLayout")
    ListLayout.Padding = UDim.new(0, 4)
    ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ListLayout.Parent = ColorsListFrame

    local isOpen = false
    AccordionBtn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        local targetSize = isOpen and UDim2.new(1, 0, 0, 260) or UDim2.new(1, 0, 0, 42)
        TweenService:Create(AccordionHolder, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Size = targetSize}):Play()
    end)

    local colorsMap = {
        {"1. Красный", Color3.fromRGB(255, 50, 50)},
        {"2. Зеленый", Color3.fromRGB(50, 255, 50)},
        {"3. Синий", Color3.fromRGB(50, 150, 255)},
        {"4. Желтый", Color3.fromRGB(255, 255, 50)},
        {"5. Фиолетовый", Color3.fromRGB(180, 50, 255)},
        {"6. Оранжевый", Color3.fromRGB(255, 140, 0)},
        {"7. Радужный", "Rainbow"},
        {"8. Белый", Color3.fromRGB(255, 255, 255)}
    }

    local rainbowActive = false
    local conn = RunService.RenderStepped:Connect(function()
        if not State.Running then return end
        if rainbowActive then
            local rainbowColor = Color3.fromHSV(tick() % 5 / 5, 1, 1)
            if isOutline and MainStroke then
                MainStroke.Color = rainbowColor
            elseif not isOutline then
                MainFrame.BackgroundColor3 = rainbowColor
                TopBar.BackgroundColor3 = rainbowColor
                Sidebar.BackgroundColor3 = rainbowColor
            end
        end
    end)
    table.insert(rainbowConnections, conn)

    for _, colorInfo in ipairs(colorsMap) do
        local name, val = colorInfo[1], colorInfo[2]
        local ColorBtn = Instance.new("TextButton")
        ColorBtn.Size = UDim2.new(1, 0, 0, 28)
        ColorBtn.BackgroundColor3 = Theme.ToggleOff
        ColorBtn.Text = "  " .. name
        ColorBtn.TextColor3 = Theme.SubText
        ColorBtn.Font = Enum.Font.Gotham
        ColorBtn.TextSize = 12
        ColorBtn.TextXAlignment = Enum.TextXAlignment.Left
        ColorBtn.Parent = ColorsListFrame

        local BtnCorner = Instance.new("UICorner")
        BtnCorner.CornerRadius = UDim.new(0, 6)
        BtnCorner.Parent = ColorBtn

        ColorBtn.MouseButton1Click:Connect(function()
            rainbowActive = false
            if val == "Rainbow" then
                rainbowActive = true
            else
                if isOutline then
                    MainStroke.Color = val
                else
                    MainFrame.BackgroundColor3 = val
                    TopBar.BackgroundColor3 = val
                    Sidebar.BackgroundColor3 = val
                end
            end
        end)
    end
end

CreateColorAccordion(SettingsPopup, "Outline Colors (Accordion)", true)
CreateColorAccordion(SettingsPopup, "Window Colors (Accordion)", false)

SettingsBtn.MouseButton1Click:Connect(function()
    State.SettingsOpen = not State.SettingsOpen
    SettingsPopup.Visible = State.SettingsOpen
end)

MinimizeBtn.MouseButton1Click:Connect(function()
    State.Minimized = not State.Minimized
    if State.Minimized then
        MinimizeBtn.Text = "+"
        BodyContainer.Visible = false
        TweenService:Create(MainFrame, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 210, 0, 38)
        }):Play()
    else
        MinimizeBtn.Text = "-"
        TweenService:Create(MainFrame, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 440, 0, 310)
        }):Play()
        task.delay(0.12, function()
            if not State.Minimized then
                BodyContainer.Visible = true
            end
        end)
    end
end)

local dragging, dragInput, dragStart, startPos
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

local inputChangedConn = UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

local function IsVisibleRecursive(guiObj)
    local current = guiObj
    while current and current ~= ScreenGui and current ~= CoreGui do
        if current:IsA("GuiObject") and not current.Visible then
            return false
        end
        current = current.Parent
    end
    return true
end

local function IsBagFull()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return false end
    
    local mainGui = playerGui:FindFirstChild("MainGUI")
    if not mainGui then return false end
    
    if mainGui:IsA("GuiObject") and not mainGui.Visible then 
        return false 
    end
    
    local gameFolder = mainGui:FindFirstChild("Game")
    if gameFolder and gameFolder:IsA("GuiObject") and not gameFolder.Visible then 
        return false 
    end
    
    local coinBags = mainGui:FindFirstChild("CoinBags", true)
    if not coinBags then return false end
    
    for _, descendant in ipairs(coinBags:GetDescendants()) do
        if descendant.Name == "FullBagIcon" and descendant:IsA("GuiObject") then
            if descendant.Visible and IsVisibleRecursive(descendant) then
                return true
            end
        end
    end
    
    return false
end

-- Гибридная система ролей (события + надежная проверка оружия для ESP)
local cachedRoles = {}
task.spawn(function()
    pcall(function()
        local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Gameplay"):WaitForChild("ShowRoleSelectNew")
        remote.OnClientEvent:Connect(function(rolesData)
            table.clear(cachedRoles)
            if type(rolesData) == "table" then
                for plr, role in pairs(rolesData) do
                    if typeof(plr) == "Instance" and plr:IsA("Player") then
                        cachedRoles[plr] = role
                    end
                end
            end
        end)
    end)
end)

local function GetPlayerRolesMap()
    local rolesMap = {}
    
    for plr, role in pairs(cachedRoles) do
        rolesMap[plr] = role
    end
    
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and not rolesMap[plr] then
            local role = "Innocent"
            local char = plr.Character
            local backpack = plr.Backpack
            
            local function hasTool(container)
                if not container then return false end
                for _, tool in ipairs(container:GetChildren()) do
                    if tool:IsA("Tool") then
                        local name = tool.Name:lower()
                        if name:find("knife") or name:find("murder") then
                            return "Murderer"
                        elseif name:find("gun") or name:find("sheriff") or name:find("revolver") then
                            return "Sheriff"
                        end
                    end
                end
                return nil
            end
            
            role = hasTool(char) or hasTool(backpack) or "Innocent"
            rolesMap[plr] = role
        end
    end
    
    return rolesMap
end

local function GetMurderer()
    local rolesMap = GetPlayerRolesMap()
    if not rolesMap then return nil end
    
    for plr, role in pairs(rolesMap) do
        if role == "Murderer" and plr ~= LocalPlayer then
            return plr
        end
    end
    return nil
end

local function FlingTarget(targetPlayer)
    local startTime = tick()
    local flingDuration = 3.5
    
    local camera = workspace.CurrentCamera
    local oldCamSubject = camera and camera.CameraSubject

    while State.Running and State.FlingMurder and IsBagFull() and (tick() - startTime) < flingDuration do
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local tChar = targetPlayer and targetPlayer.Character
        local tHrp = tChar and tChar:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")

        if hrp and tHrp and hum and hum.Health > 0 then
            if camera and hum then
                camera.CameraSubject = hum
            end

            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end

            local punchOffset = Vector3.new(
                math.random(-4, 4),
                math.random(-2, 6),
                math.random(-4, 4)
            )
            hrp.CFrame = tHrp.CFrame + punchOffset
            
            local spinVelocity = Vector3.new(9e9, 9e9, 9e9)
            hrp.AssemblyAngularVelocity = spinVelocity
            hrp.AssemblyLinearVelocity = spinVelocity
        else
            break
        end
        RunService.RenderStepped:Wait()
    end

    if camera and oldCamSubject then
        camera.CameraSubject = oldCamSubject
    end

    SetFlyingState(false)
end

-- Цикл ESP подсветки
local espRenderConn = RunService.RenderStepped:Connect(function()
    if not State.Running then return end
    local rolesMap = GetPlayerRolesMap()

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local char = plr.Character
            local hl = char:FindFirstChild("MM2_ESP_Highlight")
            
            local role = rolesMap[plr] or "Innocent"
            local shouldShow = false
            local espColor = Color3.fromRGB(255, 255, 255)

            if role == "Sheriff" and State.EspSheriff then
                shouldShow = true
                espColor = Color3.fromRGB(0, 150, 255)
            elseif role == "Murderer" and State.EspMurderer then
                shouldShow = true
                espColor = Color3.fromRGB(255, 50, 50)
            elseif role == "Innocent" and State.EspInnocent then
                shouldShow = true
                espColor = Color3.fromRGB(50, 255, 50)
            end

            if shouldShow then
                if not hl then
                    hl = Instance.new("Highlight")
                    hl.Name = "MM2_ESP_Highlight"
                    hl.Adornee = char
                    hl.Parent = char
                end
                hl.FillColor = espColor
                hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                hl.FillTransparency = 0.4
                hl.Enabled = true
            else
                if hl then
                    hl.Enabled = false
                end
            end
        end
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    State.Running = false
    State.AutoFarm = false
    State.FlingMurder = false
    SetFlyingState(false)
    StopCurrentDance()

    if charAddedConn then charAddedConn:Disconnect() end
    if inputChangedConn then inputChangedConn:Disconnect() end
    if espRenderConn then espRenderConn:Disconnect() end
    for _, conn in ipairs(rainbowConnections) do
        if conn then conn:Disconnect() end
    end

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Character then
            local hl = plr.Character:FindFirstChild("MM2_ESP_Highlight")
            if hl then hl:Destroy() end
        end
    end

    ScreenGui:Destroy()
end)

local function GetCoinContainer()
    for _, child in ipairs(workspace:GetChildren()) do
        if child:IsA("Model") or child:IsA("Folder") then
            local coinContainer = child:FindFirstChild("CoinContainer")
            if coinContainer then
                return coinContainer
            end
        end
    end
    return workspace:FindFirstChild("CoinContainer")
end

local function GetAllSortedCoinVisuals(hrp)
    local container = GetCoinContainer()
    if not container then return {} end

    local visualsList = {}

    for _, coinServer in ipairs(container:GetChildren()) do
        if coinServer.Name == "Coin_Server" then
            local visual = coinServer:FindFirstChild("CoinVisual")
            
            if visual and visual:IsA("BasePart") then
                local dist = (hrp.Position - visual.Position).Magnitude
                if dist < 99999 then
                    table.insert(visualsList, {
                        Visual = visual,
                        Distance = dist
                    })
                end
            end
        end
    end

    table.sort(visualsList, function(a, b)
        return a.Distance < b.Distance
    end)

    return visualsList
end

task.spawn(function()
    local activeTween = nil
    
    while State.Running do
        task.wait(0.2)
        
        if State.AutoFarm then
            if IsBagFull() then
                SetFlyingState(false)
                if activeTween then
                    activeTween:Cancel()
                    activeTween = nil
                end

                if State.FlingMurder then
                    local murderer = GetMurderer()
                    if murderer then
                        FlingTarget(murderer)
                    end
                end
                
                continue
            end
            
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local animator = hum and hum:FindFirstChildOfClass("Animator")

            if hrp and hum and hum.Health > 0 then
                local sortedCoins = GetAllSortedCoinVisuals(hrp)

                if #sortedCoins == 0 then
                    SetFlyingState(false)
                end

                local restartOuterLoop = false
                for _, item in ipairs(sortedCoins) do
                    if not State.AutoFarm or not State.Running or IsBagFull() then 
                        SetFlyingState(false)
                        break 
                    end
                    
                    local targetVisual = item.Visual
                    if targetVisual and targetVisual.Parent then
                        local currentChar = LocalPlayer.Character
                        local currentHum = currentChar and currentChar:FindFirstChildOfClass("Humanoid")

                        if currentChar ~= char or not currentHum or currentHum.Health <= 0 then
                            if activeTween then
                                activeTween:Cancel()
                                activeTween = nil
                            end
                            SetFlyingState(false)
                            restartOuterLoop = true
                            break
                        end

                        local targetPos = targetVisual.Position
                        local distance = (hrp.Position - targetPos).Magnitude
                        local travelTime = math.max(distance / State.FlySpeed, 0.03)

                        hrp.CFrame = CFrame.new(hrp.Position, targetPos)

                        if animator then
                            for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                                track:Stop(0)
                            end
                        end

                        activeTween = TweenService:Create(
                            hrp,
                            TweenInfo.new(travelTime, Enum.EasingStyle.Linear),
                            {CFrame = CFrame.new(targetPos)}
                        )

                        SetFlyingState(true)
                        activeTween:Play()

                        local startTime = tick()
                        while State.Running and State.AutoFarm and not IsBagFull() and targetVisual and targetVisual.Parent do
                            local loopChar = LocalPlayer.Character
                            local loopHum = loopChar and loopChar:FindFirstChildOfClass("Humanoid")

                            if loopChar ~= char or not loopHum or loopHum.Health <= 0 then
                                SetFlyingState(false)
                                restartOuterLoop = true
                                break
                            end

                            hrp.CFrame = CFrame.new(hrp.Position, targetVisual.Position)

                            if (hrp.Position - targetVisual.Position).Magnitude < 2.5 or (tick() - startTime) > (travelTime + 0.3) then
                                break
                            end
                            task.wait(0.02)
                        end

                        if activeTween then
                            activeTween:Cancel()
                            activeTween = nil
                        end
                        
                        SetFlyingState(false)

                        if restartOuterLoop then
                            break
                        end
                    end
                end

                if restartOuterLoop then
                    continue
                end
            else
                SetFlyingState(false)
            end
        else
            SetFlyingState(false)
            if activeTween then
                activeTween:Cancel()
                activeTween = nil
            end
        end
    end
    
    SetFlyingState(false)
    if activeTween then
        activeTween:Cancel()
    end
end)
