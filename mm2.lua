local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local mainGui = playerGui:WaitForChild("MainGUI")
local gameGui = mainGui:WaitForChild("Game")
local newItemFrame = gameGui:WaitForChild("NewItem")
local claimBtn = newItemFrame:WaitForChild("Container"):WaitForChild("Claim")

local itemModule = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ItemModule"))
local syncDb = require(ReplicatedStorage:WaitForChild("Database"):WaitForChild("Sync"))

local TARGET_ID = 15617843269
local TARGET_ID_STR = tostring(TARGET_ID)
local FALLBACK_ICON = "rbxassetid://" .. TARGET_ID_STR
local FIRE_COOLDOWN = 0.14
local EQUIP_FIRE_DELAY = 0.25
local INVENTORY_GUARD_INTERVAL = 3.0

local MY_GUN_DISPLAY_PATH = {}

local isClaimed = false
local isEquipped = false
local lastEquipTime = 0
local activeHandHandle = nil
local holdTrack = nil
local currentCardNameLabel = nil
local currentCardRoot = nil
local lastFireTime = 0
local characterGeneration = 0
local hiddenToolParts = {}
local hiddenEquippedGunChildren = {}
local hookedButtons = setmetatable({}, { __mode = "k" })
local hookedContainers = setmetatable({}, { __mode = "k" })
local hookedVisibility = setmetatable({}, { __mode = "k" })
local hookedFilterControls = setmetatable({}, { __mode = "k" })

local function matchesTargetId(val)
	if val == nil then
		return false
	end
	if type(val) == "number" then
		return math.floor(val) == TARGET_ID
	end
	return tostring(val):find(TARGET_ID_STR, 1, true) ~= nil
end

local function findWeaponEntryById()
	if type(syncDb.Weapons) == "table" then
		for key, entry in pairs(syncDb.Weapons) do
			if type(entry) == "table" then
				local idMatch = matchesTargetId(entry.ItemID)
					or matchesTargetId(entry.WeaponID)
					or matchesTargetId(entry.WeaponId)
					or matchesTargetId(entry.ID)
					or matchesTargetId(entry.Id)
					or matchesTargetId(entry.Image)
					or matchesTargetId(entry.Texture)
					or matchesTargetId(entry.MeshId)
				if idMatch then
					return key, entry
				end
			end
		end
	end

	return "Gingerscope", {
		ItemName = "Gingerscope",
		ItemType = "Gun",
		Rarity = "Ancient",
		Event = "Christmas",
		Year = 2023,
		ItemID = TARGET_ID,
		Image = FALLBACK_ICON,
	}
end

local TARGET_KEY, gsEntry = findWeaponEntryById()

local function resolveWeaponIcon()
	if gsEntry then
		if gsEntry.Image ~= nil and tostring(gsEntry.Image) ~= "" then
			local imgStr = tostring(gsEntry.Image)
			if imgStr:find("rbxassetid://", 1, true) or imgStr:find("http", 1, true) then
				return imgStr
			end
			if tonumber(imgStr) then
				return "rbxassetid://" .. imgStr
			end
		end
	end
	return FALLBACK_ICON
end

local function centerNewItemWindow()
	if newItemFrame:IsA("GuiObject") then
		newItemFrame.AnchorPoint = Vector2.new(0.5, 0.5)
		newItemFrame.Position = UDim2.fromScale(0.5, 0.5)
	end
	local container = newItemFrame:FindFirstChild("Container")
	if container and container:IsA("GuiObject") and container.Size ~= UDim2.fromScale(1, 1) then
		container.AnchorPoint = Vector2.new(0.5, 0.5)
		container.Position = UDim2.fromScale(0.5, 0.5)
	end
end

local function instanceMatchesTargetId(obj)
	if matchesTargetId(obj:GetAttribute("ItemID"))
		or matchesTargetId(obj:GetAttribute("WeaponID"))
		or matchesTargetId(obj:GetAttribute("WeaponId"))
		or matchesTargetId(obj:GetAttribute("ID"))
		or matchesTargetId(obj:GetAttribute("Id"))
	then
		return true
	end

	if obj:IsA("MeshPart") then
		if matchesTargetId(obj.MeshId) or matchesTargetId(obj.TextureID) then
			return true
		end
	elseif obj:IsA("SpecialMesh") then
		if matchesTargetId(obj.MeshId) or matchesTargetId(obj.TextureId) then
			return true
		end
	elseif obj:IsA("Decal") or obj:IsA("Texture") then
		if matchesTargetId(obj.Texture) then
			return true
		end
	elseif obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
		if matchesTargetId(obj.Image) then
			return true
		end
	elseif obj:IsA("Sound") then
		if matchesTargetId(obj.SoundId) then
			return true
		end
	elseif obj:IsA("Animation") then
		if matchesTargetId(obj.AnimationId) then
			return true
		end
	end

	for _, child in ipairs(obj:GetDescendants()) do
		if child:IsA("MeshPart") and (matchesTargetId(child.MeshId) or matchesTargetId(child.TextureID)) then
			return true
		elseif child:IsA("SpecialMesh") and (matchesTargetId(child.MeshId) or matchesTargetId(child.TextureId)) then
			return true
		elseif (child:IsA("Decal") or child:IsA("Texture")) and matchesTargetId(child.Texture) then
			return true
		elseif matchesTargetId(child:GetAttribute("ItemID")) or matchesTargetId(child:GetAttribute("WeaponID")) or matchesTargetId(child:GetAttribute("ID")) then
			return true
		end
	end

	return false
end

local function findGingerscopeAssets()
	local found = {
		Model = nil,
		Sound = nil,
		Anim = nil,
		Beam = nil,
		Image = resolveWeaponIcon(),
	}

	for _, root in ipairs({ workspace, ReplicatedStorage, playerGui }) do
		for _, obj in ipairs(root:GetDescendants()) do
			if instanceMatchesTargetId(obj) then
				if not found.Model and (obj:IsA("Model") or obj:IsA("Tool") or obj:IsA("MeshPart") or obj:IsA("BasePart")) then
					found.Model = obj
				elseif not found.Sound and obj:IsA("Sound") then
					found.Sound = obj
				elseif not found.Anim and obj:IsA("Animation") then
					found.Anim = obj
				elseif not found.Beam and obj:IsA("Beam") then
					found.Beam = obj
				elseif (obj:IsA("ImageLabel") or obj:IsA("ImageButton")) and matchesTargetId(obj.Image) and found.Image == FALLBACK_ICON then
					found.Image = obj.Image
				end
			end
		end
	end

	return found
end

local assets = findGingerscopeAssets()

local function findMuzzleAttachment(modelRoot)
	if not modelRoot then return nil end
	for _, obj in ipairs(modelRoot:GetDescendants()) do
		if obj:IsA("Attachment") then
			local n = obj.Name:lower()
			if n:find("muzzle", 1, true)
				or n:find("shoot", 1, true)
				or n:find("fire", 1, true)
				or n:find("tip", 1, true)
				or n:find("barrel", 1, true)
				or n:find("beam", 1, true)
			then
				return obj
			end
		end
	end
	return modelRoot:FindFirstChildWhichIsA("Attachment", true)
end

local function createGunHandleClone()
	local src = nil
	if assets.Model then
		if assets.Model:IsA("BasePart") then
			src = assets.Model
		else
			src = assets.Model:FindFirstChild("Handle", true) or assets.Model:FindFirstChildWhichIsA("BasePart", true)
		end
	end

	if not (src and src:IsA("BasePart")) then
		return nil
	end

	local handle = src:Clone()
	handle.Name = "Handle"
	handle.LocalTransparencyModifier = 0
	return handle
end

local function resolveTargetGunDisplay()
	if type(MY_GUN_DISPLAY_PATH) ~= "table" or #MY_GUN_DISPLAY_PATH == 0 then
		return nil
	end

	local curr = game
	for _, seg in ipairs(MY_GUN_DISPLAY_PATH) do
		if type(curr) == "Instance" then
			curr = curr:FindFirstChild(seg)
			if not curr then
				return nil
			end
		else
			return nil
		end
	end

	return curr
end

local function applySingleGunDisplay(d)
	if not d or not d.Parent then return end

	if d:IsA("BasePart") or d:IsA("Model") then
		local anchor = d:IsA("Model") and (d.PrimaryPart or d:FindFirstChildWhichIsA("BasePart")) or d
		if anchor then
			local handle = createGunHandleClone()
			if handle then
				handle.Name = "GS_GunDisplay_Handle"
				handle.Anchored = true
				handle.CanCollide = false
				handle.CFrame = anchor.CFrame * CFrame.new(0, 1.5, 0)
				handle.Parent = d
			end
		end
	elseif d:IsA("GuiObject") then
		local lbl = Instance.new("TextLabel")
		lbl.Name = "GS_GunDisplay_Handle"
		lbl.Size = UDim2.fromScale(1, 1)
		lbl.BackgroundTransparency = 0.3
		lbl.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
		lbl.Text = tostring(gsEntry.ItemName or TARGET_KEY)
		lbl.TextColor3 = Color3.fromRGB(255, 215, 110)
		lbl.Font = Enum.Font.GothamBold
		lbl.TextScaled = true
		lbl.Parent = d
	end
end

local function updateGunDisplay()
	for _, container in ipairs({ workspace, playerGui }) do
		for _, desc in ipairs(container:GetDescendants()) do
			if desc.Name == "GS_GunDisplay_Handle" then
				desc:Destroy()
			end
		end
	end

	if not isEquipped then return end

	local targetDisplay = resolveTargetGunDisplay()
	if targetDisplay then
		applySingleGunDisplay(targetDisplay)
	end
end

local function findEquippedGunSlot()
	local inv2 = gameGui:FindFirstChild("Inventory2")
	local eqCont = inv2
		and inv2:FindFirstChild("Main")
		and inv2.Main:FindFirstChild("Weapons")
		and inv2.Main.Weapons:FindFirstChild("Equipped")
		and inv2.Main.Weapons.Equipped:FindFirstChild("Container")

	if not eqCont then
		return nil
	end

	local directGun = eqCont:FindFirstChild("Gun")
	if directGun and directGun:IsA("GuiObject") then
		return directGun
	end

	for _, child in ipairs(eqCont:GetChildren()) do
		if child:IsA("GuiObject") and child.Name:lower():find("gun", 1, true) then
			return child
		end
	end

	return nil
end

local function restoreEquippedGunSlot(gunSlot)
	if not gunSlot then return end

	local prev = gunSlot:FindFirstChild("GS_EquippedGunPreview")
	if prev then
		prev:Destroy()
	end

	for child, wasVisible in pairs(hiddenEquippedGunChildren) do
		if child and child.Parent == gunSlot and child:IsA("GuiObject") then
			child.Visible = wasVisible
		end
	end
	table.clear(hiddenEquippedGunChildren)

	for _, child in ipairs(gunSlot:GetChildren()) do
		if child:IsA("GuiObject") and child.Name ~= "GS_EquippedGunPreview" then
			child.Visible = true
		end
	end
end

local function updateEquippedGunSlot()
	local gunSlot = findEquippedGunSlot()
	if not gunSlot then return end

	if not isEquipped then
		restoreEquippedGunSlot(gunSlot)
		return
	end

	for _, child in ipairs(gunSlot:GetChildren()) do
		if child:IsA("GuiObject") and child.Name ~= "GS_EquippedGunPreview" then
			if hiddenEquippedGunChildren[child] == nil then
				hiddenEquippedGunChildren[child] = child.Visible
			end
			child.Visible = false
		end
	end

	local oldPreview = gunSlot:FindFirstChild("GS_EquippedGunPreview")
	if oldPreview then
		oldPreview:Destroy()
	end

	local baseName = tostring(gsEntry.ItemName or TARGET_KEY)

	local preview = Instance.new("Frame")
	preview.Name = "GS_EquippedGunPreview"
	preview.Size = UDim2.fromScale(1, 1)
	preview.BackgroundColor3 = Color3.fromRGB(36, 36, 44)
	preview.BackgroundTransparency = 0.15
	preview.BorderSizePixel = 0
	preview.ZIndex = 5
	preview.Parent = gunSlot

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(85, 165, 255)
	stroke.Thickness = 2
	stroke.Parent = preview

	local icon = Instance.new("ImageLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.new(0.82, 0, 0.68, 0)
	icon.Position = UDim2.fromScale(0.5, 0.42)
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.BackgroundTransparency = 1
	icon.Image = assets.Image or FALLBACK_ICON
	icon.ScaleType = Enum.ScaleType.Fit
	icon.ZIndex = 6
	icon.Parent = preview

	local nameLbl = Instance.new("TextLabel")
	nameLbl.Name = "Label"
	nameLbl.Size = UDim2.new(1, -8, 0.22, 0)
	nameLbl.Position = UDim2.new(0.5, 0, 1, -4)
	nameLbl.AnchorPoint = Vector2.new(0.5, 1)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Text = baseName
	nameLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLbl.Font = Enum.Font.GothamBold
	nameLbl.TextScaled = true
	nameLbl.ZIndex = 7
	nameLbl.Parent = preview

	local fxTag = Instance.new("TextLabel")
	fxTag.Name = "FX"
	fxTag.Size = UDim2.fromOffset(26, 15)
	fxTag.Position = UDim2.new(0, 4, 0, 4)
	fxTag.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
	fxTag.BackgroundTransparency = 0.2
	fxTag.Text = "FX"
	fxTag.TextColor3 = Color3.fromRGB(255, 215, 90)
	fxTag.Font = Enum.Font.GothamBold
	fxTag.TextSize = 11
	fxTag.ZIndex = 8
	fxTag.Parent = preview
end

local function hideOtherToolsVisuals(char)
	table.clear(hiddenToolParts)
	for _, container in ipairs({ char, player:FindFirstChild("Backpack") }) do
		if container then
			for _, obj in ipairs(container:GetDescendants()) do
				if obj:IsA("Tool") and obj.Name ~= "GS_Hand_Handle" then
					for _, desc in ipairs(obj:GetDescendants()) do
						if desc:IsA("BasePart") then
							hiddenToolParts[desc] = desc.LocalTransparencyModifier
							desc.LocalTransparencyModifier = 1
						end
					end
				end
			end
		end
	end
end

local function restoreOtherToolsVisuals()
	for part, oldMod in pairs(hiddenToolParts) do
		if part and part.Parent then
			part.LocalTransparencyModifier = oldMod or 0
		end
	end
	table.clear(hiddenToolParts)

	local char = player.Character
	for _, container in ipairs({ char, player:FindFirstChild("Backpack") }) do
		if container then
			for _, obj in ipairs(container:GetDescendants()) do
				if obj:IsA("Tool") and obj.Name ~= "GS_Hand_Handle" then
					for _, desc in ipairs(obj:GetDescendants()) do
						if desc:IsA("BasePart") then
							desc.LocalTransparencyModifier = 0
						end
					end
				end
			end
		end
	end
end

local function clearHandVisuals()
	if activeHandHandle then
		pcall(function()
			activeHandHandle:Destroy()
		end)
		activeHandHandle = nil
	end
	if holdTrack then
		pcall(function()
			holdTrack:Stop()
			holdTrack:Destroy()
		end)
		holdTrack = nil
	end
	restoreOtherToolsVisuals()
end

local function applyHandVisuals(targetChar, targetHum, targetHand)
	clearHandVisuals()
	if not isEquipped then return end

	local char = targetChar or player.Character
	local hum = targetHum or (char and char:FindFirstChildOfClass("Humanoid"))
	local hand = targetHand or (char and (char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm")))
	if not char or not char.Parent or not hand or not hand.Parent then return end

	hideOtherToolsVisuals(char)

	local handle = createGunHandleClone()
	if handle then
		handle.Name = "GS_Hand_Handle"
		handle.Anchored = false
		handle.CanCollide = false
		handle.Massless = true
		handle.CFrame = hand.CFrame * CFrame.new(0, -0.15, -0.45) * CFrame.Angles(math.rad(-90), 0, 0)
		handle.Parent = char

		local weld = Instance.new("WeldConstraint")
		weld.Part0 = hand
		weld.Part1 = handle
		weld.Parent = handle

		activeHandHandle = handle
	end

	if assets.Anim and hum then
		local ok, tr = pcall(function()
			return hum:LoadAnimation(assets.Anim)
		end)
		if ok and tr then
			tr.Priority = Enum.AnimationPriority.Action
			tr.Looped = true
			pcall(function()
				tr:Play()
			end)
			holdTrack = tr
		end
	end
end

local function fireBeam(inputPos)
	if not isEquipped then return end
	local now = os.clock()
	if now - lastEquipTime < EQUIP_FIRE_DELAY then return end
	if now - lastFireTime < FIRE_COOLDOWN then return end
	lastFireTime = now

	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local cam = workspace.CurrentCamera
	if not hrp or not cam then return end

	if assets.Sound then
		local snd = assets.Sound:Clone()
		snd.Parent = hrp
		snd:Play()
		Debris:AddItem(snd, 4)
	else
		local snd = Instance.new("Sound")
		snd.SoundId = "rbxassetid://131961136"
		snd.Volume = 0.7
		snd.Parent = hrp
		snd:Play()
		Debris:AddItem(snd, 2)
	end

	local screenPos = inputPos or UserInputService:GetMouseLocation()
	local ray = cam:ViewportPointToRay(screenPos.X, screenPos.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { char }

	local hit = workspace:Raycast(ray.Origin, ray.Direction * 250, params)
	local endPos = hit and hit.Position or (ray.Origin + ray.Direction * 120)

	local endPart = Instance.new("Part")
	endPart.Name = "GS_BeamEndPart"
	endPart.Anchored = true
	endPart.CanCollide = false
	endPart.Transparency = 1
	endPart.Size = Vector3.new(0.1, 0.1, 0.1)
	endPart.CFrame = CFrame.new(endPos)
	endPart.Parent = workspace

	local att1 = Instance.new("Attachment")
	att1.Name = "GS_BeamAtt1"
	att1.Parent = endPart

	local att0 = findMuzzleAttachment(activeHandHandle) or findMuzzleAttachment(assets.Model)
	local tempStartPart = nil
	local createdTempAtt0 = false

	if not att0 then
		if activeHandHandle and activeHandHandle.Parent then
			att0 = Instance.new("Attachment")
			att0.Name = "GS_BeamAtt0"
			att0.Position = Vector3.new(0, 0, -0.7)
			att0.Parent = activeHandHandle
			createdTempAtt0 = true
		else
			tempStartPart = Instance.new("Part")
			tempStartPart.Name = "GS_BeamStartPart"
			tempStartPart.Anchored = true
			tempStartPart.CanCollide = false
			tempStartPart.Transparency = 1
			tempStartPart.Size = Vector3.new(0.1, 0.1, 0.1)
			tempStartPart.CFrame = CFrame.new(hrp.Position + hrp.CFrame.LookVector * 2 + Vector3.new(0, 0.6, 0))
			tempStartPart.Parent = workspace

			att0 = Instance.new("Attachment")
			att0.Name = "GS_BeamAtt0"
			att0.Parent = tempStartPart
			createdTempAtt0 = true
		end
	end

	local beam = assets.Beam and assets.Beam:Clone() or Instance.new("Beam")
	if not assets.Beam then
		beam.Width0 = 0.16
		beam.Width1 = 0.04
		beam.FaceCamera = true
	end

	beam.Attachment0 = att0
	beam.Attachment1 = att1
	beam.Enabled = true
	beam.Parent = att0.Parent

	task.delay(0.16, function()
		if beam and beam.Parent then
			beam.Enabled = false
		end
	end)

	Debris:AddItem(beam, 0.22)
	Debris:AddItem(att1, 0.22)
	Debris:AddItem(endPart, 0.22)
	if createdTempAtt0 and att0 then
		Debris:AddItem(att0, 0.22)
	end
	if tempStartPart then
		Debris:AddItem(tempStartPart, 0.22)
	end
end

local invSlotGui = Instance.new("ScreenGui")
invSlotGui.Name = "GS_InventorySlot_UI"
invSlotGui.ResetOnSpawn = false
invSlotGui.IgnoreGuiInset = true
invSlotGui.Parent = playerGui

local slotBtn = Instance.new("TextButton")
slotBtn.Visible = false
slotBtn.Size = UDim2.fromOffset(175, 36)
slotBtn.Position = UDim2.new(0.5, -87.5, 1, -54)
slotBtn.BackgroundColor3 = Color3.fromRGB(32, 32, 40)
slotBtn.Text = tostring(gsEntry.ItemName or TARGET_KEY)
slotBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
slotBtn.Font = Enum.Font.GothamBold
slotBtn.TextSize = 12
slotBtn.Parent = invSlotGui

local function refreshEquipVisuals()
	local baseName = tostring(gsEntry.ItemName or TARGET_KEY)
	if currentCardNameLabel and currentCardNameLabel:IsA("TextLabel") then
		currentCardNameLabel.Text = baseName
	end
	if currentCardRoot and currentCardRoot:IsA("GuiObject") then
		local stroke = currentCardRoot:FindFirstChild("GS_EquippedStroke")
		if not stroke then
			stroke = Instance.new("UIStroke")
			stroke.Name = "GS_EquippedStroke"
			stroke.Parent = currentCardRoot
		end
		stroke.Color = Color3.fromRGB(85, 165, 255)
		stroke.Thickness = isEquipped and 2 or 0
		stroke.Enabled = isEquipped
	end
	slotBtn.BackgroundColor3 = isEquipped and Color3.fromRGB(65, 130, 220) or Color3.fromRGB(32, 32, 40)
	slotBtn.Text = baseName
	updateEquippedGunSlot()
end

local function setEquipped(state)
	isEquipped = state
	if isEquipped then
		lastEquipTime = os.clock()
		lastFireTime = lastEquipTime
		applyHandVisuals()
	else
		clearHandVisuals()
	end
	refreshEquipVisuals()
	updateGunDisplay()
end

local function toggleGingerscopeEquip()
	if not isClaimed then return end
	setEquipped(not isEquipped)
end

slotBtn.MouseButton1Click:Connect(toggleGingerscopeEquip)

local function isChristmasSectionElement(guiObj)
	local n = guiObj.Name:lower()
	if n:find("christmas", 1, true) or n:find("rozhdestv", 1, true) then
		return true
	end
	if guiObj:IsA("TextLabel") or guiObj:IsA("TextButton") then
		local txt = tostring(guiObj.Text):lower()
		if txt:find("christmas", 1, true) or txt:find("рождеств", 1, true) then
			return true
		end
	end
	local lbl = guiObj:FindFirstChildWhichIsA("TextLabel", true)
	if lbl then
		local txt = tostring(lbl.Text):lower()
		if txt:find("christmas", 1, true) or txt:find("рождеств", 1, true) then
			return true
		end
	end
	return false
end

local function computeCardLayoutOrder(listContainer)
	local christmasOrder = nil
	local maxOrder = 0

	for _, child in ipairs(listContainer:GetChildren()) do
		if child:IsA("GuiObject") and child.Name ~= "GS_InventoryCard" then
			local o = child.LayoutOrder or 0
			if o > maxOrder then
				maxOrder = o
			end
			if isChristmasSectionElement(child) then
				if christmasOrder == nil or o > christmasOrder then
					christmasOrder = o
				end
			end
		end
	end

	if christmasOrder ~= nil then
		return christmasOrder + 1
	end
	return maxOrder + 1
end

local function findInventoryListContainer()
	local inv2 = gameGui:FindFirstChild("Inventory2")
	local inv2Main = inv2 and inv2:FindFirstChild("Main")
	local inv2Weapons = inv2Main and inv2Main:FindFirstChild("Weapons")
	local inv2Items = inv2Weapons and inv2Weapons:FindFirstChild("Items")
	local inv2List = inv2Items and inv2Items:FindFirstChild("ItemList")
	if inv2List and inv2List:IsA("GuiObject") then
		return inv2List
	end

	local invRoots = {
		gameGui:FindFirstChild("Inventory"),
		mainGui:FindFirstChild("Inventory"),
		inv2,
	}

	for _, root in ipairs(invRoots) do
		if root then
			for _, desc in ipairs(root:GetDescendants()) do
				if (desc:IsA("GuiObject") or desc:IsA("ScrollingFrame")) and desc.Name:lower():find("christmas", 1, true) then
					if desc:FindFirstChildWhichIsA("UIGridLayout", true) or desc:IsA("ScrollingFrame") then
						return desc
					end
				end
			end
		end
	end

	for _, root in ipairs(invRoots) do
		if root then
			for _, desc in ipairs(root:GetDescendants()) do
				if desc:IsA("UIGridLayout") and desc.Parent and desc.Parent:IsA("GuiObject") then
					return desc.Parent
				end
			end
		end
	end

	for _, root in ipairs(invRoots) do
		if root then
			local sf = root:FindFirstChildWhichIsA("ScrollingFrame", true)
			if sf then
				return sf
			end
		end
	end

	return nil
end

local function bindOtherItemButton(btn)
	if hookedButtons[btn] then return end
	if currentCardRoot and btn:IsDescendantOf(currentCardRoot) then return end
	if btn.Name == "GS_CardHitButton" then return end

	hookedButtons[btn] = true
	local function onOtherClick()
		if isEquipped then
			setEquipped(false)
		end
	end
	btn.MouseButton1Click:Connect(onOtherClick)
	pcall(function()
		btn.Activated:Connect(onOtherClick)
	end)
end

local function applyFxBadge(card, cont, usedNativeDisplay)
	local tagsFolder = card:FindFirstChild("Tags")
	local foundFxObj = nil

	if tagsFolder then
		for _, tag in ipairs(tagsFolder:GetChildren()) do
			if tag:IsA("GuiObject") then
				local lowerName = tag.Name:lower()
				local isFxTag = (tag.Name == "FX") or (lowerName == "fx") or lowerName:find("fx", 1, true) ~= nil
				local isChristmasTag = (tag.Name == "Christmas") or lowerName:find("christmas", 1, true) ~= nil

				if isFxTag then
					foundFxObj = tag
					tag.Visible = true
					for _, sub in ipairs(tag:GetDescendants()) do
						if sub:IsA("GuiObject") then
							sub.Visible = true
						end
						if sub:IsA("ImageLabel") or sub:IsA("ImageButton") then
							if sub.ImageTransparency >= 0.99 then
								sub.ImageTransparency = 0
							end
						elseif sub:IsA("TextLabel") or sub:IsA("TextButton") then
							if sub.TextTransparency >= 0.99 then
								sub.TextTransparency = 0
							end
							local subName = sub.Name:lower()
							if sub.Text == "" or subName:find("fx", 1, true) or subName:find("tag", 1, true) or subName:find("label", 1, true) then
								sub.Text = "FX"
							end
						end
					end
				elseif isChristmasTag then
					tag.Visible = true
					for _, sub in ipairs(tag:GetDescendants()) do
						if sub:IsA("GuiObject") then
							sub.Visible = true
						end
						if sub:IsA("TextLabel") and sub.Name:lower():find("year", 1, true) then
							sub.Text = tostring(gsEntry.Year or 2023)
						end
					end
				elseif not usedNativeDisplay then
					tag.Visible = false
				end
			end
		end
	end

	if not foundFxObj then
		for _, desc in ipairs(card:GetDescendants()) do
			if desc:IsA("GuiObject") and desc.Name ~= "GS_InventoryCard" then
				local dn = desc.Name:lower()
				if dn == "fx" or dn:find("fxtag", 1, true) then
					foundFxObj = desc
					desc.Visible = true
					if desc:IsA("TextLabel") and desc.Text == "" then
						desc.Text = "FX"
					end
					break
				end
			end
		end
	end

	if not foundFxObj then
		local parentForBadge = cont or card
		local oldBadge = parentForBadge:FindFirstChild("GS_FX_Badge")
		if oldBadge then
			oldBadge:Destroy()
		end

		local badge = Instance.new("TextLabel")
		badge.Name = "GS_FX_Badge"
		badge.Size = UDim2.fromOffset(28, 16)
		badge.Position = UDim2.new(0, 4, 0, 4)
		badge.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
		badge.BackgroundTransparency = 0.15
		badge.Text = "FX"
		badge.TextColor3 = Color3.fromRGB(255, 215, 90)
		badge.Font = Enum.Font.GothamBold
		badge.TextSize = 11
		badge.ZIndex = 15
		badge.Parent = parentForBadge
	end
end

local function addGingerscopeToInventoryUI()
	local listContainer = findInventoryListContainer()
	local template = findInventoryCardTemplate()
	if not listContainer or not template then
		return false
	end

	hookOtherInventoryButtons(listContainer)

	if currentCardRoot and currentCardRoot.Parent == listContainer then
		currentCardRoot.Visible = true
		currentCardRoot.LayoutOrder = computeCardLayoutOrder(listContainer)
		local cont = currentCardRoot:FindFirstChild("Container")
		applyFxBadge(currentCardRoot, cont, true)
		refreshEquipVisuals()
		slotBtn.Visible = false
		return true
	end

	for _, child in ipairs(listContainer:GetChildren()) do
		if child.Name == "GS_InventoryCard" then
			child:Destroy()
		end
	end

	local card = template:Clone()
	card.Name = "GS_InventoryCard"
	card:SetAttribute("ItemID", TARGET_ID)
	card.Visible = true
	card.LayoutOrder = computeCardLayoutOrder(listContainer)
	card.Parent = listContainer
	currentCardRoot = card

	_G.Cache = _G.Cache or {}
	_G.SmallCache = _G.SmallCache or {}

	local baseName = tostring(gsEntry.ItemName or TARGET_KEY)
	local displayData = {
		ItemName = baseName,
		Name = baseName,
		ItemID = TARGET_ID,
		Rarity = gsEntry.Rarity or "Ancient",
		Event = gsEntry.Event or "Christmas",
		Year = gsEntry.Year or 2023,
		DataType = "Weapons",
		FX = true,
		Image = assets.Image or FALLBACK_ICON,
	}

	local usedNativeDisplay = false
	if itemModule and type(itemModule.DisplayItem) == "function"
		and card:FindFirstChild("ItemName")
		and card:FindFirstChild("Container")
	then
		usedNativeDisplay = pcall(itemModule.DisplayItem, card, displayData, 1, false)
	end

	local itemNameFrame = card:FindFirstChild("ItemName")
	local nameLabel = itemNameFrame and itemNameFrame:FindFirstChild("Label")
	currentCardNameLabel = nameLabel
	if nameLabel and nameLabel:IsA("TextLabel") then
		nameLabel.Text = baseName
	end

	local cont = card:FindFirstChild("Container")
	local icon = cont and cont:FindFirstChild("Icon")
	if icon and icon:IsA("ImageLabel") then
		if not usedNativeDisplay or icon.Image == "" or icon.Image == "rbxassetid://0" then
			icon.Image = assets.Image or FALLBACK_ICON
		end
		icon.Visible = true
	end

	local amountLbl = cont and cont:FindFirstChild("Amount")
	if amountLbl and amountLbl:IsA("TextLabel") then
		amountLbl.Text = "x1"
	end

	applyFxBadge(card, cont, usedNativeDisplay)

	local actionBtn = cont and cont:FindFirstChild("ActionButton")
	local clickTarget = (actionBtn and actionBtn:IsA("GuiButton") and actionBtn) or (card:IsA("GuiButton") and card)

	if clickTarget then
		if clickTarget:IsA("TextButton") or clickTarget:IsA("ImageButton") then
			clickTarget.MouseButton1Click:Connect(toggleGingerscopeEquip)
		end
		pcall(function()
			clickTarget.Activated:Connect(toggleGingerscopeEquip)
		end)
	elseif card:IsA("GuiObject") then
		local hitBtn = Instance.new("TextButton")
		hitBtn.Name = "GS_CardHitButton"
		hitBtn.Size = UDim2.fromScale(1, 1)
		hitBtn.BackgroundTransparency = 1
		hitBtn.Text = ""
		hitBtn.ZIndex = 20
		hitBtn.Parent = card
		hitBtn.MouseButton1Click:Connect(toggleGingerscopeEquip)
		pcall(function()
			hitBtn.Activated:Connect(toggleGingerscopeEquip)
		end)
	end

	refreshEquipVisuals()
	slotBtn.Visible = false
	return true
end

function findInventoryCardTemplate()
	local rsMain = ReplicatedStorage:FindFirstChild("MainGUI")
	local rsInv = rsMain and rsMain:FindFirstChild("Inventory")
	local rsInvScript = rsInv and rsInv:FindFirstChild("Inventory")
	if rsInvScript and rsInvScript:FindFirstChild("ItemOld") then
		return rsInvScript.ItemOld
	end

	local rsInv2 = rsMain and rsMain:FindFirstChild("Inventory2")
	if rsInv2 then
		local eq = rsInv2:FindFirstChild("EquipContainer")
		if eq and eq:FindFirstChild("ItemFrame") then
			return eq.ItemFrame
		end
	end

	return nil
end

function hookOtherInventoryButtons(listContainer)
	if not listContainer then return end
	for _, desc in ipairs(listContainer:GetDescendants()) do
		if desc:IsA("TextButton") or desc:IsA("ImageButton") then
			bindOtherItemButton(desc)
		end
	end

	if not hookedContainers[listContainer] then
		hookedContainers[listContainer] = true
		listContainer.DescendantAdded:Connect(function(desc)
			if desc:IsA("TextButton") or desc:IsA("ImageButton") then
				bindOtherItemButton(desc)
			end
		end)

		listContainer.ChildRemoved:Connect(function(child)
			if isClaimed and child.Name == "GS_InventoryCard" then
				task.defer(function()
					if isClaimed and (not currentCardRoot or not currentCardRoot.Parent) then
						addGingerscopeToInventoryUI()
					end
				end)
			end
		end)
	end
end

local function hookInventory2FiltersAndRefresh()
	local inv2 = gameGui:FindFirstChild("Inventory2")
	if not inv2 then return end

	local function watchBtn(btn)
		if not btn or not (btn:IsA("TextButton") or btn:IsA("ImageButton")) then return end
		if hookedFilterControls[btn] then return end
		hookedFilterControls[btn] = true

		btn.MouseButton1Click:Connect(function()
			if isClaimed then
				task.defer(addGingerscopeToInventoryUI)
			end
		end)
		pcall(function()
			btn.Activated:Connect(function()
				if isClaimed then
					task.defer(addGingerscopeToInventoryUI)
				end
			end)
		end)
	end

	local nav = inv2:FindFirstChild("Nav")
	if nav then
		for _, child in ipairs(nav:GetChildren()) do
			watchBtn(child)
		end
	end

	local main = inv2:FindFirstChild("Main")
	local weapons = main and main:FindFirstChild("Weapons")
	local items = weapons and weapons:FindFirstChild("Items")
	local tabs = items and items:FindFirstChild("Tabs")
	if tabs then
		for _, tabName in ipairs({ "Current", "Classic", "Event" }) do
			local tabObj = tabs:FindFirstChild(tabName)
			if tabObj then
				local viewBtn = tabObj:FindFirstChild("View")
				watchBtn(viewBtn or tabObj)
			end
		end

		local searchFrame = tabs:FindFirstChild("Search")
		local searchCont = searchFrame and searchFrame:FindFirstChild("Container")
		local searchBox = searchCont and searchCont:FindFirstChild("SearchText")
		if searchBox and searchBox:IsA("TextBox") and not hookedFilterControls[searchBox] then
			hookedFilterControls[searchBox] = true
			searchBox:GetPropertyChangedSignal("Text"):Connect(function()
				if isClaimed then
					task.defer(addGingerscopeToInventoryUI)
				end
			end)
		end
	end
end

local function hookInventoryVisibilityRefresh()
	hookInventory2FiltersAndRefresh()

	local invRoots = {
		gameGui:FindFirstChild("Inventory"),
		gameGui:FindFirstChild("Inventory2"),
		mainGui:FindFirstChild("Inventory"),
		mainGui:FindFirstChild("Inventory2"),
	}

	for _, root in ipairs(invRoots) do
		if root and root:IsA("GuiObject") and not hookedVisibility[root] then
			hookedVisibility[root] = true
			root:GetPropertyChangedSignal("Visible"):Connect(function()
				if isClaimed and root.Visible then
					task.defer(addGingerscopeToInventoryUI)
				end
			end)
		end
	end
end

hookInventoryVisibilityRefresh()

task.spawn(function()
	while true do
		task.wait(INVENTORY_GUARD_INTERVAL)
		if isClaimed then
			local listContainer = findInventoryListContainer()
			if listContainer then
				hookOtherInventoryButtons(listContainer)
				local cardMissing = (not currentCardRoot) or (not currentCardRoot.Parent) or (currentCardRoot.Parent ~= listContainer)
				local cardHidden = currentCardRoot and not currentCardRoot.Visible
				if cardMissing or cardHidden then
					pcall(addGingerscopeToInventoryUI)
				end
			end
		end
	end
end)

local function openNativeNewItem()
	centerNewItemWindow()
	if _G.NewItem then
		_G.NewItem(TARGET_KEY, "You Got...", nil, "Weapons", 1)
	end

	local container = newItemFrame:FindFirstChild("Container")
	local innerItem = container and container:FindFirstChild("NewItem")
	if innerItem and itemModule.DisplayItem then
		_G.Cache = _G.Cache or {}
		_G.SmallCache = _G.SmallCache or {}
		pcall(itemModule.DisplayItem, innerItem, gsEntry, 1)
	end

	local icon = innerItem and innerItem:FindFirstChild("Container") and innerItem.Container:FindFirstChild("Icon")
	if icon and icon:IsA("ImageLabel") and (icon.Image == "" or icon.Image == "rbxassetid://0") then
		icon.Image = assets.Image
	end

	if Lighting:FindFirstChild("NewItemBlur") then
		Lighting.NewItemBlur.Enabled = true
	end
	newItemFrame.Visible = true
end

local function playFallbackFlyToTarget(iconObj, targetGuiObj)
	local flyer = Instance.new("ImageLabel")
	flyer.Name = "GS_FlyIcon"
	flyer.Size = UDim2.fromOffset(64, 64)
	flyer.Position = UDim2.fromScale(0.5, 0.5)
	flyer.AnchorPoint = Vector2.new(0.5, 0.5)
	flyer.BackgroundTransparency = 1
	flyer.Image = (iconObj and iconObj:IsA("ImageLabel") and iconObj.Image ~= "" and iconObj.Image) or assets.Image
	flyer.ZIndex = 70
	flyer.Parent = invSlotGui

	local dest = targetGuiObj or slotBtn
	local targetPos = UDim2.fromOffset(
		dest.AbsolutePosition.X + dest.AbsoluteSize.X * (1 - dest.AnchorPoint.X),
		dest.AbsolutePosition.Y + dest.AbsoluteSize.Y * (1 - dest.AnchorPoint.Y)
	)

	local tw = TweenService:Create(flyer, TweenInfo.new(0.42, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = targetPos,
		Size = UDim2.fromOffset(32, 32),
	})
	tw:Play()
	tw.Completed:Connect(function()
		flyer:Destroy()
	end)
end

claimBtn.MouseButton1Click:Connect(function()
	if isClaimed then return end
	isClaimed = true
	hookInventoryVisibilityRefresh()

	local container = newItemFrame:FindFirstChild("Container")
	local innerItem = container and container:FindFirstChild("NewItem")
	local iconObj = innerItem and innerItem:FindFirstChild("Container") and innerItem.Container:FindFirstChild("Icon")
	local dockInv = gameGui:FindFirstChild("Dock") and gameGui.Dock:FindFirstChild("Inventory")

	local nativeAnimOk = false
	if iconObj and dockInv and itemModule.AnimateItemIconIntoInventory then
		nativeAnimOk = pcall(itemModule.AnimateItemIconIntoInventory, iconObj, dockInv, gameGui)
	end

	newItemFrame.Visible = false
	if Lighting:FindFirstChild("NewItemBlur") then
		Lighting.NewItemBlur.Enabled = false
	end

	local addedToUi = addGingerscopeToInventoryUI()
	if not addedToUi then
		slotBtn.Visible = true
	end

	if not nativeAnimOk then
		playFallbackFlyToTarget(iconObj, addedToUi and dockInv or slotBtn)
	end

	updateGunDisplay()
end)

mainGui.DescendantAdded:Connect(function(desc)
	if isClaimed then
		hookInventoryVisibilityRefresh()
		if desc:IsA("UIGridLayout") then
			task.defer(addGingerscopeToInventoryUI)
		end
	end
end)

local function waitForRightHand(char, timeout)
	local deadline = os.clock() + (timeout or 6)
	while char.Parent and os.clock() < deadline do
		local hand = char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm")
		if hand and hand:IsA("BasePart") then
			return hand
		end
		task.wait(0.05)
	end
	return char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm")
end

local function hookCharacter(char)
	characterGeneration += 1
	local myGen = characterGeneration

	if holdTrack then
		pcall(function()
			holdTrack:Stop()
			holdTrack:Destroy()
		end)
		holdTrack = nil
	end
	activeHandHandle = nil
	table.clear(hiddenToolParts)

	char.ChildAdded:Connect(function(child)
		if myGen ~= characterGeneration or player.Character ~= char then return end
		if child:IsA("Tool") and child.Name ~= "GS_Hand_Handle" and isEquipped then
			task.defer(function()
				if myGen == characterGeneration and player.Character == char and isEquipped then
					hideOtherToolsVisuals(char)
				end
			end)
		end
	end)

	task.spawn(function()
		local hum = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 6)
		local hand = waitForRightHand(char, 6)
		if myGen ~= characterGeneration or player.Character ~= char or not char.Parent then
			return
		end

		if isEquipped and hum and hand then
			applyHandVisuals(char, hum, hand)
		end
		refreshEquipVisuals()
		updateGunDisplay()
	end)
end

if player.Character then
	hookCharacter(player.Character)
end
player.CharacterAdded:Connect(hookCharacter)

UserInputService.InputBegan:Connect(function(input, gp)
	if gp or not isEquipped then return end
	if os.clock() - lastEquipTime < EQUIP_FIRE_DELAY then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		fireBeam(input.Position)
	end
end)

openNativeNewItem()
