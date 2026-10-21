--!strict
-- Gun Game progression. Everyone starts on the first weapon in WeaponLadder.
-- Each kill moves the killer up one weapon, and a kill with the last weapon
-- wins. Kills and Level show in the player list (top right).
-- Only kills on real players count; the target dummy doesn't.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local WeaponLadder = require(ReplicatedStorage.Shared.WeaponLadder)
local Combat = require(script.Parent.Combat)

local gunsFolder = ServerStorage:WaitForChild("Guns")

local function getStat(player: Player, name: string): IntValue?
	local leaderstats = player:FindFirstChild("leaderstats")
	local stat = leaderstats and leaderstats:FindFirstChild(name)
	if stat and stat:IsA("IntValue") then
		return stat
	end
	return nil
end

local function setUpLeaderstats(player: Player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats" -- this exact name makes Roblox show it in the player list

	local level = Instance.new("IntValue")
	level.Name = "Level"
	level.Value = 1
	level.Parent = leaderstats

	local kills = Instance.new("IntValue")
	kills.Name = "Kills"
	kills.Value = 0
	kills.Parent = leaderstats

	leaderstats.Parent = player
end

-- Take away the player's current gun and give them the one for their level.
local function giveWeapon(player: Player)
	local level = getStat(player, "Level")
	local character = player.Character
	if not level or not character then
		return
	end
	local backpack = player:WaitForChild("Backpack", 5)
	local humanoid = character:WaitForChild("Humanoid", 5)
	if not backpack or not humanoid or not humanoid:IsA("Humanoid") then
		return
	end

	for _, container in { backpack, character } do
		for _, child in container:GetChildren() do
			if child:IsA("Tool") then
				child:Destroy()
			end
		end
	end

	local template = gunsFolder:FindFirstChild(WeaponLadder[level.Value])
	if not template then
		warn(`[GunGame] No gun called {WeaponLadder[level.Value]}; check WeaponLadder and GunConfig`)
		return
	end
	local tool = template:Clone() :: Tool
	tool.Parent = backpack
	if humanoid.Health > 0 then
		humanoid:EquipTool(tool)
	end
end

local function onPlayerAdded(player: Player)
	setUpLeaderstats(player)
	player.CharacterAdded:Connect(function()
		giveWeapon(player)
	end)
	if player.Character then
		task.spawn(giveWeapon, player)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end

-- Everyone goes back to the first weapon.
local function resetEveryone()
	for _, player in Players:GetPlayers() do
		local level = getStat(player, "Level")
		if level then
			level.Value = 1
			task.spawn(giveWeapon, player)
		end
	end
end

Combat.PlayerKilled:Connect(function(killer: Player, _victim: Player)
	local kills = getStat(killer, "Kills")
	local level = getStat(killer, "Level")
	if not kills or not level then
		return
	end
	kills.Value += 1

	if level.Value >= #WeaponLadder then
		print(`[GunGame] {killer.Name} wins!`)
		-- Proper rounds come in the next step. For now everyone starts over.
		resetEveryone()
		return
	end

	level.Value += 1
	print(`[GunGame] {killer.Name} levelled up to {WeaponLadder[level.Value]}`)
	task.spawn(giveWeapon, killer)
end)
