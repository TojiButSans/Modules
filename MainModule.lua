local module = {}
local vics = {}
local chars = workspace.Characters
local items = workspace.Items
repeat wait() until game:IsLoaded()
function module:KillAura(dis, mob, wep)
  for _, v in pairs(chars:GetChildren())
    if (humRP.Posisition - v.HumanoidRootPart.Position).Magnitude <= dis then
game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("ToolDamageObject"):InvokeServer(workspace:WaitForChild("Characters"):WaitForChild("Bunny"),
	game:GetService("Players").LocalPlayer:WaitForChild("Inventory"):WaitForChild("Old Axe"),
	"0_".. game.Player.UserId)
    end
  end
end
return module
