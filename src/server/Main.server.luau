--!strict
-- Server entry point. Runs once when the game starts.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GunConfig = require(ReplicatedStorage.Shared.GunConfig)

print(`[Server] Rojo sync works! Pistol damage is {GunConfig.Pistol.damage}.`)
