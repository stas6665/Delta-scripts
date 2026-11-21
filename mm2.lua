local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local mainGui = playerGui:WaitForChild("MainGUI")
local gameGui = mainGui:WaitForChild("Game")
local newItemFrame = gameGui:WaitForChild("NewItem")
local claimBtn = newItemFrame:WaitForChild("Container"):WaitForChild("Claim")

local itemModule = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ItemModule"))
local syncDb = require(ReplicatedStorage:WaitForChild("Database"):WaitForChild("Sync"))

local equipService = nil
pcall(function()
	local clientServices = ReplicatedStorage:FindFirstChild("ClientServices")
	if clientServices and clientServices:FindFirstChild("EquipService") then
		equipService = require(clientServices.EquipService)
	end
end)

local TARGET_KEY = "Gingerscope"
local TARGET_ID = 15617843269
local ASSET_ID_URI = "rbxassetid://" .. tostring(TARGET_ID)
local ANCIENT_COLOR = Color3.fromRGB(115, 35, 225)
local ANCIENT_DARK = Color3.fromRGB(65, 15, 145)

local isClaimed = false
local isEquipped = false
local holdTrack = nil
local currentCardNameLabel = nil
local currentCardRoot = nil
local currentCardContainer = nil
local attachedByHandle = setmetatable({}, { __mode = "k" })
local hiddenPartsState = setmetatable({}, { __mode = "k" })
local hookedButtons = setmetatable({}, { __mode = "k" })
local hookedCardSignals = setmetatable({}, { __mode = "k" })

local gsEntry = (syncDb.Weapons and syncDb.Weapons[TARGET_KEY]) or {
	ItemName = "Gingerscope",
	ItemType = "Gun",
	Rarity = "Ancient",
	Event = "Christmas",
	Year = 2023,
	ItemID = TARGET_ID,
}
gsEntry.Rarity = "Ancient"
gsEntry.Event = "Christmas"

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

local function hasTargetId(obj)
	local idStr = tostring(TARGET_ID)
	if tostring(obj:GetAttribute("ItemID") or "") == idStr then
		return true
	end
	if obj:IsA("MeshPart") or obj:IsA("SpecialMesh") then
		if tostring(obj.MeshId):find(idStr) then
			return true
		end
	end
	if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
		if tostring(obj.Image):find(idStr) then
			return true
		end
	end
	return false
end

local function findGingerscopeAssets()
	local found = {
		Item = nil,
		Sound = nil,
		Anim = nil,
		Beam = nil,
		Image = gsEntry.Image or ASSET_ID_URI,
	}

	for _, root in ipairs({ ReplicatedStorage, workspace }) do
		for _, obj in ipairs(root:GetDescendants()) do
			if hasTargetId(obj) or obj.Name:lower():find("gingerscope") then
				if not found.Item and (obj:IsA("MeshPart") or obj:IsA("Model") or obj:IsA("Tool") or obj:IsA("BasePart")) then
					found.Item = obj
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

local function findMuzzleAttachment(rootObj)
	if not rootObj then return nil end
	for _, obj in ipairs(rootObj:GetDescendants()) do
		if obj:IsA("Attachment") then
			local n = obj.Name:lower()
			if n:find("muzzle") or n:find("shoot") or n:find("fire") or n:find("tip") or n:find("barrel") or n:find("beam") then
				return obj
			end
		end
	end
	return rootObj:FindFirstChildWhichIsA("Attachment", true)
end

local function isPistolTool(tool)
	if not tool or not tool:IsA("Tool") then return false end
	if tool.Name == "GS_Gingerscope_Tool" then return false end
	local n = tool.Name:lower()
	if n:find("knife") or n:find("blade") or n:find("dagger") or n:find("scythe") or n:find("axe") or n:find("sword") then
		return false
	end
	if n:find("gun") or n:find("pistol") or n:find("revolver") or n:find("gingerscope") or n:find("blaster") or n:find("raygun") then
		return true
	end
	local itemType = tostring(tool:GetAttribute("ItemType") or tool:GetAttribute("Type") or ""):lower()
	if itemType == "gun" then
		return true
	end
	return tool:FindFirstChild("Handle", true) ~= nil
end

local function collectPistolHandles()
	local handles = {}
	local seen = {}

	local function scanContainer(container)
		if not container then return end
		for _, desc in ipairs(container:GetDescendants()) do
			if desc:IsA("BasePart") and desc.Name == "Handle" and desc.Name ~= "GS_Gingerscope_Handle" then
				local tool = desc:FindFirstAncestorOfClass("Tool")
				if isPistolTool(tool) and not seen[desc] then
					seen[desc] = true
					table.insert(handles, { handle = desc, tool = tool })
				end
			end
		end
	end

	scanContainer(player.Character)
	scanContainer(player:FindFirstChild("Backpack"))

	return handles
end

local function createUnifiedItemClone()
	if assets.Item then
		local clone = assets.Item:Clone()
		for _, desc in ipairs(clone:GetDescendants()) do
			if desc:IsA("BasePart") then
				desc.LocalTransparencyModifier = 0
				desc.Transparency = 0
				desc.Anchored = false
				desc.CanCollide = false
				desc.Massless = true
			end
		end
		if clone:IsA("BasePart") then
			clone.Name = "GS_Gingerscope_Handle"
			clone.LocalTransparencyModifier = 0
			clone.Transparency = 0
			clone.Anchored = false
			clone.CanCollide = false
			clone.Massless = true
		end
		return clone
	end

	local itemPart = Instance.new("MeshPart")
	itemPart.Name = "GS_Gingerscope_Handle"
	itemPart.MeshId = ASSET_ID_URI
	itemPart.Size = Vector3.new(0.3, 1.0, 2.2)
	itemPart.Anchored = false
	itemPart.CanCollide = false
	itemPart.Massless = true
	itemPart.LocalTransparencyModifier = 0
	return itemPart
end

local function hideToolOriginalParts(tool, keepHandle)
	if not tool then return end
	for _, desc in ipairs(tool:GetDescendants()) do
		if desc:IsA("BasePart") and desc ~= keepHandle and desc.Name ~= "GS_Gingerscope_Handle" and not desc:IsDescendantOf(attachedByHandle[keepHandle] or workspace) then
			if not hiddenPartsState[desc] then
				hiddenPartsState[desc] = {
					mod = desc.LocalTransparencyModifier,
					tr = desc.Transparency,
				}
			end
			desc.LocalTransparencyModifier = 1
			desc.Transparency = 1
		end
	end
end

local function restoreHiddenParts()
	for part, state in pairs(hiddenPartsState) do
		if part and part.Parent then
			part.LocalTransparencyModifier = state.mod or 0
			part.Transparency = state.tr or 0
		end
		hiddenPartsState[part] = nil
	end
end

local function attachReplacementToHandle(handle, tool)
	if attachedByHandle[handle] and attachedByHandle[handle].Parent then
		hideToolOriginalParts(tool, handle)
		return attachedByHandle[handle]
	end

	local clone = createUnifiedItemClone()
	clone.Name = "GS_Gingerscope_Handle"

	local primary = nil
	if clone:IsA("BasePart") then
		clone.CFrame = handle.CFrame
		clone.Parent = handle.Parent
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = handle
		weld.Part1 = clone
		weld.Parent = clone
		primary = clone
	elseif clone:IsA("Model") then
		local rootPart = clone.PrimaryPart or clone:FindFirstChild("Handle", true) or clone:FindFirstChildWhichIsA("BasePart", true)
		if rootPart then
			clone.PrimaryPart = rootPart
			clone:PivotTo(handle.CFrame)
			clone.Parent = handle.Parent
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = handle
			weld.Part1 = rootPart
			weld.Parent = rootPart
			primary = rootPart
		end
	end

	if primary then
		attachedByHandle[handle] = clone
		hideToolOriginalParts(tool, handle)
	end

	return primary
end

local function clearAllHandleReplacements()
	for handle, repl in pairs(attachedByHandle) do
		if repl and repl.Parent then
			repl:Destroy()
		end
		attachedByHandle[handle] = nil
	end
	restoreHiddenParts()
end

local function isOwnedByLocalPlayer(obj)
	if not obj then return false end
	if obj:IsDescendantOf(playerGui) then
		return true
	end
	local char = player.Character
	if char and obj:IsDescendantOf(char) then
		return true
	end

	local pName = player.Name:lower()
	local uidStr = tostring(player.UserId)

	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= player then
			local oChar = other.Character
			if oChar and obj:IsDescendantOf(oChar) then
				return false
			end
			local oName = other.Name:lower()
			if obj.Name:lower():find(oName, 1, true) then
				return false
			end
		end
	end

	if obj.Name:lower():find(pName, 1, true) then
		return true
	end

	local cur = obj
	while cur and cur ~= workspace and cur ~= game do
		local cName = cur.Name:lower()
		if cName:find(pName, 1, true) or cur.Name == uidStr then
			return true
		end
		local ownerAttr = tostring(cur:GetAttribute("Owner") or cur:GetAttribute("Player") or cur:GetAttribute("UserId") or "")
		if ownerAttr == uidStr or ownerAttr:lower() == pName then
			return true
		end
		local ownerVal = cur:FindFirstChild("Owner") or cur:FindFirstChild("Player") or cur:FindFirstChild("UserId")
		if ownerVal and ownerVal:IsA("ValueBase") then
			local vStr = tostring(ownerVal.Value)
			if vStr == uidStr or vStr:lower() == pName then
				return true
			end
		end
		cur = cur.Parent
	end

	return false
end

local function updateGunDisplay()
	for _, container in ipairs({ workspace, playerGui }) do
		for _, d in ipairs(container:GetDescendants()) do
			if d.Name == "GS_GunDisplay_Handle" then
				d:Destroy()
			end
		end
	end

	if not isEquipped then
		return
	end

	for _, container in ipairs({ workspace, playerGui }) do
		for _, d in ipairs(container:GetDescendants()) do
			if d.Name:lower():find("gundisplay") and isOwnedByLocalPlayer(d) then
				if d:IsA("BasePart") or d:IsA("Model") then
					local anchor = d:IsA("Model") and (d.PrimaryPart or d:FindFirstChildWhichIsA("BasePart")) or d
					if anchor then
						local itemClone = createUnifiedItemClone()
						itemClone.Name = "GS_GunDisplay_Handle"
						if itemClone:IsA("BasePart") then
							itemClone.Anchored = true
							itemClone.CFrame = anchor.CFrame * CFrame.new(0, 1.5, 0)
							itemClone.Parent = d
						elseif itemClone:IsA("Model") then
							local p = itemClone.PrimaryPart or itemClone:FindFirstChildWhichIsA("BasePart", true)
							if p then
								itemClone.PrimaryPart = p
								itemClone:PivotTo(anchor.CFrame * CFrame.new(0, 1.5, 0))
								p.Anchored = true
							end
							itemClone.Parent = d
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
		end
	end
end

local function syncHoldAnimation()
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")

	if not isEquipped or not hum or not assets.Anim then
		if holdTrack then
			holdTrack:Stop()
			holdTrack:Destroy()
			holdTrack = nil
		end
		return
	end

	if not holdTrack then
		local ok, tr = pcall(function() return hum:LoadAnimation(assets.Anim) end)
		if ok and tr then
			tr.Priority = Enum.AnimationPriority.Action
			tr.Looped = true
			tr:Play()
			holdTrack = tr
		end
	elseif not holdTrack.IsPlaying then
		holdTrack:Play()
	end
end

local function syncPistolReplacements()
	if not isEquipped then
		clearAllHandleReplacements()
		syncHoldAnimation()
		updateGunDisplay()
		return
	end

	local entries = collectPistolHandles()
	local activeHandles = {}
	for _, entry in ipairs(entries) do
		activeHandles[entry.handle] = true
		attachReplacementToHandle(entry.handle, entry.tool)
	end

	for handle, repl in pairs(attachedByHandle) do
		if not activeHandles[handle] or not handle.Parent then
			if repl and repl.Parent then
				repl:Destroy()
			end
			attachedByHandle[handle] = nil
		end
	end

	syncHoldAnimation()
	updateGunDisplay()
end

local function getActiveMuzzleParent()
	local char = player.Character
	if char then
		for _, entry in ipairs(collectPistolHandles()) do
			if entry.tool and entry.tool.Parent == char then
				return attachedByHandle[entry.handle] or entry.handle
			end
		end
	end
	return workspace
end

local function fireBeam(inputPos)
	if not isEquipped then return end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local cam = workspace.CurrentCamera
	if not hrp or not cam then return end

	local muzzleParent = getActiveMuzzleParent()

	if assets.Sound then
		local snd = assets.Sound:Clone()
		snd.Parent = muzzleParent
		snd:Play()
		Debris:AddItem(snd, 4)
	else
		local snd = Instance.new("Sound")
		snd.SoundId = "rbxassetid://131961136"
		snd.Volume = 0.7
		snd.Parent = muzzleParent
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

	local att0 = findMuzzleAttachment(muzzleParent) or findMuzzleAttachment(assets.Item)
	local tempStartPart = nil

	if not att0 then
		if muzzleParent and muzzleParent:IsA("BasePart") then
			att0 = Instance.new("Attachment")
			att0.Name = "GS_BeamAtt0"
			att0.Position = Vector3.new(0, 0, -0.7)
			att0.Parent = muzzleParent
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

local function findLayoutContainer(node)
	if not node then return nil end
	if node:IsA("UIGridLayout") or node:IsA("UIListLayout") then
		if node.Parent and node.Parent:IsA("GuiObject") then
			return node.Parent
		end
	end
	local layout = node:FindFirstChildWhichIsA("UIGridLayout", true) or node:FindFirstChildWhichIsA("UIListLayout", true)
	if layout and layout.Parent and layout.Parent:IsA("GuiObject") then
		return layout.Parent
	end
	if node:IsA("ScrollingFrame") or node:IsA("GuiObject") then
		return node
	end
	return nil
end

local function findChristmasContainer()
	local inv2 = gameGui:FindFirstChild("Inventory2")
	local main = inv2 and inv2:FindFirstChild("Main")
	local weapons = main and main:FindFirstChild("Weapons")
	local items = weapons and weapons:FindFirstChild("Items")
	local itemList = items and items:FindFirstChild("ItemList")

	for _, root in ipairs({ mainGui, playerGui }) do
		for _, desc in ipairs(root:GetDescendants()) do
			local n = desc.Name:lower()
			if (n:find("christmas") or n:find("xmas")) and not n:find("halloween") then
				local cont = findLayoutContainer(desc)
				if cont then
					return cont
				end
			end
		end
	end

	for _, root in ipairs({ mainGui, playerGui }) do
		for _, desc in ipairs(root:GetDescendants()) do
			if desc:IsA("TextLabel") then
				local t = desc.Text:lower()
				if t:find("christmas") or t:find("рождество") then
					local parent = desc.Parent
					if parent then
						for _, sib in ipairs(parent:GetChildren()) do
							if sib ~= desc and sib:IsA("GuiObject") then
								local cont = findLayoutContainer(sib)
								if cont then
									return cont
								end
							end
						end
						local grand = parent.Parent
						if grand then
							for _, sib in ipairs(grand:GetChildren()) do
								if sib ~= parent and sib:IsA("GuiObject") then
									local cont = findLayoutContainer(sib)
									if cont then
										return cont
									end
								end
							end
						end
					end
				end
			end
		end
	end

	if itemList and itemList:IsA("GuiObject") then
		return itemList
	end

	return nil
end

local function getBottomLayoutOrder(container)
	local maxOrder = 0
	for _, child in ipairs(container:GetChildren()) do
		if child:IsA("GuiObject") and child.Name ~= "GS_InventoryCard" then
			if child.LayoutOrder > maxOrder then
				maxOrder = child.LayoutOrder
			end
		end
	end
	return maxOrder + 1
end

local function isEventTabSelected()
	local inv2 = gameGui:FindFirstChild("Inventory2")
	local main = inv2 and inv2:FindFirstChild("Main")
	local weapons = main and main:FindFirstChild("Weapons")
	local items = weapons and weapons:FindFirstChild("Items")
	local tabs = items and items:FindFirstChild("Tabs")
	local eventTab = tabs and tabs:FindFirstChild("Event")
	local border = eventTab and eventTab:FindFirstChild("ViewBorder")
	if border and border:IsA("GuiObject") then
		return border.Visible
	end
	return true
end

local function syncCardVisibility()
	if not isClaimed then return end
	local container = currentCardContainer or findChristmasContainer()
	if not currentCardRoot or not currentCardRoot.Parent then
		if container then
			addGingerscopeToInventoryUI()
		end
		return
	end

	if container and currentCardRoot.Parent ~= container then
		pcall(function()
			currentCardRoot.Parent = container
		end)
	end

	local shouldBeVisible = isEventTabSelected()
	if currentCardRoot:IsA("GuiObject") and currentCardRoot.Visible ~= shouldBeVisible then
		currentCardRoot.Visible = shouldBeVisible
	end
end

local function updateEquippedGunSlot()
	local inv2 = gameGui:FindFirstChild("Inventory2")
	local main = inv2 and inv2:FindFirstChild("Main")
	local weapons = main and main:FindFirstChild("Weapons")
	local equipped = weapons and weapons:FindFirstChild("Equipped")
	local container = equipped and equipped:FindFirstChild("Container")
	local gunSlot = container and container:FindFirstChild("Gun")
	if not gunSlot then return end

	local slotCont = gunSlot:FindFirstChild("Container")
	local slotIcon = slotCont and slotCont:FindFirstChild("Icon")
	local slotName = gunSlot:FindFirstChild("ItemName") and gunSlot.ItemName:FindFirstChild("Label")

	if isEquipped then
		if not gunSlot:GetAttribute("GS_PrevIcon") and slotIcon and slotIcon:IsA("ImageLabel") then
			gunSlot:SetAttribute("GS_PrevIcon", slotIcon.Image)
		end
		if not gunSlot:GetAttribute("GS_PrevName") and slotName and slotName:IsA("TextLabel") then
			gunSlot:SetAttribute("GS_PrevName", slotName.Text)
		end
		if slotIcon and slotIcon:IsA("ImageLabel") then
			slotIcon.Image = assets.Image
		end
		if slotName and slotName:IsA("TextLabel") then
			slotName.Text = tostring(gsEntry.ItemName or TARGET_KEY)
		end
		if equipService and equipService.EquipItem then
			pcall(function()
				equipService:EquipItem("Weapons", TARGET_KEY)
			end)
		end
	else
		local prevIcon = gunSlot:GetAttribute("GS_PrevIcon")
		local prevName = gunSlot:GetAttribute("GS_PrevName")
		if prevIcon and slotIcon and slotIcon:IsA("ImageLabel") then
			slotIcon.Image = prevIcon
		end
		if prevName and slotName and slotName:IsA("TextLabel") then
			slotName.Text = prevName
		end
	end
end

local function refreshEquipVisuals()
	local baseName = tostring(gsEntry.ItemName or TARGET_KEY)
	if currentCardNameLabel and currentCardNameLabel:IsA("TextLabel") then
		currentCardNameLabel.Text = baseName
	end
	if currentCardRoot then
		local stroke = currentCardRoot:FindFirstChildOfClass("UIStroke") or (currentCardRoot:FindFirstChild("Container") and currentCardRoot.Container:FindFirstChildOfClass("UIStroke"))
		if stroke then
			stroke.Color = isEquipped and Color3.fromRGB(255, 255, 255) or ANCIENT_COLOR
			stroke.Thickness = isEquipped and 2.5 or 1.5
		end
	end
	slotBtn.BackgroundColor3 = isEquipped and Color3.fromRGB(65, 130, 220) or Color3.fromRGB(32, 32, 40)
	slotBtn.Text = baseName
end

local function setEquipped(state)
	isEquipped = state
	refreshEquipVisuals()
	updateEquippedGunSlot()
	syncPistolReplacements()
	syncCardVisibility()
end

local function toggleGingerscopeEquip()
	if not isClaimed then return end
	setEquipped(not isEquipped)
end

slotBtn.MouseButton1Click:Connect(toggleGingerscopeEquip)

local function bindOtherItemButton(btn)
	if hookedButtons[btn] then return end
	if currentCardRoot and btn:IsDescendantOf(currentCardRoot) then return end
	if btn.Name == "Claim" then return end

	hookedButtons[btn] = true
	if btn:IsA("GuiButton") then
		btn.Activated:Connect(function()
			if isEquipped then
				setEquipped(false)
			end
			task.defer(syncCardVisibility)
		end)
		btn.MouseButton1Click:Connect(function()
			if isEquipped then
				setEquipped(false)
			end
			task.defer(syncCardVisibility)
		end)
	end
end

local function hookOtherInventoryButtons(rootScope)
	if not rootScope then return end
	for _, desc in ipairs(rootScope:GetDescendants()) do
		if desc:IsA("GuiButton") then
			bindOtherItemButton(desc)
		end
	end
end

local function findInventoryCardTemplate()
	local inv2 = gameGui:FindFirstChild("Inventory2")
	if inv2 and inv2:FindFirstChild("EquipContainer") and inv2.EquipContainer:FindFirstChild("ItemFrame") then
		return inv2.EquipContainer.ItemFrame
	end

	local rsMain = ReplicatedStorage:FindFirstChild("MainGUI")
	local rsInv2 = rsMain and rsMain:FindFirstChild("Inventory2")
	if rsInv2 and rsInv2:FindFirstChild("EquipContainer") and rsInv2.EquipContainer:FindFirstChild("ItemFrame") then
		return rsInv2.EquipContainer.ItemFrame
	end

	local rsInv = rsMain and rsMain:FindFirstChild("Inventory")
	local rsInvScript = rsInv and rsInv:FindFirstChild("Inventory")
	if rsInvScript and rsInvScript:FindFirstChild("ItemOld") then
		return rsInvScript.ItemOld
	end

	return nil
end

local function applyAncientCardStyle(card)
	local itemNameFrame = card:FindFirstChild("ItemName")
	if itemNameFrame and itemNameFrame:IsA("GuiObject") then
		itemNameFrame.BackgroundColor3 = ANCIENT_COLOR
		local bg = itemNameFrame:FindFirstChild("BG")
		if bg and bg:IsA("GuiObject") then
			bg.BackgroundColor3 = ANCIENT_COLOR
			if bg:IsA("ImageLabel") then
				bg.ImageColor3 = ANCIENT_COLOR
			end
		end
		for _, sub in ipairs(itemNameFrame:GetDescendants()) do
			if sub:IsA("UIGradient") then
				sub.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, ANCIENT_DARK),
					ColorSequenceKeypoint.new(0.5, ANCIENT_COLOR),
					ColorSequenceKeypoint.new(1, ANCIENT_DARK),
				})
			elseif sub:IsA("UIStroke") then
				sub.Color = ANCIENT_DARK
			end
		end
	end

	local cont = card:FindFirstChild("Container")
	if cont then
		for _, sub in ipairs(cont:GetDescendants()) do
			if sub:IsA("UIGradient") then
				sub.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, ANCIENT_DARK),
					ColorSequenceKeypoint.new(1, ANCIENT_COLOR),
				})
			elseif sub:IsA("UIStroke") then
				sub.Color = ANCIENT_COLOR
			end
		end
	end
end

local function attachCardGuards(card)
	if not card or hookedCardSignals[card] then return end
	hookedCardSignals[card] = true

	card:GetPropertyChangedSignal("Visible"):Connect(function()
		if not isClaimed or card ~= currentCardRoot then return end
		local expected = isEventTabSelected()
		if card:IsA("GuiObject") and card.Visible ~= expected then
			task.defer(function()
				if currentCardRoot == card and card.Parent then
					card.Visible = isEventTabSelected()
				end
			end)
		end
	end)

	card:GetPropertyChangedSignal("Parent"):Connect(function()
		if not isClaimed or card ~= currentCardRoot then return end
		if not card.Parent then
			task.defer(function()
				if isClaimed and currentCardRoot == card and not card.Parent then
					addGingerscopeToInventoryUI()
				end
			end)
		else
			local container = currentCardContainer or findChristmasContainer()
			if container and card.Parent ~= container then
				task.defer(function()
					if isClaimed and currentCardRoot == card and container.Parent then
						card.Parent = container
						card.Visible = isEventTabSelected()
					end
				end)
			end
		end
	end)
end

function addGingerscopeToInventoryUI()
	local targetContainer = findChristmasContainer()
	local template = findInventoryCardTemplate()
	if not targetContainer or not template then
		return false
	end

	currentCardContainer = targetContainer

	-- Если живая карточка уже есть в нужном контейнере, просто обновляем её и не пересоздаём зря
	if currentCardRoot and currentCardRoot.Parent == targetContainer then
		currentCardRoot.Visible = isEventTabSelected()
		refreshEquipVisuals()
		attachCardGuards(currentCardRoot)
		return true
	end

	for _, root in ipairs({ mainGui, playerGui }) do
		for _, obj in ipairs(root:GetDescendants()) do
			if obj.Name == "GS_InventoryCard" and obj ~= currentCardRoot then
				obj:Destroy()
			end
		end
	end

	local card = template:Clone()
	card.Name = "GS_InventoryCard"
	card.Visible = isEventTabSelected()
	card.LayoutOrder = getBottomLayoutOrder(targetContainer)
	card.Parent = targetContainer
	currentCardRoot = card

	local itemNameFrame = card:FindFirstChild("ItemName")
	local nameLabel = itemNameFrame and itemNameFrame:FindFirstChild("Label")
	currentCardNameLabel = nameLabel
	if nameLabel and nameLabel:IsA("TextLabel") then
		nameLabel.Text = tostring(gsEntry.ItemName or TARGET_KEY)
	end

	local cont = card:FindFirstChild("Container")
	local icon = cont and cont:FindFirstChild("Icon")
	if icon and icon:IsA("ImageLabel") then
		icon.Image = assets.Image
		icon.Visible = true
	end

	local amountLbl = cont and cont:FindFirstChild("Amount")
	if amountLbl and amountLbl:IsA("TextLabel") then
		amountLbl.Text = ""
		amountLbl.Visible = false
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

	applyAncientCardStyle(card)
	refreshEquipVisuals()
	attachCardGuards(card)

	local actionBtn = cont and cont:FindFirstChild("ActionButton")
	local clickTarget = (actionBtn and actionBtn:IsA("GuiButton") and actionBtn) or (card:IsA("GuiButton") and card)

	if clickTarget then
		clickTarget.Activated:Connect(toggleGingerscopeEquip)
		clickTarget.MouseButton1Click:Connect(toggleGingerscopeEquip)
	else
		for _, desc in ipairs(card:GetDescendants()) do
			if desc:IsA("GuiButton") then
				desc.Activated:Connect(toggleGingerscopeEquip)
				desc.MouseButton1Click:Connect(toggleGingerscopeEquip)
			end
		end
	end

	hookOtherInventoryButtons(mainGui)
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

claimBtn.Activated:Connect(function()
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

	syncPistolReplacements()
end)

mainGui.DescendantAdded:Connect(function(desc)
	if desc:IsA("GuiButton") then
		bindOtherItemButton(desc)
	end
	if isClaimed and (desc:IsA("UIGridLayout") or desc:IsA("UIListLayout")) then
		task.defer(function()
			syncCardVisibility()
		end)
	end
end)

-- Следим за открытием/скрытием инвентаря и переключением вкладок даже после долгого закрытия
task.spawn(function()
	local inv2 = gameGui:FindFirstChild("Inventory2")
	if inv2 and inv2:IsA("GuiObject") then
		inv2:GetPropertyChangedSignal("Visible"):Connect(function()
			if isClaimed then
				task.defer(function()
					addGingerscopeToInventoryUI()
					syncCardVisibility()
				end)
			end
		end)
	end

	local main = inv2 and inv2:FindFirstChild("Main")
	local weapons = main and main:FindFirstChild("Weapons")
	local items = weapons and weapons:FindFirstChild("Items")
	local tabs = items and items:FindFirstChild("Tabs")
	if tabs then
		for _, tab in ipairs(tabs:GetChildren()) do
			if tab.Name ~= "Search" and tab.Name ~= "UIListLayout" then
				local btn = tab:FindFirstChild("View")
				if btn and btn:IsA("GuiButton") then
					btn.Activated:Connect(function()
						task.defer(syncCardVisibility)
					end)
				end
			end
		end
	end
end)

local function hookCharacter(char)
	char.ChildAdded:Connect(function()
		task.defer(syncPistolReplacements)
	end)
	char.ChildRemoved:Connect(function()
		task.defer(syncPistolReplacements)
	end)
	local backpack = player:FindFirstChild("Backpack")
	if backpack then
		backpack.ChildAdded:Connect(function()
			task.defer(syncPistolReplacements)
		end)
		backpack.ChildRemoved:Connect(function()
			task.defer(syncPistolReplacements)
		end)
	end
	syncPistolReplacements()
end

if player.Character then
	hookCharacter(player.Character)
end
player.CharacterAdded:Connect(hookCharacter)

local lastCardGuardTick = 0
RunService.Heartbeat:Connect(function(dt)
	if isEquipped then
		syncPistolReplacements()
	end
	if isClaimed then
		lastCardGuardTick += dt
		if lastCardGuardTick >= 1 then
			lastCardGuardTick = 0
			syncCardVisibility()
		end
	end
end)

UserInputService.InputBegan:Connect(function(input, gp)
	if gp or not isEquipped then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		fireBeam(input.Position)
	end
end)

openNativeNewItem()
