## ADDED Requirements

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
