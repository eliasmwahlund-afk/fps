# Roblox Gun Game

A Roblox gun game built by a beginner with AI help. Explain changes simply.

## Project layout
- Scripts live in `src/` and sync into Roblox Studio with Rojo (`default.project.json`).
  - `src/server/` → ServerScriptService.Server (damage, ammo, scoring, rounds)
  - `src/client/` → StarterPlayer.StarterPlayerScripts.Client (input, UI, effects)
  - `src/shared/` → ReplicatedStorage.Shared (config and modules both sides use)
- File names: `*.server.luau` = Script, `*.client.luau` = LocalScript, plain `*.luau` = ModuleScript.
- Never ask the user to edit scripts inside Studio; Rojo would overwrite them. Maps, models and
  UI layouts built in Studio are fine and stay in the place file.

## Code rules
- Luau with `--!strict` at the top of every script.
- Format with StyLua and keep Selene clean (`stylua src` and `selene src`).
- Gun stats live in `src/shared/GunConfig.luau`.
- RemoteEvents go in `ReplicatedStorage.Remotes`, created by the server, one per action.

## Security (important for gun games)
- The server is the authority. The client only says "I fired, aiming here".
- The server checks ammo, fire rate, range and line of sight, then applies damage.
- Never trust values sent by the client (damage, hit target, ammo count, position jumps).

## Working style
- Make small, focused changes and say how to test each one in Studio (press Play, check Output).
- Suggest a git commit when a change works.
