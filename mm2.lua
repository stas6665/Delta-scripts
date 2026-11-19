local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local scanEnabled = true
local pulseEnabled = false
local serverEventsEnabled = true
local scanInterval = 0.2
local pulseInterval = 1.5

local lastGunSnap = ""
local hookedAttr: { [Instance]: boolean } = {}
local hookedGunTools: { [Tool]: boolean } = {}
local hookedRemoteEvents: { [RemoteEvent]: boolean } = {}
local hookedRemoteFunctions: { [RemoteFunction]: boolean } = {}
local logLines: { string } = {}
local maxLogLines = 500

local logLabel: TextLabel? = nil
local scrollFrame: ScrollingFrame? = nil
local scanBtn: TextButton? = nil
local pulseBtn: TextButton? = nil
local srvBtn: TextButton? = nil
local statusLabel: TextLabel? = nil

local function fullPath(inst: Instance?): string
	if not inst then
		return "nil"
	end
	local ok, path = pcall(function()
		return inst:GetFullName()
	end)
	if not ok or not path then
		return tostring(inst)
	end
	return string.format("%s [%s]", path, inst.ClassName)
end

local function fmtVal(v: any): string
	local t = typeof(v)
	if t == "Instance" then
		return fullPath(v)
	elseif t == "Vector3" then
		return string.format("Vector3(%.2f, %.2f, %.2f)", v.X, v.Y, v.Z)
	elseif t == "CFrame" then
		local p = v.Position
		return string.format("CFrame(%.2f, %.2f, %.2f)", p.X, p.Y, p.Z)
	elseif t == "table" then
		local items = {}
		for k, val in pairs(v) do
			table.insert(items, tostring(k) .. "=" .. fmtVal(val))
			if #items >= 12 then
				table.insert(items, "...")
				break
			end
		end
		return "{" .. table.concat(items, ", ") .. "}"
	end
	return tostring(v)
end

local function fmtArgs(...): string
	local count = select("#", ...)
	if count == 0 then
		return "none"
	end
	local list = {}
	for i = 1, count do
		table.insert(list, string.format("arg%d=%s", i, fmtVal(select(i, ...))))
	end
	return table.concat(list, ", ")
end

local function fmtAttrs(inst: Instance): string
	local ok, attrs = pcall(function()
		return inst:GetAttributes()
	end)
	if not ok or type(attrs) ~= "table" or next(attrs) == nil then
		return ""
	end
	local list = {}
	for k, v in pairs(attrs) do
		table.insert(list, string.format("%s=%s(%s)", tostring(k), fmtVal(v), typeof(v)))
	end
	return " | Attrs{" .. table.concat(list, "; ") .. "}"
end

local function refreshUI()
	if not logLabel or not scrollFrame then
		return
	end
	logLabel.Text = table.concat(logLines, "\n")
	logLabel.Size = UDim2.new(1, -8, 0, math.max(scrollFrame.AbsoluteSize.Y, logLabel.TextBounds.Y + 14))
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, logLabel.TextBounds.Y + 18)
	scrollFrame.CanvasPosition = Vector2.new(0, math.max(0, scrollFrame.CanvasSize.Y.Offset - scrollFrame.AbsoluteSize.Y))
end

local function LogEvent(tag: string, msg: string)
	local stamp = os.date("%H:%M:%S")
	local line = string.format("[%s][%s] %s", tostring(stamp), tostring(tag), tostring(msg))
	table.insert(logLines, line)
	if #logLines > maxLogLines then
		table.remove(logLines, 1)
	end
	refreshUI()
	print(line)
end

local function watchAttributes(inst: Instance, tag: string)
	if not inst or not inst.Parent or hookedAttr[inst] then
		return
	end
	hookedAttr[inst] = true
	inst.AttributeChanged:Connect(function(attrName)
		if not scanEnabled then
			return
		end
		local val = inst:GetAttribute(attrName)
		LogEvent(tag, string.format("Path=%s | Attr '%s' = %s (%s)",
			fullPath(inst), tostring(attrName), fmtVal(val), typeof(val)))
	end)
end

-- Подписка на все входящие от сервера RemoteEvent.OnClientEvent
local function attachServerRemoteListener(obj: Instance)
	if obj:IsA("RemoteEvent") and not hookedRemoteEvents[obj] then
		hookedRemoteEvents[obj] = true
		watchAttributes(obj, "SRV_REM_ATTR")
		obj.OnClientEvent:Connect(function(...)
			if not scanEnabled or not serverEventsEnabled then
				return
			end
			LogEvent("SRV_TO_CLI", string.format("Path=%s%s | Args: %s",
				fullPath(obj), fmtAttrs(obj), fmtArgs(...)))
		end)
	elseif obj:IsA("RemoteFunction") and not hookedRemoteFunctions[obj] then
		hookedRemoteFunctions[obj] = true
		watchAttributes(obj, "SRV_RF_ATTR")
		local ok = pcall(function()
			obj.OnClientInvoke = function(...)
				if scanEnabled and serverEventsEnabled then
					LogEvent("SRV_INVOKE_CLI", string.format("Path=%s%s | Args: %s",
						fullPath(obj), fmtAttrs(obj), fmtArgs(...)))
				end
				return nil
			end
		end)
		if not ok then
			-- Если OnClientInvoke уже занят игровым скриптом, не ломаем его работу
			LogEvent("SRV_RF_BUSY", string.format("Path=%s (OnClientInvoke already bound)", fullPath(obj)))
		end
	end
end

local function hookAllExistingAndNewRemotes()
	for _, d in ipairs(game:GetDescendants()) do
		attachServerRemoteListener(d)
	end
	game.DescendantAdded:Connect(function(d)
		attachServerRemoteListener(d)
	end)
end

local function isGunTool(obj: Instance): boolean
	if not obj:IsA("Tool") then
		return false
	end
	local n = string.lower(obj.Name)
	return string.find(n, "gun", 1, true) ~= nil
		or string.find(n, "revolver", 1, true) ~= nil
		or string.find(n, "pistol", 1, true) ~= nil
		or string.find(n, "sheriff", 1, true) ~= nil
		or obj:GetAttribute("IsGun") ~= nil
		or obj:GetAttribute("Gun") ~= nil
end

local function getEquippedGun(): Tool?
	local char = player.Character
	if not char then
		return nil
	end
	for _, child in ipairs(char:GetChildren()) do
		if isGunTool(child) then
			return child :: Tool
		end
	end
	return nil
end

local function findAllGunTools(): { Tool }
	local out: { Tool } = {}
	local function scanIn(root: Instance?)
		if not root then
			return
		end
		for _, obj in ipairs(root:GetDescendants()) do
			if isGunTool(obj) then
				table.insert(out, obj :: Tool)
			end
		end
	end
	scanIn(player:FindFirstChild("Backpack"))
	scanIn(player.Character)
	return out
end

local function getRayAndAim(...): string
	local cam = Workspace.CurrentCamera
	local mousePos = UserInputService:GetMouseLocation()
	local originStr = "no_cam"
	local dirStr = "no_cam"
	local hitStr = "none"

	if cam then
		local unitRay = cam:ViewportPointToRay(mousePos.X, mousePos.Y)
		originStr = fmtVal(unitRay.Origin)
		dirStr = fmtVal(unitRay.Direction)

		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = player.Character and { player.Character } or {}
		local hit = Workspace:Raycast(unitRay.Origin, unitRay.Direction * 500, params)
		if hit then
			hitStr = string.format("%s @ %s (dist=%.1f)",
				fullPath(hit.Instance), fmtVal(hit.Position), hit.Distance)
		end
	end

	local argsPart = select("#", ...) > 0 and (" | Args: " .. fmtArgs(...)) or ""
	return string.format("Mouse=(%.0f,%.0f) Origin=%s Dir=%s Hit=%s%s",
		mousePos.X, mousePos.Y, originStr, dirStr, hitStr, argsPart)
end

local function hookGunEvents(tool: Tool)
	if hookedGunTools[tool] then
		return
	end
	hookedGunTools[tool] = true
	watchAttributes(tool, "GUN_ATTR")

	for _, d in ipairs(tool:GetDescendants()) do
		watchAttributes(d, "GUN_DESC_ATTR")
		if d:IsA("Sound") then
			d.Played:Connect(function()
				if scanEnabled then
					LogEvent("EV_SOUND_PLAYED", string.format("Path=%s | SoundId=%s",
						fullPath(d), tostring(d.SoundId)))
				end
			end)
		end
	end

	tool.Equipped:Connect(function()
		if scanEnabled then
			LogEvent("EV_EQUIPPED", string.format("Path=%s | %s%s",
				fullPath(tool), getRayAndAim(), fmtAttrs(tool)))
		end
	end)

	tool.Unequipped:Connect(function()
		if scanEnabled then
			LogEvent("EV_UNEQUIPPED", string.format("Path=%s%s",
				fullPath(tool), fmtAttrs(tool)))
		end
	end)

	tool.Activated:Connect(function()
		if scanEnabled then
			LogEvent("EV_ACTIVATED", string.format("Path=%s | %s%s",
				fullPath(tool), getRayAndAim(), fmtAttrs(tool)))
		end
	end)

	tool.Deactivated:Connect(function()
		if scanEnabled then
			LogEvent("EV_DEACTIVATED", string.format("Path=%s%s",
				fullPath(tool), fmtAttrs(tool)))
		end
	end)

	tool.DescendantAdded:Connect(function(d)
		watchAttributes(d, "GUN_DESC_ATTR")
		if scanEnabled then
			LogEvent("EV_DESC_ADDED", string.format("Gun=%s | Added=%s%s",
				fullPath(tool), fullPath(d), fmtAttrs(d)))
		end
	end)

	tool.DescendantRemoving:Connect(function(d)
		if scanEnabled then
			LogEvent("EV_DESC_REMOVING", string.format("Gun=%s | Removing=%s",
				fullPath(tool), fullPath(d)))
		end
	end)
end

local function dumpGunFullTreeWithPaths(tool: Tool)
	hookGunEvents(tool)
	LogEvent("TREE_ROOT", string.format("Path=%s%s", fullPath(tool), fmtAttrs(tool)))

	local desc = tool:GetDescendants()
	for _, d in ipairs(desc) do
		watchAttributes(d, "GUN_DESC_ATTR")
		local extra = ""
		if d:IsA("BaseScript") then
			extra = " | Disabled=" .. tostring(d.Disabled)
		elseif d:IsA("ValueBase") then
			extra = " | Value=" .. fmtVal((d :: any).Value)
		elseif d:IsA("Sound") then
			extra = " | SoundId=" .. tostring(d.SoundId)
		elseif d:IsA("Animation") then
			extra = " | AnimId=" .. tostring(d.AnimationId)
		end

		local tags = CollectionService:GetTags(d)
		local tagStr = #tags > 0 and (" | Tags[" .. table.concat(tags, ", ") .. "]") or ""
		LogEvent("TREE_PATH", string.format("Path=%s%s%s%s",
			fullPath(d), extra, fmtAttrs(d), tagStr))
	end
end

local function scanTick()
	if not scanEnabled then
		if statusLabel then
			statusLabel.Text = "Scan: PAUSED"
		end
		return
	end

	local guns = findAllGunTools()
	local eq = getEquippedGun()
	local snapParts = {
		"EQ:" .. (eq and eq:GetFullName() or "NONE"),
		"N:" .. tostring(#guns)
	}

	for _, g in ipairs(guns) do
		hookGunEvents(g)
		table.insert(snapParts, g:GetFullName() .. ":" .. tostring(#g:GetDescendants()) .. fmtAttrs(g))
		for _, d in ipairs(g:GetDescendants()) do
			local vStr = d:IsA("ValueBase") and ("=" .. fmtVal((d :: any).Value)) or ""
			table.insert(snapParts, d:GetFullName() .. vStr .. fmtAttrs(d))
		end
	end

	local snap = table.concat(snapParts, "|")
	if statusLabel then
		statusLabel.Text = string.format("0.2s ON | Guns:%d | Eq:%s",
			#guns, eq and eq.Name or "none")
	end

	if snap ~= lastGunSnap then
		lastGunSnap = snap
		if #guns == 0 then
			LogEvent("GUN_SCAN", "Gun не найден (проверены Backpack и Character).")
		else
			for _, g in ipairs(guns) do
				dumpGunFullTreeWithPaths(g)
			end
		end
	end
end

local function watchContainer(container: Instance, prefix: string)
	watchAttributes(container, prefix .. "_ATTR")
	container.ChildAdded:Connect(function(child)
		watchAttributes(child, prefix .. "_CHILD_ATTR")
		if isGunTool(child) then
			hookGunEvents(child :: Tool)
		end
		if scanEnabled then
			LogEvent(prefix .. "_ADDED", string.format("Path=%s%s", fullPath(child), fmtAttrs(child)))
		end
		task.defer(scanTick)
	end)
	container.ChildRemoved:Connect(function(child)
		if scanEnabled then
			LogEvent(prefix .. "_REMOVED", string.format("Path=%s", fullPath(child)))
		end
		task.defer(scanTick)
	end)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not scanEnabled then
		return
	end
	local eq = getEquippedGun()
	if not eq then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
		or input.KeyCode == Enum.KeyCode.R
		or input.KeyCode == Enum.KeyCode.F
	then
		local keyName = input.KeyCode ~= Enum.KeyCode.Unknown and input.KeyCode.Name or input.UserInputType.Name
		LogEvent("EV_INPUT_BEGAN", string.format("Input=%s (GP=%s) | GunPath=%s | %s",
			keyName, tostring(gameProcessed), fullPath(eq), getRayAndAim()))
	end
end)

local function createUI()
	local old = playerGui:FindFirstChild("GunFullPathEventsGui")
	if old then
		old:Destroy()
	end

	local sg = Instance.new("ScreenGui")
	sg.Name = "GunFullPathEventsGui"
	sg.ResetOnSpawn = false
	sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	sg.Parent = playerGui

	local main = Instance.new("Frame")
	main.Size = UDim2.new(0, 620, 0, 360)
	main.Position = UDim2.new(0, 20, 0, 70)
	main.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
	main.BorderSizePixel = 0
	main.Active = true
	main.Draggable = true
	main.Parent = sg

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = main

	local top = Instance.new("Frame")
	top.Size = UDim2.new(1, 0, 0, 34)
	top.BackgroundColor3 = Color3.fromRGB(30, 34, 44)
	top.BorderSizePixel = 0
	top.Parent = main

	local tCorner = Instance.new("UICorner")
	tCorner.CornerRadius = UDim.new(0, 8)
	tCorner.Parent = top

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(0.55, 0, 1, 0)
	title.Position = UDim2.new(0, 10, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "GUN FULL PATHS, CLI & SRV EVENTS (0.2s)"
	title.TextColor3 = Color3.fromRGB(235, 240, 250)
	title.TextSize = 12
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = top

	statusLabel = Instance.new("TextLabel")
	statusLabel.Size = UDim2.new(0.42, -10, 1, 0)
	statusLabel.Position = UDim2.new(0.55, 0, 0, 0)
	statusLabel.BackgroundTransparency = 1
	statusLabel.Text = "0.2s ON"
	statusLabel.TextColor3 = Color3.fromRGB(130, 220, 160)
	statusLabel.TextSize = 12
	statusLabel.Font = Enum.Font.GothamMedium
	statusLabel.TextXAlignment = Enum.TextXAlignment.Right
	statusLabel.Parent = top

	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(1, -16, 0, 28)
	bar.Position = UDim2.new(0, 8, 0, 40)
	bar.BackgroundTransparency = 1
	bar.Parent = main

	local function makeBtn(txt: string, x: number, w: number, bg: Color3): TextButton
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(0, w, 1, 0)
		b.Position = UDim2.new(0, x, 0, 0)
		b.BackgroundColor3 = bg
		b.Text = txt
		b.TextColor3 = Color3.new(1, 1, 1)
		b.TextSize = 11
		b.Font = Enum.Font.GothamBold
		b.Parent = bar
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 6)
		c.Parent = b
		return b
	end

	scanBtn = makeBtn("Scan: ON", 0, 80, Color3.fromRGB(45, 130, 85))
	srvBtn = makeBtn("SrvEv: ON", 86, 84, Color3.fromRGB(50, 110, 155))
	pulseBtn = makeBtn("Pulse: OFF", 176, 86, Color3.fromRGB(70, 75, 90))
	local dumpBtn = makeBtn("Full Paths", 268, 86, Color3.fromRGB(95, 70, 160))
	local clearBtn = makeBtn("Clear", 360, 62, Color3.fromRGB(130, 50, 55))
	local copyBtn = makeBtn("Copy", 428, 66, Color3.fromRGB(55, 95, 150))
	local hideBtn = makeBtn("Hide", 500, 56, Color3.fromRGB(65, 68, 80))

	local body = Instance.new("Frame")
	body.Size = UDim2.new(1, -16, 1, -76)
	body.Position = UDim2.new(0, 8, 0, 72)
	body.BackgroundColor3 = Color3.fromRGB(14, 16, 21)
	body.BorderSizePixel = 0
	body.Parent = main

	local bCorner = Instance.new("UICorner")
	bCorner.CornerRadius = UDim.new(0, 6)
	bCorner.Parent = body

	scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Size = UDim2.new(1, -8, 1, -8)
	scrollFrame.Position = UDim2.new(0, 4, 0, 4)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.ScrollBarThickness = 6
	scrollFrame.Parent = body

	logLabel = Instance.new("TextLabel")
	logLabel.Size = UDim2.new(1, -8, 0, 200)
	logLabel.BackgroundTransparency = 1
	logLabel.Text = ""
	logLabel.TextColor3 = Color3.fromRGB(215, 222, 235)
	logLabel.TextSize = 11
	logLabel.Font = Enum.Font.Code
	logLabel.TextWrapped = true
	logLabel.TextXAlignment = Enum.TextXAlignment.Left
	logLabel.TextYAlignment = Enum.TextYAlignment.Top
	logLabel.Parent = scrollFrame

	scanBtn.MouseButton1Click:Connect(function()
		scanEnabled = not scanEnabled
		scanBtn.Text = scanEnabled and "Scan: ON" or "Scan: OFF"
		scanBtn.BackgroundColor3 = scanEnabled and Color3.fromRGB(45, 130, 85) or Color3.fromRGB(120, 60, 60)
		LogEvent("UI", "Scan -> " .. tostring(scanEnabled))
	end)

	srvBtn.MouseButton1Click:Connect(function()
		serverEventsEnabled = not serverEventsEnabled
		srvBtn.Text = serverEventsEnabled and "SrvEv: ON" or "SrvEv: OFF"
		srvBtn.BackgroundColor3 = serverEventsEnabled and Color3.fromRGB(50, 110, 155) or Color3.fromRGB(90, 65, 65)
		LogEvent("UI", "ServerEvents -> " .. tostring(serverEventsEnabled))
	end)

	pulseBtn.MouseButton1Click:Connect(function()
		pulseEnabled = not pulseEnabled
		pulseBtn.Text = pulseEnabled and "Pulse: ON" or "Pulse: OFF"
		pulseBtn.BackgroundColor3 = pulseEnabled and Color3.fromRGB(145, 105, 35) or Color3.fromRGB(70, 75, 90)
		LogEvent("UI", "Pulse -> " .. tostring(pulseEnabled))
	end)

	dumpBtn.MouseButton1Click:Connect(function()
		local guns = findAllGunTools()
		if #guns == 0 then
			LogEvent("FULL_PATHS", "Gun не найден.")
			return
		end
		for _, g in ipairs(guns) do
			dumpGunFullTreeWithPaths(g)
		end
	end)

	clearBtn.MouseButton1Click:Connect(function()
		table.clear(logLines)
		lastGunSnap = ""
		refreshUI()
	end)

	copyBtn.MouseButton1Click:Connect(function()
		if typeof(setclipboard) == "function" then
			setclipboard(table.concat(logLines, "\n"))
			LogEvent("UI", "Лог скопирован.")
		else
			LogEvent("UI", "setclipboard недоступен.")
		end
	end)

	local minimized = false
	hideBtn.MouseButton1Click:Connect(function()
		minimized = not minimized
		body.Visible = not minimized
		bar.Visible = not minimized
		hideBtn.Text = minimized and "Show" or "Hide"
		main.Size = minimized and UDim2.new(0, 620, 0, 38) or UDim2.new(0, 620, 0, 360)
	end)
end

createUI()
hookAllExistingAndNewRemotes()

local bp = player:FindFirstChild("Backpack")
if bp then
	watchContainer(bp, "BP")
end
player.ChildAdded:Connect(function(child)
	if child.Name == "Backpack" then
		watchContainer(child, "BP")
		task.defer(scanTick)
	end
end)

if player.Character then
	watchContainer(player.Character, "CHAR")
end
player.CharacterAdded:Connect(function(char)
	watchContainer(char, "CHAR")
	task.defer(scanTick)
end)

task.spawn(function()
	while true do
		scanTick()
		task.wait(scanInterval)
	end
end)

task.spawn(function()
	while true do
		task.wait(pulseInterval)
		if scanEnabled and pulseEnabled then
			LogEvent("PULSE", getRayAndAim())
		end
	end
end)

if typeof(hookmetamethod) == "function" and typeof(getnamecallmethod) == "function" then
	local oldNamecall
	oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
		local method = getnamecallmethod()
		if not checkcaller() and typeof(self) == "Instance" then
			if (method == "FireServer" or method == "InvokeServer") and (self:IsA("RemoteEvent") or self:IsA("RemoteFunction")) then
				watchAttributes(self, "REM_ATTR")
				local eq = getEquippedGun()
				local eqInfo = eq and (" | EquippedGun=" .. fullPath(eq)) or ""
				local pStr = fullPath(self)
				local argsStr = fmtArgs(...)
				task.defer(LogEvent, method, string.format("Path=%s%s%s | Args: %s",
					pStr, eqInfo, fmtAttrs(self), argsStr))
				local lowPath = string.lower(pStr)
				if string.find(lowPath, "shoot", 1, true)
					or string.find(lowPath, "gun", 1, true)
					or string.find(lowPath, "fire", 1, true)
				then
					task.defer(LogEvent, "RAY_SHOT", method .. " Path=" .. pStr .. eqInfo .. " | " .. getRayAndAim(...))
				end
			elseif method == "Fire" and self:IsA("BindableEvent") then
				watchAttributes(self, "BIND_ATTR")
				local eq = getEquippedGun()
				local eqInfo = eq and (" | EquippedGun=" .. fullPath(eq)) or ""
				local pStr = fullPath(self)
				local argsStr = fmtArgs(...)
				task.defer(LogEvent, "Bindable:Fire", string.format("Path=%s%s%s | Args: %s",
					pStr, eqInfo, fmtAttrs(self), argsStr))
			end
		end
		return oldNamecall(self, ...)
	end)
	LogEvent("INIT", "GUN FULL PATHS, CLI & SRV EVENTS (0.2s) запущен.")
else
	LogEvent("INIT", "GUN FULL PATHS, CLI & SRV EVENTS (0.2s) запущен без __namecall хука.")
end
