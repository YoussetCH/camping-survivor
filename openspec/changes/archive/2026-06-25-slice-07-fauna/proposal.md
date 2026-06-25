# Proposal — Slice 07: Fauna

## Why

World (slice-06) gives players explorable biomes and harvestable nodes, but the forest still feels safe — no predators, no status effects, and no reason to craft bandages beyond HP top-ups. GDD Cap. 3 (§3.5 status effects, §3.7 fauna damage) and Cap. 5 (§5.11 fauna AI) require hostile wildlife and curable debuffs before quests (slice-08) and helpers (slice-09) can reference escort/defense scenarios.

## What Changes

- Add **`AnimalService`** — server-authoritative fauna lifecycle: spawn caps per player radius, AI state machine (Idle → Patrol → Alert → Chase → Attack / Flee), melee damage + status application, death + loot drops.
- Add **fauna feature modules** — `Wolf` and `Snake` under `Shared/Features/` with `FaunaRegistry`, `FaunaModelFactory`, and per-species `*Behavior.luau` on the server.
- Wire **`SurvivalService`** status-effect tick damage (`bleeding` −6/min, `poison` −2/min) and `bleeding` → `infection` transition after 5 min untreated.
- Extend **`InventoryService.useItem`** — `bandage` cures `bleeding`; add `antidote` item and cure `poison`.
- Dev world spawns **2–4 wolves** and **1–2 snakes** in `forest_near` (day: passive patrol; night: wolves aggressive per GDD).
- Remotes: `AttackFaunaEvent`, `FaunaUpdatedEvent` (client sends faunaId only; server validates).
- Client **`FaunaController`** — proximity attack intent (equipped tool), fauna health bar billboard, status-effect icon row on survival HUD.
- Localization keys for status effects, fauna names, attack errors, and cure feedback.

## Out of scope

- **Bear, crab** and mountain/coast biome fauna — constants-only stubs; no spawn in v0.1
- **Dynamic world events** (`wolf_pack`, `storm`, `deer_herd`) — slice-10+
- **`wet` status** from weather — slice-10+
- **Bow/ranged flee** AI branch — deferred; wolves always chase in v0.1
- **Fauna entering camp plots** / wall defense — slice-08+ with quests
- **Helper fauna damage** — slice-09
- **Infection cure** via disinfectant — add item stub only; full cure chain slice-08+
- **Full `forest_deep`** authored zone — optional stub; wolves spawn in `forest_near` only
- **Spawn invulnerability** after player death — 3 s anti spawn-kill deferred

## Capabilities

### New Capabilities

_(none — fauna extends existing world + survival specs)_

### Modified Capabilities

- **world**: ADDED fauna spawn, AI, combat, drops, and `AnimalService` contract.
- **survival**: ADDED status-effect tick damage, blocking regen rules, death clears effects, bleeding→infection transition.
- **inventory**: MODIFIED `bandage` use to cure `bleeding`; ADDED `antidote` item and poison cure.
- **ui**: ADDED status-effect icon row on survival HUD and fauna health bar display.
- **feature-modules**: ADDED `FaunaRegistry` and fauna feature-module folder convention.

## Impact

| Area | Change |
|------|--------|
| New service | `AnimalService` |
| New registry | `FaunaRegistry`, `FaunaBootstrap` |
| Feature modules | `Wolf/`, `Snake/` (Definition, Model, Behavior) |
| `SurvivalService` | Status-effect tick + transition logic |
| `InventoryService` | bandage/antidote cure paths |
| `BiomeService` / `DayNightService` | Read-only queries for spawn aggression rules |
| Remotes | `AttackFaunaEvent`, `FaunaUpdatedEvent` |
| Controllers | `FaunaController`; extend `SurvivalHUDController` |
| Constants | `FaunaConstants`, `StatusEffectConstants` |
| Localization | `status.*`, `fauna.*`, `combat.*` keys in `en` / `es` |
| Workspace | Fauna spawn markers in `forest_near` |

## Success

Player enters `forest_near` at night → wolf detects and chases → melee hit applies −15 HP and 60% `bleeding` → survival HUD shows bleeding icon → player uses bandage → bleeding cleared → player equips axe, attacks wolf → wolf dies and drops fiber → snake ambush applies `poison` → antidote cures poison. All combat validated server-side; slice-06 harvest/camp/survival still work.
