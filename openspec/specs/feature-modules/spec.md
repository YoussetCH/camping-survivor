# Feature Modules — Technical Spec

**Status:** Implemented (slice-05b)  
**GDD:** Infrastructure  
**Modules:** `StructureBehaviorRegistry`, `StationRegistry`, `FeatureBootstrap`, `GameEvents`

## Purpose

Pluggable structure behaviors, station registry, game event bus, and folder conventions for isolated feature modules.
## Requirements
### Requirement: Structure behavior registry

The system SHALL provide a server-side `StructureBehaviorRegistry` that maps each structure `blueprintId` to a registered `StructureBehavior` module. The registry MUST expose `register(behavior)`, `get(blueprintId)`, and `getAll()` for lookup during camp lifecycle hooks.

#### Scenario: Behavior lookup on place

- GIVEN `CampfireBehavior` is registered for `bp_campfire`
- WHEN `CampService` completes generic placement validation for `bp_campfire`
- THEN the registry returns the campfire behavior
- AND `onPlace` is invoked with player, profile, structure, and plotId context

#### Scenario: Unknown blueprint has no behavior

- GIVEN no behavior is registered for a blueprint id
- WHEN placement succeeds for that blueprint
- THEN generic camp placement completes without behavior hooks
- AND no server error is thrown

### Requirement: Structure behavior lifecycle hooks

Each registered `StructureBehavior` MAY implement `onPlace`, `onDemolish`, `validatePlacement`, and `onCampLevelRecalculate`. The camp orchestrator SHALL invoke these hooks after generic validation and before or after profile mutation as defined in design, without embedding structure-specific logic in the orchestrator.

#### Scenario: Chest initializes storage on place

- GIVEN `ChestBehavior` is registered for `bp_chest`
- WHEN a player successfully places `bp_chest`
- THEN `onPlace` creates an empty slot map at `camp.chests[structureId]`

#### Scenario: Chest cleans storage on demolish

- GIVEN a placed chest with `camp.chests[structureId]` populated
- WHEN the owner demolishes that structure
- THEN `onDemolish` removes or merges chest contents per existing camp rules
- AND `camp.chests[structureId]` is cleared

### Requirement: Station registry for craft proximity

The system SHALL provide a server-side `StationRegistry` that registers craft station ids (`campfire`, `craft_table`, etc.) with proximity range and owning blueprint id. Crafting and other consumers MUST resolve station proximity through `StationRegistry.isPlayerNearStation(player, stationId)` without importing `CampService`.

#### Scenario: Craft table proximity via registry

- GIVEN the player owns a placed `bp_craft_table` within 12 studs
- WHEN `StationRegistry.isPlayerNearStation(player, "craft_table")` is called
- THEN the result is true

#### Scenario: Campfire too far via registry

- GIVEN the player has a campfire but stands more than 8 studs away
- WHEN `StationRegistry.isPlayerNearStation(player, "campfire")` is called
- THEN the result is false

### Requirement: Feature module folder convention

Each pluggable game element (structure or future helper) SHALL live under `ReplicatedStorage/Shared/Features/<FeatureName>/` for shared definition and model code, and `ServerScriptService/Features/Behaviors/<FeatureName>Behavior.luau` for server hooks. A `FeatureBootstrap` module MUST require all behavior modules at server init so registrations complete before camp and crafting services start.

#### Scenario: Bootstrap registers starter trio

- GIVEN the server has finished `FeatureBootstrap` init
- WHEN `StructureBehaviorRegistry.get("bp_campfire")`, `get("bp_chest")`, and `get("bp_craft_table")` are queried
- THEN each returns a non-nil behavior

### Requirement: Aggregated structure definitions

Structure definitions SHALL be exported from individual feature modules and aggregated into `StructuresConstants` via a shared collector module. Callers MUST continue to use `StructuresConstants.get(blueprintId)` without requiring feature modules directly.

#### Scenario: Constants API unchanged

- GIVEN feature modules export campfire, chest, and craft table definitions
- WHEN `StructuresConstants.get("bp_campfire")` is called
- THEN footprint is 2×2 grid cells
- AND station is `campfire`

### Requirement: Per-feature model builders

Structure 3D models SHALL be built by per-feature model modules registered in a `StructureModelRegistry`. `StructureModelFactory.build(blueprintId)` MUST delegate to the registered builder for that blueprint.

#### Scenario: Campfire model builds via registry

- GIVEN `CampfireModel` is registered for `bp_campfire`
- WHEN `StructureModelFactory.build("bp_campfire")` is called
- THEN a valid Model is returned with `ModelVersion` attribute matching the current factory version

### Requirement: Fauna registry

The system SHALL provide a server-side `FaunaRegistry` mapping each `speciesId` to a registered fauna behavior module. The registry MUST expose `register(behavior)`, `get(speciesId)`, and `getAll()`. `AnimalService` MUST resolve species stats, model builders, and hooks through the registry without species-specific branches.

#### Scenario: Wolf behavior registered

- GIVEN `WolfBehavior` registers on server init via `FaunaBootstrap`
- WHEN `FaunaRegistry.get("wolf")` is called
- THEN a non-nil behavior with species stats and drop table is returned

#### Scenario: Unknown species has no behavior

- GIVEN no behavior is registered for `bear`
- WHEN `FaunaRegistry.get("bear")` is called
- THEN the result is nil
- AND `AnimalService` skips spawn for that species

### Requirement: Fauna feature module folder convention

Each fauna species SHALL live under `ReplicatedStorage/Shared/Features/<SpeciesName>/` with `<Species>Definition.luau` and `<Species>Model.luau`. Server hooks live in `ServerScriptService/Features/Behaviors/<Species>Behavior.luau`. Aggregated species lists MAY live in `FaunaDefinitions.luau` similar to `FeatureDefinitions.luau`.

#### Scenario: Wolf module isolation

- GIVEN the wolf feature folder and registry entry exist
- WHEN wolf is removed from `FaunaBootstrap` and registry
- THEN wolves no longer spawn and no wolf-specific code remains in `AnimalService`

### Requirement: Helper behavior registry

The system SHALL provide a server-side `HelperBehaviorRegistry` that maps each `helperTypeId` to a registered helper behavior module. The registry MUST expose `register(behavior)`, `get(helperTypeId)`, and `getAll()`. `HelperService` SHALL delegate task execution and recruitment validation to registry lookups — no `if helperTypeId ==` branches in the orchestrator.

#### Scenario: Lumberjack behavior lookup

- GIVEN `LumberjackBehavior` is registered for `lumberjack`
- WHEN `HelperService` runs a work tick for a lumberjack instance
- THEN the registry returns lumberjack behavior
- AND `onWorkTick` is invoked with player, profile, and helper state context

### Requirement: Helper feature module folder convention

Each helper type SHALL live under `ReplicatedStorage/Shared/Features/<HelperName>/` (definition + model) and `ServerScriptService/Features/Behaviors/<HelperName>Behavior.luau`. `HelperBootstrap` MUST require all helper behavior modules at server init before `HelperService` starts.

#### Scenario: Disable lumberjack by module removal

- GIVEN lumberjack folder and registry entry are removed
- WHEN the server starts
- THEN no lumberjack recruitment or work ticks run
- AND other helpers (future) remain unaffected if registered separately

## Related

- [camp/spec.md](../camp/spec.md)
- [crafting/spec.md](../crafting/spec.md)
- [foundation/spec.md](../foundation/spec.md)
