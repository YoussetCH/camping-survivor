# Verify — Slice 09: Helpers

## Automated / code

- [x] All new files have `--!strict`
- [x] Helper remotes registered in `Remotes.luau` and exist under `ReplicatedStorage.Remotes.Events`
- [x] Helper stats are server-authoritative (client sends helper id + slot/mode only)
- [x] No helper-type branches in `HelperService` orchestrator (uses `HelperBehaviorRegistry`)
- [x] Lumberjack model is a readable silhouette (not a single placeholder cube)
- [x] All helper player-visible strings use localization keys
- [x] `rojo build` succeeds
- [x] `openspec validate slice-09-helpers` passes

## Studio manual (Rojo serve)

1. [x] Complete `main_01_chest` — `main_05_lumberjack` becomes available
2. [x] Travel to `forest_deep` — lumberjack escort NPC spawns at `HelperSpawn`
3. [x] Escort NPC follows player toward camp plot
4. [x] Enter plot with NPC — quest completes; lumberjack joins helper roster
5. [x] Open helper panel (`H`) — hunger/health bars visible with localized name
6. [x] Lumberjack in work mode — after ~60 s with campfire active, player receives wood
7. [x] Feed helper with food item — hunger increases; sync updates panel
8. [x] Set shelter mode — wood gathering stops; hunger drains slower
9. [x] Apply bandage via cure action when helper has bleeding (test via dev inflict if needed)
10. [x] Let hunger hit 0 — weak state; helper stops working; warning toast appears
11. [x] Third helper recruitment attempt — rejected at max 2
12. [x] Switch locale EN → ES — panel text updates

## Regression

- [x] Quest tracker/journal, survival HUD, inventory, crafting, camp build still work
- [x] Fauna combat and quest progression still work
- [x] Client bootstrap completes without remote errors

## Done criteria

All checkboxes checked. `tasks.md` is 100% `[x]` except archive step. User approval required before archive.
