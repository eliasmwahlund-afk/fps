# Roblox Gun Game

Starter project for building a Roblox gun game with Claude and other AI tools.
Scripts live as files in `src/`, and [Rojo](https://rojo.space) syncs them into Roblox Studio.

## First-time setup

1. Install [Git](https://git-scm.com), [VS Code](https://code.visualstudio.com) and Claude Code.
2. Clone this repo: in VS Code, open the command palette (Ctrl+Shift+P / Cmd+Shift+P),
   run **Git: Clone**, and paste this repo's URL.
3. When VS Code asks, install the **recommended extensions** (Rojo, Luau Language Server, StyLua, Selene).
4. In Roblox Studio, install the **Rojo** plugin (the Rojo VS Code extension offers to do it,
   or search "Rojo" in the Creator Store).

## Every time you work

1. In VS Code, open the command palette and run **Rojo: Open Menu**, then start the server
   for `default.project.json`.
2. In Studio, open your place (a Baseplate is fine to start), click the **Rojo** plugin, then **Connect**.
3. Press **Play**. The Output window should show:
   - `[Server] Rojo sync works! Pistol damage is 25.`
   - `[Client] Hello, <your name>! Client scripts are syncing too.`
4. Ask Claude Code for changes. Saved files appear in Studio within a second.
5. When something works, commit it with Git.

## Folder map

| Folder | Shows up in Studio as | Used for |
|---|---|---|
| `src/server` | ServerScriptService › Server | Damage, ammo, scoring, rounds |
| `src/client` | StarterPlayer › StarterPlayerScripts › Client | Input, UI, effects |
| `src/shared` | ReplicatedStorage › Shared | Gun stats and shared code |

See `CLAUDE.md` for the rules Claude follows in this project.

## Optional: command-line tools

If you want `rojo`, `stylua` and `selene` on the command line, install
[Rokit](https://github.com/rojo-rbx/rokit) and run `rokit install` in this folder.
