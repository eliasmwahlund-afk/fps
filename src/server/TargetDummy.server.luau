--!strict
-- Test helper: spawns a target dummy in front of the spawn point so you have
-- something to shoot in solo play. It respawns a few seconds after dying.
-- Delete this file once the game has real players or enemies to test on.

local DUMMY_POSITION = Vector3.new(0, 0, -20) -- where its feet stand
local RESPAWN_DELAY = 3

local function makePart(name: string, size: Vector3, position: Vector3): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Anchored = true
	part.Color = Color3.fromRGB(200, 170, 120)
	return part
end

local function spawnDummy()
	local model = Instance.new("Model")
	model.Name = "TargetDummy"

	local torso = makePart("Torso", Vector3.new(2, 4, 1), DUMMY_POSITION + Vector3.new(0, 2, 0))
	torso.Parent = model
	local head = makePart("Head", Vector3.new(1.5, 1, 1), DUMMY_POSITION + Vector3.new(0, 4.5, 0))
	head.Parent = model
	model.PrimaryPart = torso

	local humanoid = Instance.new("Humanoid")
	humanoid.RequiresNeck = false -- the parts aren't jointed, so don't die from that
	humanoid.Parent = model

	humanoid.Died:Connect(function()
		torso.Color = Color3.fromRGB(150, 40, 40)
		head.Color = Color3.fromRGB(150, 40, 40)
		task.wait(RESPAWN_DELAY)
		model:Destroy()
		spawnDummy()
	end)

	model.Parent = workspace
end

spawnDummy()
