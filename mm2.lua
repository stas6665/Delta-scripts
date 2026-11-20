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

local TARGET_KEY = "Gingerscope"
local TARGET_ID = 15617843269
local FALLBACK_ICON = "rbxassetid://" .. tostring(TARGET_ID)

local isClaimed = false
local isEquipped = false
local activeHandHandle = nil
local holdTrack = nil
local currentCardNameLabel = nil
local currentCardRoot = nil
local hiddenToolParts = {}
local hookedButtons = setmetatable({}, { __mode = "k" })

local gsEntry = (syncDb.Weapons and syncDb.Weapons[TARGET_KEY]) or {
	ItemName = "Gingerscope",
	ItemType = "Gun",
	Rarity = "Ancient",
	Event = "Christmas",
	Year = 2023,
	ItemID = TARGET_ID,
}

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

local function findGingerscopeAssets()
	local found = {
		Model = nil,
		Sound = nil,
		Anim = nil,
		Beam = nil,
		Image = gsEntry.Image or FALLBACK_ICON,
	}
	local idStr = tostring(TARGET_ID)

	for _, root in ipairs({ ReplicatedStorage, workspace }) do
		for _, obj in ipairs(root:GetDescendants()) do
			local n = obj.Name:lower()
			local matchName = n:find("gingerscope") ~= nil
			local matchId = false

			if obj:IsA("Model") or obj:IsA("Tool") or obj:IsA("MeshPart") or obj:IsA("SpecialMesh") then
				local meshId = (obj:IsA("MeshPart") and tostring(obj.MeshId))
					or (obj:IsA("SpecialMesh") and tostring(obj.MeshId))
					or ""
				if meshId:find(idStr) or tostring(obj:GetAttribute("ItemID") or "") == idStr then
					matchId = true
				end
			end

			if matchName or matchId then
				if not found.Model and (obj:IsA("Model") or obj:IsA("Tool") or obj:IsA("MeshPart") or obj:IsA("BasePart")) then
					found.Model = obj
				elseif not found.Sound and obj:IsA("Sound") then
					found.Sound = obj
				elseif not found.Anim and obj:IsA("Animation") then
					found.Anim = obj
				elseif not found.Beam and obj:IsA("Beam") then
					found.Beam = obj
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
			if n:find("muzzle") or n:find("shoot") or n:find("fire") or n:find("tip") or n:find("barrel") or n:find("beam") then
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

	local handle
	if src and src:IsA("BasePart") then
		handle = src:Clone()
	else
		handle = Instance.new("Part")
		handle.Size = Vector3.new(0.25, 0.85, 1.4)
		handle.Color = Color3.fromRGB(190, 45, 45)
		handle.Material = Enum.Material.Neon
	end

	handle.Name = "Handle"
	handle.LocalTransparencyModifier = 0
	return handle
end

local function updateGunDisplay()
	for _, container in ipairs({ workspace, playerGui }) do
		for _, d in ipairs(container:GetDescendants()) do
			if d.Name == "GS_GunDisplay_Handle" then
				d:Destroy()
			end
			if isEquipped and d.Name:lower():find("gundisplay") then
				if d:IsA("BasePart") or d:IsA("Model") then
					local anchor = d:IsA("Model") and (d.PrimaryPart or d:FindFirstChildWhichIsA("BasePart")) or d
					if anchor then
						local handle = createGunHandleClone()
						handle.Name = "GS_GunDisplay_Handle"
						handle.Anchored = true
						handle.CanCollide = false
						handle.CFrame = anchor.CFrame * CFrame.new(0, 1.5, 0)
						handle.Parent = d
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
		end
	end
end

local function hideOtherToolsVisuals(char)
	table.clear(hiddenToolParts)
	for _, container in ipairs({ char, player:FindFirstChild("Backpack") }) do
		if container then
			for _, obj in ipairs(container:GetDescendants()) do
				if obj:IsA("Tool") then
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
				if obj:IsA("Tool") then
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
		activeHandHandle:Destroy()
		activeHandHandle = nil
	end
	if holdTrack then
		holdTrack:Stop()
		holdTrack:Destroy()
		holdTrack = nil
	end
	restoreOtherToolsVisuals()
end

local function applyHandVisuals()
	clearHandVisuals()
	if not isEquipped then return end

	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local hand = char and (char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm"))
	if not char or not hand then return end

	hideOtherToolsVisuals(char)

	local handle = createGunHandleClone()
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

	if assets.Anim and hum then
		local ok, tr = pcall(function() return hum:LoadAnimation(assets.Anim) end)
		if ok and tr then
			tr.Priority = Enum.AnimationPriority.Action
			tr.Looped = true
			tr:Play()
			holdTrack = tr
		end
	end
end

local function fireBeam(inputPos)
	if not isEquipped then return end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local cam = workspace.CurrentCamera
	if not hrp or not cam then return end

	if assets.Sound then
		local snd = assets.Sound:Clone()
		snd.Parent = workspace
		snd:Play()
		Debris:AddItem(snd, 4)
	else
		local snd = Instance.new("Sound")
		snd.SoundId = "rbxassetid://131961136"
		snd.Volume = 0.7
		snd.Parent = workspace
		snd:Play()
		Debris:AddItem(snd, 2)
	end

	local screenPos = inputPos or UserInputService:GetMouseLocation()
	local ray = cam:ViewportPointToRay(screenPos.X, screenPos.Y)
	local hit = workspace:Raycast(ray.Origin, ray.Direction * 250)
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

	if not att0 then
		if activeHandHandle then
			att0 = Instance.new("Attachment")
			att0.Name = "GS_BeamAtt0"
			att0.Position = Vector3.new(0, 0, -0.7)
			att0.Parent = activeHandHandle
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
		end
	end

	local beam
	if assets.Beam then
		beam = assets.Beam:Clone()
	else
		beam = Instance.new("Beam")
		beam.Width0 = 0.16
		beam.Width1 = 0.04
		beam.FaceCamera = true
	end

	beam.Attachment0 = att0
	beam.Attachment1 = att1
	beam.Enabled = true
	beam.Parent = att0.Parent

	Debris:AddItem(beam, 0.22)
	Debris:AddItem(att1, 0.22)
	Debris:AddItem(endPart, 0.22)
	if att0.Name == "GS_BeamAtt0" then
		Debris:AddItem(att0, 0.22)
	end
	if tempStartPart then
		Debris:AddItem(tempStartPart, 0.22)
	end
end

local invSlotGui = Instance.new("ScreenGui")
invSlotGui.Name = "GS_InventorySlot_UI"
invSlotGui.ResetOnSpawn = false
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
		currentCardNameLabel.Text = isEquipped and (baseName .. " [E]") or baseName
	end
	slotBtn.BackgroundColor3 = isEquipped and Color3.fromRGB(65, 130, 220) or Color3.fromRGB(32, 32, 40)
	slotBtn.Text = isEquipped and (baseName .. " [E]") or baseName
end

local function setEquipped(state)
	isEquipped = state
	if isEquipped then
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

local function findInventoryListContainer()
	local invRoots = {
		mainGui:FindFirstChild("Game") and mainGui.Game:FindFirstChild("Inventory"),
		mainGui:FindFirstChild("Inventory"),
		mainGui:FindFirstChild("Inventory2"),
	}

	for _, root in ipairs(invRoots) do
		if root then
			for _, desc in ipairs(root:GetDescendants()) do
				if (desc:IsA("GuiObject") or desc:IsA("ScrollingFrame")) and desc.Name:lower():find("christmas") then
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
	btn.MouseButton1Click:Connect(function()
		if isEquipped then
			setEquipped(false)
		end
	end)
end

local function hookOtherInventoryButtons(listContainer)
	if not listContainer then return end
	for _, desc in ipairs(listContainer:GetDescendants()) do
		if desc:IsA("TextButton") or desc:IsA("ImageButton") then
			bindOtherItemButton(desc)
		end
	end
end

local function findInventoryCardTemplate()
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

local function addGingerscopeToInventoryUI()
	local listContainer = findInventoryListContainer()
	local template = findInventoryCardTemplate()
	if not listContainer or not template then
		return false
	end

	local existing = listContainer:FindFirstChild("GS_InventoryCard")
	if existing then
		existing:Destroy()
	end

	local card = template:Clone()
	card.Name = "GS_InventoryCard"
	card.Visible = true
	card.LayoutOrder = -9999
	card.Parent = listContainer
	currentCardRoot = card

	local itemNameFrame = card:FindFirstChild("ItemName")
	local nameLabel = itemNameFrame and itemNameFrame:FindFirstChild("Label")
	currentCardNameLabel = nameLabel
	if nameLabel and nameLabel:IsA("TextLabel") then
		nameLabel.Text = isEquipped and (tostring(gsEntry.ItemName or TARGET_KEY) .. " [E]") or tostring(gsEntry.ItemName or TARGET_KEY)
	end

	local cont = card:FindFirstChild("Container")
	local icon = cont and cont:FindFirstChild("Icon")
	if icon and icon:IsA("ImageLabel") then
		icon.Image = assets.Image
		icon.Visible = true
	end

	local amountLbl = cont and cont:FindFirstChild("Amount")
	if amountLbl and amountLbl:IsA("TextLabel") then
		amountLbl.Text = "x1"
	end

	local tagsFolder = card:FindFirstChild("Tags")
	if tagsFolder then
		for _, tag in ipairs(tagsFolder:GetChildren()) do
			if tag:IsA("GuiObject") then
				local showTag = (tag.Name == "FX" or tag.Name == "Christmas")
				tag.Visible = showTag
				if showTag then
					for _, sub in ipairs(tag:GetDescendants()) do
						if sub:IsA("GuiObject") then
							sub.Visible = true
						end
						if sub:IsA("TextLabel") and sub.Name:lower():find("year") then
							sub.Text = tostring(gsEntry.Year or 2023)
						elseif sub:IsA("TextLabel") and sub.Name:lower():find("tagname") then
							sub.Text = "FX"
						end
					end
				end
			end
		end
	end

	local actionBtn = cont and cont:FindFirstChild("ActionButton")
	local clickTarget = (actionBtn and actionBtn:IsA("GuiButton") and actionBtn) or (card:IsA("GuiButton") and card)

	if clickTarget then
		clickTarget.MouseButton1Click:Connect(toggleGingerscopeEquip)
	elseif card:IsA("GuiObject") then
		local hitBtn = Instance.new("TextButton")
		hitBtn.Name = "GS_CardHitButton"
		hitBtn.Size = UDim2.fromScale(1, 1)
		hitBtn.BackgroundTransparency = 1
		hitBtn.Text = ""
		hitBtn.ZIndex = 20
		hitBtn.Parent = card
		hitBtn.MouseButton1Click:Connect(toggleGingerscopeEquip)
	end

	hookOtherInventoryButtons(listContainer)
	listContainer.DescendantAdded:Connect(function(desc)
		if desc:IsA("TextButton") or desc:IsA("ImageButton") then
			bindOtherItemButton(desc)
		end
	end)

	slotBtn.Visible = false
	return true
end

local function openNativeNewItem()
	centerNewItemWindow()
	if _G.NewItem then
		_G.NewItem(TARGET_KEY, "You Got...", nil, "Weapons", 1)
	end

	local container = newItemFrame:FindFirstChild("Container")
	local innerItem = container and container:FindFirstChild("NewItem")
	if innerItem and itemModule.DisplayItem then
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
		dest.AbsolutePosition.X + dest.AbsoluteSize.X * 0.5,
		dest.AbsolutePosition.Y + dest.AbsoluteSize.Y * 0.5
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
	if isClaimed and desc:IsA("UIGridLayout") then
		task.defer(function()
			addGingerscopeToInventoryUI()
		end)
	end
end)

local function hookCharacter(char)
	char.ChildAdded:Connect(function(child)
		if child:IsA("Tool") and child.Name ~= "GS_Hand_Handle" and isEquipped then
			setEquipped(false)
		end
	end)
	if isEquipped then
		applyHandVisuals()
	end
	updateGunDisplay()
end

if player.Character then
	hookCharacter(player.Character)
end
player.CharacterAdded:Connect(hookCharacter)

UserInputService.InputBegan:Connect(function(input, gp)
	if gp or not isEquipped then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		fireBeam(input.Position)
	end
end)

openNativeNewItem()
