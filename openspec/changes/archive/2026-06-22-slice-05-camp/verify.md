# Verify — Slice 05: Camp

## Automated / code

- [x] All new files have `--!strict`
- [x] Remotes registered in `Remotes.luau` and exist under `ReplicatedStorage.Remotes.Events`
- [x] No client-side camp mutation (controllers fire remotes only)
- [x] Server validates plot ownership, bounds, overlap, blueprint consumption, chest ownership
- [x] Client sends placement/transfer intent only — never trusts local inventory/chest state for grants
- [x] `rojo build` succeeds
- [x] `openspec validate slice-05-camp` passes

## Studio manual (Rojo serve)

1. [x] Play — player receives a plot on first join (`CampUpdatedEvent` shows `plotId`)
2. [x] Craft `bp_campfire` via hands recipes (existing flow)
3. [x] Press `B` — build mode opens; ghost preview visible
4. [x] Place campfire on plot — blueprint consumed, structure appears in world
5. [x] Reach camp level 1 — place chest + craft table; `camp.level` becomes 1
6. [x] Starter recipes unlock (`recipe_chest`, `recipe_craft_table`) after level 1
7. [x] Craft `bp_chest` at craft table (within range) — fails when too far from table
8. [x] Place chest; open chest UI — deposit and withdraw items via transfer
9. [x] Attempt placement outside plot — error toast, no mutation
10. [x] Demolish a structure — removed from world; partial material refund if space allows
11. [x] Rejoin — plot, structures, and chest contents persist
12. [x] Switch locale — build and chest UI strings update (EN ↔ ES)

## Regression

- [x] Survival HUD, inventory HUD (`I`), crafting panel (`C`), language panel still work
- [x] Client bootstrap completes without remote errors
- [x] Studio dev grant still provides starter items
- [x] Tutorial hands crafting still works away from camp

## Done criteria

All checkboxes checked. `tasks.md` is 100% `[x]` except archive step. User approval required before archive.
