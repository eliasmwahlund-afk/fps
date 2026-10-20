--!strict
-- Server side of the pistol. Builds the tool, then checks every shot before
-- doing damage. The client only tells us where it aimed; everything else
-- (fire rate, range, what got hit, how much damage) is decided here.

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPack = game:GetService("StarterPack")

local GunConfig = require(ReplicatedStorage.Shared.GunConfig)

local GUN_NAME = "Pistol"
local stats = GunConfig[GUN_NAME]

-- A little slack so shots aren't rejected because of network lag.
local MIN_SHOT_INTERVAL = (1 / stats.fireRate) * 0.9

local function getRemotesFolder(): Instance
	local existing = ReplicatedStorage:FindFirstChild("Remotes")
	if existing then
		return existing
	end
	local folder = Instance.new("Folder")
	folder.Name = "Remotes"
	folder.Parent = ReplicatedStorage
	return folder
end

local fireGun = Instance.new("RemoteEvent")
fireGun.Name = "FireGun"
fireGun.Parent = getRemotesFolder()

-- Build the pistol and put it in StarterPack so every player spawns with one.
local function buildPistol(): Tool
	local tool = Instance.new("Tool")
	tool.Name = GUN_NAME
	tool.CanBeDropped = false

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.3, 0.6, 1.4)
	handle.Color = Color3.fromRGB(45, 45, 50)
	handle.Material = Enum.Material.Metal
	handle.CanCollide = false
	handle.Massless = true
	handle.Parent = tool

	return tool
end

buildPistol().Parent = StarterPack

-- Walk up from the part that was hit to find a character's Humanoid, if any.
local function getHumanoidFromPart(part: Instance): Humanoid?
	local model = part:FindFirstAncestorOfClass("Model")
	while model do
		local humanoid = model:FindFirstChildOfClass("Humanoid")
		if humanoid then
			return humanoid
		end
		model = model:FindFirstAncestorOfClass("Model")
	end
	return nil
end

-- A quick bullet streak so everyone can see the shot.
local function showTracer(from: Vector3, to: Vector3)
	local distance = (to - from).Magnitude
	if distance < 0.01 then
		return
	end

	local tracer = Instance.new("Part")
	tracer.Anchored = true
	tracer.CanCollide = false
	tracer.CanQuery = false
	tracer.CanTouch = false
	tracer.Material = Enum.Material.Neon
	tracer.Color = Color3.fromRGB(255, 220, 120)
	tracer.Size = Vector3.new(0.1, 0.1, distance)
	tracer.CFrame = CFrame.lookAt(from, to) * CFrame.new(0, 0, -distance / 2)
	tracer.Parent = workspace
	Debris:AddItem(tracer, 0.05)
end

local lastShotAt: { [Player]: number } = {}

fireGun.OnServerEvent:Connect(function(player: Player, aimPosition: unknown)
	-- The client can send anything, so make sure it's a real position.
	if typeof(aimPosition) ~= "Vector3" then
		return
	end
	local aim = aimPosition :: Vector3
	if aim ~= aim then -- NaN check
		return
	end

	-- The player must be alive and actually holding the pistol.
	local character = player.Character
	if not character then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return
	end
	local tool = character:FindFirstChild(GUN_NAME)
	if not tool or not tool:IsA("Tool") then
		return
	end
	local handle = tool:FindFirstChild("Handle")
	if not handle or not handle:IsA("BasePart") then
		return
	end

	-- Fire rate: ignore shots that come in faster than the gun allows.
	local now = os.clock()
	local last = lastShotAt[player]
	if last and now - last < MIN_SHOT_INTERVAL then
		return
	end
	lastShotAt[player] = now

	-- Fire the ray from the gun's real position on the server, up to the gun's range.
	local origin = handle.Position
	local toAim = aim - origin
	if toAim.Magnitude < 0.01 then
		return
	end
	local direction = toAim.Unit * stats.range

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }

	local result = workspace:Raycast(origin, direction, params)
	showTracer(origin, if result then result.Position else origin + direction)

	if result then
		local target = getHumanoidFromPart(result.Instance)
		if target and target.Health > 0 then
			target:TakeDamage(stats.damage)
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	lastShotAt[player] = nil
end)
