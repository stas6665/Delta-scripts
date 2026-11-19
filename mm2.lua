local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local StarterPack = game:GetService("StarterPack")
local StarterGui = game:GetService("StarterGui")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")

local LocalPlayer = Players.LocalPlayer

local SHOW_FULL_GAME_TREE = false
local SHOW_ONLY_WEAPON_TREES = true

local WEAPON_KEYWORDS = {
	"gun", "knife", "weapon", "pistol", "rifle", "shotgun",
	"sniper", "sword", "melee", "blade", "dagger", "tool"
}

local EVENT_EXPLANATIONS = {
	shoot = "Выстрел: синхронизация выстрела, трассера/пули или состояния патронов.",
	fire = "Огонь/атака: активация или подтверждение выстрела/удара.",
	reload = "Перезарядка: подтверждение перезарядки или обновление магазина.",
	slash = "Взмах холодным оружием: синхронизация взмаха ножа/клинка.",
	stab = "Колющий удар / бэкстаб: подтверждение удара или проверка цели.",
	hit = "Попадание: подтверждение контакта, урона или эффекта хита.",
	damage = "Урон: уведомление об уроне, изменении HP или боевом событии.",
	equip = "Экипировка: взятие оружия в руки или смена активного слота.",
	unequip = "Уборка оружия: убирание предмета.",
	ammo = "Патроны: данные о боезапасе и обойме.",
	cooldown = "Кулдаун: задержка между действиями."
}

local DiscoveredWeapons = {}
local ConnectedEvents = {}

local function containsKeyword(name)
	local lower = string.lower(tostring(name))
	for i = 1, #WEAPON_KEYWORDS do
		if string.find(lower, WEAPON_KEYWORDS[i], 1, true) then
			return true
		end
	end
	return false
end

local function explainEventRole(eventName)
	local lower = string.lower(tostring(eventName))
	for pattern, desc in pairs(EVENT_EXPLANATIONS) do
		if string.find(lower, pattern, 1, true) then
			return desc
		end
	end
	return "Событие логики/синхронизации: передаёт данные или сигнал между сервером и клиентом."
end

local function explainElementType(inst)
	if inst:IsA("LocalScript") then
		return "LocalScript (клиентский скрипт: ввод, камера, анимации, UI, запросы на сервер)"
	elseif inst:IsA("Script") then
		return "Script (скрипт игровой логики / правил)"
	elseif inst:IsA("ModuleScript") then
		return "ModuleScript (модуль с настройками/характеристиками или общими функциями)"
	elseif inst:IsA("RemoteEvent") then
		return "RemoteEvent (асинхронный сетевой ивент Клиент <-> Сервер)"
	elseif inst:IsA("RemoteFunction") then
		return "RemoteFunction (сетевой запрос с возвратом значения)"
	elseif inst:IsA("BindableEvent") or inst:IsA("BindableFunction") then
		return "Bindable-объект (внутренний сигнал внутри одной стороны)"
	elseif inst:IsA("Animation") then
		return "Animation (ID анимации: " .. tostring(inst.AnimationId) .. ")"
	elseif inst:IsA("Sound") then
		return "Sound (звуковой эффект: " .. tostring(inst.SoundId) .. ")"
	elseif inst:IsA("BasePart") then
		return "Деталь (" .. inst.ClassName .. ": часть модели, рукоять, лезвие или хитбокс)"
	elseif inst:IsA("ValueBase") then
		return "Value (" .. inst.ClassName .. ", значение: " .. tostring(inst.Value) .. ")"
	elseif inst:IsA("Folder") or inst:IsA("Configuration") then
		return "Контейнер (" .. inst.ClassName .. ": группирует связанные объекты)"
	else
		return inst.ClassName
	end
end

local function formatValue(val, depth)
	local currentDepth = depth or 0
	local t = typeof(val)

	if t == "Instance" then
		return string.format("Instance(%s: %s) [%s]", val.ClassName, val.Name, val:GetFullName())
	elseif t == "Vector3" then
		return string.format("Vector3(%.2f, %.2f, %.2f)", val.X, val.Y, val.Z)
	elseif t == "CFrame" then
		local pos = val.Position
		return string.format("CFrame(pos=%.2f, %.2f, %.2f)", pos.X, pos.Y, pos.Z)
	elseif t == "table" then
		if currentDepth >= 2 then
			return "table{...}"
		end
		local parts = {}
		for k, v in pairs(val) do
			table.insert(parts, tostring(k) .. " = " .. formatValue(v, currentDepth + 1))
		end
		return "table{ " .. table.concat(parts, ", ") .. " }"
	else
		return tostring(val) .. " (" .. tostring(t) .. ")"
	end
end

local function printHierarchyTree(root, prefix, isLast)
	local connector = isLast and "└── " or "├── "
	local linePrefix = prefix or ""

	if prefix == nil then
		print(root.Name .. " [" .. root.ClassName .. "] — " .. explainElementType(root))
	else
		local extra = ""
		if root:IsA("RemoteEvent") or root:IsA("RemoteFunction") then
			extra = " | Смысл: " .. explainEventRole(root.Name)
		end
		print(linePrefix .. connector .. root.Name .. " [" .. root.ClassName .. "] — " .. explainElementType(root) .. extra)
	end

	for k, v in pairs(root:GetAttributes()) do
		local attrPad = linePrefix .. (prefix == nil and "  " or (isLast and "    " or "│   "))
		print(attrPad .. "• Атрибут [" .. tostring(k) .. "] = " .. tostring(v))
	end

	local children = root:GetChildren()
	local nextPrefix = prefix == nil and "" or (linePrefix .. (isLast and "    " or "│   "))

	for i = 1, #children do
		printHierarchyTree(children[i], nextPrefix, i == #children)
	end
end

local function getScannableRoots()
	local roots = {
		Workspace,
		ReplicatedStorage,
		StarterPack,
		StarterGui,
		Lighting,
		SoundService
	}

	if LocalPlayer then
		if LocalPlayer:FindFirstChild("Backpack") then
			table.insert(roots, LocalPlayer.Backpack)
		end
		if LocalPlayer:FindFirstChild("StarterGear") then
			table.insert(roots, LocalPlayer.StarterGear)
		end
		if LocalPlayer.Character then
			table.insert(roots, LocalPlayer.Character)
		end
	end

	return roots
end

local function dumpFullGameTree()
	print("==========================================================================")
	print("[ПОЛНАЯ СТРУКТУРА ДОСТУПНОЙ ИГРЫ]")
	print("==========================================================================")
	local roots = getScannableRoots()
	for i = 1, #roots do
		printHierarchyTree(roots[i], nil, true)
		print("--------------------------------------------------------------------------")
	end
end

local function scanWeaponsAndTrees()
	DiscoveredWeapons = {}
	local roots = getScannableRoots()
	local seen = {}

	for r = 1, #roots do
		local desc = roots[r]:GetDescendants()
		for d = 1, #desc do
			local obj = desc[d]
			if not seen[obj] and (obj:IsA("Tool") or obj:IsA("Model") or obj:IsA("Folder")) then
				if containsKeyword(obj.Name) then
					seen[obj] = true
					table.insert(DiscoveredWeapons, obj)

					print("==========================================================================")
					print("[ОРУЖИЕ / СТРУКТУРА] " .. obj.Name .. " (" .. obj:GetFullName() .. ")")
					print("==========================================================================")
					if SHOW_ONLY_WEAPON_TREES then
						printHierarchyTree(obj, nil, true)
					end
					print("")
				end
			end
		end
	end

	print("[ИТОГ] Найдено объектов оружия: " .. tostring(#DiscoveredWeapons) .. "\n")
end

local function isWeaponRelatedRemote(remote)
	for i = 1, #DiscoveredWeapons do
		if remote:IsDescendantOf(DiscoveredWeapons[i]) then
			return true, "Внутри оружия [" .. DiscoveredWeapons[i].Name .. "]"
		end
	end

	if containsKeyword(remote.Name) then
		return true, "Имя ремоута связано с оружием"
	end

	local lower = string.lower(remote.Name)
	for pattern in pairs(EVENT_EXPLANATIONS) do
		if string.find(lower, pattern, 1, true) then
			return true, "Имя ремоута связано с боевым событием (" .. pattern .. ")"
		end
	end

	return false, ""
end

local function logServerEvent(remote, reason, ...)
	local args = { ... }
	local argList = {}
	for i = 1, #args do
		table.insert(argList, "arg" .. tostring(i) .. ": " .. formatValue(args[i], 0))
	end

	print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")
	print("[СЕРВЕР -> КЛИЕНТ] " .. remote.Name .. " (" .. remote:GetFullName() .. ")")
	print("Связь с оружием: " .. reason)
	print("Что делает ивент: " .. explainEventRole(remote.Name))
	print("Аргументы: " .. (#argList > 0 and table.concat(argList, " | ") or "нет аргументов"))
	print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n")
end

local function hookServerEvents()
	local roots = getScannableRoots()
	local hooked = 0

	for r = 1, #roots do
		local desc = roots[r]:GetDescendants()
		for d = 1, #desc do
			local obj = desc[d]
			if obj:IsA("RemoteEvent") and not ConnectedEvents[obj] then
				local ok, reason = isWeaponRelatedRemote(obj)
				if ok then
					ConnectedEvents[obj] = true
					hooked = hooked + 1
					obj.OnClientEvent:Connect(function(...)
						logServerEvent(obj, reason, ...)
					end)
				end
			end
		end
	end

	game.DescendantAdded:Connect(function(desc)
		if desc:IsA("RemoteEvent") and not ConnectedEvents[desc] then
			local ok, reason = isWeaponRelatedRemote(desc)
			if ok then
				ConnectedEvents[desc] = true
				desc.OnClientEvent:Connect(function(...)
					logServerEvent(desc, reason .. " (динамически)", ...)
				end)
			end
		end
	end)

	print("[СЕРВЕРНЫЕ ИВЕНТЫ] Подключено слушателей: " .. tostring(hooked) .. "\n")
end

if SHOW_FULL_GAME_TREE then
	dumpFullGameTree()
end

scanWeaponsAndTrees()
hookServerEvents()
