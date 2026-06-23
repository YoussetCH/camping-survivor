# Proposal — Slice 06: World

## Why

Camp (slice-05) gives players a home, but the game loop still lacks explorable space: no harvestable resource nodes, no biome context for survival temperature, and no day/night cycle. GDD Cap. 5 requires a shared map with regenerating nodes and environmental rhythm before fauna (slice-07), quests (slice-08), and helpers (slice-09) can anchor to world content.

## What Changes

- Author a **dev world layout** in Rojo: `camp_hub` (existing plots) + `forest_near` ring with tagged biome zones and starter resource nodes.
- Add **`ResourceService`** — server-authoritative harvest: distance, tool, cooldown, shared node depletion, global respawn timers.
- Add **`DayNightService`** — 20 min cycle (14 min day / 6 min night), Lighting sync, client HUD phase indicator.
- Add **`BiomeService`** — detect player biome from tagged `BiomeZone` parts; expose ambient temperature per GDD §5.7–5.10 (v0.1: `camp_hub`, `forest_near` fully wired; other biomes stubbed in constants).
- Wire **`SurvivalService`** to biome + day/night ambient instead of fixed `45`.
- Remotes: `HarvestResourceEvent`, `HarvestResourceResultEvent`, `WorldUpdatedEvent`.
- Client **`ResourceController`** (proximity + harvest intent) and **`WorldController`** (day/night HUD icon).
- Localization keys for harvest errors, node depleted, day/night labels.
- Studio dev grant adds no new items (nodes drop existing raw items: `berry`, `wood`, `stick`, `stone`, `leaf`, `tinder`).

## Out of scope

- **`AnimalService` / fauna AI** — slice-07
- **`WeatherService` / dynamic events** (storm, wolf pack, traveler) — slice-07+
- Full **1800×1800** authored map and all five biomes — v0.1 prototype zones only
- **Map fog**, first-discovery XP, POIs — slice-08+
- **Clue nodes** and helper recruitment at POIs — slice-08/09
- Fishing minigame, pickaxe mining tiers, water container collection — simplified gather/chop only in v0.1
- Biome **hard gates** (rope for coast, bandage for swamp) — terrain design only; no enforced blockers
- `wet` status from storms — slice-07+
- Night visibility reduction and lantern mechanics — cosmetic lighting only in v0.1

## Capabilities

### New Capabilities

_(world spec already stubbed — this slice fills it)_

### Modified Capabilities

- **world**: Define biome zones, resource nodes, harvest rules, day/night cycle, and service contracts (was stub).
- **survival**: Temperature drift SHALL use biome ambient + day/night modifier from world services instead of constant 45.
- **inventory**: ADDED server grant path for resource harvest (validated distance, node state, bag capacity).
- **ui**: ADDED resource harvest feedback (toast/result) and day/night HUD indicator.

## Impact

| Area | Change |
|------|--------|
| New services | `BiomeService`, `DayNightService`, `ResourceService` |
| `SurvivalService` | Query ambient from `BiomeService` + night modifier |
| `InventoryService` | Called by `ResourceService` to grant harvested items |
| `Remotes.luau` + Rojo | 3 new events |
| `Workspace/` | Dev world folders: biome zones, resource node markers |
| `Shared/Constants/` | `WorldConstants`, `ResourceNodesConstants` |
| Controllers | `ResourceController`, `WorldController` |
| Localization | `world.*`, `resource.*`, `ui.world.*` keys in `en` / `es` |
| Profile schema | Optional per-player node cooldown map (session-only acceptable for v0.1) |

## Success

Player leaves camp hub → enters `forest_near` → sees day/night cycle on HUD → harvests berries/sticks/wood from tagged nodes → items appear in bag → node depletes and respawns after cooldown → temperature drifts toward biome ambient (colder at night in forest). All harvest validated server-side; prior slices (camp, craft, survival, inventory) still work.
