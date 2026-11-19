local TARGET_TREE_KEYWORDS = { "sync", "item", "inventory", "module", "moduls" }
local autoTreeScanEnabled = false
local autoTreeScanThread = nil
local loggedScanSignatures = {}

local function containsAnyKeyword(text, list)
	local low = string.lower(tostring(text or ""))
	for _, kw in ipairs(list) do
		if string.find(low, kw, 1, true) then
			return true
		end
	end
	return false
end

local function isReadableClientScript(inst)
	return typeof(inst) == "Instance" and (inst:IsA("LocalScript") or inst:IsA("ModuleScript"))
end

local function readClientScriptSource(scriptObj)
	if not isReadableClientScript(scriptObj) then
		return nil, "not_script", false
	end

	local okSrc, src = pcall(function()
		return scriptObj.Source
	end)
	if okSrc and type(src) == "string" and #src > 0 then
		return src, "Source", true
	end

	local env = (typeof(getgenv) == "function" and getgenv()) or _G
	local decFn = (type(decompile) == "function" and decompile)
		or (env and type(env.decompile) == "function" and env.decompile)
		or nil

	if decFn then
		local okDec, decOut = pcall(decFn, scriptObj)
		if okDec and type(decOut) == "string" and #decOut > 0 then
			local isReal = not string.find(string.lower(decOut), "decompile failed", 1, true)
				and not string.find(string.lower(decOut), "unable to decompile", 1, true)
			return decOut, "decompile", isReal
		end
	end

	if type(getscriptbytecode) == "function" then
		local okBc, bc = pcall(getscriptbytecode, scriptObj)
		if okBc and type(bc) == "string" and #bc > 0 then
			return string.format("-- [Bytecode %d bytes; decompile unavailable for %s]", #bc, safeFullName(scriptObj)), "bytecode", false
		end
	end

	return string.format("-- [Unreadable/No decompile API for %s]", safeFullName(scriptObj)), "unreadable", false
end

local function collectAllClientRoots()
	local roots = {
		Workspace,
		ReplicatedStorage,
		player:FindFirstChildOfClass("PlayerGui"),
		player:FindFirstChildOfClass("Backpack"),
		player.Character,
		StarterPlayer:FindFirstChild("StarterPlayerScripts"),
		StarterPlayer:FindFirstChild("StarterCharacterScripts"),
		StarterGui,
	}
	local all = {}
	local seen = {}
	for _, r in ipairs(roots) do
		if r and not seen[r] then
			seen[r] = true
			table.insert(all, r)
			local okDesc, descList = pcall(function()
				return r:GetDescendants()
			end)
			if okDesc and type(descList) == "table" then
				for _, d in ipairs(descList) do
					if not seen[d] then
						seen[d] = true
						table.insert(all, d)
					end
				end
			end
		end
	end
	return all
end

local function appendTreeLines(rootObj, linesOut)
	local function walk(node, depth, prefix, isLast)
		local branch = (depth == 0) and "" or (isLast and "└── " or "├── ")
		local meta = ""
		if node:IsA("Tool") then
			meta = " | TextureId=" .. tostring(node.TextureId)
		elseif node:IsA("Decal") or node:IsA("Texture") then
			meta = " | Texture=" .. tostring(node.Texture)
		elseif node:IsA("MeshPart") then
			meta = " | MeshId=" .. tostring(node.MeshId)
		elseif node:IsA("SpecialMesh") then
			meta = " | MeshId=" .. tostring(node.MeshId) .. " | TextureId=" .. tostring(node.TextureId)
		elseif node:IsA("ImageLabel") or node:IsA("ImageButton") then
			meta = " | Image=" .. tostring(node.Image)
		end

		table.insert(linesOut, string.format("%s%s[%s] %s%s", prefix, branch, node.ClassName, node.Name, meta))

		local okCh, children = pcall(function()
			return node:GetChildren()
		end)
		if okCh and type(children) == "table" then
			local nextPrefix = (depth == 0) and "" or (prefix .. (isLast and "    " or "│   "))
			for i, ch in ipairs(children) do
				walk(ch, depth + 1, nextPrefix, i == #children)
			end
		end
	end

	walk(rootObj, 0, "", true)
end

local function logOnceSignature(tag, msg)
	local sig = tostring(tag) .. "::" .. tostring(msg)
	if not loggedScanSignatures[sig] then
		loggedScanSignatures[sig] = true
		LogEvent(tag, msg)
	end
end

local function runTreesAndScriptsScan(isAutoTick)
	local allObjs = collectAllClientRoots()
	local matchedRoots = {}
	local allReadableScripts = {}
	local fullReportLines = {}

	table.insert(fullReportLines, "=== TREES SCAN (Sync, Item, Inventory, Module) - UNLIMITED DEPTH + FULL WORKSPACE ===")
	table.insert(fullReportLines, "Player: " .. player.Name .. " | Time: " .. os.date("%Y-%m-%d %H:%M:%S"))
	table.insert(fullReportLines, "")

	for _, obj in ipairs(allObjs) do
		if containsAnyKeyword(obj.Name, TARGET_TREE_KEYWORDS) then
			table.insert(matchedRoots, obj)
		end
		if isReadableClientScript(obj) then
			local src, method, isReal = readClientScriptSource(obj)
			table.insert(allReadableScripts, {
				Instance = obj,
				Path = safeFullName(obj),
				ClassName = obj.ClassName,
				Source = src,
				Method = method,
				IsReal = isReal
			})
		end
	end

	table.insert(fullReportLines, string.format("Matched target trees: %d | Total client scripts inspected: %d", #matchedRoots, #allReadableScripts))
	table.insert(fullReportLines, "")

	if not isAutoTick then
		LogEvent("TREE_SCAN", string.format("Найдено веток [Sync/Item/Inventory/Module]: %d | Клиентских скриптов: %d", #matchedRoots, #allReadableScripts))
	else
		logOnceSignature("TREE_SCAN", string.format("Найдено веток [Sync/Item/Inventory/Module]: %d | Клиентских скриптов: %d", #matchedRoots, #allReadableScripts))
	end

	for idx, rootObj in ipairs(matchedRoots) do
		local pathStr = safeFullName(rootObj)
		table.insert(fullReportLines, string.format("--- TREE #%d: %s [%s] ---", idx, pathStr, rootObj.ClassName))

		local treeLines = {}
		appendTreeLines(rootObj, treeLines)
		for _, tLine in ipairs(treeLines) do
			table.insert(fullReportLines, tLine)
			if not isAutoTick then
				LogEvent("TREE_SCAN", tLine)
			else
				logOnceSignature("TREE_SCAN", pathStr .. " -> " .. tLine)
			end
		end

		local innerScripts = {}
		if isReadableClientScript(rootObj) then
			table.insert(innerScripts, rootObj)
		end
		for _, d in ipairs(rootObj:GetDescendants()) do
			if isReadableClientScript(d) then
				table.insert(innerScripts, d)
			end
		end

		for sIdx, scr in ipairs(innerScripts) do
			local scrPath = safeFullName(scr)
			local src, method = readClientScriptSource(scr)
			table.insert(fullReportLines, string.format("[Tree#%d -> Script#%d] (%s via %s) %s", idx, sIdx, scr.ClassName, method, scrPath))
			table.insert(fullReportLines, "--- SCRIPT CODE START ---")
			table.insert(fullReportLines, src)
			table.insert(fullReportLines, "--- SCRIPT CODE END ---")

			if not isAutoTick then
				LogEvent("SCRIPT_PATH", string.format("[Tree#%d -> Script#%d] (%s via %s) %s", idx, sIdx, scr.ClassName, method, scrPath))
				LogEvent("SCRIPT_SRC", string.format("=== CODE: %s ===\n%s", scrPath, src))
			else
				logOnceSignature("SCRIPT_PATH", scrPath .. "|" .. method)
				logOnceSignature("SCRIPT_SRC", scrPath .. "|" .. src)
			end
		end
	end

	table.insert(fullReportLines, "")
	table.insert(fullReportLines, string.format("=== ALL CLIENT SCRIPTS (%d) ===", #allReadableScripts))

	local readableCount = 0
	for i, entry in ipairs(allReadableScripts) do
		if entry.IsReal then
			readableCount += 1
		end
		table.insert(fullReportLines, string.format("#%d [%s | %s | readable=%s] %s", i, entry.ClassName, entry.Method, tostring(entry.IsReal), entry.Path))
		if not isAutoTick then
			LogEvent("SCRIPT_PATH", string.format("#%d [%s | %s | readable=%s] %s", i, entry.ClassName, entry.Method, tostring(entry.IsReal), entry.Path))
		else
			logOnceSignature("SCRIPT_PATH", entry.Path .. "|" .. entry.Method .. "|" .. tostring(entry.IsReal))
		end

		if entry.IsReal then
			table.insert(fullReportLines, "--- SOURCE START ---")
			table.insert(fullReportLines, entry.Source)
			table.insert(fullReportLines, "--- SOURCE END ---")
			if not isAutoTick then
				LogEvent("SCRIPT_SRC", string.format("=== SOURCE #%d: %s ===\n%s", i, entry.Path, entry.Source))
			else
				logOnceSignature("SCRIPT_SRC", entry.Path .. "|" .. entry.Source)
			end
		end
	end

	lastFullDumpText = table.concat(fullReportLines, "\n")

	if not isAutoTick then
		if type(writefile) == "function" then
			pcall(writefile, "MM2_Trees_Scripts_Dump_" .. tostring(os.time()) .. ".txt", lastFullDumpText)
		end
		copyToClipboard(lastFullDumpText, "TreeScan")
		LogEvent("TREE_SCAN", string.format("Готово! Полностью читаемых скриптов: %d/%d. Дамп скопирован в буфер.", readableCount, #allReadableScripts))
	end
end

local function setAutoTreeScan(state)
	autoTreeScanEnabled = state
	TreeScanBtn.Text = state and "Scan0.2:ON" or "TreeScan"
	TreeScanBtn.BackgroundColor3 = state and Color3.fromRGB(38, 155, 90) or Color3.fromRGB(95, 55, 165)

	if state then
		table.clear(loggedScanSignatures)
		runTreesAndScriptsScan(false)
		if not autoTreeScanThread then
			autoTreeScanThread = task.spawn(function()
				while autoTreeScanEnabled do
					task.wait(0.2)
					if autoTreeScanEnabled and scanEnabled then
						runTreesAndScriptsScan(true)
					end
				end
				autoTreeScanThread = nil
			end)
		end
	end
end

TreeScanBtn.MouseButton1Click:Connect(function()
	setAutoTreeScan(not autoTreeScanEnabled)
end)
