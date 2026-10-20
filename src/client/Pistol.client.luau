--!strict
-- Client side of the pistol. When the player clicks while holding it, tell the
-- server where they aimed. The server decides whether anything was hit.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GunConfig = require(ReplicatedStorage.Shared.GunConfig)

local GUN_NAME = "Pistol"
local MIN_SHOT_INTERVAL = 1 / GunConfig[GUN_NAME].fireRate

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local fireGun = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("FireGun") :: RemoteEvent

local hookedUp: { [Tool]: boolean } = {}
local lastShotAt = 0

local function onChildAdded(child: Instance)
	if not child:IsA("Tool") or child.Name ~= GUN_NAME or hookedUp[child] then
		return
	end
	hookedUp[child] = true

	child.Activated:Connect(function()
		-- Match the server's fire rate so shots aren't thrown away.
		local now = os.clock()
		if now - lastShotAt < MIN_SHOT_INTERVAL then
			return
		end
		lastShotAt = now
		fireGun:FireServer(mouse.Hit.Position)
	end)
end

-- Tools move into the character when equipped, so watch the character.
local function onCharacterAdded(character: Model)
	hookedUp = {} -- a new character means a fresh copy of the pistol
	for _, child in character:GetChildren() do
		onChildAdded(child)
	end
	character.ChildAdded:Connect(onChildAdded)
end

player.CharacterAdded:Connect(onCharacterAdded)
if player.Character then
	onCharacterAdded(player.Character)
end
