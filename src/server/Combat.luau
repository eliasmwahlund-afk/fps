--!strict
-- All damage in the game goes through here, so the server always knows who
-- landed the killing blow. Guns call Combat.dealDamage instead of TakeDamage.

local Players = game:GetService("Players")

local Combat = {}

local playerKilled = Instance.new("BindableEvent")

-- Fires with (killer: Player, victim: Player) when one player kills another.
Combat.PlayerKilled = playerKilled.Event

-- Damage a Humanoid on behalf of a player. If the hit is lethal, the attacker
-- gets the kill.
function Combat.dealDamage(attacker: Player, target: Humanoid, amount: number)
	if target.Health <= 0 then
		return -- already dead, nobody gets credit for hitting a body
	end

	-- TakeDamage does nothing while the target has a spawn ForceField.
	target:TakeDamage(amount)
	if target.Health > 0 then
		return
	end

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
end

return Combat
