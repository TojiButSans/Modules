local Utility = {}
-- Variables
local plr = game.Players.LocalPlayer
-- functions
function Utility:GetAllPlayers()
    local chars = {}
    for _, v in ipairs(game.Players:GetPlayers()) do
        if v ~= plr then
            table.insert(chars, v.Character)
        end
    end
    return chars
end
return Utitlity
