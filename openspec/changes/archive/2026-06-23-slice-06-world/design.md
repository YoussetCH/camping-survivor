# Design — Slice 06: World

## Context

- Slice-05 creates `CampHub` plots at runtime via `CampService.ensureCampHub()` on a 512-stud dev baseplate.
- `SurvivalService` uses `SurvivalConstants.DEFAULT_AMBIENT_TEMPERATURE = 45` as placeholder until world exists.
- No world services, biome tags, or harvest remotes exist.
- Items for forest nodes already defined: `berry`, `wood`, `stick`, `stone`, `leaf`, `tinder`, `fiber`.
- GDD §5.16: nodes tagged `ResourceNode`; zones tagged `BiomeZone` with `BiomeId` attribute.

## Goals / Non-Goals

**Goals:** Dev world with `camp_hub` + `forest_near`, authoritative harvest loop, shared node respawn, 20 min day/night with Lighting sync, biome ambient feeding survival tick, passive client HUD for time phase.

**Non-Goals:** Fauna, weather events, full map art, map fog, POIs, clues, fishing/mining complexity, biome hard gates, night visibility gameplay.

## Decisions

### Dev world authored in Rojo (`src/Workspace/World/`)

```
Workspace/
  World/
    BiomeZones/
      camp_hub/      (Part, BiomeZone tag, BiomeId=camp_hub)
      forest_near/   (Part ring around hub, BiomeId=forest_near)
    ResourceNodes/
      berry_bush_01/ (Part + ProximityPrompt template attrs)
      ...
```

`CampService` keeps generating plots inside `camp_hub` bounds. `BiomeService` scans `CollectionService:GetTagged("BiomeZone")` at start.

**Alternative:** Procedural biome from heightmap — rejected for v0.1; GDD expects authored zones.

### Biome ambient table (v0.1)

| BiomeId | Day ambient | Night ambient | Notes |
|---------|-------------|---------------|-------|
| `camp_hub` | 50 | 45 | Safe zone |
| `forest_near` | 45 | 25 | GDD §5.7 |
| `forest_deep` | 42 | 22 | Constants only; zone stub optional |
| `mountain` | 30 | 10 | Constants only |
| `swamp` | 40 | 35 | Constants only |
| `coast` | 55 | 48 | Constants only |
| _(default)_ | 45 | 30 | Outside any zone |

`BiomeService.getAmbientForPlayer(player)` returns interpolated day/night value from `DayNightService.getPhase()`.

### Day/night cycle

| Parameter | Value |
|-----------|-------|
| Full cycle | 1200 s (20 min) |
| Day length | 840 s (14 min) |
| Night length | 360 s (6 min) |
| Transition | 30 s at dawn/dusk (Lighting tween) |

Server owns elapsed time; sets `Lighting.ClockTime` each tick. Fires `WorldUpdatedEvent` to all clients on phase change and every 30 s with `{ phase: "day" | "night" | "dawn" | "dusk", cycleProgress: number }`.

**Alternative:** Client-local clock — rejected; survival must use server phase.

### Resource node model

Nodes are anchored Parts tagged `ResourceNode` with attributes:

| Attribute | Type | Example |
|-----------|------|---------|
| `NodeId` | string | `berry_bush_01` |
| `NodeType` | string | `gather` \| `chop` |
| `Outputs` | string | JSON or comma: `berry:2-3` |
| `RequiredTool` | string? | `axe_*` pattern for chop |
| `HarvestTime` | number | 1.5 s hold default |

Server tracks per-node state in memory:

```luau
type NodeState = {
  depleted: boolean,
  respawnAt: number?, -- os.clock()
  lastHarvestByPlayer: { [number]: number }, -- userId -> os.clock() anti-spam
}
```

Constants in `ResourceNodesConstants` map `NodeType` → default respawn (common 180 s global, 60 s per-player cooldown).

### Harvest validation (server)

| Check | Rule |
|-------|------|
| Distance | Player character root ≤ **12 studs** from node |
| Depleted | Node not in depleted state |
| Player cooldown | ≥ 60 s since same player harvested same node (common) |
| Tool | `chop` requires equipped tool id matching `axe_*` or `stone_axe` |
| Bag space | `InventoryService.tryGrantItems` before marking depleted |

Client sends `{ nodeId: string }` via `HarvestResourceEvent`. Server responds `HarvestResourceResultEvent` with `{ success, reasonKey?, items? }`.

**Hold time:** Client shows progress bar for `HarvestTime`; server validates elapsed time ≥ harvest time using timestamp sent on confirm OR server starts hold on first event and completes on second — **v0.1 simplification:** single event after client hold completes; server trusts hold duration only as minimum delay check using `os.clock()` from session start map (client sends `{ nodeId, holdDuration }`; server rejects if `holdDuration < node.HarvestTime - 0.2`).

Actually for security, better: two-phase or server-side hold tracking. Simplest secure approach:

1. Client fires `BeginHarvestEvent` → server records start time
2. Client fires `CompleteHarvestEvent` after hold → server checks elapsed ≥ HarvestTime

For minimal scope: **single `HarvestResourceEvent`** — server uses fixed instant grant for `gather` nodes (no hold) and for `chop` requires tool only. Hold UI is client-only cosmetic; server does not validate hold duration in v0.1 (document as known limitation, add in slice-07).

### Node depletion & respawn

On successful harvest:
1. Grant items
2. Set node `depleted = true`, `respawnAt = now + respawnSeconds`
3. Set node part transparency / disable prompt (replicate via attribute `Depleted=true`)
4. On respawn timer: clear depleted, reset attribute

Shared multiplayer: first successful harvest depletes for everyone.

### Service dependencies

```
DayNightService (no deps)
BiomeService → DayNightService
ResourceService → InventoryService, BiomeService (optional zone check)
SurvivalService → BiomeService
```

Init order: add `DayNightService` before `BiomeService` before `ResourceService` in `ServerKernel.INIT_ORDER` if needed (alphabetical default may work: Biome before Resource before Survival).

### Remotes

| Event | Direction | Payload |
|-------|-----------|---------|
| `HarvestResourceEvent` | C→S | `{ nodeId: string }` |
| `HarvestResourceResultEvent` | S→C | `{ success: boolean, reasonKey?: string, granted?: { itemId, quantity }[] }` |
| `WorldUpdatedEvent` | S→C | `{ phase: string, cycleProgress: number, serverTime: number }` |

### Client controllers

**ResourceController**
- On `CollectionService` tag `ResourceNode`, attach proximity listener
- When in range and not depleted, show prompt (localized)
- On trigger → fire `HarvestResourceEvent`
- Show toast from `HarvestResourceResultEvent`

**WorldController**
- Listen `WorldUpdatedEvent`; update small HUD icon (sun/moon) + optional phase label
- Passive display only

### Localization keys

- `resource.prompt.gather`, `resource.prompt.chop`
- `resource.error.too_far`, `resource.error.depleted`, `resource.error.no_tool`, `resource.error.bag_full`
- `resource.success.harvest`
- `ui.world.phase.day`, `ui.world.phase.night`, `ui.world.phase.dawn`, `ui.world.phase.dusk`

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| Dev world too small for 8 plots + forest | Expand baseplate to 800×800 in bootstrap |
| Instant harvest exploitable | Per-player cooldown + distance check; hold validation deferred |
| Many nodes = many prompts | Limit v0.1 to ~12 nodes in forest_near |
| Lighting changes affect camp visibility | Keep brightness moderate; camp_hub well-lit at night |

## Migration Plan

1. Ship Rojo world folders; bootstrap ensures baseplate if missing
2. Services scan tags at Init — no profile migration
3. Survival ambient change is behavioral only (players feel colder at night in forest)

## Open Questions

- _(none blocking v0.1)_ — full map layout deferred to slice-10 biomes-mid
