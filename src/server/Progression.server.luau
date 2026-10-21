--!strict
-- Gun Game progression and rounds. Everyone starts on the first weapon in
-- WeaponLadder. Each kill moves the killer up one weapon, and a kill with the
-- last weapon wins the round. After a short break with no damage, everyone
-- respawns on the first weapon for a new round.
-- Kills and Level show in the player list (top right).
-- Only kills on real players count; the target dummy doesn't.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local WeaponLadder = require(ReplicatedStorage.Shared.WeaponLadder)
local Combat = require(script.Parent.Combat)
local Remotes = require(script.Parent.Remotes)

local INTERMISSION = 8 -- seconds between a win and the next round

-- The HUD on each player's screen listens to these.
local killFeed = Remotes.get("KillFeed") -- (killerName, victimName, weaponName)
local roundEnded = Remotes.get("RoundEnded") -- (winnerName, secondsUntilNextRound)
local roundStarted = Remotes.get("RoundStarted")

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

-- Everyone goes back to the first weapon with no kills, and respawns.
local function startNewRound()
	for _, player in Players:GetPlayers() do
		local level = getStat(player, "Level")
		local kills = getStat(player, "Kills")
		if level and kills then
			level.Value = 1
			kills.Value = 0
		end
		-- Respawning also hands out the pistol and picks a spawn point.
		task.spawn(function()
			player:LoadCharacter()
		end)
	end
	Combat.enabled = true
	roundStarted:FireAllClients()
	print("[GunGame] New round!")
end

local function endRound(winner: Player)
	Combat.enabled = false -- nobody can be hurt during the break
	print(`[GunGame] {winner.Name} wins!`)
	roundEnded:FireAllClients(winner.Name, INTERMISSION)
	task.delay(INTERMISSION, startNewRound)
end

Combat.PlayerKilled:Connect(function(killer: Player, victim: Player)
	local kills = getStat(killer, "Kills")
	local level = getStat(killer, "Level")
	if not kills or not level then
		return
	end
	kills.Value += 1
	killFeed:FireAllClients(killer.Name, victim.Name, WeaponLadder[level.Value])

	if level.Value >= #WeaponLadder then
		endRound(killer)
		return
	end

	level.Value += 1
	print(`[GunGame] {killer.Name} levelled up to {WeaponLadder[level.Value]}`)
	task.spawn(giveWeapon, killer)
end)
