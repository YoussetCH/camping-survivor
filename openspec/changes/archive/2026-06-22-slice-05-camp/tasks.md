# Tasks — Slice 05: Camp

## 1. Types & constants

- [x] 1.1 Extend `Camp.luau` with `CampStructure`, chest maps, and extended `CampData` / `CampSnapshot`
- [x] 1.2 Update `PlayerProfile.luau`, `PlayerProfileTemplate.luau` with `structures` and `chests`
- [x] 1.3 Create `StructuresConstants.luau` (starter blueprints: campfire, chest, craft_table)
- [x] 1.4 Add `bp_chest`, `bp_craft_table` to `Items.luau`
- [x] 1.5 Add `recipe_chest`, `recipe_craft_table` to `Recipes.luau`

## 2. Dev camp hub (Workspace)

- [x] 2.1 Create `Workspace/CampHub/` with 8 tagged plot parts (`CampPlot`, `PlotId` attribute)
- [x] 2.2 Add placeholder structure templates under `ServerStorage/StructureTemplates/`

## 3. Remotes

- [x] 3.1 Register `PlaceStructureEvent`, `PlaceStructureResultEvent`, `DemolishStructureEvent`, `DemolishStructureResultEvent`, `TransferItemEvent` in `Remotes.luau`
- [x] 3.2 Add Rojo RemoteEvent instances under `Remotes/Events/`

## 4. Server camp

- [x] 4.1 Create `CampRepository.luau` (normalize/reconcile camp profile slice)
- [x] 4.2 Create `CampService.luau` (plot scan, assign, place, demolish, level, world spawn)
- [x] 4.3 Extend `PlayerSyncService` with full camp snapshot (structures + chests)
- [x] 4.4 Hook `CampService` on profile load (assign plot, respawn structures)
- [x] 4.5 Extend studio dev grant with construction materials for testing

## 5. Inventory & crafting integration

- [x] 5.1 Implement chest transfer handler in `InventoryService` or `CampService` with `TransferItemEvent`
- [x] 5.2 Extend `CraftingConstants` for `craft_table` / `campfire` stations
- [x] 5.3 Extend `CraftingService` with `CampService.getNearbyStation` validation
- [x] 5.4 Add `ensureStarterRecipesUnlocked` when camp level reaches 1

## 6. Client UI

- [x] 6.1 Extend `ClientSyncController` camp cache (structures, chests)
- [x] 6.2 Create `BuildingController.luau` (build mode, ghost preview, place/demolish intent)
- [x] 6.3 Create `ChestController.luau` (chest panel, transfer intent)
- [x] 6.4 Add localization keys (`ui.build.*`, `ui.chest.*`, `camp.error.*`, `camp.success.*`) in `en` / `es`
- [x] 6.5 Register controllers in client bootstrap

## 7. Survival polish

- [x] 7.1 Teleport respawn to assigned plot center when `plotId` is set (optional: first assign only)

## 8. Specs & archive prep

- [x] 8.1 Merge deltas into `openspec/specs/camp/spec.md`, `crafting/spec.md`, `inventory/spec.md`, `ui/spec.md`, `foundation/spec.md`
- [x] 8.2 Run `verify.md` checklist
- [x] 8.3 Archive with `openspec archive slice-05-camp` (after user approval)

## Verification

- [x] Run `verify.md` — all items checked
