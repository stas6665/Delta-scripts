local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local SCAN_INTERVAL = 0.2
local MAX_LOG_LINES = 800

local scanActive = true
local lastSnap = ""
local hookedAttr = {}
local hookedTools = {}
local hookedRemotes = {}
local logLines = {}

local logLbl = nil
local scrollFrame = nil
local statusLbl = nil
local toggleBtn = nil

local TARGET_NAMES = {
	["Gun"] = true,
	["Animations"] = true,
	["Reload"] = true,
	["Shoot"] = true,
	["Sounds"] = true,
	["GunServer"] = true,
	["GunRaycastAttachment1"] = true,
	["GunClient"] = true,
	["Handle"] = true,
	["Gunshot"] = true,
	["GunBelt"] = true,
	["GunTipAttachment"] = true,
	["GunRaycastAttachment"] = true,
	["GunShoulderAttachment"] = true,
	["DisplayRefGun"] = true,
}

local function fullPath(inst)
	if not inst then
		return "nil"
	end
	local ok, path = pcall(function()
		return inst:GetFullName()
	end)
	return (ok and path) and path or tostring(inst)
end

local function fmtVal(v)
	local t = typeof(v)
	if t == "Instance" then
		return string.format("%s [%s]", fullPath(v), v.ClassName)
	elseif t == "Vector3" then
		return string.format("Vector3(%.2f, %.2f, %.2f)", v.X, v.Y, v.Z)
	elseif t == "CFrame" then
		local p = v.Position
		return string.format("CFrame(%.2f, %.2f, %.2f)", p.X, p.Y, p.Z)
	elseif t == "Color3" then
		return string.format("Color3(%d, %d, %d)",
			math.round(v.R * 255), math.round(v.G * 255), math.round(v.B * 255))
	elseif t == "table" then
		local parts = {}
		local count = 0
		for k, val in pairs(v) do
			count = count + 1
			table.insert(parts, tostring(k) .. "=" .. fmtVal(val))
			if count >= 10 then
				table.insert(parts, "...")
				break
			end
		end
		return "{" .. table.concat(parts, ", ") .. "}"
	end
	return tostring(v)
end

local function fmtArgs(...)
	local n = select("#", ...)
	if n == 0 then
		return "none"
	end
	local list = {}
	for i = 1, n do
		local val = select(i, ...)
		table.insert(list, string.format("arg%d=%s (%s)", i, fmtVal(val), typeof(val)))
	end
	return table.concat(list, ", ")
end

local function safeGetValue(obj)
	local ok, val = pcall(function()
		return obj.Value
	end)
	return ok and fmtVal(val) or "err"
end

local function getMeta(obj)
	local parts = {}

	pcall(function()
		if obj:IsA("Tool") then
			table.insert(parts, "Enabled=" .. tostring(obj.Enabled))
		elseif obj:IsA("BaseScript") then
			table.insert(parts, "Disabled=" .. tostring(obj.Disabled))
		elseif obj:IsA("ValueBase") then
			table.insert(parts, "Value=" .. safeGetValue(obj))
		elseif obj:IsA("BasePart") then
			table.insert(parts, string.format("Anchored=%s CanCollide=%s Trans=%.2f",
				tostring(obj.Anchored), tostring(obj.CanCollide), obj.Transparency))
		elseif obj:IsA("Sound") then
			table.insert(parts, "SoundId=" .. tostring(obj.SoundId))
		elseif obj:IsA("Animation") then
			table.insert(parts, "AnimId=" .. tostring(obj.AnimationId))
		end
	end)

	local okAttr, attrs = pcall(function()
		return obj:GetAttributes()
	end)
	if okAttr and type(attrs) == "table" and next(attrs) ~= nil then
		local aList = {}
		for k, v in pairs(attrs) do
			table.insert(aList, string.format("%s=%s(%s)", tostring(k), fmtVal(v), typeof(v)))
		end
		table.insert(parts, "Attrs{" .. table.concat(aList, "; ") .. "}")
	end

	local okTag, tags = pcall(function()
		return CollectionService:GetTags(obj)
	end)
	if okTag and type(tags) == "table" and #tags > 0 then
		table.insert(parts, "Tags[" .. table.concat(tags, ", ") .. "]")
	end

	return #parts > 0 and (" | " .. table.concat(parts, " | ")) or ""
end

local function getPlayerRoots()
	local roots = {}
	local bp = player:FindFirstChild("Backpack")
	if bp then
		table.insert(roots, bp)
	end
	if player.Character then
		table.insert(roots, player.Character)
	end
	local wsChar = Workspace:FindFirstChild(player.Name)
	if wsChar and wsChar ~= player.Character then
		table.insert(roots, wsChar)
	end
	return roots
end

local function getEquippedGunPath()
	for _, root in ipairs(getPlayerRoots()) do
		if root:IsA("Model") then
			for _, ch in ipairs(root:GetChildren()) do
				if ch:IsA("Tool") and ch.Name == "Gun" then
					return fullPath(ch)
				end
			end
		end
	end
	return "none"
end

local function refreshUI()
	if not logLbl or not scrollFrame then
		return
	end
	local text = table.concat(logLines, "\n")
	logLbl.Text = text
	task.defer(function()
		if not logLbl or not scrollFrame then
			return
		end
		local h = math.max(scrollFrame.AbsoluteSize.Y, logLbl.TextBounds.Y + 16)
		logLbl.Size = UDim2.new(1, -8, 0, h)
		scrollFrame.CanvasSize = UDim2.new(0, 0, 0, h + 8)
		scrollFrame.CanvasPosition = Vector2.new(0, math.max(0, scrollFrame.CanvasSize.Y.Offset - scrollFrame.AbsoluteSize.Y))
	end)
end

local function pushLog(tag, msg)
	local line = string.format("[%s | t=%.2f][%s] %s", os.date("%H:%M:%S"), tick() % 10000, tostring(tag), tostring(msg))
	table.insert(logLines, line)
	if #logLines > MAX_LOG_LINES then
		table.remove(logLines, 1)
	end
	refreshUI()
	pcall(print, line)
end

local function watchAttr(inst, tag)
	if not inst or not inst.Parent or hookedAttr[inst] then
		return
	end
	hookedAttr[inst] = true
	pcall(function()
		inst.AttributeChanged:Connect(function(attrName)
			if not scanActive then
				return
			end
			local val = inst:GetAttribute(attrName)
			pushLog(tag, string.format("Path=%s | Attr '%s' = %s (%s)",
				fullPath(inst), tostring(attrName), fmtVal(val), typeof(val)))
		end)
	end)
end

local function isInsideGun(obj)
	local cur = obj
	while cur do
		if cur:IsA("Tool") and cur.Name == "Gun" then
			return true
		end
		cur = cur.Parent
	end
	return false
end

local function isRelevantTarget(obj)
	if isInsideGun(obj) then
		return true
	end
	if TARGET_NAMES[obj.Name] then
		for _, root in ipairs(getPlayerRoots()) do
			if obj:IsDescendantOf(root) or obj == root then
				return true
			end
		end
	end
	return false
end

local function collectTargets()
	local list = {}
	local seen = {}
	for _, root in ipairs(getPlayerRoots()) do
		for _, d in ipairs(root:GetDescendants()) do
			if not seen[d] and isRelevantTarget(d) then
				seen[d] = true
				table.insert(list, d)
			end
		end
	end
	return list
end

local function hookRemote(obj)
	if not obj or hookedRemotes[obj] then
		return
	end
	if obj:IsA("RemoteEvent") and (obj.Name == "Shoot" or isInsideGun(obj)) then
		hookedRemotes[obj] = true
		watchAttr(obj, "SHOOT_REM_ATTR")
		pcall(function()
			obj.OnClientEvent:Connect(function(...)
				if not scanActive then
					return
				end
				pushLog("SRV -> CLI", string.format("From=Server | To=Client(%s) | Event=%s%s | Args: %s",
					player.Name, fullPath(obj), getMeta(obj), fmtArgs(...)))
			end)
		end)
	end
end

local function attachGunToolListeners(gun)
	if hookedTools[gun] then
		return
	end
	hookedTools[gun] = true
	watchAttr(gun, "GUN_ATTR")

	for _, d in ipairs(gun:GetDescendants()) do
		watchAttr(d, "GUN_DESC_ATTR")
		hookRemote(d)
		if d:IsA("Sound") then
			pcall(function()
				d.Played:Connect(function()
					if scanActive then
						pushLog("GUN_SOUND", string.format("Sound=%s | SoundId=%s | EquippedGun=%s",
							fullPath(d), tostring(d.SoundId), getEquippedGunPath()))
					end
				end)
			end)
		end
	end

	pcall(function()
		gun.Equipped:Connect(function()
			if scanActive then
				pushLog("EV_EQUIPPED", "Gun=" .. fullPath(gun))
			end
		end)
		gun.Unequipped:Connect(function()
			if scanActive then
				pushLog("EV_UNEQUIPPED", "Gun=" .. fullPath(gun))
			end
		end)
		gun.Activated:Connect(function()
			if scanActive then
				pushLog("EV_ACTIVATED", "Gun=" .. fullPath(gun))
			end
		end)
		gun.DescendantAdded:Connect(function(d)
			watchAttr(d, "GUN_DESC_ATTR")
			hookRemote(d)
			if scanActive then
				pushLog("GUN_ADD", "Added=" .. fullPath(d) .. getMeta(d))
			end
		end)
	end)
end

local function dumpTargets(targets)
	for _, t in ipairs(targets) do
		watchAttr(t, "TARGET_ATTR")
		hookRemote(t)
		if t:IsA("Tool") and t.Name == "Gun" then
			attachGunToolListeners(t)
		end
		pushLog("TARGET_FOUND", string.format("Name=%s | Path=%s%s",
			t.Name, fullPath(t), getMeta(t)))
	end
end

local function buildSnapshot(targets)
	if #targets == 0 then
		return "EMPTY"
	end
	local parts = {}
	for _, t in ipairs(targets) do
		table.insert(parts, fullPath(t) .. ":" .. t.ClassName .. getMeta(t))
	end
	return table.concat(parts, ";")
end

local function scanTick(force)
	local targets = collectTargets()
	local snap = buildSnapshot(targets)

	if statusLbl then
		statusLbl.Text = scanActive
			and string.format("0.2s ON | Found: %d", #targets)
			or string.format("PAUSED | Found: %d", #targets)
	end

	if not scanActive and not force then
		return
	end

	if force or snap ~= lastSnap then
		lastSnap = snap
		if #targets == 0 then
			pushLog("SCAN", "Цели Gun / Shoot / Attachments / Handle пока не найдены.")
		else
			dumpTargets(targets)
		end
	end
end

local function createUI()
	local prev = playerGui:FindFirstChild("GunFixedTrackerUI")
	if prev then
		prev:Destroy()
	end

	local sg = Instance.new("ScreenGui")
	sg.Name = "GunFixedTrackerUI"
	sg.ResetOnSpawn = false
	sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	sg.Parent = playerGui

	local win = Instance.new("Frame")
	win.Size = UDim2.new(0, 620, 0, 340)
	win.Position = UDim2.new(0, 20, 0, 80)
	win.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
	win.BorderSizePixel = 0
	win.Active = true
	win.Draggable = true
	win.Parent = sg
	Instance.new("UICorner", win).CornerRadius = UDim.new(0, 8)

	local top = Instance.new("Frame")
	top.Size = UDim2.new(1, 0, 0, 34)
	top.BackgroundColor3 = Color3.fromRGB(30, 34, 44)
	top.BorderSizePixel = 0
	top.Parent = win
	Instance.new("UICorner", top).CornerRadius = UDim.new(0, 8)

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(0.56, 0, 1, 0)
	title.Position = UDim2.new(0, 10, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "GUN FIXED SCANNER & SHOOT (0.2s)"
	title.TextColor3 = Color3.fromRGB(235, 240, 250)
	title.TextSize = 12
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = top

	statusLbl = Instance.new("TextLabel")
	statusLbl.Size = UDim2.new(0.41, -10, 1, 0)
	statusLbl.Position = UDim2.new(0.56, 0, 0, 0)
	statusLbl.BackgroundTransparency = 1
	statusLbl.Text = "0.2s ON"
	statusLbl.TextColor3 = Color3.fromRGB(130, 220, 160)
	statusLbl.TextSize = 12
	statusLbl.Font = Enum.Font.GothamMedium
	statusLbl.TextXAlignment = Enum.TextXAlignment.Right
	statusLbl.Parent = top

	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(1, -16, 0, 28)
	bar.Position = UDim2.new(0, 8, 0, 40)
	bar.BackgroundTransparency = 1
	bar.Parent = win

	local function makeBtn(txt, x, w, bg)
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(0, w, 1, 0)
		b.Position = UDim2.new(0, x, 0, 0)
		b.BackgroundColor3 = bg
		b.Text = txt
		b.TextColor3 = Color3.new(1, 1, 1)
		b.TextSize = 11
		b.Font = Enum.Font.GothamBold
		b.Parent = bar
		Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
		return b
	end

	toggleBtn = makeBtn("Scan: ON", 0, 86, Color3.fromRGB(45, 130, 85))
	local scanBtn = makeBtn("Scan Now", 92, 88, Color3.fromRGB(95, 70, 160))
	local clearBtn = makeBtn("Clear", 186, 68, Color3.fromRGB(130, 50, 55))
	local copyBtn = makeBtn("Copy", 260, 72, Color3.fromRGB(55, 95, 150))
	local hideBtn = makeBtn("Hide", 338, 58, Color3.fromRGB(65, 68, 80))

	local box = Instance.new("Frame")
	box.Size = UDim2.new(1, -16, 1, -76)
	box.Position = UDim2.new(0, 8, 0, 72)
	box.BackgroundColor3 = Color3.fromRGB(14, 16, 21)
	box.BorderSizePixel = 0
	box.Parent = win
	Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)

	scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Size = UDim2.new(1, -8, 1, -8)
	scrollFrame.Position = UDim2.new(0, 4, 0, 4)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.ScrollBarThickness = 6
	scrollFrame.Parent = box

	logLbl = Instance.new("TextLabel")
	logLbl.Size = UDim2.new(1, -8, 0, 200)
	logLbl.BackgroundTransparency = 1
	logLbl.Text = ""
	logLbl.TextColor3 = Color3.fromRGB(215, 222, 235)
	logLbl.TextSize = 11
	logLbl.Font = Enum.Font.Code
	logLbl.TextWrapped = true
	logLbl.TextXAlignment = Enum.TextXAlignment.Left
	logLbl.TextYAlignment = Enum.TextYAlignment.Top
	logLbl.Parent = scrollFrame

	toggleBtn.MouseButton1Click:Connect(function()
		scanActive = not scanActive
		toggleBtn.Text = scanActive and "Scan: ON" or "Scan: OFF"
		toggleBtn.BackgroundColor3 = scanActive and Color3.fromRGB(45, 130, 85) or Color3.fromRGB(120, 60, 60)
		scanTick(false)
	end)

	scanBtn.MouseButton1Click:Connect(function()
		scanTick(true)
	end)

	clearBtn.MouseButton1Click:Connect(function()
		table.clear(logLines)
		lastSnap = ""
		refreshUI()
	end)

	copyBtn.MouseButton1Click:Connect(function()
		if typeof(setclipboard) == "function" then
			setclipboard(table.concat(logLines, "\n"))
			pushLog("UI", "Лог скопирован.")
		else
			pushLog("UI", "setclipboard недоступен.")
		end
	end)

	local minimized = false
	hideBtn.MouseButton1Click:Connect(function()
		minimized = not minimized
		box.Visible = not minimized
		bar.Visible = not minimized
		hideBtn.Text = minimized and "Show" or "Hide"
		win.Size = minimized and UDim2.new(0, 620, 0, 38) or UDim2.new(0, 620, 0, 340)
	end)
end

if typeof(hookmetamethod) == "function" and typeof(getnamecallmethod) == "function" then
	pcall(function()
		local oldNamecall
		oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
			local method = getnamecallmethod()
			local callerOrigin = (typeof(checkcaller) == "function" and checkcaller()) and "Executor" or "GameClient"
			if typeof(self) == "Instance" and (self.Name == "Shoot" or isInsideGun(self) or TARGET_NAMES[self.Name]) then
				if (method == "FireServer" or method == "InvokeServer") and (self:IsA("RemoteEvent") or self:IsA("RemoteFunction")) then
					watchAttr(self, "SHOOT_REM_ATTR")
					local argsStr = fmtArgs(...)
					local eqStr = getEquippedGunPath()
					task.defer(pushLog, "CLI -> SRV", string.format("From=Client(%s, %s) | To=Server | Method=%s | Event=%s%s | EquippedGun=%s | Args: %s",
						player.Name, callerOrigin, method, fullPath(self), getMeta(self), eqStr, argsStr))
				elseif method == "Fire" and self:IsA("BindableEvent") then
					watchAttr(self, "SHOOT_BIND_ATTR")
					local argsStr = fmtArgs(...)
					task.defer(pushLog, "LOCAL_BIND", string.format("From=%s(%s) | LocalBind=%s%s | Args: %s",
						player.Name, callerOrigin, fullPath(self), getMeta(self), argsStr))
				end
			end
			return oldNamecall(self, ...)
		end)
	end)
end

createUI()

task.spawn(function()
	while true do
		pcall(scanTick, false)
		task.wait(SCAN_INTERVAL)
	end
end)
