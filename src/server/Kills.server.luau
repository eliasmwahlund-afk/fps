--!strict
-- Counts kills per player and shows them in the player list (top right).
-- Only kills on real players count; the target dummy doesn't.

local Players = game:GetService("Players")

local Combat = require(script.Parent.Combat)

local function setUpLeaderstats(player: Player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats" -- this exact name makes Roblox show it in the player list

	local kills = Instance.new("IntValue")
	kills.Name = "Kills"
	kills.Value = 0
	kills.Parent = leaderstats

	leaderstats.Parent = player
end

Players.PlayerAdded:Connect(setUpLeaderstats)
for _, player in Players:GetPlayers() do
	setUpLeaderstats(player)
end

Combat.PlayerKilled:Connect(function(killer: Player, _victim: Player)
	local leaderstats = killer:FindFirstChild("leaderstats")
	local kills = leaderstats and leaderstats:FindFirstChild("Kills")
	if kills and kills:IsA("IntValue") then
		kills.Value += 1
	end
end)
