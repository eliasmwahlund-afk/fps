--!strict
-- Puts players at a spawn point when they (re)spawn, picking the one farthest
-- from everyone else so nobody spawns right in front of an enemy.
--
-- Spawn points are parts inside a Workspace folder called "SpawnPoints". You
-- can build that folder in Studio with your own parts. If it doesn't exist,
-- this script makes a ring of points around the middle of the map.

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")

local RESPAWN_TIME = 3 -- seconds between dying and coming back
local SPAWN_PROTECTION = 3 -- seconds you can't be hurt after spawning (shooting ends it early)
local DEFAULT_POINT_COUNT = 8
local DEFAULT_RING_RADIUS = 60 -- studs from the middle of the map

Players.RespawnTime = RESPAWN_TIME

local function makeDefaultSpawnPoints(): Folder
	local folder = Instance.new("Folder")
	folder.Name = "SpawnPoints"

	for i = 1, DEFAULT_POINT_COUNT do
		local angle = (i / DEFAULT_POINT_COUNT) * math.pi * 2
		local position = Vector3.new(math.cos(angle), 0, math.sin(angle)) * DEFAULT_RING_RADIUS

		local point = Instance.new("Part")
		point.Name = `Spawn{i}`
		point.Size = Vector3.new(4, 1, 4)
		point.Anchored = true
		point.CanCollide = false
		point.CanQuery = false -- bullets fly straight through
		point.CanTouch = false
		point.Transparency = 1
		point.CFrame = CFrame.lookAt(position, Vector3.zero) -- face the middle
		point.Parent = folder
	end

	folder.Parent = workspace
	return folder
end

local spawnFolder = workspace:FindFirstChild("SpawnPoints") or makeDefaultSpawnPoints()

local function getSpawnPoints(): { BasePart }
	local points = {}
	for _, child in spawnFolder:GetChildren() do
		if child:IsA("BasePart") then
			table.insert(points, child)
		end
	end
	return points
end

-- Positions of every other player who is alive right now.
local function getEnemyPositions(except: Player): { Vector3 }
	local positions = {}
	for _, other in Players:GetPlayers() do
		local character = other.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if other ~= except and humanoid and humanoid.Health > 0 and root and root:IsA("BasePart") then
			table.insert(positions, root.Position)
		end
	end
	return positions
end

local function pickSpawnPoint(player: Player): BasePart?
	local points = getSpawnPoints()
	if #points == 0 then
		return nil
	end

	local enemies = getEnemyPositions(player)
	if #enemies == 0 then
		return points[math.random(#points)]
	end

	-- Score each point by how close its nearest enemy is; the safest point wins.
	local best: BasePart? = nil
	local bestDistance = -1
	for _, point in points do
		local nearest = math.huge
		for _, enemyPosition in enemies do
			nearest = math.min(nearest, (enemyPosition - point.Position).Magnitude)
		end
		if nearest > bestDistance then
			best = point
			bestDistance = nearest
		end
	end
	return best
end

local function onCharacterAdded(player: Player, character: Model)
	if not character:WaitForChild("HumanoidRootPart", 5) then
		return
	end
	task.wait() -- let Roblox finish its own spawn placement first, then move them

	local point = pickSpawnPoint(player)
	if point then
		character:PivotTo(point.CFrame + Vector3.new(0, 3, 0))
	end

	-- Swap the SpawnLocation's long ForceField for our short one.
	for _, child in character:GetChildren() do
		if child:IsA("ForceField") then
			child:Destroy()
		end
	end
	local forceField = Instance.new("ForceField")
	forceField.Parent = character
	Debris:AddItem(forceField, SPAWN_PROTECTION)
end

local function onPlayerAdded(player: Player)
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
	if player.Character then
		onCharacterAdded(player, player.Character)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end
