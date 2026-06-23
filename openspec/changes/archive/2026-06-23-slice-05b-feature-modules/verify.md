# Verify — Slice 05b: Feature Modules

## Automated / code

- [x] All new files have `--!strict`
- [x] `StructureBehaviorRegistry` registers campfire, chest, craft table at server start
- [x] `CampService` has no inline `if blueprintId == "bp_chest"` (or campfire/craft_table) for feature logic
- [x] `CraftingService` does not require `CampService` — uses `StationRegistry` only
- [x] `SurvivalService` does not require `CampService` — uses `GameEvents.CampPlotAssigned`
- [x] `CampService` does not require `CraftingService` — uses `GameEvents.CampLevelChanged`
- [x] Chest transfer handler lives under `ServerScriptService/Features/Behaviors/` (or chest feature tree)
- [x] No client-side camp mutation (controllers unchanged — fire remotes only)
- [x] Server validates plot ownership, bounds, overlap, blueprint consumption, chest ownership (unchanged rules)
- [x] `rojo build` succeeds
- [x] `openspec validate slice-05b-feature-modules` passes

## Studio manual (Rojo serve)

1. [x] Play — server logs show FeatureBootstrap + behavior registration without errors
2. [x] Player receives a plot on first join (`CampUpdatedEvent` shows `plotId`); teleport to plot works
3. [x] Craft `bp_campfire` via hands recipes (existing flow)
4. [x] Press `B` — build mode opens; ghost preview visible (models unchanged visually)
5. [x] Place campfire on plot — blueprint consumed, structure appears in world
6. [x] Reach camp level 1 — place chest + craft table; `camp.level` becomes 1
7. [x] Starter recipes unlock after level 1 (`RecipesUpdatedEvent`)
8. [x] Craft `bp_chest` at craft table (within 12 studs) — fails when too far
9. [x] Craft at campfire station (within 8 studs) — proximity via StationRegistry works
10. [x] Place chest; open chest UI — deposit and withdraw items via transfer
11. [x] Attempt placement outside plot — error toast, no mutation
12. [x] Demolish chest — storage cleared/merged per rules; structure removed from world
13. [x] Demolish other structures — partial material refund if space allows
14. [x] Rejoin — plot, structures, and chest contents persist
15. [x] Switch locale — build and chest UI strings update (EN ↔ ES)

## Regression (prior slices)

- [x] Survival HUD, inventory HUD (`I`), crafting panel (`C`), language panel still work
- [x] Client bootstrap completes without remote errors
- [x] Studio dev grant still provides starter items
- [x] Tutorial hands crafting still works away from camp
- [x] Localization sync on join still works

## Done criteria

All checkboxes checked. `tasks.md` is 100% `[x]`. User approval required before archive.
