local module = {}
local victims = {}
local chars = workspace.Characters
local items = workspace.Items
repeat wait() until game:IsLoaded()
function module:KillAura(dis, mob)
  for _, v in pairs(chars:GetChildren())
    if (humRP.Posisition - v.HumanoidRootPart.Position).Magnitude <= dis then
  end
end
return module
