# World — Technical Spec

**Status:** Implemented (slice-06)  
**GDD:** Cap. 5  
**Services:** BiomeService, DayNightService, ResourceService

## Purpose

Biome zones, resource node harvesting, day/night cycle, and ambient temperature context for survival. Fauna and weather events are slice-07+.

## Requirements

### Requirement: Biome zones

The system SHALL tag authored zone parts with `BiomeZone` (CollectionService) and a string attribute `BiomeId` matching GDD zone ids (`camp_hub`, `forest_near`, etc.).

#### Scenario: Player in forest_near

- GIVEN a player character's HumanoidRootPart is inside a `BiomeZone` with `BiomeId = "forest_near"`
- WHEN `BiomeService` resolves the player's biome
- THEN the returned biome id is `forest_near`

#### Scenario: Outside all zones

- GIVEN a player is not inside any `BiomeZone`
- WHEN `BiomeService` resolves the player's biome
- THEN the returned biome id is the default fallback

### Requirement: Biome ambient temperature

The system SHALL expose ambient temperature per biome for day and night phases per GDD §5.7–5.10. v0.1 MUST wire `camp_hub` and `forest_near`; other biomes MAY exist as constants-only stubs.

#### Scenario: Forest near day ambient

- GIVEN phase is `day` and biome is `forest_near`
- WHEN ambient temperature is queried
- THEN the value is **45**

#### Scenario: Forest near night ambient

- GIVEN phase is `night` and biome is `forest_near`
- WHEN ambient temperature is queried
- THEN the value is **25**

### Requirement: Day/night cycle

The system SHALL run a **20 minute** real-time cycle (**14 min** day, **6 min** night) via `DayNightService`, updating server `Lighting.ClockTime` and broadcasting phase to clients.

#### Scenario: Phase broadcast

- GIVEN the server is running
- WHEN the cycle phase changes (dawn, day, dusk, night)
- THEN all clients receive `WorldUpdatedEvent` with the new phase

#### Scenario: Cycle duration

- GIVEN the server starts a fresh cycle at phase `day`
- WHEN 14 minutes elapse
- THEN the phase transitions toward `dusk` then `night`

### Requirement: Resource nodes

Resource harvest points SHALL be tagged `ResourceNode` with attributes `NodeId`, `NodeType` (`gather` | `chop`), and output item definitions. v0.1 dev world MUST include at least **6** nodes in `forest_near` producing existing raw items.

#### Scenario: Node discovery at server start

- GIVEN tagged `ResourceNode` instances exist under `Workspace/World/ResourceNodes`
- WHEN `ResourceService` initializes
- THEN each node is registered by `NodeId` without duplicate ids

### Requirement: Authoritative harvest

The system SHALL process harvest only through `ResourceService` on `HarvestResourceEvent`. The server MUST validate distance (≤ **12 studs**), node not depleted, per-player cooldown, tool requirement for `chop`, and bag capacity before granting items.

#### Scenario: Successful gather

- GIVEN a player within 12 studs of a non-depleted `gather` node outputting `berry` × 2
- WHEN the client fires `HarvestResourceEvent` with valid `nodeId`
- THEN the server grants berries to the bag
- AND fires `HarvestResourceResultEvent` with `success = true`
- AND marks the node depleted until global respawn

#### Scenario: Too far rejected

- GIVEN a player is 20 studs from the node
- WHEN the client fires `HarvestResourceEvent`
- THEN the server rejects with reason key `resource.error.too_far`
- AND inventory is unchanged

#### Scenario: Chop requires axe

- GIVEN a `chop` node and the player has no axe tool equipped
- WHEN the client fires `HarvestResourceEvent`
- THEN the server rejects with reason key `resource.error.no_tool`

#### Scenario: Bag full

- GIVEN the player's bag cannot accept the harvest output
- WHEN the client fires `HarvestResourceEvent`
- THEN the server rejects with reason key `resource.error.bag_full`
- AND the node remains available

### Requirement: Shared node respawn

Harvested nodes SHALL deplete for all players until a global respawn timer elapses (common nodes: **180 s** default). Depleted nodes MUST set a replicable `Depleted` attribute on the world instance.

#### Scenario: Respawn after timer

- GIVEN a node was harvested and depleted
- WHEN 180 seconds pass
- THEN the node becomes harvestable again
- AND `Depleted` attribute is cleared

### Requirement: Dev world layout

The project SHALL include a dev world with `camp_hub` biome zone encompassing existing camp plots and a `forest_near` zone with harvestable nodes outside the hub.

#### Scenario: Forest reachable on foot

- GIVEN a player spawns at camp hub
- WHEN they walk outward from plots
- THEN they enter `forest_near` within **30 seconds** without teleport
