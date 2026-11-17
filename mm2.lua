local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function ScanFolder(parentObject, indent)
    indent = indent or ""
    local children = parentObject:GetChildren()
    
    for _, child in ipairs(children) do
        print(indent .. "├── " .. child.Name .. " [" .. child.ClassName .. "]")
        
        if #child:GetChildren() > 0 then
            ScanFolder(child, indent .. "│   ")
        end
    end
end

print("=== STARTING REPLICATEDSTORAGE SCAN ===")
pcall(function()
    ScanFolder(ReplicatedStorage, "")
end)
print("=== SCAN COMPLETED ===")
