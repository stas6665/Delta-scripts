local Players = game:GetService("Players")
local cache = {}

print("=== [MM2 Cyclic State Inspector] Запущено ===")

while true do
    for _, player in ipairs(Players:GetPlayers()) do
        if not cache[player] then 
            cache[player] = {attributes = {}} 
        end
        
        for attrName, attrValue in pairs(player:GetAttributes()) do
            if cache[player].attributes[attrName] ~= attrValue then
                cache[player].attributes[attrName] = attrValue
                print(string.format("[Player] %s -> '%s' = %s (%s)", player.Name, attrName, tostring(attrValue), typeof(attrValue)))
            end
        end
        
        local character = player.Character
        if character then
            if not cache[character] then 
                cache[character] = {} 
            end
            
            for attrName, attrValue in pairs(character:GetAttributes()) do
                if cache[character][attrName] ~= attrValue then
                    cache[character][attrName] = attrValue
                    print(string.format("[Character] %s -> '%s' = %s (%s)", player.Name, attrName, tostring(attrValue), typeof(attrValue)))
                end
            end
            
            for _, child in ipairs(character:GetChildren()) do
                if child:IsA("ValueBase") or child:IsA("Folder") then
                    local uniqueKey = player.Name .. "_" .. child.Name
                    local val = child:IsA("ValueBase") and child.Value or "Folder"
                    if cache[uniqueKey] ~= val then
                        cache[uniqueKey] = val
                        print(string.format("[Object] %s у %s -> [%s] = %s", child.Name, player.Name, child.ClassName, tostring(val)))
                    end
                end
            end
        end
    end
    
    task.wait(0.2)
end
