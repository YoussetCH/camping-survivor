## ADDED Requirements

### Requirement: Camp plot assignment

The system SHALL assign a free camp plot to a player on first profile load when `camp.plotId` is nil. Plots are defined in Workspace with CollectionService tag `CampPlot` and string attribute `PlotId`. Assignment MUST persist to the player profile.

#### Scenario: First join receives plot

- GIVEN a new player with `camp.plotId` nil
- WHEN player data loads on the server
- THEN the server assigns the nearest unoccupied plot
- AND `camp.plotId` is persisted
- AND `CampUpdatedEvent` fires with the updated camp snapshot

#### Scenario: Rejoin keeps plot

- GIVEN a returning player with `camp.plotId` set
- WHEN player data loads
- THEN the same plot is retained
- AND structures are respawned in world from profile data

### Requirement: Structure blueprint catalog

The system SHALL define starter structure blueprints in `StructuresConstants` for `bp_campfire`, `bp_chest`, and `bp_craft_table` with grid footprint, max HP (where applicable), and optional craft station id.

#### Scenario: Campfire blueprint metadata

- GIVEN `StructuresConstants.get("bp_campfire")` is queried
- WHEN the definition loads
- THEN footprint is 2×2 grid cells (4 studs per cell)
- AND station is `campfire`

### Requirement: Server-authoritative structure placement

The system SHALL process `PlaceStructureEvent` on the server. The client MUST send `blueprintId`, `position`, and `rotation` only. The server MUST validate plot ownership, blueprint in bag, grid bounds inside plot, no overlap, structure cap, and camp level before consuming the blueprint and creating the structure.

#### Scenario: Successful placement

- GIVEN a player owns a plot and bag contains 1× `bp_campfire`
- WHEN the client fires `PlaceStructureEvent` with valid in-bounds position
- THEN the blueprint is consumed from the bag
- AND a structure entry is added to `camp.structures`
- AND a world instance is spawned under the plot
- AND `PlaceStructureResultEvent` fires with `success = true`
- AND `CampUpdatedEvent` and `InventoryUpdatedEvent` reflect changes

#### Scenario: Out of bounds rejected

- GIVEN a placement position outside the player's plot footprint
- WHEN the client fires `PlaceStructureEvent`
- THEN inventory and structures are unchanged
- AND `PlaceStructureResultEvent` fires with `success = false` and reason key `camp.error.out_of_bounds`

#### Scenario: Overlap rejected

- GIVEN an existing structure occupies the target grid cells
- WHEN the client fires `PlaceStructureEvent` for another structure overlapping it
- THEN the request is rejected without mutation

### Requirement: Structure demolition

The system SHALL process `DemolishStructureEvent` for structures on the player's own plot. Demolish MUST remove the structure from profile and world and refund 50% of the blueprint recipe inputs as raw items when bag space allows.

#### Scenario: Owner demolishes chest

- GIVEN a player placed `bp_chest` on their plot
- WHEN the client fires `DemolishStructureEvent` with that structure id
- THEN the structure is removed
- AND chest contents are merged into bag when possible or cleared with server log
- AND `CampUpdatedEvent` fires

### Requirement: Camp level progression (v0.1)

The system SHALL recalculate `camp.level` after structure changes. Level 1 requires at least one placed instance each of `bp_campfire`, `bp_chest`, and `bp_craft_table`. Level MUST NOT decrease when structures are demolished (v0.1: level is monotonic max achieved).

#### Scenario: Reach camp level 1

- GIVEN camp level is 0
- WHEN the player has placed campfire, chest, and craft table
- THEN `camp.level` becomes 1
- AND `CampUpdatedEvent` includes `level = 1`

### Requirement: Camp chest storage

Each placed `bp_chest` structure SHALL have an independent storage of **24** slots keyed by `structureId` under `camp.chests`. Only the plot owner MAY read or mutate that chest via server handlers.

#### Scenario: Empty chest on place

- GIVEN a player places `bp_chest`
- WHEN placement succeeds
- THEN `camp.chests[structureId]` exists as an empty slot map

### Requirement: Structure persistence and respawn

The system SHALL persist `camp.structures[]` with `structureId`, `blueprintId`, `position`, `rotation`, and `hp`. On join, the server MUST spawn world instances for all persisted structures on the player's plot.

#### Scenario: Structures survive rejoin

- GIVEN a player placed structures and leaves
- WHEN they rejoin
- THEN world instances match persisted structure count and positions
- AND `CampUpdatedEvent` includes the structure list

### Requirement: Structure cap by camp level

The system SHALL enforce a maximum of **10** placed structures when `camp.level` is 0 or 1.

#### Scenario: Cap blocks extra placement

- GIVEN a player already has 10 structures on their plot
- WHEN they attempt to place an 11th
- THEN the request is rejected with reason key `camp.error.structure_cap`
