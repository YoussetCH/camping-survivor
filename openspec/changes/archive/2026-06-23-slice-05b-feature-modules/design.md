# Design — Slice 05b: Feature Modules

## Context

Slice-05 implemented camp plots, structure placement, chest storage, camp level 0→1, and craft stations. All structure-specific logic lives inside `CampService.luau` (~1000 lines) with hardcoded `blueprintId` branches. Cross-service coupling uses lazy `require`:

| From | To | Why |
|------|-----|-----|
| `CraftingService` | `CampService.isPlayerNearStation` | Validate craft_table / campfire proximity |
| `CampService` | `CraftingService.ensureStarterRecipesUnlocked` | Unlock recipes on camp level 1 |
| `SurvivalService` | `CampService.teleportPlayerToPlot` | Move player to plot on assign |

`StructureModelFactory` and `StructuresConstants` are monolithic — adding a structure means editing shared central files.

**Constraints:** No player-visible behavior change. No new remotes. No profile schema change. Strict Luau. OpenSpec slice before slice-06-world.

## Goals / Non-Goals

**Goals:**

- Each starter structure (campfire, chest, craft table) is a self-contained feature module with definition, model builder, and server behavior.
- `CampService` orchestrates generic camp lifecycle only; structure hooks delegate to `StructureBehaviorRegistry`.
- `CraftingService` resolves station proximity via `StationRegistry` (no `CampService` import).
- Cross-feature side effects use `GameEvents` (no lateral service `require` for notifications).
- New structures in future slices add a folder + register — no edits to `CampService` core logic.
- Preserve all slice-05 scenarios (place, demolish, move, chest transfer, camp level 1, craft at stations).

**Non-Goals:**

- Fogata fuel/tick, cooking, pot-on-campfire rules (GDD §6.4 future).
- New structure types (wall, trap, alarm, dock).
- Helper/pet feature modules (slice-09).
- Client-side feature registry (controllers stay as-is).
- Runtime feature toggling / plugin hot-reload.
- Splitting `CampService` into multiple services (single orchestrator remains).

## Decisions

### 1. Three-layer module layout

```
ReplicatedStorage/Shared/Features/
  Campfire/CampfireDefinition.luau    -- StructureDefinition export
  Campfire/CampfireModel.luau         -- buildModel(blueprintId, options?) -> Model
  Chest/ChestDefinition.luau
  Chest/ChestModel.luau
  CraftTable/CraftTableDefinition.luau
  CraftTable/CraftTableModel.luau

ServerScriptService/Features/
  StructureBehaviorRegistry.luau      -- register + lookup behaviors
  StationRegistry.luau                -- station proximity queries
  GameEvents.luau                     -- typed Signal bus (server-only)
  Behaviors/
    CampfireBehavior.luau
    ChestBehavior.luau
    CraftTableBehavior.luau
  FeatureBootstrap.luau               -- requires all behaviors at server start
```

**Rationale:** Shared holds data + visuals (client can require models for ghost preview later). Server holds authoritative hooks. Matches existing Services/Controllers/Repositories split.

**Alternative:** One file per feature — rejected; definition vs behavior separation keeps shared code server-safe.

### 2. StructureBehavior contract

```luau
export type StructureContext = {
  player: Player,
  data: PlayerProfile,
  structure: CampStructure,
  plotId: string,
}

export type StructureBehavior = {
  blueprintId: string,

  onPlace: (ctx: StructureContext) -> (),
  onDemolish: (ctx: StructureContext) -> (),
  validatePlacement: ((ctx: StructureContext & { position: Vector3, rotation: number }) -> (boolean, string?))?,
  onCampLevelRecalculate: ((ctx: { data: PlayerProfile }) -> ())?,
}
```

`CampService` calls registry after generic validation passes:

1. `validatePlacement` (optional) — structure-specific rules (none for starter trio).
2. Mutate profile + spawn world (generic).
3. `onPlace` — e.g. chest init `camp.chests[structureId] = {}`.
4. `recalculateCampLevel` — generic count + behavior `onCampLevelRecalculate` hooks.

**Rationale:** Minimal interface; extend later with `onTick` for fogata fuel without breaking callers.

**Alternative:** ECS — overkill for Roblox Luau camp structures.

### 3. StationRegistry replaces CampService.isPlayerNearStation

```luau
export type StationRegistryModule = {
  register: (stationId: string, rangeStuds: number, blueprintId: string) -> (),
  isPlayerNearStation: (player: Player, stationId: string) -> boolean,
}
```

Each behavior with `definition.station` registers on init. Registry reads player profile structures + world folder (same logic as current `CampProximity` + structure list).

`CraftingService` calls `StationRegistry.isPlayerNearStation(player, recipe.station)` — removes lazy `CampService` require.

Station ranges unchanged: `craft_table` = 12 studs, `campfire` = 8 studs (from `CampProximity`).

### 4. GameEvents for plot assignment

```luau
-- ServerScriptService/Features/GameEvents.luau
export type GameEventsModule = {
  CampPlotAssigned: RBXScriptSignal, -- (player: Player, plotId: string)
}
```

`CampService` fires `CampPlotAssigned` after assigning plot. `SurvivalService` (or a thin listener in `FeatureBootstrap`) subscribes and calls existing teleport logic — **or** `CampService.teleportPlayerToPlot` remains public but Survival listens to event instead of requiring CampService.

Implementation: `SurvivalService:Start` connects to `GameEvents.CampPlotAssigned` and teleports. Remove `require(CampService)` from SurvivalService.

Camp level 1 → starter recipe unlock: move trigger to `GameEvents.CampLevelChanged` or keep in `CampService.recalculateCampLevel` calling `CraftingService` via event `CampLevelReached(1)`. Prefer **event** to break Camp↔Craft cycle:

```luau
GameEvents.CampLevelChanged:Connect(function(player, newLevel, oldLevel)
  if newLevel >= 1 and oldLevel < 1 then
    CraftingService.ensureStarterRecipesUnlocked(player, data)
  end
end)
```

`CraftingService` subscribes in `:Start()` — `CampService` fires event, no `require(CraftingService)`.

### 5. StructuresConstants aggregation

`StructuresConstants.luau` becomes a thin aggregator:

```luau
local definitions = {}
for _, def in FeatureDefinitions.getAll() do
  definitions[def.id] = def
end
```

`FeatureDefinitions.luau` in Shared collects from `CampfireDefinition`, `ChestDefinition`, `CraftTableDefinition`.

**Rationale:** Single lookup API preserved; features own their data.

### 6. StructureModelFactory delegation

`StructureModelFactory.build(blueprintId)` looks up builder in `StructureModelRegistry` populated by feature model modules. Fallback to placeholder box if unregistered (dev safety).

Extract existing model code from monolithic factory into per-feature files unchanged visually (`MODEL_VERSION` stays 3).

### 7. Chest transfer ownership

`TransferItemEvent` handler moves from `CampService` to `ChestBehavior` (or `ChestService` thin wrapper). `CampService:Init` delegates remote wiring:

```luau
StructureBehaviorRegistry.bindRemotes(CampService) -- or ChestBehavior registers via FeatureBootstrap
```

Prefer **`FeatureBootstrap`** registering chest transfer handler directly — keeps `CampService` unaware of transfer logic.

Validation unchanged: server authoritative, owner-only, 24 slots.

### 8. Feature bootstrap order

New module `FeatureBootstrap.luau` called from `ServerKernel` or first line of `CampService:Init`:

1. Require all behavior modules (side effect: register with registry).
2. Register station ranges.
3. Bind behavior-specific remotes (chest transfer).
4. Connect GameEvents listeners (survival teleport, crafting unlock).

**Init order:** `NetworkingService` → `FeatureBootstrap` → other services. Add `FeatureBootstrap` to `ServerKernel.INIT_ORDER` before camp/crafting start.

### 9. Services, controllers, remotes (unchanged surface)

| Layer | Module | Change |
|-------|--------|--------|
| Service | `CampService` | Slim orchestrator |
| Service | `CraftingService` | StationRegistry only |
| Service | `SurvivalService` | GameEvents listener |
| Service | `InventoryService` | No change |
| Controller | `BuildingController`, `ChestController`, `CraftingHUDController` | No change |
| Remotes | All existing camp/craft remotes | No new names |

### 10. Security validations (preserved)

- Place/demolish/move: server validates plot ownership, blueprint in bag, grid, overlap, cap — all remain in `CampService`.
- Chest transfer: owner-only, slot validation, stack limits — remain in chest behavior.
- Craft: unlock, station via registry, inputs, cooldown — unchanged rules.

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| Registry not populated before service Start | `FeatureBootstrap` in INIT_ORDER before Camp/Crafting |
| Behavior hook throws mid-place leaves inconsistent state | Wrap hooks in pcall; rollback profile + world on failure |
| More files to navigate | Consistent `Features/<Name>/` convention; one behavior per structure |
| Circular requires if behaviors import CampService | Behaviors receive context from CampService; never require CampService |
| Regression in slice-05 flows | Full verify.md checklist before archive |

## Migration Plan

1. Add infrastructure (GameEvents, registries, FeatureBootstrap) — no behavior change.
2. Extract definitions/models for 3 structures — `StructuresConstants`/`StructureModelFactory` delegate.
3. Implement behaviors; wire CampService to registry.
4. Move chest transfer to ChestBehavior.
5. Switch CraftingService to StationRegistry.
6. Switch SurvivalService to GameEvents.
7. Remove dead code and lazy requires.
8. Run `rojo build` + Studio verify.md regression.
9. Archive; update Implementation-Plan with slice-05b entry.

**Rollback:** Revert to monolithic CampService (single commit); no datastore migration.

## Open Questions

- None blocking — starter trio has no extra placement rules. Future `bp_pot` will use `validatePlacement` for adjacent campfire check.
