--!strict
-- Server side of every gun. Builds one Tool per gun in GunConfig and keeps
-- them in ServerStorage.Guns, where Progression hands out copies. Then checks
-- every shot before doing damage. The client only tells us where it aimed;
-- everything else (which gun, fire rate, range, spread, what got hit, how much
-- damage) is decided here.

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local GunConfig = require(ReplicatedStorage.Shared.GunConfig)
local Combat = require(script.Parent.Combat)
local Remotes = require(script.Parent.Remotes)

-- A little slack so shots aren't rejected because of network lag.
local LAG_SLACK = 0.9

local random = Random.new()

local fireGun = Remotes.get("FireGun")
local hitConfirmed = Remotes.get("HitConfirmed") -- sent to the shooter: (killed: boolean)

local function buildGun(name: string, stats: GunConfig.GunStats): Tool
	local tool = Instance.new("Tool")
	tool.Name = name
	tool.CanBeDropped = false

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = stats.size
	handle.Color = stats.color
	handle.Material = Enum.Material.Metal
	handle.CanCollide = false
	handle.Massless = true
	handle.Parent = tool

	return tool
end

local gunsFolder = Instance.new("Folder")
gunsFolder.Name = "Guns"
for name, stats in GunConfig do
	buildGun(name, stats).Parent = gunsFolder
end
gunsFolder.Parent = ServerStorage

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

-- A little flash of sparks where a bullet lands.
local function showImpact(position: Vector3)
	local spark = Instance.new("Part")
	spark.Shape = Enum.PartType.Ball
	spark.Size = Vector3.new(0.5, 0.5, 0.5)
	spark.Anchored = true
	spark.CanCollide = false
	spark.CanQuery = false
	spark.CanTouch = false
	spark.Material = Enum.Material.Neon
	spark.Color = Color3.fromRGB(255, 200, 90)
	spark.Position = position
	spark.Parent = workspace
	Debris:AddItem(spark, 0.08)
end

-- Tilt a direction by a random angle of up to `degrees`, in a random direction.
local function applySpread(direction: Vector3, degrees: number): Vector3
	if degrees <= 0 then
		return direction
	end
	local roll = CFrame.Angles(0, 0, random:NextNumber(0, math.pi * 2))
	local tilt = CFrame.Angles(random:NextNumber(0, math.rad(degrees)), 0, 0)
	return (CFrame.lookAt(Vector3.zero, direction) * roll * tilt).LookVector * direction.Magnitude
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

	-- The player must be alive and holding one of our guns. Guns only ever come
	-- from the server, so a cheater can't invent a better one.
	local character = player.Character
	if not character then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return
	end
	local tool = character:FindFirstChildOfClass("Tool")
	if not tool then
		return
	end
	local stats = GunConfig[tool.Name]
	if not stats then
		return
	end
	local handle = tool:FindFirstChild("Handle")
	if not handle or not handle:IsA("BasePart") then
		return
	end

	-- Fire rate: ignore shots that come in faster than this gun allows.
	local now = os.clock()
	local last = lastShotAt[player]
	if last and now - last < (1 / stats.fireRate) * LAG_SLACK then
		return
	end
	lastShotAt[player] = now

	-- Shooting ends your spawn protection early, so nobody can fire from safety.
	local forceField = character:FindFirstChildOfClass("ForceField")
	if forceField then
		forceField:Destroy()
	end

	-- Fire from the gun's real position on the server, up to the gun's range.
	local origin = handle.Position
	local toAim = aim - origin
	if toAim.Magnitude < 0.01 then
		return
	end
	local aimDirection = toAim.Unit * stats.range

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }

	-- A shotgun fires several pellets but the shooter gets one hit marker.
	local anyHit = false
	local anyKill = false

	for _ = 1, stats.pellets do
		local direction = applySpread(aimDirection, stats.spread)
		local result = workspace:Raycast(origin, direction, params)
		showTracer(origin, if result then result.Position else origin + direction)

		if result then
			showImpact(result.Position)
			local target = getHumanoidFromPart(result.Instance)
			if target then
				local hit = Combat.dealDamage(player, target, stats.damage)
				anyHit = anyHit or hit ~= "none"
				anyKill = anyKill or hit == "kill"
			end
		end
	end

	if anyHit then
		hitConfirmed:FireClient(player, anyKill)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	lastShotAt[player] = nil
end)
