-- Обновлённая логика поиска в Module.Item + _G.NewItem + активация FX при itemData.FX == true

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

_G.Cache = _G.Cache or {}
_G.SmallCache = _G.SmallCache or {}

local ORDERED_FIELDS = {
	"ItemName",
	"Image",
	"ItemType",
	"Rarity",
	"ItemID",
	"Event",
	"Year",
	"FX",
}

local function normalizeName(str)
	if type(str) ~= "string" then
		return ""
	end
	return str:lower():gsub("[%s'%-%_]", "")
end

local function formatLuaValue(val, indent)
	indent = indent or ""
	local nextIndent = indent .. "    "
	local t = typeof(val)

	if t == "string" then
		return string.format("%q", val)
	elseif t == "number" or t == "boolean" then
		return tostring(val)
	elseif t == "Color3" then
		return string.format(
			"Color3.fromRGB(%d, %d, %d)",
			math.floor(val.R * 255 + 0.5),
			math.floor(val.G * 255 + 0.5),
			math.floor(val.B * 255 + 0.5)
		)
	elseif t == "table" then
		local parts = {}
		for k, v in pairs(val) do
			local keyFormatted = (type(k) == "string") and string.format("[%q]", k) or ("[" .. tostring(k) .. "]")
			table.insert(parts, nextIndent .. keyFormatted .. " = " .. formatLuaValue(v, nextIndent))
		end
		if #parts == 0 then
			return "{}"
		end
		return "{\n" .. table.concat(parts, ",\n") .. "\n" .. indent .. "}"
	end

	return string.format("%q", tostring(val))
end

local function buildV1EntryCode(itemKey, data)
	local lines = {}
	local seen = {}

	for _, field in ipairs(ORDERED_FIELDS) do
		if data[field] ~= nil then
			seen[field] = true
			table.insert(lines, string.format("    [%q] = %s,", field, formatLuaValue(data[field], "    ")))
		end
	end

	for k, v in pairs(data) do
		if type(k) == "string" and not seen[k] then
			table.insert(lines, string.format("    [%q] = %s,", k, formatLuaValue(v, "    ")))
		end
	end

	local safeIdent = itemKey:match("^[%a_][%w_]*$")
	local headerLine = safeIdent and ("v1." .. safeIdent .. " = {") or ("v1[" .. string.format("%q", itemKey) .. "] = {")
	return headerLine .. "\n" .. table.concat(lines, "\n") .. "\n}"
end

local function getModuleItemTable()
	local moduleFolder = ReplicatedStorage:FindFirstChild("Module")
	if not moduleFolder then
		for _, child in ipairs(ReplicatedStorage:GetChildren()) do
			if child.Name:lower() == "module" then
				moduleFolder = child
				break
			end
		end
	end
	if not moduleFolder then
		return nil, "Module folder not found"
	end

	local itemObj = moduleFolder:FindFirstChild("Item")
	if not itemObj then
		for _, child in ipairs(moduleFolder:GetChildren()) do
			if child.Name:lower() == "item" then
				itemObj = child
				break
			end
		end
	end
	if not itemObj or not itemObj:IsA("ModuleScript") then
		return nil, "Module.Item ModuleScript not found"
	end

	local ok, data = pcall(require, itemObj)
	if not ok or type(data) ~= "table" then
		return nil, "Failed require Module.Item"
	end

	return data, nil
end

local function findEntryInItemModule(rootTbl, rawQuery)
	local targetNorm = normalizeName(rawQuery)
	if targetNorm == "blosson" then
		targetNorm = normalizeName("Blossom")
	end

	local function search(tbl, categoryName)
		for k, v in pairs(tbl) do
			if type(k) == "string" and type(v) == "table" then
				local kNorm = normalizeName(k)
				local itemField = (type(v.ItemName) == "string" and v.ItemName) or (type(v.Name) == "string" and v.Name) or ""
				local fNorm = normalizeName(itemField)

				local looksLikeItem = (
					v.ItemName ~= nil
					or v.Image ~= nil
					or v.Icon ~= nil
					or v.ItemType ~= nil
					or v.Rarity ~= nil
					or v.ItemID ~= nil
					or v.Event ~= nil
					or v.Year ~= nil
					or v.Chroma ~= nil
					or v.FX ~= nil
				)

				if looksLikeItem and (k == rawQuery or kNorm == targetNorm or (fNorm ~= "" and fNorm == targetNorm)) then
					local resolvedCat = v.Type or v.DataType or categoryName or "Weapons"
					return k, v, resolvedCat
				end

				if not looksLikeItem then
					local foundKey, foundData, foundCat = search(v, categoryName or k)
					if foundKey then
						return foundKey, foundData, foundCat
					end
				end
			end
		end
		return nil, nil, nil
	end

	return search(rootTbl, nil)
end

-- Включаем FX в NewItem, если в базе предмета FX == true
local function applyItemFX(enabled)
	local mainGui = playerGui:FindFirstChild("MainGUI")
	local inventory = mainGui and mainGui:FindFirstChild("Inventory")
	local newItemPopup = inventory and inventory:FindFirstChild("NewItem")
	if not newItemPopup then
		return
	end

	-- Пробуем дождаться/найти кадр предмета внутри NewItem.Container.NewItem
	local container = newItemPopup:FindFirstChild("Container")
	local itemCard = container and container:FindFirstChild("NewItem")

	if itemCard then
		local tags = itemCard:FindFirstChild("Tags")
		local fxTag = tags and tags:FindFirstChild("FX")
		if fxTag and fxTag:IsA("GuiObject") then
			fxTag.Visible = enabled
		end
	end

	-- Дополнительно включаем/выключаем любые элементы с именем "FX" внутри NewItem попапа
	for _, desc in ipairs(newItemPopup:GetDescendants()) do
		if desc.Name == "FX" then
			if desc:IsA("GuiObject") then
				desc.Visible = enabled
			elseif desc:IsA("ParticleEmitter") or desc:IsA("Beam") or desc:IsA("Trail") then
				desc.Enabled = enabled
			end
		end
	end
end

local function OnSpawnRequested(itemName)
	_G.Cache = _G.Cache or {}
	_G.SmallCache = _G.SmallCache or {}

	if type(_G.NewItem) ~= "function" then
		return false, "_G.NewItem not found"
	end

	local itemTable, err = getModuleItemTable()
	if not itemTable then
		return false, err
	end

	local foundKey, itemData, category = findEntryInItemModule(itemTable, itemName)
	if not foundKey or type(itemData) ~= "table" then
		return false, 'Not found: "' .. itemName .. '"'
	end

	local hasFX = (itemData.FX == true)

	local entryCode = buildV1EntryCode(foundKey, itemData)
	print(entryCode)
	if type(setclipboard) == "function" then
		pcall(setclipboard, entryCode)
	end

	local displayItemName = itemData.ItemName or itemData.Name or foundKey
	_G.NewItem(displayItemName, "You Got...", nil, category, 1)

	-- Небольшая задержка на кадр, чтобы NewItem успел отрисовать карточку, затем включаем FX при FX == true
	task.defer(function()
		applyItemFX(hasFX)
		if hasFX then
			task.wait(0.05)
			applyItemFX(true)
		end
	end)

	local rarityInfo = itemData.Rarity and (" [" .. tostring(itemData.Rarity) .. "]") or ""
	local fxInfo = hasFX and " [FX:ON]" or ""
	return true, displayItemName .. rarityInfo .. fxInfo
end
