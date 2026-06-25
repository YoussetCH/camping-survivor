# Design — Slice 07: Fauna

## Context

- Slice-06 provides `BiomeService`, `DayNightService`, `ResourceService`, and dev `forest_near` zone.
- `SurvivalService` already blocks regen when `bleeding`, `poison`, or `infection` exist in profile but does **not** apply status tick damage yet.
- `InventoryService.useItem` heals HP on `bandage` use but does **not** cure status effects.
- `StatusEffect` type exists in `Shared/Types/Survival.luau`; profile persists `statusEffects` array.
- Feature-module pattern established in slice-05b (`StructureBehaviorRegistry`, `FeatureBootstrap`).
- GDD §5.11 defines AI states and species stats; §3.5 defines effect damage rates.

## Goals / Non-Goals

**Goals:** Two fauna species (wolf, snake) in `forest_near`, server AI loop, fauna→player melee with instant damage + status, player→fauna melee with tool, loot on death, status-effect HUD, bandage/antidote cures.

**Non-Goals:** Ranged weapons, dynamic events, bear/crab, fauna in camp plots, helper damage, infection full cure chain, spawn invulnerability, full forest_deep map.

## Decisions

### FaunaRegistry + feature modules (mirrors StructureBehaviorRegistry)

```
Shared/Features/Wolf/
  WolfDefinition.luau    -- speciesId, stats, drops, biomes
  WolfModel.luau         -- readable wolf silhouette (2+ parts)
Shared/Features/Snake/
  SnakeDefinition.luau
  SnakeModel.luau
ServerScriptService/Features/
  FaunaRegistry.luau
  FaunaBootstrap.luau    -- require WolfBehavior, SnakeBehavior
  Behaviors/
    WolfBehavior.luau    -- register species + attack hook
    SnakeBehavior.luau
```

`AnimalService` orchestrates spawn, AI tick, and combat; species-specific attack/drop logic lives in behaviors via registry lookup.

**Alternative:** Inline `if speciesId == "wolf"` in AnimalService — rejected per feature-module rules.

### AnimalService architecture

| Responsibility | Owner |
|----------------|-------|
| Spawn from tagged `FaunaSpawn` markers | `AnimalService` |
| Per-player cap (max 8 within 100 studs) | `AnimalService` |
| AI state machine tick (1 s interval) | `AnimalService` + behavior hooks |
| Fauna→player attack cooldown | `AnimalService` |
| Player→fauna attack via remote | `AnimalService` |
| Apply survival damage + status | `SurvivalService.applyDamage(player, amount, statusIds?)` |
| Grant drops on death | `InventoryService` via behavior drop table |

Runtime state (session-only):

```luau
type FaunaInstance = {
  faunaId: string,
  speciesId: string,
  model: Model,
  hp: number,
  state: "idle" | "patrol" | "alert" | "chase" | "attack" | "flee",
  targetPlayer: Player?,
  lastAttackAt: number,
  spawnPosition: Vector3,
}
```

Models parented under `Workspace/World/Fauna/`. `faunaId` attribute on model for client lookup.

### Species stats (v0.1 — GDD §5.11)

| speciesId | HP | Damage | Status | Detect | Aggro range | Attack CD | Drops |
|-----------|-----|--------|--------|--------|-------------|-----------|-------|
| `wolf` | 40 | 15 | `bleeding` 60% | 40 studs | 12 studs melee | 2 s | `fiber` ×1 (50%) |
| `snake` | 15 | 8 | `poison` 100% | 25 studs | 8 studs | 1.5 s | `herb_common` ×1 (30%) |

**Night rule:** wolves in `forest_near` only chase/attack when `DayNightService` phase is `night` or `dusk`. Day: patrol only, Alert shows but no Chase.

**Snake:** starts hidden (transparency); Alert when player within detect → ambush Chase.

### Player attack (melee)

Client fires `AttackFaunaEvent(faunaId)` when player clicks/taps near fauna with a tool equipped.

Server validates:
- Fauna exists and hp > 0
- Player within **10 studs** of fauna PrimaryPart
- Player has tool equipped (`stone_axe` or any `axe_*` / `pick_*` for v0.1)
- Per-player attack cooldown **1 s**

Damage to fauna: **10 HP** per hit (axe). On death: roll drops, destroy model, remove from registry, fire `FaunaUpdatedEvent`.

**Alternative:** ProximityPrompt auto-attack — rejected; explicit intent matches harvest pattern.

### Status effects in SurvivalService

New public API:

```luau
SurvivalService.applyDamage(player, amount: number, statusEffectIds: { string }?)
SurvivalService.addStatusEffect(player, effectId: string)
SurvivalService.removeStatusEffect(player, effectId: string)
SurvivalService.clearStatusEffects(player)
```

Tick additions (each 6 s tick):
- `bleeding`: −1 HP per tick (−6/min)
- `poison`: −0.2 HP per tick (−2/min)
- Track `bleeding` appliedAt; if ≥ 300 s without cure → add `infection` (−0.1 HP/tick)

Status damage stacks with critical-stat damage but total HP loss capped at `HP_DAMAGE_CAP_PER_MINUTE`.

Death respawn already resets stats; extend to `clearStatusEffects`.

### Inventory cures

| Item | Effect |
|------|--------|
| `bandage` | Remove `bleeding`; +10 HP (existing heal reduced from flat heal-only) |
| `antidote` | Remove `poison`; new item in `Items.luau` + locale keys |

`infection`: bandage alone insufficient in GDD — v0.1 bandage does not cure infection (deferred disinfectant).

### Remotes

| Remote | Direction | Payload |
|--------|-----------|---------|
| `AttackFaunaEvent` | Client → Server | `faunaId: string` |
| `FaunaUpdatedEvent` | Server → Client | `{ faunaId, speciesId, hp, maxHp, state?, position? }` or `{ faunaId, removed: true }` |

Broadcast `FaunaUpdatedEvent` to players within 120 studs on HP change or death. Initial sync on player join for nearby fauna.

### Client FaunaController

- Listen `FaunaUpdatedEvent`; maintain local cache of nearby fauna HP.
- Render `BillboardGui` health bar on fauna models (passive display).
- On click/tap fauna while tool equipped → fire `AttackFaunaEvent`.
- No client-side HP mutation.

### Survival HUD status row

Extend `SurvivalHUDController` with icon row below stat bars for active `statusEffects` from `SurvivalUpdatedEvent`. Icons use localization tooltip keys (`status.bleeding.name`, etc.).

### Dev world spawns

Tag Parts under `Workspace/World/FaunaSpawns/` with `FaunaSpawn` + attributes `SpeciesId`, optional `BiomeId` filter. Bootstrap creates models at server start.

Example: 3 wolf spawns, 2 snake spawns in `forest_near` ring.

### Service init order

```
FeatureBootstrap (FaunaRegistry)
→ DayNightService, BiomeService
→ SurvivalService
→ AnimalService
```

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| AI tick cost with many fauna | 1 s tick; max 8 fauna per player radius; despawn far fauna |
| Client attack spam | 1 s server cooldown per player |
| Spawn-kill at night | Document deferral; wolves slower than player sprint in v0.1 |
| Snake too hard to see | Hidden until alert; bright model on reveal |

## Migration Plan

No profile migration. New `antidote` item added to constants; existing profiles unaffected. Studio dev grant adds 1× antidote for testing.

## Open Questions

- _(none for v0.1 — infection cure deferred to slice-08)_
