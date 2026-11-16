local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("=== REPLICATEDSTORAGE SCAN START ===")

local function scanFolder(folder, depth)
    local indent = string.rep("  ", depth)
    for _, child in ipairs(folder:GetChildren()) do
        print(indent .. "- " .. child.Name .. " (" .. child.ClassName .. ")")
        
        if depth < 3 and (child:IsA("Folder") or child:IsA("Model") or child:IsA("Configuration")) then
            scanFolder(child, depth + 1)
        elseif child:IsA("ModuleScript") then
            local success, data = pcall(function()
                return require(child)
            end)
            if success and typeof(data) == "table" then
                print(indent .. "   [Module Contents]:")
                for k, v in pairs(data) do
                    print(indent .. "      Key:", k, "Type:", typeof(v))
                end
            end
        end
    end
end

scanFolder(ReplicatedStorage, 0)
print("=== REPLICATEDSTORAGE SCAN COMPLETED ===")
