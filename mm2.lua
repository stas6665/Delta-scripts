local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local targetNick = "Stas_mine12"
local parentGui = player:WaitForChild("PlayerGui")

if parentGui:FindFirstChild("MobileOmniLogger") then
parentGui.MobileOmniLogger:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MobileOmniLogger"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = parentGui

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0.94, 0, 0.5, 0)
MainFrame.Position = UDim2.new(0.03, 0, 0.04, 0)
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
TitleLabel.Size = UDim2.new(0.32, -6, 1, 0)
TitleLabel.Position = UDim2.new(0, 8, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "ESP+GUN " .. targetNick
TitleLabel.TextColor3 = Color3.fromRGB(235, 235, 245)
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 11
TitleLabel.Parent = TopBar

local PulseBtn = Instance.new("TextButton")
PulseBtn.Size = UDim2.new(0, 56, 0, 22)
PulseBtn.Position = UDim2.new(1, -296, 0.5, -11)
PulseBtn.BackgroundColor3 = Color3.fromRGB(65, 65, 85)
PulseBtn.Text = "Pulse:OFF"
PulseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
PulseBtn.Font = Enum.Font.GothamBold
PulseBtn.TextSize = 9
PulseBtn.Parent = TopBar
Instance.new("UICorner", PulseBtn).CornerRadius = UDim.new(0, 6)

local ScanBtn = Instance.new("TextButton")
ScanBtn.Size = UDim2.new(0, 52, 0, 22)
ScanBtn.Position = UDim2.new(1, -234, 0.5, -11)
ScanBtn.BackgroundColor3 = Color3.fromRGB(38, 125, 75)
ScanBtn.Text = "Scan:ON"
ScanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ScanBtn.Font = Enum.Font.GothamBold
ScanBtn.TextSize = 9
ScanBtn.Parent = TopBar
Instance.new("UICorner", ScanBtn).CornerRadius = UDim.new(0, 6)

local CopyBtn = Instance.new("TextButton")
CopyBtn.Size = UDim2.new(0, 48, 0, 22)
CopyBtn.Position = UDim2.new(1, -176, 0.5, -11)
CopyBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 58)
CopyBtn.Text = "Filter"
CopyBtn.TextColor3 = Color3.fromRGB(230, 230, 240)
CopyBtn.Font = Enum.Font.GothamBold
CopyBtn.TextSize = 9
CopyBtn.Parent = TopBar
Instance.new("UICorner", CopyBtn).CornerRadius = UDim.new(0, 6)

local ClearBtn = Instance.new("TextButton")
ClearBtn.Size = UDim2.new(0, 50, 0, 22)
ClearBtn.Position = UDim2.new(1, -122, 0.5, -11)
ClearBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 58)
ClearBtn.Text = "Clear"
ClearBtn.TextColor3 = Color3.fromRGB(230, 230, 240)
ClearBtn.Font = Enum.Font.GothamBold
ClearBtn.TextSize = 9
ClearBtn.Parent = TopBar
Instance.new("UICorner", ClearBtn).CornerRadius = UDim.new(0, 6)

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0, 52, 0, 22)
ToggleBtn.Position = UDim2.new(1, -64, 0.5, -11)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 58)
ToggleBtn.Text = "Min"
ToggleBtn.TextColor3 = Color3.fromRGB(230, 230, 240)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 9
ToggleBtn.Parent = TopBar
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 6)

local FilterBox = Instance.new("TextBox")
FilterBox.Size = UDim2.new(1, -16, 0, 28)
FilterBox.Position = UDim2.new(0, 8, 0, 38)
FilterBox.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
FilterBox.PlaceholderText = "Фильтр (например: ROLE_LIST, RAY, GunFired, GUN, ATTR)..."
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
   TitleLabel.Text = "ESP+GUN " .. targetNick
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
  warn("[EspLogger] Clipboard:\n" .. tostring(text))
  return false
end
end

local logs = {}
local maxLogs = 120
local logOrder = 0
local pulseEnabled = false
local scanEnabled = true

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
  local lv = val.LookVector
  return string.format("CF(P:%.2f,%.2f,%.2f | L:%.2f,%.2f,%.2f)", p.X, p.Y, p.Z, lv.X, lv.Y, lv.Z)
elseif t == "Ray" then
  local o = val.Origin
  local d = val.Direction
  return string.format("Ray(O:%.2f,%.2f,%.2f | D:%.2f,%.2f,%.2f)", o.X, o.Y, o.Z, d.X, d.Y, d.Z)
elseif t == "Color3" then
  return string.format("RGB(%d, %d, %d)", math.round(val.R * 255), math.round(val.G * 255), math.round(val.B * 255))
elseif t == "Instance" then
  return string.format("%s [%s]", val:GetFullName(), val.ClassName)
elseif t == "table" then
  local items = {}
  local count = 0
  for k, v in pairs(val) do
   count += 1
   if count <= 6 then
    table.insert(items, tostring(k) .. "=" .. formatValue(v))
   end
  end
  if count == 0 then
   return "{}"
  end
  local suffix = count > 6 and string.format(" (+%d)", count - 6) or ""
  return "{" .. table.concat(items, ", ") .. suffix .. "}"
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

local function formatArgs(...)
local parts = {}
for i = 1, select("#", ...) do
  local arg = select(i, ...)
  local s = formatValue(arg)
  if typeof(arg) == "Instance" then
   watchAttributes(arg, "OBJ_ATTR")
   s = s .. formatAttributes(arg)
  end
  parts[i] = s
end
return table.concat(parts, ", ")
end

-- Автоподсветка ролей через Highlight (запускается сразу без кнопки)
local playerRoles = {} -- [nick] = { Role = ..., Dead = ... }
local highlights = {} -- [nick] = Highlight

local function getRoleColor(role)
if role == "Murderer" then
  return Color3.fromRGB(255, 50, 50)
elseif role == "Sheriff" then
  return Color3.fromRGB(55, 145, 255)
else
  return Color3.fromRGB(65, 215, 110)
end
end

local function removeHighlight(nick)
local hl = highlights[nick]
if hl then
  pcall(function()
   hl:Destroy()
  end)
  highlights[nick] = nil
end
end

local function applyHighlightForNick(nick)
removeHighlight(nick)
local info = playerRoles[nick]
if not info or not info.Role or info.Dead == true then
  return
end

local plr = Players:FindFirstChild(nick)
local char = plr and plr.Character
if not char or not char.Parent then
  return
end

local color = getRoleColor(info.Role)
local hl = Instance.new("Highlight")
hl.Name = "RoleEspHighlight"
hl.FillColor = color
hl.OutlineColor = color
hl.FillTransparency = 0.65
hl.OutlineTransparency = 0.1
hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
hl.Adornee = char
hl.Parent = char
highlights[nick] = hl
end

local function refreshAllHighlights()
for nick in pairs(playerRoles) do
  applyHighlightForNick(nick)
end
end

for _, plr in ipairs(Players:GetPlayers()) do
plr.CharacterAdded:Connect(function()
  task.defer(applyHighlightForNick, plr.Name)
end)
plr.CharacterRemoving:Connect(function()
  removeHighlight(plr.Name)
end)
end

Players.PlayerAdded:Connect(function(plr)
plr.CharacterAdded:Connect(function()
  task.defer(applyHighlightForNick, plr.Name)
end)
plr.CharacterRemoving:Connect(function()
  removeHighlight(plr.Name)
end)
end)

Players.PlayerRemoving:Connect(function(plr)
playerRoles[plr.Name] = nil
removeHighlight(plr.Name)
end)

-- Разбор таблиц игроков (Fade / RoundStart / PlayerDataChanged) и вывод "Ник - Роль"
local lastRoleSummary = ""
local function tryLogPlayerRoles(remoteName, ...)
local foundEntries = {}
local seenNicks = {}
local updatedAny = false

local function scanTable(tbl)
  if type(tbl) ~= "table" then
   return
  end
  for k, v in pairs(tbl) do
   if type(v) == "table" then
    local nick = v.PlayerName or v.Name or (type(k) == "string" and k) or nil
    local role = v.Role
    if nick and role then
     local nickStr = tostring(nick)
     local roleStr = tostring(role)
     local isDead = (v.Dead == true)
     playerRoles[nickStr] = { Role = roleStr, Dead = isDead }
     updatedAny = true

     if not seenNicks[nickStr] then
      seenNicks[nickStr] = true
      local deadTag = isDead and " [DEAD]" or ""
      table.insert(foundEntries, string.format("%s - %s%s", nickStr, roleStr, deadTag))
     end
    end
   end
  end
end

for i = 1, select("#", ...) do
  local arg = select(i, ...)
  if type(arg) == "table" then
   scanTable(arg)
  end
end

if updatedAny then
  refreshAllHighlights()
end

if #foundEntries > 0 then
  table.sort(foundEntries)
  local summary = table.concat(foundEntries, " | ")
  if summary ~= lastRoleSummary then
   lastRoleSummary = summary
   LogEvent("ROLE_LIST", string.format("(%s) %s", tostring(remoteName), summary))
  end
elseif remoteName == "RoleSelect" then
  local myRole = select(1, ...)
  if myRole ~= nil then
   local nickStr = tostring(player.Name)
   local roleStr = tostring(myRole)
   playerRoles[nickStr] = { Role = roleStr, Dead = false }
   refreshAllHighlights()

   local singleSummary = string.format("%s - %s", nickStr, roleStr)
   if singleSummary ~= lastRoleSummary then
    lastRoleSummary = singleSummary
    LogEvent("ROLE_LIST", string.format("(RoleSelect) %s", singleSummary))
   end
  end
end
end

local scrollScheduled = false
local function scheduleScrollToBottom()
if scrollScheduled then
  return
end
scrollScheduled = true
task.defer(function()
  scrollScheduled = false
  Scroll.CanvasPosition = Vector2.new(0, Scroll.AbsoluteCanvasSize.Y)
end)
end

function LogEvent(tag, message)
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

scheduleScrollToBottom()
end

-- Снимок камеры, персонажа, Gun и геометрии луча при выстреле
local function getRayAndAimSnapshot(...)
local info = {}
local cam = Workspace.CurrentCamera
if cam then
  local cp = cam.CFrame.Position
  local cl = cam.CFrame.LookVector
  table.insert(info, string.format("CamPos=(%.2f,%.2f,%.2f) CamLook=(%.3f,%.3f,%.3f)", cp.X, cp.Y, cp.Z, cl.X, cl.Y, cl.Z))
end

local char = player.Character
local hrp = char and char:FindFirstChild("HumanoidRootPart")
if hrp and hrp:IsA("BasePart") then
  local hp = hrp.Position
  local hl = hrp.CFrame.LookVector
  table.insert(info, string.format("HRP=(%.2f,%.2f,%.2f) HRPLook=(%.3f,%.3f,%.3f)", hp.X, hp.Y, hp.Z, hl.X, hl.Y, hl.Z))
  local rayAttach = hrp:FindFirstChild("GunRaycastAttachment")
  if rayAttach and rayAttach:IsA("Attachment") then
   local wp = rayAttach.WorldPosition
   table.insert(info, string.format("GunRaycastAttach=(%.2f,%.2f,%.2f)", wp.X, wp.Y, wp.Z))
  end
end

local gun = char and char:FindFirstChild("Gun")
local handle = gun and gun:FindFirstChild("Handle")
if handle and handle:IsA("BasePart") then
  local gp = handle.Position
  local gl = handle.CFrame.LookVector
  table.insert(info, string.format("HandlePos=(%.2f,%.2f,%.2f) HandleLook=(%.3f,%.3f,%.3f)", gp.X, gp.Y, gp.Z, gl.X, gl.Y, gl.Z))
end

local vecs = {}
for i = 1, select("#", ...) do
  local a = select(i, ...)
  if typeof(a) == "Vector3" then
   table.insert(vecs, a)
  elseif typeof(a) == "CFrame" then
   table.insert(vecs, a.Position)
  end
end

if #vecs >= 2 then
  local p1, p2 = vecs[1], vecs[2]
  local delta = p2 - p1
  local dist = delta.Magnitude
  local dir = dist > 1e-4 and delta.Unit or Vector3.zero
  table.insert(
   info,
   string.format(
    "RayFromArg: Start=(%.2f,%.2f,%.2f) End=(%.2f,%.2f,%.2f) Dir=(%.3f,%.3f,%.3f) Dist=%.2f",
    p1.X, p1.Y, p1.Z,
    p2.X, p2.Y, p2.Z,
    dir.X, dir.Y, dir.Z,
    dist
   )
  )
end

return table.concat(info, " | ")
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
lastRoleSummary = ""
end)

PulseBtn.MouseButton1Click:Connect(function()
pulseEnabled = not pulseEnabled
PulseBtn.Text = pulseEnabled and "Pulse:ON" or "Pulse:OFF"
PulseBtn.BackgroundColor3 = pulseEnabled
  and Color3.fromRGB(165, 95, 25)
  or Color3.fromRGB(65, 65, 85)
end)

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
PulseBtn.Visible = not minimized
ScanBtn.Visible = not minimized
CopyBtn.Visible = not minimized
ClearBtn.Visible = not minimized
MainFrame.Size = minimized
  and UDim2.new(0.55, 0, 0, 32)
  or UDim2.new(0.94, 0, 0.5, 0)
ToggleBtn.Text = minimized and "Max" or "Min"
end)

-- Подписка на RemoteEvent и BindableEvent + атрибуты ремоутов
local hookedRemotes = {}
local hookedBindables = {}

local function hookRemoteEvent(rem)
if not rem:IsA("RemoteEvent") or hookedRemotes[rem] then
  return
end
hookedRemotes[rem] = true
watchAttributes(rem, "REM_ATTR")
rem.OnClientEvent:Connect(function(...)

if not scanEnabled then
   return
  end
  local fullName = rem:GetFullName()
  local argsStr = formatArgs(...)
  LogEvent("OnClientEvent", string.format("%s%s | Args: %s", fullName, formatAttributes(rem), argsStr))
  tryLogPlayerRoles(rem.Name, ...)
  if string.find(fullName, "GunFired", 1, true) then
   LogEvent("RAY_SHOT", fullName .. " | " .. getRayAndAimSnapshot(...))
  end
end)
end

local function hookBindableEvent(bind)
if not bind:IsA("BindableEvent") or hookedBindables[bind] then
  return
end
hookedBindables[bind] = true
watchAttributes(bind, "BIND_ATTR")
bind.Event:Connect(function(...)
  if not scanEnabled then
   return
  end
  LogEvent("BindableEvent", string.format("%s%s | Args: %s", bind:GetFullName(), formatAttributes(bind), formatArgs(...)))
end)
end

for _, obj in ipairs(game:GetDescendants()) do
if obj:IsA("RemoteEvent") then
  hookRemoteEvent(obj)
elseif obj:IsA("BindableEvent") then
  hookBindableEvent(obj)
end
end

game.DescendantAdded:Connect(function(obj)
if obj:IsA("RemoteEvent") then
  hookRemoteEvent(obj)
elseif obj:IsA("BindableEvent") then
  hookBindableEvent(obj)
end
end)

-- Атрибуты и изменения персонажа Stas_mine12 и его частей
local function watchCharacter(char)
if not char then
  return
end
watchAttributes(char, "CHAR_ATTR")
for _, desc in ipairs(char:GetDescendants()) do
  watchAttributes(desc, "CHAR_ATTR")
  if desc:IsA("Tool") and desc.Name == "Gun" then
   watchGunTool(desc)
  end
end
char.DescendantAdded:Connect(function(desc)
  watchAttributes(desc, "CHAR_ATTR")
  if desc:IsA("Tool") and desc.Name == "Gun" then
   watchGunTool(desc)
  end
end)
end

-- Наблюдение за Gun, его дочерними объектами, событиями и атрибутами
local watchedGuns = {}
function watchGunTool(tool)
if not tool or not tool:IsA("Tool") or tool.Name ~= "Gun" or watchedGuns[tool] then
  return
end
watchedGuns[tool] = true

watchAttributes(tool, "GUN_ATTR")
for _, desc in ipairs(tool:GetDescendants()) do
  watchAttributes(desc, "GUN_ATTR")
  if desc:IsA("RemoteEvent") then
   hookRemoteEvent(desc)
  elseif desc:IsA("BindableEvent") then
   hookBindableEvent(desc)
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
   LogEvent("RAY_SHOT", "Gun.Activated | " .. getRayAndAimSnapshot())
  end
end)

tool.DescendantAdded:Connect(function(desc)
  watchAttributes(desc, "GUN_ATTR")
  if scanEnabled then
   LogEvent("GUN+Child", string.format("%s [%s] in %s%s", desc.Name, desc.ClassName, desc:GetFullName(), formatAttributes(desc)))
  end
  if desc:IsA("RemoteEvent") then
   hookRemoteEvent(desc)
  elseif desc:IsA("BindableEvent") then
   hookBindableEvent(desc)
  end
end)

tool.DescendantRemoving:Connect(function(desc)
  if scanEnabled then
   LogEvent("GUN-Child", string.format("%s [%s] from %s%s", desc.Name, desc.ClassName, tool:GetFullName(), formatAttributes(desc)))
  end
end)
end

local function watchBackpack(bp)
if not bp then
  return
end
for _, item in ipairs(bp:GetDescendants()) do
  if item:IsA("Tool") and item.Name == "Gun" then
   watchGunTool(item)
  end
end
bp.DescendantAdded:Connect(function(item)
  if item:IsA("Tool") and item.Name == "Gun" then
   watchGunTool(item)
  end
end)
end

if player.Character then
watchCharacter(player.Character)
end
player.CharacterAdded:Connect(watchCharacter)

local bp = player:FindFirstChild("Backpack")
if bp then
watchBackpack(bp)
end
player.ChildAdded:Connect(function(child)
if child.Name == "Backpack" then
  watchBackpack(child)
end
end)

-- Опциональный редкий пульс (1 раз в 1.5s, только когда Pulse:ON)
task.spawn(function()
while true do
  task.wait(1.5)
  if scanEnabled and pulseEnabled then
   LogEvent("PULSE", getRayAndAimSnapshot())
  end
end
end)

-- Перехват FireServer / InvokeServer / BindableEvent:Fire + атрибуты вызываемого объекта и аргументов
if typeof(hookmetamethod) == "function" and typeof(getnamecallmethod) == "function" then
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
  local method = getnamecallmethod()
  if not checkcaller() and typeof(self) == "Instance" then
   if (method == "FireServer" or method == "InvokeServer") and (self:IsA("RemoteEvent") or self:IsA("RemoteFunction")) then
    watchAttributes(self, "REM_ATTR")
    local fullName = self:GetFullName()
    local argsStr = formatArgs(...)
    task.defer(LogEvent, method, string.format("%s%s | Args: %s", fullName, formatAttributes(self), argsStr))
    if string.find(fullName, "Shoot", 1, true) then
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
LogEvent("INIT", "ESP+GUN логгер запущен: автоподсветка ролей, [ROLE_LIST], RAY_SHOT, Gun, атрибуты.")
else
LogEvent("INIT", "ESP+GUN логгер запущен без __namecall хука.")
end
