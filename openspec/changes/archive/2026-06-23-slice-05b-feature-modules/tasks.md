# Tasks — Slice 05b: Feature Modules

## 1. Infrastructure (registries & events)

- [x] 1.1 Create `Shared/Types/StructureBehavior.luau` with `StructureContext`, `StructureBehavior`, and placement context types
- [x] 1.2 Create `ServerScriptService/Features/GameEvents.luau` with `CampPlotAssigned` and `CampLevelChanged` signals
- [x] 1.3 Create `ServerScriptService/Features/StructureBehaviorRegistry.luau` (`register`, `get`, `getAll`)
- [x] 1.4 Create `ServerScriptService/Features/StationRegistry.luau` (`register`, `isPlayerNearStation`)
- [x] 1.5 Create `Shared/Features/StructureModelRegistry.luau` and `Shared/Features/FeatureDefinitions.luau` aggregators
- [x] 1.6 Create `ServerScriptService/Features/FeatureBootstrap.luau` — require behaviors, wire GameEvents listeners
- [x] 1.7 Add `FeatureBootstrap` to `ServerKernel.INIT_ORDER` before camp/crafting services start

## 2. Extract starter structure features (shared)

- [x] 2.1 Create `Shared/Features/Campfire/CampfireDefinition.luau` and `CampfireModel.luau` (extract from monolithic files)
- [x] 2.2 Create `Shared/Features/Chest/ChestDefinition.luau` and `ChestModel.luau`
- [x] 2.3 Create `Shared/Features/CraftTable/CraftTableDefinition.luau` and `CraftTableModel.luau`
- [x] 2.4 Refactor `StructuresConstants.luau` to aggregate from `FeatureDefinitions`
- [x] 2.5 Refactor `StructureModelFactory.luau` to delegate to `StructureModelRegistry`

## 3. Server behaviors

- [x] 3.1 Create `Behaviors/CampfireBehavior.luau` — register station `campfire` (8 studs) via `StationRegistry`
- [x] 3.2 Create `Behaviors/CraftTableBehavior.luau` — register station `craft_table` (12 studs)
- [x] 3.3 Create `Behaviors/ChestBehavior.luau` — `onPlace`/`onDemolish`, move `TransferItemEvent` handler from `CampService`
- [x] 3.4 Register all three behaviors in `FeatureBootstrap`

## 4. Decouple services

- [x] 4.1 Refactor `CampService` — remove inline `blueprintId` branches; call registry hooks; fire `GameEvents`
- [x] 4.2 Refactor `CraftingService` — use `StationRegistry.isPlayerNearStation`; remove `CampService` require
- [x] 4.3 Refactor `SurvivalService` — listen to `GameEvents.CampPlotAssigned` for teleport; remove `CampService` require
- [x] 4.4 Wire `GameEvents.CampLevelChanged` → `CraftingService.ensureStarterRecipesUnlocked`; remove `CampService` → `CraftingService` require
- [x] 4.5 Remove dead code and unused lazy requires; confirm no Camp↔Craft↔Survival circular imports

## 5. Rojo & project layout

- [x] 5.1 Add new folders/modules to `default.project.json` if needed for Rojo sync
- [x] 5.2 Confirm all new files use `--!strict` and follow folder conventions

## 6. Specs & archive prep

- [x] 6.1 Merge deltas into `openspec/specs/feature-modules/spec.md` (new), `camp/spec.md`, `crafting/spec.md`, `foundation/spec.md`
- [x] 6.2 Run `verify.md` checklist in Studio
- [x] 6.3 Run `openspec validate slice-05b-feature-modules`
- [x] 6.4 Update `docs/Implementation-Plan.md` with slice-05b entry
- [x] 6.5 Archive with `openspec archive slice-05b-feature-modules` (after user approval)

## Verification

- [x] Run `verify.md` — all items checked
