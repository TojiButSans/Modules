local Utility = {}
-- Variables
local plr = game.Players.LocalPlayer
local regs = workspace.Regions
-- functions
function Utility:GetPlayerCountry()
  local plr = game.Players.LocalPlayer
end
function Utility:GetAllTiles()
  local tiles = {}
  for _, v in pairs(regs:GetChildren()) do
    if v:IsA("Folder") then
      if v:GetAttribute("Country", GetPlayerCountry)
        table.insert(tiles, v)
      end
    end
  end
  return tiles
end
return Utility
