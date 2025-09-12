local Utility = {}

-- Variables
local plr = game.Players.LocalPlayer
local regs = workspace:WaitForChild("Regions")

-- Functions
function Utility:FireRemote(REpath, REargs)
  REpath:FireServer(unpack(REargs))
end
function Utility:GetAllTiles()
	local tiles = {}
	for _, v in ipairs(regs:GetChildren()) do
		if v:IsA("Folder") then
			if v:GetAttribute("Country") == plr:GetAttribute("MyCountry") then
				table.insert(tiles, v)
			end
		end
	end
	return tiles
end
function Utility:GetMoney()
  local cash
  for _, v in pairs(RS:GetDescendants()) do
    if v.Name == plr:GetAttribute("MyCountry") then
      cash = v.Money
	end
  end
  return cash
end

return Utility
