--!strict
-- All damage in the game goes through here, so the server always knows who
-- landed the killing blow. Guns call Combat.dealDamage instead of TakeDamage.

local Players = game:GetService("Players")

local Combat = {}

local playerKilled = Instance.new("BindableEvent")

-- Humanoids that have already died. We can't just check Health, because
-- Roblox's built-in health regen keeps running on a dead character and nudges
-- its Health back above 0. Without this, shooting a body would count as a
-- second kill.
local alreadyDead: { [Humanoid]: boolean } = setmetatable({}, { __mode = "k" }) :: any

-- Fires with (killer: Player, victim: Player) when one player kills another.
Combat.PlayerKilled = playerKilled.Event

-- Set to false between rounds so nobody can be hurt.
Combat.enabled = true

-- What a hit did: "none" (no damage, e.g. a ForceField), "hit" or "kill".
export type HitResult = "none" | "hit" | "kill"

-- Damage a Humanoid on behalf of a player. If the hit is lethal, the attacker
-- gets the kill.
function Combat.dealDamage(attacker: Player, target: Humanoid, amount: number): HitResult
	if not Combat.enabled then
		return "none"
	end
	if alreadyDead[target] or target.Health <= 0 then
		return "none" -- already dead, nobody gets credit for hitting a body
	end

	-- TakeDamage does nothing while the target has a spawn ForceField.
	local healthBefore = target.Health
	target:TakeDamage(amount)
	if target.Health >= healthBefore then
		return "none"
	elseif target.Health > 0 then
		return "hit"
	end
	alreadyDead[target] = true

	local victimCharacter = target.Parent
	local victim = if victimCharacter and victimCharacter:IsA("Model")
		then Players:GetPlayerFromCharacter(victimCharacter)
		else nil

	if victim and victim ~= attacker then
		print(`[Combat] {attacker.Name} killed {victim.Name}`)
		playerKilled:Fire(attacker, victim)
	else
		print(`[Combat] {attacker.Name} killed {victimCharacter and victimCharacter.Name or "something"}`)
	end
	return "kill"
end

return Combat
