local bp = player:FindFirstChild("Backpack")
if bp then
watchBackpack(bp)
end
player.ChildAdded:Connect(function(child)
if child.Name == "Backpack" then
  watchBackpack(child)
end
end)

-- Опциональный редкий пульс (1 раз в 1.5s, только когда Pulse:ON)
task.spawn(function()
while true do
  task.wait(1.5)
  if scanEnabled and pulseEnabled then
   LogEvent("PULSE", getRayAndAimSnapshot())
  end
end
end)

-- Перехват FireServer / InvokeServer / BindableEvent:Fire + атрибуты вызываемого объекта и аргументов
if typeof(hookmetamethod) == "function" and typeof(getnamecallmethod) == "function" then
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
  local method = getnamecallmethod()
  if not checkcaller() and typeof(self) == "Instance" then
   if (method == "FireServer" or method == "InvokeServer") and (self:IsA("RemoteEvent") or self:IsA("RemoteFunction")) then
    watchAttributes(self, "REM_ATTR")
    local fullName = self:GetFullName()
    local argsStr = formatArgs(...)
    task.defer(LogEvent, method, string.format("%s%s | Args: %s", fullName, formatAttributes(self), argsStr))
    if string.find(fullName, "Shoot", 1, true) then
     task.defer(LogEvent, "RAY_SHOT", method .. " " .. fullName .. " | " .. getRayAndAimSnapshot(...))
    end
   elseif method == "Fire" and self:IsA("BindableEvent") then
    watchAttributes(self, "BIND_ATTR")
    local fullName = self:GetFullName()
    local argsStr = formatArgs(...)
    task.defer(LogEvent, "Bindable:Fire", string.format("%s%s | Args: %s", fullName, formatAttributes(self), argsStr))
   end
  end
  return oldNamecall(self, ...)
end)
LogEvent("INIT", "ESP+GUN логгер запущен: автоподсветка ролей, [ROLE_LIST], RAY_SHOT, Gun, атрибуты.")
else
LogEvent("INIT", "ESP+GUN логгер запущен без __namecall хука.")
end
