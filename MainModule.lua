local module = {}
local vics = {}
local p1 = game.Players.LocalPlayer
local wepdmgIds = {
    ["Old Axe"] = "1_" .. p1.UserId,
    ["Good Axe"] = "112_" .. p1.UserId,
    ["Strong Axe"] = "116_" .. p1.UserId,
    ["Chainsaw"] = "647_" .. p1.UserId,
    ["Spear"] = "196_" .. p1.UserId
}
local chars = workspace.Characters
local items = workspace.Items
local RE = ReplicatedStorage:WaitForChild("RemoteEvents")
_G.status = "Discontinued"
repeat wait() until game:IsLoaded()
function module:CheckWep()
    for i, v in pairs(wepdmgIds) do
        local wepon = p1.Inventory:FindFirstChild(i)
        if wepon then
            return wep, dmgId
        end
    end
    return nil, nil
end
function module:KillAura(dis)
  for _, v in pairs(chars:GetChildren())
    if (humRP.Posisition - v.HumanoidRootPart.Position).Magnitude <= dis then
	  local wep, dmgId = module:CheckWep()
	  table.insert(vics, v)
      pcall(function()
	    RE.ToolDamageObject:InvokeServer(
         vics,
         wep,
         dmgId,
         CFrame.new(v.HumanoidRootPart.CFrame)
	    )
	  end)
    end
  end
end
function module:CheckStatus(s)
  if s == "Discontinued" then setclipboard("Discordlmao") p1:Kick("The Script Is Discontinued, Join Our Discord To know the problem")
  elseif s == "Broken" then return
  elseif s == "Detected" then return end
end
return module
