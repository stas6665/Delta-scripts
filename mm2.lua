local function GetPlayerRole(p)
    local playerData = CurrentRoundClient.PlayerData
    
    if typeof(playerData) == "table" then
        -- Выводим в консоль все данные, которые прислал сервер
        print("--- DEBUG PLAYER DATA ---")
        for k, v in pairs(playerData) do
            print("Key:", k, "Value:", v)
            if typeof(v) == "table" then
                for subK, subV in pairs(v) do
                    print("   -> SubKey:", subK, "SubVal:", subV)
                end
            end
        end
        
        for _, data in pairs(playerData) do
            if typeof(data) == "table" then
                local playerField = data.Player or data.Instance or data.Name or data.User or data[1]
                local roleField = data.Role or data.Value or data[2]
                
                if playerField == p or (typeof(playerField) == "string" and playerField == p.Name) then
                    if roleField == "Sheriff" or roleField == "Murderer" or roleField == "Innocent" then
                        return roleField
                    end
                end
                
                for _, v in pairs(data) do
                    if v == p or (typeof(v) == "string" and v == p.Name) then
                        for _, subV in pairs(data) do
                            if typeof(subV) == "string" and (subV == "Sheriff" or subV == "Murderer" or subV == "Innocent") then
                                return subV
                            end
                        end
                    end
                end
            end
        end
    end
    return "Innocent"
end
