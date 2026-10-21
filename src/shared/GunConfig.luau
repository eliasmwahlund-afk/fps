--!strict
-- Stats for every gun in the game. Tweak numbers here; the server reads them
-- when deciding damage, so players can't change them.
-- The order players go through the guns lives in WeaponLadder.luau.

export type GunStats = {
	damage: number, -- per bullet (a shotgun fires several)
	fireRate: number, -- shots per second
	magazineSize: number,
	reloadTime: number, -- seconds
	range: number, -- studs
	pellets: number, -- bullets per shot; more than 1 makes a shotgun
	spread: number, -- degrees each bullet can stray from where you aimed
	automatic: boolean, -- true = hold the mouse button to keep firing
	color: Color3, -- what the gun looks like
	size: Vector3,
}

local GunConfig: { [string]: GunStats } = {
	Pistol = {
		damage = 25,
		fireRate = 4,
		magazineSize = 12,
		reloadTime = 1.5,
		range = 300,
		pellets = 1,
		spread = 0,
		automatic = false,
		color = Color3.fromRGB(45, 45, 50),
		size = Vector3.new(0.3, 0.6, 1.4),
	},
	SMG = {
		damage = 14,
		fireRate = 10,
		magazineSize = 30,
		reloadTime = 1.8,
		range = 200,
		pellets = 1,
		spread = 3,
		automatic = true,
		color = Color3.fromRGB(60, 70, 90),
		size = Vector3.new(0.35, 0.7, 1.8),
	},
	Shotgun = {
		damage = 12,
		fireRate = 1.2,
		magazineSize = 6,
		reloadTime = 2.5,
		range = 80,
		pellets = 8,
		spread = 7,
		automatic = false,
		color = Color3.fromRGB(110, 70, 40),
		size = Vector3.new(0.4, 0.6, 2.6),
	},
	Rifle = {
		damage = 30,
		fireRate = 6,
		magazineSize = 25,
		reloadTime = 2,
		range = 400,
		pellets = 1,
		spread = 1,
		automatic = true,
		color = Color3.fromRGB(70, 85, 55),
		size = Vector3.new(0.35, 0.7, 2.8),
	},
	Sniper = {
		damage = 90,
		fireRate = 0.8,
		magazineSize = 5,
		reloadTime = 3,
		range = 1000,
		pellets = 1,
		spread = 0,
		automatic = false,
		color = Color3.fromRGB(30, 30, 30),
		size = Vector3.new(0.35, 0.6, 3.6),
	},
	-- The last weapon. It's a "gun" with a very short range, so the same shot
	-- checks work for stabbing.
	Knife = {
		damage = 55,
		fireRate = 2,
		magazineSize = math.huge,
		reloadTime = 0,
		range = 7,
		pellets = 1,
		spread = 0,
		automatic = false,
		color = Color3.fromRGB(200, 200, 210),
		size = Vector3.new(0.15, 0.3, 1.4),
	},
}

return GunConfig
