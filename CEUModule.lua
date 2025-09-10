local Utility = {}

-- Variables
local plr = game.Players.LocalPlayer
local regs = workspace:WaitForChild("Regions")

-- Functions
function Utility:FireRemote(REpath, REargs)
  REpath::FireServer(unpack(REargs))
end
function Utility:GetAllTiles()
	local tiles = {}
	for _, v in ipairs(regs:GetChildren()) do
		if v:IsA("Folder") then
			if v:GetAttribute("Core") == plr:GetAttribute("MyCountry") then
				table.insert(tiles, v)
			end
		end
	end
	return tiles
end

return Utility
