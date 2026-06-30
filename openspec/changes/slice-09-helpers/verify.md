# Verify — Slice 09: Helpers

## Automated / code

- [ ] All new files have `--!strict`
- [ ] Helper remotes registered in `Remotes.luau` and exist under `ReplicatedStorage.Remotes.Events`
- [ ] Helper stats are server-authoritative (client sends helper id + slot/mode only)
- [ ] No helper-type branches in `HelperService` orchestrator (uses `HelperBehaviorRegistry`)
- [ ] Lumberjack model is a readable silhouette (not a single placeholder cube)
- [ ] All helper player-visible strings use localization keys
- [ ] `rojo build` succeeds
- [ ] `openspec validate slice-09-helpers` passes

## Studio manual (Rojo serve)

1. [ ] Complete `main_01_chest` — `main_05_lumberjack` becomes available
2. [ ] Travel to `forest_deep` — lumberjack escort NPC spawns at `HelperSpawn`
3. [ ] Escort NPC follows player toward camp plot
4. [ ] Enter plot with NPC — quest completes; lumberjack joins helper roster
5. [ ] Open helper panel (`H`) — hunger/health bars visible with localized name
6. [ ] Lumberjack in work mode — after ~60 s with campfire active, player receives wood
7. [ ] Feed helper with food item — hunger increases; sync updates panel
8. [ ] Set shelter mode — wood gathering stops; hunger drains slower
9. [ ] Apply bandage via cure action when helper has bleeding (test via dev inflict if needed)
10. [ ] Let hunger hit 0 — weak state; helper stops working; warning toast appears
11. [ ] Third helper recruitment attempt — rejected at max 2
12. [ ] Switch locale EN → ES — panel text updates

## Regression

- [ ] Quest tracker/journal, survival HUD, inventory, crafting, camp build still work
- [ ] Fauna combat and quest progression still work
- [ ] Client bootstrap completes without remote errors

## Done criteria

All checkboxes checked. `tasks.md` is 100% `[x]` except archive step. User approval required before archive.
