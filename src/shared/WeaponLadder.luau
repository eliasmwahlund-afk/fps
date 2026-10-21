--!strict
-- The order of weapons in Gun Game. Everyone starts on the first one, each
-- kill moves you one step down the list, and a kill with the last one wins.
-- Every name here must match a gun in GunConfig.luau.

local WeaponLadder: { string } = {
	"Pistol",
	"SMG",
	"Shotgun",
	"Rifle",
	"Sniper",
	"Knife",
}

return WeaponLadder
