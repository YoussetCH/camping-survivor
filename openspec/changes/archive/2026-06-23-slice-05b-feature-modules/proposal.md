# Proposal — Slice 05b: Feature Modules

## Why

Camp structures (campfire, chest, craft table) and future features (pets, traps, walls) are implemented as inline logic inside monolithic services (`CampService` ~1000 lines, lazy `require` cycles with `CraftingService` and `SurvivalService`). Adding or reusing a feature requires editing central services instead of dropping in a self-contained module. This refactor establishes a **pluggable feature architecture** so each game element is isolated behind a registry contract while preserving all slice-05 player-visible behavior.

## What Changes

- Introduce **`feature-modules`** capability: `StructureBehaviorRegistry`, `StationRegistry`, and `GameEvents` for cross-feature communication without service-to-service `require` cycles.
- Extract existing starter structures into dedicated feature modules:
  - `CampfireFeature` — definition, model builder, station registration
  - `ChestFeature` — storage init/cleanup, transfer handlers
  - `CraftTableFeature` — definition, model, station registration
- Slim **`CampService`** to orchestration only: plots, grid validation, place/demolish/move lifecycle, camp level, world spawn — delegating structure-specific hooks to the behavior registry.
- Decouple **`CraftingService`** from `CampService`: station proximity via `StationRegistry`.
- Decouple **`SurvivalService`** from `CampService`: plot teleport via `GameEvents.CampPlotAssigned`.
- Split **`StructureModelFactory`** per-feature model builders; registry aggregates definitions into `StructuresConstants`.
- **No player-visible behavior changes** — same remotes, same validation rules, same camp level 0→1 logic, same chest 24 slots, same craft stations.
- **Out of scope:** fogata fuel/tick, new structures (wall, pot, trap), helper/pet features (slice-09), feature-flag toggling, client-side feature modules beyond existing controllers.

## Capabilities

### New Capabilities

- `feature-modules`: Pluggable structure behaviors, station registry, game event bus, and folder conventions for server/shared feature modules.

### Modified Capabilities

- `camp`: Structure-specific placement, demolition, storage, and level side-effects SHALL delegate to registered structure behaviors instead of inline `blueprintId` checks in `CampService`.
- `crafting`: Camp station proximity SHALL be resolved through `StationRegistry`, not direct calls to `CampService.isPlayerNearStation`.
- `foundation`: Cross-feature notifications (e.g. plot assignment) SHALL use `GameEvents` instead of direct service imports where applicable.

## Impact

| Area | Change |
|------|--------|
| `CampService.luau` | Major refactor — remove chest/campfire/table-specific branches |
| `CraftingService.luau` | Replace `CampService` require with `StationRegistry` |
| `SurvivalService.luau` | Replace `CampService.teleportPlayerToPlot` with event listener |
| `PlayerDataService.luau` | Unchanged API; may listen to events if needed |
| `StructuresConstants.luau` | Aggregates definitions from feature modules |
| `StructureModelFactory.luau` | Delegates to per-feature model builders |
| New folders | `Shared/Features/`, `ServerScriptService/Features/` |
| Remotes | No new remotes; existing events unchanged |
| Profile schema | No changes |
| Tests / verify | Full slice-05 regression (place, demolish, chest, craft at stations, camp level 1) |
