local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

_G.Cache = _G.Cache or {}
_G.SmallCache = _G.SmallCache or {}

local SyncFolder = ReplicatedStorage:WaitForChild("Database"):WaitForChild("Sync")
local SyncDB = require(SyncFolder)
local ItemDB = SyncDB.Item or require(SyncFolder:WaitForChild("Item"))
local RarityDB = SyncDB.Rarities

local ItemModule = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ItemModule"))

local MainGUI = PlayerGui:WaitForChild("MainGUI")
local NativeNewItem = MainGUI:WaitForChild("Inventory"):WaitForChild("NewItem")

local CrossPlatform = PlayerGui:WaitForChild("CrossPlatform")
local CrossSection = CrossPlatform:WaitForChild("NewItem")
local CrossMedium = CrossSection:WaitForChild("Medium")
local CrossContainer = CrossMedium:WaitForChild("Container")
local TargetCard = CrossContainer:WaitForChild("NewItem")

local PopupScript = CrossSection:FindFirstChild("ItemPopupScript")
local SavedPopupScriptEnabled = nil

local function setGamePopupScriptSuppressed(suppressed)
if not PopupScript or not (PopupScript:IsA("LocalScript") or PopupScript:IsA("Script")) then
return
end
if suppressed then
if SavedPopupScriptEnabled == nil then
SavedPopupScriptEnabled = PopupScript.Enabled
end
PopupScript.Enabled = false
elseif SavedPopupScriptEnabled ~= nil then
PopupScript.Enabled = SavedPopupScriptEnabled
SavedPopupScriptEnabled = nil
end
end

local SavedMediumState = {
Size = CrossMedium.Size,
Position = CrossMedium.Position,
AnchorPoint = CrossMedium.AnchorPoint,
}
local SavedIgnoreInset = nil
local isPopupCurrentlyVisible = false
local currentItemKey = nil
local currentItemData = nil
local LockedInventoryCenter = nil

local function getScreenBounds()
local cam = workspace.CurrentCamera
if cam and cam.ViewportSize.X > 0 and cam.ViewportSize.Y > 0 then
return cam.ViewportSize.X, cam.ViewportSize.Y
end
local guiSize = PlayerGui.AbsoluteSize
if guiSize.X > 0 and guiSize.Y > 0 then
return guiSize.X, guiSize.Y
end
return 1920, 1080
end

local function isDockInventory(obj)
if not obj or not obj:IsA("GuiObject") then return false end
if obj.Name ~= "Inventory" then return false end
if obj:FindFirstAncestor("Shop") or obj:FindFirstAncestor("Spectate") then
return false
end
return true
end

local function isGuiActuallyVisible(obj)
local cur = obj
while cur and cur ~= PlayerGui do
if cur:IsA("GuiObject") and not cur.Visible then
return false
end
if cur:IsA("ScreenGui") and not cur.Enabled then
return false
end
cur = cur.Parent
end
return true
end

local function getAnimationTargetAndRoot()
local lobbyFrame = MainGUI:FindFirstChild("Lobby")
local lobbyDockInv = lobbyFrame
and lobbyFrame:FindFirstChild("Dock")
and lobbyFrame.Dock:FindFirstChild("Inventory")

local gameFrame = MainGUI:FindFirstChild("Game") local gameDockInv = gameFrame 	and gameFrame:FindFirstChild("Dock") 	and gameFrame.Dock:FindFirstChild("Inventory") if gameFrame and isDockInventory(gameDockInv) and ((gameFrame:IsA("GuiObject") and gameFrame.Visible) or not lobbyFrame or not lobbyFrame.Visible) then 	return gameDockInv, gameFrame end if isDockInventory(lobbyDockInv) then 	return lobbyDockInv, MainGUI end if gameFrame and isDockInventory(gameDockInv) then 	return gameDockInv, gameFrame end for _, desc in ipairs(MainGUI:GetDescendants()) do 	if isDockInventory(desc) and desc.Parent and desc.Parent.Name == "Dock" then 		local parentScreen = desc:FindFirstAncestorWhichIsA("GuiObject") 		return desc, parentScreen or MainGUI 	end end return nil, MainGUI 

end

local function getExactCenter(guiObj)
if guiObj and guiObj:IsA("GuiObject") and guiObj.AbsoluteSize.X > 2 and guiObj.AbsoluteSize.Y > 2 then
return guiObj.AbsolutePosition + (guiObj.AbsoluteSize * 0.5)
end
return nil
end

local function lockInventoryCenter(invTarget)
local target = invTarget
if not target then
target = select(1, getAnimationTargetAndRoot())
end

if target and isGuiActuallyVisible(target) then 	local center = getExactCenter(target) 	if center then 		LockedInventoryCenter = center 		return LockedInventoryCenter 	end end local lobbyFrame = MainGUI:FindFirstChild("Lobby") local gameFrame = MainGUI:FindFirstChild("Game") for _, dockParent in ipairs({ gameFrame, lobbyFrame }) do 	local dock = dockParent and dockParent:FindFirstChild("Dock") 	local inv = dock and dock:FindFirstChild("Inventory") 	if isDockInventory(inv) and isGuiActuallyVisible(inv) then 		local center = getExactCenter(inv) 		if center then 			LockedInventoryCenter = center 			return LockedInventoryCenter 		end 	end end if not LockedInventoryCenter then 	local _, screenH = getScreenBounds() 	LockedInventoryCenter = Vector2.new(56, math.clamp(screenH * 0.22, 95, 180)) end return LockedInventoryCenter 

end

local function getInventoryTargetCenter(invTarget)
if invTarget and isGuiActuallyVisible(invTarget) then
local center = getExactCenter(invTarget)
if center then
LockedInventoryCenter = center
return center
end
end

local detectedInv = select(1, getAnimationTargetAndRoot()) if detectedInv and isGuiActuallyVisible(detectedInv) then 	local center = getExactCenter(detectedInv) 	if center then 		LockedInventoryCenter = center 		return center 	end end return lockInventoryCenter(nil) 

end

task.defer(function()
lockInventoryCenter(nil)
task.wait(0.5)
lockInventoryCenter(nil)
end)

local function stretchMediumNoGaps(enabled)
if not CrossMedium or not CrossMedium:IsA("GuiObject") then return end

if enabled then 	if CrossPlatform:IsA("ScreenGui") then 		if SavedIgnoreInset == nil then 			SavedIgnoreInset = CrossPlatform.IgnoreGuiInset 		end 		CrossPlatform.IgnoreGuiInset = true 	end else 	CrossMedium.AnchorPoint = SavedMediumState.AnchorPoint 	CrossMedium.Position = SavedMediumState.Position 	CrossMedium.Size = SavedMediumState.Size 	if CrossPlatform:IsA("ScreenGui") and SavedIgnoreInset ~= nil then 		CrossPlatform.IgnoreGuiInset = SavedIgnoreInset 	end end 

end

local function hookCameraViewport(cam)
if not cam then return end
cam:GetPropertyChangedSignal("ViewportSize"):Connect(function()
LockedInventoryCenter = nil
lockInventoryCenter(nil)
end)
end

hookCameraViewport(workspace.CurrentCamera)
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
LockedInventoryCenter = nil
hookCameraViewport(workspace.CurrentCamera)
lockInventoryCenter(nil)
end)

local function cleanName(str)
if type(str) ~= "string" then return "" end
local s = string.lower(str)
s = s:gsub("\", "")
s = s:gsub("['’`]", "")
s = s:gsub("[^%w]+", " ")
return (s:match("^%s*(.-)%s*$") or "")
end

local function isChromaItem(key, data)
if type(data) == "table" and data.Chroma == true then
return true
end
if type(key) == "string" and string.find(string.lower(key), "chroma", 1, true) then
return true
end
if type(data) == "table" and data.ItemName and string.find(string.lower(tostring(data.ItemName)), "chroma", 1, true) then
return true
end
return false
end

local NormalLookup = {}
local NormalKeys = {}
local ChromaLookup = {}
local ChromaKeys = {}

local function registerToBucket(lookup, cleanStr, itemKey)
if cleanStr ~= "" and not lookup[cleanStr] then
lookup[cleanStr] = itemKey
end
end

for key, data in pairs(ItemDB) do
if type(data) == "table" then
local isChroma = isChromaItem(key, data)
local targetLookup = isChroma and ChromaLookup or NormalLookup
local targetKeys = isChroma and ChromaKeys or NormalKeys

	table.insert(targetKeys, key) 	local kClean = cleanName(key) 	registerToBucket(targetLookup, kClean, key) 	if data.ItemName then 		local nClean = cleanName(tostring(data.ItemName)) 		registerToBucket(targetLookup, nClean, key) 	end end 

end

local chromaEnabled = false

local function findChromaVariantForBase(baseKey, baseData)
local baseClean = cleanName(baseKey)
local baseItemNameClean = type(baseData) == "table" and baseData.ItemName and cleanName(tostring(baseData.ItemName)) or ""

for _, cKey in ipairs(ChromaKeys) do 	local cClean = cleanName(cKey) 	local cData = ItemDB[cKey] 	local cNameClean = type(cData) == "table" and cData.ItemName and cleanName(tostring(cData.ItemName)) or "" 	if (baseClean ~= "" and string.find(cClean, baseClean, 1, true)) 		or (baseItemNameClean ~= "" and (cNameClean == baseItemNameClean or string.find(cClean, baseItemNameClean, 1, true))) 	then 		return cKey 	end end return nil 

end

local function resolveWeapon(inputText)
local useChroma = chromaEnabled
local keys = useChroma and ChromaKeys or NormalKeys
local lookup = useChroma and ChromaLookup or NormalLookup

local q = cleanName(inputText) if q == "" or q == "random" then 	if #keys == 0 then 		keys = useChroma and NormalKeys or ChromaKeys 	end 	if #keys == 0 then return nil end 	return keys[math.random(1, #keys)] end local qNoChroma = cleanName((q:gsub("%f[%a]chroma%f[%A]", ""))) if qNoChroma == "" then 	qNoChroma = q end if lookup[q] then 	return lookup[q] end if lookup[qNoChroma] then 	return lookup[qNoChroma] end for norm, key in pairs(lookup) do 	if string.find(norm, q, 1, true) or (qNoChroma ~= "" and string.find(norm, qNoChroma, 1, true)) then 		return key 	end end if useChroma then 	local baseKey = NormalLookup[qNoChroma] or NormalLookup[q] 	if not baseKey then 		for norm, nKey in pairs(NormalLookup) do 			if string.find(norm, qNoChroma, 1, true) then 				baseKey = nKey 				break 			end 		end 	end 	if baseKey then 		local chromaMatch = findChromaVariantForBase(baseKey, ItemDB[baseKey]) 		if chromaMatch then 			return chromaMatch 		end 	end end return nil 

end

local function findUI(names, className)
for _, root in ipairs({ TargetCard, CrossContainer, CrossMedium, CrossSection }) do
for _, nm in ipairs(names) do
local obj = root:FindFirstChild(nm, true)
if obj and (not className or obj:IsA(className)) then
return obj
end
end
end
return nil
end

local Starburst = findUI({ "Starburst" }, "ImageLabel")
local TitleObj = findUI({ "Title" }, "TextLabel")
local ClaimBtn = findUI({ "Claim", "ClaimButton" }, "GuiButton")

local function getClaimTextObj(btn)
if not btn then return nil end
if btn:IsA("TextButton") or btn:IsA("TextLabel") or btn:IsA("TextBox") then
return btn
end
for _, d in ipairs(btn:GetDescendants()) do
if d:IsA("TextLabel") or d:IsA("TextBox") then
return d
end
end
return nil
end

local ClaimTextObj = getClaimTextObj(ClaimBtn)

local function setClaimText(txt)
if ClaimTextObj then
ClaimTextObj.Text = txt
end
end

local function setPopupVisible(visible)
isPopupCurrentlyVisible = visible
setGamePopupScriptSuppressed(visible)

for _, obj in ipairs({ CrossSection, CrossMedium, CrossContainer, TargetCard }) do 	if obj and obj:IsA("GuiObject") then 		obj.Visible = visible 	end end stretchMediumNoGaps(visible) local blur = Lighting:FindFirstChild("NewItemBlur") if blur and blur:IsA("BlurEffect") then 	blur.Enabled = visible end 

end

local function getCardIcon()
local direct = TargetCard:FindFirstChild("Container") and TargetCard.Container:FindFirstChild("Icon")
if direct and direct:IsA("GuiObject") then
return direct
end

local nested = TargetCard:FindFirstChild("Icon", true) if nested and nested:IsA("GuiObject") then 	return nested end for _, desc in ipairs(TargetCard:GetDescendants()) do 	if desc:IsA("ImageLabel") and desc ~= Starburst then 		local nm = string.lower(desc.Name) 		if nm:find("icon") or nm:find("item") or nm:find("weapon") or nm:find("image") then 			return desc 		end 	end end for _, desc in ipairs(TargetCard:GetDescendants()) do 	if desc:IsA("ImageLabel") and desc ~= Starburst then 		return desc 	end end return NativeNewItem:FindFirstChild("Container") 	and NativeNewItem.Container:FindFirstChild("NewItem") 	and NativeNewItem.Container.NewItem:FindFirstChild("Container") 	and NativeNewItem.Container.NewItem.Container:FindFirstChild("Icon") 

end

local function getImageFromObject(obj)
if obj then
if (obj:IsA("ImageLabel") or obj:IsA("ImageButton")) and obj.Image ~= "" then
return obj.Image
end
for _, d in ipairs(obj:GetDescendants()) do
if (d:IsA("ImageLabel") or d:IsA("ImageButton")) and d.Image ~= "" then
return d.Image
end
end
end

if type(currentItemData) == "table" then 	for _, field in ipairs({ "ChromaImage", "ChromaIcon", "Image", "Icon", "ItemImage", "ItemIcon" }) do 		local val = currentItemData[field] 		if type(val) == "string" and val ~= "" then 			return val 		end 	end end for _, d in ipairs(TargetCard:GetDescendants()) do 	if (d:IsA("ImageLabel") or d:IsA("ImageButton")) and d ~= Starburst and d.Image ~= "" then 		return d.Image 	end end return "" 

end

local function countGuiDescendants(root)
if not root then return 0 end
local ok, list = pcall(function()
return root:GetDescendants()
end)
return ok and #list or 0
end

local function didNativeAnimationActivate(iconToFly, animRoot, countBefore, posBefore, sizeBefore)
local countAfter = countGuiDescendants(animRoot) + countGuiDescendants(PlayerGui)
if countAfter > countBefore then
return true
end

if iconToFly and iconToFly:IsA("GuiObject") then 	if (iconToFly.AbsolutePosition - posBefore).Magnitude > 2 then 		return true 	end 	if (iconToFly.AbsoluteSize - sizeBefore).Magnitude > 2 then 		return true 	end end return false 

end

local function playGuaranteedInventoryFlight(iconObj, invTarget)
local screenW, screenH = getScreenBounds()
local hasValidIcon = iconObj and iconObj:IsA("GuiObject") and iconObj.AbsoluteSize.X > 1 and iconObj.AbsoluteSize.Y > 1
local startPos = hasValidIcon
and iconObj.AbsolutePosition
or Vector2.new(screenW * 0.5 - 48, screenH * 0.5 - 48)
local startSize = hasValidIcon
and iconObj.AbsoluteSize
or Vector2.new(96, 96)

local targetCenter = getInventoryTargetCenter(invTarget) local endSize = Vector2.new(math.clamp(startSize.X * 0.45, 28, 48), math.clamp(startSize.Y * 0.45, 28, 48)) local endPos = targetCenter - (endSize * 0.5) local oldFly = PlayerGui:FindFirstChild("InventoryFlyEffect") if oldFly then 	oldFly:Destroy() end local flyGui = Instance.new("ScreenGui") flyGui.Name = "InventoryFlyEffect" flyGui.IgnoreGuiInset = true flyGui.DisplayOrder = 50 flyGui.ResetOnSpawn = false flyGui.Parent = PlayerGui local img = getImageFromObject(iconObj) local flyIcon = Instance.new("ImageLabel") flyIcon.BackgroundTransparency = img == "" and 0.25 or 1 flyIcon.BackgroundColor3 = Color3.fromRGB(255, 215, 60) flyIcon.Image = img flyIcon.ScaleType = Enum.ScaleType.Fit flyIcon.Size = UDim2.fromOffset(startSize.X, startSize.Y) flyIcon.Position = UDim2.fromOffset(startPos.X, startPos.Y) flyIcon.Parent = flyGui if img == "" then 	local corner = Instance.new("UICorner") 	corner.CornerRadius = UDim.new(1, 0) 	corner.Parent = flyIcon end local tween = TweenService:Create( 	flyIcon, 	TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), 	{ 		Position = UDim2.fromOffset(endPos.X, endPos.Y), 		Size = UDim2.fromOffset(endSize.X, endSize.Y), 		ImageTransparency = 0.15, 		BackgroundTransparency = img == "" and 0.85 or 1, 	} ) tween:Play() tween.Completed:Connect(function() 	if flyGui and flyGui.Parent then 		flyGui:Destroy() 	end end) 

end

local function playNativeGameInventoryAnimation(sourceIcon)
local iconToFly = sourceIcon or getCardIcon()
local invTarget, animRoot = getAnimationTargetAndRoot()
lockInventoryCenter(invTarget)

if iconToFly and iconToFly:IsA("GuiObject") then 	iconToFly.Visible = true end if invTarget and invTarget:IsA("GuiObject") then 	invTarget.Visible = true end local countBefore = countGuiDescendants(animRoot) + countGuiDescendants(PlayerGui) local posBefore = (iconToFly and iconToFly:IsA("GuiObject")) and iconToFly.AbsolutePosition or Vector2.zero local sizeBefore = (iconToFly and iconToFly:IsA("GuiObject")) and iconToFly.AbsoluteSize or Vector2.zero local nativeCalledOk = false if iconToFly and invTarget and animRoot and type(ItemModule.AnimateItemIconIntoInventory) == "function" then 	nativeCalledOk = pcall(function() 		ItemModule.AnimateItemIconIntoInventory(iconToFly, invTarget, animRoot) 	end) end task.delay(0.03, function() 	if not nativeCalledOk or not didNativeAnimationActivate(iconToFly, animRoot, countBefore, posBefore, sizeBefore) then 		playGuaranteedInventoryFlight(iconToFly, invTarget) 	end end) 

end

local function getTargetCategory(itemKey, itemData)
if type(itemData) == "table" and type(itemData.DataType) == "string" then
return itemData.DataType
end
if SyncDB.Weapons and SyncDB.Weapons[itemKey] then return "Weapons" end
if SyncDB.Pets and SyncDB.Pets[itemKey] then return "Pets" end
if SyncDB.Effects and SyncDB.Effects[itemKey] then return "Effects" end
if SyncDB.Emotes and SyncDB.Emotes[itemKey] then return "Emotes" end
if SyncDB.Toys and SyncDB.Toys[itemKey] then return "Toys" end
return "Weapons"
end

local function getTargetTabName(category, itemData)
if category == "Weapons" then
local ev = type(itemData) == "table" and itemData.Event or nil
if ev == "Christmas" or ev == "Halloween" then
return ev
end
return (type(itemData) == "table" and itemData.Season) and "Current" or "Classic"
end
return "Current"
end

local function findInventoryContainer(mainFrame, category, tabName)
if not mainFrame then return nil end
local catFrame = mainFrame:FindFirstChild(category)
if not catFrame then return nil end

local items = catFrame:FindFirstChild("Items") local container = items and items:FindFirstChild("Container") if container then 	local directTab = container:FindFirstChild(tabName) 	if directTab and directTab:FindFirstChild("Container") then 		return directTab.Container 	end 	local holiday = container:FindFirstChild("Holiday") 	local holidayContainer = holiday and holiday:FindFirstChild("Container") 	if holidayContainer then 		local holidayTab = holidayContainer:FindFirstChild(tabName) 		if holidayTab and holidayTab:FindFirstChild("Container") then 			return holidayTab.Container 		end 	end 	if container:FindFirstChild("ItemList") then 		return container.ItemList 	end end local itemList = items and items:FindFirstChild("ItemList") if itemList then 	return itemList end return nil 

end

local function isValidInventoryCardTemplate(obj)
if not obj or not obj:IsA("GuiObject") then return false end
if obj == TargetCard or obj == CrossContainer or obj == CrossMedium or obj == CrossSection then
return false
end
if obj:FindFirstChild("Claim", true) or obj:FindFirstChild("ClaimButton", true) then
return false
end
return true
end

local function cleanClaimClonesInContainer(container)
if not container then return end
for _, child in ipairs(container:GetChildren()) do
if child:IsA("GuiObject") and (child:FindFirstChild("Claim", true) or child:FindFirstChild("ClaimButton", true)) then
child:Destroy()
end
end
end

local function getInventoryCardTemplate(InvModule, container)
local candidates = {
InvModule and InvModule.GUI and InvModule.GUI.NewItem,
NativeNewItem,
}

if container then 	for _, child in ipairs(container:GetChildren()) do 		if child:IsA("GuiObject") and not child:FindFirstChild("Claim", true) and not child:FindFirstChild("ClaimButton", true) then 			table.insert(candidates, child) 		end 	end end for _, cand in ipairs(candidates) do 	if isValidInventoryCardTemplate(cand) then 		return cand 	end end return nil 

end

local function getCardMatchesItem(card, itemKey, itemData)
if not card or not card:IsA("GuiObject") then return false end
if card.Name == itemKey then
return true
end

local itemIsChroma = isChromaItem(itemKey, itemData) local expectedName = tostring((type(itemData) == "table" and itemData.ItemName) or itemKey):lower() local keyLower = tostring(itemKey):lower() local hasChromaIndicator = false if itemIsChroma then 	for _, desc in ipairs(card:GetDescendants()) do 		if desc:IsA("TextLabel") or desc:IsA("TextBox") then 			if string.find(string.lower(tostring(desc.Text)), "chroma", 1, true) then 				hasChromaIndicator = true 				break 			end 		elseif (desc:IsA("ImageLabel") or desc:IsA("ImageButton")) and string.find(string.lower(desc.Name), "chroma", 1, true) then 			hasChromaIndicator = true 			break 		end 	end end for _, desc in ipairs(card:GetDescendants()) do 	if desc:IsA("TextLabel") or desc:IsA("TextBox") then 		local txt = tostring(desc.Text):lower() 		if txt ~= "" and (txt == keyLower or (txt == expectedName and (not itemIsChroma or hasChromaIndicator or string.find(txt, "chroma", 1, true)))) then 			return true 		end 	end end return false 

end

local function updateCardAmount(card, totalAmount)
if not card then return end
local amtLabel = card:FindFirstChild("Amount", true)
if amtLabel and (amtLabel:IsA("TextLabel") or amtLabel:IsA("TextBox")) then
amtLabel.Text = totalAmount > 1 and ("x" .. tostring(totalAmount)) or ""
end
end

local function enforceSingleCardInContainer(container, itemKey, itemData, totalAmount)
if not container then return nil end
local keeper = nil
for _, child in ipairs(container:GetChildren()) do
if child:IsA("GuiObject") and getCardMatchesItem(child, itemKey, itemData) then
if not keeper then
keeper = child
else
child:Destroy()
end
end
end
if keeper then
updateCardAmount(keeper, totalAmount)
end
return keeper
end

local ContainerGuards = {}

local function armDuplicateGuard(container, itemKey, itemData, getTotalFn)
if not container or not itemKey then return end
local guardKey = tostring(container:GetDebugId()) .. ":" .. tostring(itemKey)
if ContainerGuards[guardKey] then
ContainerGuards[guardKey]:Disconnect()
ContainerGuards[guardKey] = nil
end

local conn conn = container.DescendantAdded:Connect(function(desc) 	if not desc or not desc.Parent then return end 	local card = desc:IsA("GuiObject") and desc.Parent == container and desc or desc:FindFirstAncestorOfClass("GuiObject") 	while card and card.Parent ~= container do 		card = card.Parent and card.Parent:FindFirstAncestorOfClass("GuiObject") 	end 	if not card or card.Parent ~= container then return end 	task.defer(function() 		if not container.Parent then return end 		local totalAmt = (type(getTotalFn) == "function" and getTotalFn()) or 1 		enforceSingleCardInContainer(container, itemKey, itemData, totalAmt) 	end) end) ContainerGuards[guardKey] = conn task.delay(3.0, function() 	if ContainerGuards[guardKey] == conn then 		conn:Disconnect() 		ContainerGuards[guardKey] = nil 	end end) 

end

local function syncAndCreateInventoryCard(itemKey, amountToAdd)
if not itemKey then return end
local qty = math.max(1, tonumber(amountToAdd) or 1)
local itemData = ItemDB[itemKey]
if type(itemData) ~= "table" then return end

local category = getTargetCategory(itemKey, itemData) local tabName = getTargetTabName(category, itemData) local okInvMod, InvModule = pcall(function() 	return require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("InventoryModule")) end) local okProfile, ProfileData = pcall(function() 	return require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ProfileData")) end) if okProfile and ProfileData and ProfileData[category] and type(ProfileData[category].Owned) == "table" then 	local curOwned = tonumber(ProfileData[category].Owned[itemKey]) or 0 	ProfileData[category].Owned[itemKey] = curOwned + qty end local function getCurrentOwned() 	if okProfile and ProfileData and ProfileData[category] and type(ProfileData[category].Owned) == "table" then 		return tonumber(ProfileData[category].Owned[itemKey]) or qty 	end 	return qty end local totalAmount = getCurrentOwned() local invGui = InvModule and InvModule.GUI and InvModule.GUI.MyInventory and InvModule.GUI.MyInventory.Main local invData = InvModule and InvModule.MyInventory local initialContainer = findInventoryContainer(invGui, category, tabName) if initialContainer then 	cleanClaimClonesInContainer(initialContainer) 	armDuplicateGuard(initialContainer, itemKey, itemData, getCurrentOwned) end local nativeSucceeded = false if okInvMod and invGui and invData and type(InvModule.UpdateInventory) == "function" then 	local okCall = pcall(function() 		InvModule.UpdateInventory(InvModule.GUI.MyInventory, invData) 	end) 	if okCall then 		for _, waitStep in ipairs({ 0.1, 0.15, 0.2 }) do 			task.wait(waitStep) 			local cont = findInventoryContainer(invGui, category, tabName) 			if cont then 				cleanClaimClonesInContainer(cont) 				armDuplicateGuard(cont, itemKey, itemData, getCurrentOwned) 				if enforceSingleCardInContainer(cont, itemKey, itemData, getCurrentOwned()) then 					nativeSucceeded = true 					break 				end 			end 		end 	end end local targetContainer = findInventoryContainer(invGui, category, tabName) if targetContainer then 	cleanClaimClonesInContainer(targetContainer) 	armDuplicateGuard(targetContainer, itemKey, itemData, getCurrentOwned) end local latestAmount = getCurrentOwned() local existing = enforceSingleCardInContainer(targetContainer, itemKey, itemData, latestAmount) if not existing and not nativeSucceeded then 	local templateCard = getInventoryCardTemplate(InvModule, targetContainer) 	if targetContainer and templateCard then 		local card = templateCard:Clone() 		card.Name = itemKey 		card.Visible = true 		for _, desc in ipairs(card:GetDescendants()) do 			if desc:IsA("GuiObject") and (desc.Name == "Claim" or desc.Name == "ClaimButton") then 				desc:Destroy() 			end 		end 		pcall(function() 			ItemModule.DisplayItem(card, itemData, latestAmount, true) 		end) 		card.Parent = targetContainer 		enforceSingleCardInContainer(targetContainer, itemKey, itemData, latestAmount) 	end end local okInvSrv, InvService = pcall(function() 	return require(ReplicatedStorage:WaitForChild("ClientServices"):WaitForChild("InventoryService")) end) if okInvSrv and InvService and type(InvService.ApplyChangesToInventoryInfo) == "function" and _G.ActiveInventoryInfo then 	pcall(function() 		InvService:ApplyChangesToInventoryInfo(_G.ActiveInventoryInfo, itemKey, latestAmount) 	end) end 

end

local function populateNativeNewItem(itemKey, titleText, itemType, amount)
local categoryTable = (SyncDB and SyncDB[itemType or "Weapons"]) or ItemDB
local itemData = categoryTable[itemKey] or ItemDB[itemKey]
if type(itemData) ~= "table" then return false end

currentItemKey = itemKey currentItemData = itemData ItemModule.DisplayItem(TargetCard, itemData, amount) if Starburst and RarityDB and itemData.Rarity and RarityDB[itemData.Rarity] then 	local col = RarityDB[itemData.Rarity].Color 	if col then 		Starburst.ImageColor3 = Color3.fromRGB(col.r, col.g, col.b) or Color3.new(1, 1, 1) 	end end if TitleObj then 	TitleObj.Text = titleText or "You Got..." end setPopupVisible(true) return true 

end

local Queue = {}
local TotalInBatch = 0
local ClaimedCount = 0
local IsShowing = false
local ClaimLock = false

local function refreshClaimLabel()
if TotalInBatch > 1 then
setClaimText("Claim (" .. ClaimedCount .. "/" .. TotalInBatch .. ")")
else
setClaimText("Claim")
end
end

local function showNextInQueue()
if #Queue == 0 then
IsShowing = false
TotalInBatch = 0
ClaimedCount = 0
currentItemKey = nil
currentItemData = nil
setClaimText("Claim")
setPopupVisible(false)
return
end

IsShowing = true local entry = table.remove(Queue, 1) refreshClaimLabel() populateNativeNewItem(entry.ItemName, entry.TitleText, entry.Type, entry.Amount) 

end

local function enqueueWeapon(itemKey, count)
if not itemKey or not ItemDB[itemKey] then return end
local qty = math.clamp(math.floor(tonumber(count) or 1), 1, 250)
local wasEmpty = (#Queue == 0 and not IsShowing)

if wasEmpty then 	TotalInBatch = qty 	ClaimedCount = 0 else 	TotalInBatch += qty end for _ = 1, qty do 	table.insert(Queue, { 		ItemName = itemKey, 		TitleText = "You Got...", 		Type = "Weapons", 		Amount = nil 	}) end if wasEmpty then 	showNextInQueue() else 	refreshClaimLabel() end 

end

local function handleClaimClick()
if not IsShowing or ClaimLock then return end
ClaimLock = true

ClaimedCount = math.min(ClaimedCount + 1, TotalInBatch) refreshClaimLabel() local itemToSync = currentItemKey local icon = getCardIcon() playNativeGameInventoryAnimation(icon) if itemToSync then 	task.spawn(function() 		syncAndCreateInventoryCard(itemToSync, 1) 	end) end _G.UnfinishedItem = nil _G.UnfinishedType = nil task.delay(0.12, function() 	showNextInQueue() 	ClaimLock = false end) 

end

if ClaimBtn then
ClaimBtn.MouseButton1Click:Connect(handleClaimClick)
if ClaimBtn.Activated then
ClaimBtn.Activated:Connect(handleClaimClick)
end
end

local oldGui = PlayerGui:FindFirstChild("Native_NewItem_Spawner")
if oldGui then
oldGui:Destroy()
end

local FULL_HEIGHT = 202
local TOP_HEIGHT = 30

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Native_NewItem_Spawner"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 20
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 250, 0, FULL_HEIGHT)
Frame.Position = UDim2.new(0.5, -125, 0.25, 0)
Frame.BackgroundColor3 = Color3.fromRGB(14, 14, 16)
Frame.BackgroundTransparency = 0.06
Frame.BorderSizePixel = 0
Frame.Parent = ScreenGui

local FrameCorner = Instance.new("UICorner")
FrameCorner.CornerRadius = UDim.new(0, 10)
FrameCorner.Parent = Frame

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(255, 200, 0)
Stroke.Thickness = 1.5
Stroke.Parent = Frame

local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, TOP_HEIGHT)
TopBar.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
TopBar.BorderSizePixel = 0
TopBar.Parent = Frame

local TopCorner = Instance.new("UICorner")
TopCorner.CornerRadius = UDim.new(0, 10)
TopCorner.Parent = TopBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -38, 1, 0)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "NewItem Spawner"
Title.TextColor3 = Color3.fromRGB(255, 215, 60)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 13
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 24, 0, 22)
MinBtn.Position = UDim2.new(1, -28, 0, 4)
MinBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
MinBtn.Text = "-"
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 15
MinBtn.Parent = TopBar

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 6)
MinCorner.Parent = MinBtn

local Body = Instance.new("Frame")
Body.Size = UDim2.new(1, -16, 1, -38)
Body.Position = UDim2.new(0, 8, 0, 34)
Body.BackgroundTransparency = 1
Body.Parent = Frame

local WeaponBox = Instance.new("TextBox")
WeaponBox.Size = UDim2.new(1, 0, 0, 34)
WeaponBox.Position = UDim2.new(0, 0, 0, 0)
WeaponBox.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
WeaponBox.PlaceholderText = "Название оружия"
WeaponBox.Text = ""
WeaponBox.TextColor3 = Color3.fromRGB(255, 255, 255)
WeaponBox.PlaceholderColor3 = Color3.fromRGB(130, 130, 140)
WeaponBox.Font = Enum.Font.Gotham
WeaponBox.TextSize = 13
WeaponBox.ClearTextOnFocus = false
WeaponBox.Parent = Body

local WeaponCorner = Instance.new("UICorner")
WeaponCorner.CornerRadius = UDim.new(0, 7)
WeaponCorner.Parent = WeaponBox

local CountBox = Instance.new("TextBox")
CountBox.Size = UDim2.new(1, 0, 0, 34)
CountBox.Position = UDim2.new(0, 0, 0, 40)
CountBox.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
CountBox.PlaceholderText = "Количество (1 или больше)"
CountBox.Text = "1"
CountBox.TextColor3 = Color3.fromRGB(255, 215, 60)
CountBox.PlaceholderColor3 = Color3.fromRGB(130, 130, 140)
CountBox.Font = Enum.Font.GothamBold
CountBox.TextSize = 13
CountBox.ClearTextOnFocus = false
CountBox.Parent = Body

local CountCorner = Instance.new("UICorner")
CountCorner.CornerRadius = UDim.new(0, 7)
CountCorner.Parent = CountBox

CountBox:GetPropertyChangedSignal("Text"):Connect(function()
local digits = CountBox.Text:gsub("%D+", "")
if CountBox.Text ~= digits then
CountBox.Text = digits
end
end)

local SpawnBtn = Instance.new("TextButton")
SpawnBtn.Size = UDim2.new(1, 0, 0, 36)
SpawnBtn.Position = UDim2.new(0, 0, 0, 82)
SpawnBtn.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
SpawnBtn.Text = "Spawn"
SpawnBtn.TextColor3 = Color3.fromRGB(15, 15, 15)
SpawnBtn.Font = Enum.Font.GothamBold
SpawnBtn.TextSize = 14
SpawnBtn.Parent = Body

local SpawnCorner = Instance.new("UICorner")
SpawnCorner.CornerRadius = UDim.new(0, 8)
SpawnCorner.Parent = SpawnBtn

local ChromaBtn = Instance.new("TextButton")
ChromaBtn.Size = UDim2.new(1, 0, 0, 32)
ChromaBtn.Position = UDim2.new(0, 0, 0, 124)
ChromaBtn.BackgroundColor3 = Color3.fromRGB(32, 32, 38)
ChromaBtn.Text = "Chroma: OFF"
ChromaBtn.TextColor3 = Color3.fromRGB(220, 220, 230)
ChromaBtn.Font = Enum.Font.GothamBold
ChromaBtn.TextSize = 13
ChromaBtn.Parent = Body

local ChromaCorner = Instance.new("UICorner")
ChromaCorner.CornerRadius = UDim.new(0, 8)
ChromaCorner.Parent = ChromaBtn

local ChromaStroke = Instance.new("UIStroke")
ChromaStroke.Color = Color3.fromRGB(90, 90, 105)
ChromaStroke.Thickness = 1
ChromaStroke.Parent = ChromaBtn

local function updateChromaButton()
if chromaEnabled then
ChromaBtn.Text = "Chroma: ON"
ChromaBtn.BackgroundColor3 = Color3.fromRGB(48, 28, 72)
ChromaBtn.TextColor3 = Color3.fromRGB(235, 190, 255)
ChromaStroke.Color = Color3.fromRGB(190, 110, 255)
else
ChromaBtn.Text = "Chroma: OFF"
ChromaBtn.BackgroundColor3 = Color3.fromRGB(32, 32, 38)
ChromaBtn.TextColor3 = Color3.fromRGB(220, 220, 230)
ChromaStroke.Color = Color3.fromRGB(90, 90, 105)
end
end

ChromaBtn.MouseButton1Click:Connect(function()
chromaEnabled = not chromaEnabled
updateChromaButton()
end)

SpawnBtn.MouseButton1Click:Connect(function()
local itemKey = resolveWeapon(WeaponBox.Text)
if not itemKey then
SpawnBtn.Text = "Not found"
task.delay(1.2, function() SpawnBtn.Text = "Spawn" end)
return
end

local amount = math.clamp(math.floor(tonumber(CountBox.Text) or 1), 1, 250) CountBox.Text = tostring(amount) enqueueWeapon(itemKey, amount) 

end)

local minimized = false
MinBtn.MouseButton1Click:Connect(function()
minimized = not minimized
Body.Visible = not minimized
Frame.Size = minimized and UDim2.new(0, 250, 0, TOP_HEIGHT) or UDim2.new(0, 250, 0, FULL_HEIGHT)
MinBtn.Text = minimized and "+" or "-"
end)

local dragging, dragInput, dragStart, startPos

TopBar.InputBegan:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
dragging = true
dragInput = input
dragStart = input.Position
startPos = Frame.Position
end
end)

UserInputService.InputChanged:Connect(function(input)
if dragging and input == dragInput and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
local delta = input.Position - dragStart
Frame.Position = UDim2.new(
startPos.X.Scale,
startPos.X.Offset + delta.X,
startPos.Y.Scale,
startPos.Y.Offset + delta.Y
)
end
end)

UserInputService.InputEnded:Connect(function(input)
if input == dragInput and dragging then
dragging = false
dragInput = nil
end
end)

