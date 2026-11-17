local ReplicatedStorage = game:GetService("ReplicatedStorage")
local outputBuffer = {}

local function ScanFolder(parentObject, indent)
    indent = indent or ""
    local children = parentObject:GetChildren()
    
    for _, child in ipairs(children) do
        table.insert(outputBuffer, indent .. "├── " .. child.Name .. " [" .. child.ClassName .. "]")
        
        if #child:GetChildren() > 0 then
            ScanFolder(child, indent .. "│   ")
        end
    end
end

table.insert(outputBuffer, "=== STARTING REPLICATEDSTORAGE SCAN ===")
pcall(function()
    ScanFolder(ReplicatedStorage, "")
end)
table.insert(outputBuffer, "=== SCAN COMPLETED ===")

local finalResult = table.concat(outputBuffer, "\n")

print(finalResult)

local success = pcall(function()
    setclipboard(finalResult)
end)

if success then
    print("=== STRUCTURE SUCCESSFULLY COPIED TO CLIPBOARD! ===")
else
    print("=== ERROR: CLIPBOARD FUNCTION NOT SUPPORTED BY YOUR EXECUTOR ===")
end
