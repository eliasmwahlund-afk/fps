--!strict
-- Client side of every gun. When the player clicks while holding a gun, tell
-- the server where they aimed. Automatic guns keep firing while the button is
-- held. The server decides whether anything was hit.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GunConfig = require(ReplicatedStorage.Shared.GunConfig)

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local fireGun = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("FireGun") :: RemoteEvent

local hookedUp: { [Tool]: boolean } = {}
local lastShotAt = 0

-- Match the server's fire rate so shots aren't thrown away.
local function tryFire(stats: GunConfig.GunStats)
	local now = os.clock()
	if now - lastShotAt < 1 / stats.fireRate then
		return
	end
	lastShotAt = now
	fireGun:FireServer(mouse.Hit.Position)
end

local function onChildAdded(child: Instance)
	if not child:IsA("Tool") or hookedUp[child] then
		return
	end
	local stats = GunConfig[child.Name]
	if not stats then
		return
	end
	hookedUp[child] = true

	local triggerHeld = false

	child.Activated:Connect(function()
		if not stats.automatic then
			tryFire(stats)
			return
		end
		triggerHeld = true
		while triggerHeld and child.Parent == player.Character do
			tryFire(stats)
			task.wait()
		end
	end)
	child.Deactivated:Connect(function()
		triggerHeld = false
	end)
	child.Unequipped:Connect(function()
		triggerHeld = false
	end)
end

-- Tools move into the character when equipped, so watch the character.
local function onCharacterAdded(character: Model)
	hookedUp = {} -- a new character means fresh copies of the guns
	for _, child in character:GetChildren() do
		onChildAdded(child)
	end
	character.ChildAdded:Connect(onChildAdded)
end

player.CharacterAdded:Connect(onCharacterAdded)
if player.Character then
	onCharacterAdded(player.Character)
end
