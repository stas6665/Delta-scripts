local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local function scanStrictRoleElements(folder)
for _, child in ipairs(folder:GetChildren()) do
local name = child.Name

local isRoleElement = name == "RoleSelector" or name == "ShowRoleSelect" or name == "ShowRoleSelectNew" or name == "CurrentRoundClient" or name == "PlayerDataChanged" or name == "GetPlayerData" or name == "GetPlayerData_REMOTE" if isRoleElement then print("[EXACT TARGET] " .. name .. " (" .. child.ClassName .. ") -> Path: " .. child:GetFullName()) end local success, children = pcall(function() return child:GetChildren() end) if success and #children > 0 then scanStrictRoleElements(child) end end 

end

print("=== UNLIMITED DEPTH WORKSPACE SCAN START ===")
scanStrictRoleElements(Workspace)

print("=== UNLIMITED DEPTH REPLICATEDSTORAGE SCAN START ===")
scanStrictRoleElements(ReplicatedStorage)

if LocalPlayer then
local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
if playerGui then
print("=== UNLIMITED DEPTH PLAYERGUI SCAN START ===")
scanStrictRoleElements(playerGui)
end
end

print("=== SCAN COMPLETED ===")

