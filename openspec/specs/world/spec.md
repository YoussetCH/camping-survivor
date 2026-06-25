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

### Requirement: Fauna registry and feature modules

Each fauna species SHALL live under `ReplicatedStorage/Shared/Features/<Species>/` (definition + model) with server behavior in `ServerScriptService/Features/Behaviors/<Species>Behavior.luau`. A `FaunaRegistry` MUST map `speciesId` to behavior and stats. `FaunaBootstrap` MUST require all fauna behaviors at server init before `AnimalService` starts.

#### Scenario: Registry lookup for wolf

- GIVEN `WolfBehavior` registered for `wolf`
- WHEN `AnimalService` resolves species `wolf`
- THEN the registry returns wolf stats, model builder, and attack/drop hooks

### Requirement: Fauna spawning

The system SHALL spawn fauna from tagged `FaunaSpawn` markers at server start. v0.1 MUST include at least **3 wolf** and **2 snake** spawns in `forest_near`. Each active fauna instance MUST have a unique `faunaId` and readable model (not a single placeholder cube).

#### Scenario: Spawn at server start

- GIVEN tagged `FaunaSpawn` parts exist with `SpeciesId = "wolf"`
- WHEN `AnimalService` initializes
- THEN wolf models appear under `Workspace/World/Fauna/`
- AND each model has attribute `FaunaId` and `SpeciesId`

#### Scenario: Per-player fauna cap

- GIVEN 8 fauna already active within 100 studs of a player
- WHEN a new spawn would enter that radius
- THEN the spawn is deferred or skipped until cap frees

### Requirement: Fauna AI state machine

The server SHALL run fauna AI on a **1 second** tick with states: `idle`, `patrol`, `alert`, `chase`, `attack`, `flee` (flee unused in v0.1). Wolves in `forest_near` MUST NOT chase players during `day` phase; they MAY chase during `dusk` and `night`. Snakes MUST ambush (hidden until alert) when players enter detection range.

#### Scenario: Wolf passive by day

- GIVEN phase is `day` and a player enters wolf detection range (40 studs)
- WHEN the AI tick runs
- THEN wolf enters `alert` but does not enter `chase`

#### Scenario: Wolf aggressive at night

- GIVEN phase is `night` and a player is within 40 studs
- WHEN the AI tick runs
- THEN wolf enters `chase` toward the player
- AND enters `attack` within melee range (12 studs)

### Requirement: Fauna melee attack

When fauna attacks a player in melee range, the server SHALL apply species damage and status effects via `SurvivalService.applyDamage`. Attack cooldown MUST be enforced server-side (wolf: **2 s**, snake: **1.5 s**).

#### Scenario: Wolf bite damage

- GIVEN a wolf in `attack` state within 12 studs of a player
- WHEN attack cooldown elapsed
- THEN player loses 15 HP
- AND `bleeding` is applied with 60% probability

#### Scenario: Snake poison

- GIVEN a snake in `attack` state within 8 studs
- WHEN attack cooldown elapsed
- THEN player loses 8 HP
- AND `poison` is always applied

#### Scenario: Snake cobra telegraph

- GIVEN a snake starts a melee attack in range
- WHEN the attack begins
- THEN the snake visibly raises its head before damage resolves
- AND the strike lunge occurs after a short windup on the server

### Requirement: Player attack on fauna

The system SHALL process player attacks only through `AttackFaunaEvent`. The server MUST validate fauna exists, player within **10 studs**, tool equipped, and per-player cooldown **1 s**. Each valid hit SHALL deal **10 HP** to fauna (v0.1 axe damage).

#### Scenario: Successful fauna hit

- GIVEN a player with `stone_axe` equipped within 10 studs of a wolf at 40 HP
- WHEN the client fires `AttackFaunaEvent` with valid `faunaId`
- THEN wolf HP becomes 30
- AND `FaunaUpdatedEvent` broadcasts to nearby clients

#### Scenario: Attack too far rejected

- GIVEN a player is 15 studs from fauna
- WHEN the client fires `AttackFaunaEvent`
- THEN no damage is applied
- AND no remote error is thrown to client

#### Scenario: No tool rejected

- GIVEN the player has no tool equipped
- WHEN the client fires `AttackFaunaEvent`
- THEN no damage is applied

### Requirement: Fauna death and drops

When fauna HP reaches 0, the server SHALL roll drop table from species definition, grant items via `InventoryService` if bag has space, destroy the model, and fire `FaunaUpdatedEvent` with `removed = true`.

#### Scenario: Wolf drops fiber

- GIVEN a wolf dies and drop roll succeeds (50%)
- WHEN death is processed
- THEN player receives 1× `fiber` if bag accepts it
- AND fauna model is removed from workspace

### Requirement: Fauna sync event

The server SHALL fire `FaunaUpdatedEvent` to clients within **120 studs** when fauna HP changes or fauna is removed. On player join, nearby fauna state MUST be synced.

#### Scenario: HP bar update

- GIVEN a fauna takes damage
- WHEN HP changes
- THEN clients in range receive `FaunaUpdatedEvent` with `{ faunaId, hp, maxHp, speciesId }`

