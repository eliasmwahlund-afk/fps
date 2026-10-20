--!strict
-- Client entry point. Runs on each player's computer when they join.

local Players = game:GetService("Players")

print(`[Client] Hello, {Players.LocalPlayer.Name}! Client scripts are syncing too.`)
