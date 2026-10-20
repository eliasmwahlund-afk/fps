--!strict
-- Stats for every gun in the game. Tweak numbers here; the server reads them
-- when deciding damage, so players can't change them.

export type GunStats = {
	damage: number,
	fireRate: number, -- shots per second
	magazineSize: number,
	reloadTime: number, -- seconds
	range: number, -- studs
}

local GunConfig: { [string]: GunStats } = {
	Pistol = {
		damage = 25,
		fireRate = 4,
		magazineSize = 12,
		reloadTime = 1.5,
		range = 300,
	},
}

return GunConfig
