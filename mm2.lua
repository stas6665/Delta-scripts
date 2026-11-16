local function GetPlayerRole(p)
    local success, CurrentRoundClient = pcall(function()
        return require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("CurrentRoundClient"))
    end)
    
    if success and CurrentRoundClient then
        -- Проверим, что находится внутри CurrentRoundClient
        print("CurrentRoundClient loaded successfully!")
        
        -- Если у него есть PlayerData
        if CurrentRoundClient.PlayerData then
            for k, v in pairs(CurrentRoundClient.PlayerData) do
                print("PlayerData Item -> Key:", k, "Type:", typeof(v))
                if typeof(v) == "table" then
                    for subK, subV in pairs(v) do
                        print("    SubKey:", subK, "Value:", tostring(subV))
                        -- Если найдем совпадение с игроком
                        if subV == p or (typeof(subV) == "string" and subV == p.Name) then
                            -- Ищем роль в этой же таблице
                            for _, possibleRole in pairs(v) do
                                if possibleRole == "Sheriff" or possibleRole == "Murderer" or possibleRole == "Innocent" then
                                    return possibleRole
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    return "Innocent"
end
