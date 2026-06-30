# Design — Slice 09: Helpers

## Context

- Camp (slice-05), fauna (slice-07), and quests (slice-08) are live; `main_05_lumberjack` was deferred from slice-08.
- Feature-module pattern exists (`StructureBehaviorRegistry`, `FaunaRegistry`); helpers need parallel `HelperBehaviorRegistry`.
- Player profile has no `helpers` field yet; GDD §3.8 defines hunger/health/death rules; §5.12 defines lumberjack recruitment via escort.
- Survival status effects (`bleeding`, `poison`, `infection`, `weak`) already exist for players — helpers reuse subset (no thirst/temperature).

## Goals / Non-Goals

**Goals:** One recruitable helper type (Lumberjack), escort quest, hunger/care/death loop, work tick (wood), helper panel UI, server sync, localized copy.

**Non-Goals:** Five other helper types, clan roster, raid damage, auto-feed from chest, replace-quest cooldown, full POI map, helper combat.

## Decisions

### HelperService architecture

| Responsibility | Owner |
|----------------|-------|
| Recruit / remove on death | `HelperService` |
| Hunger & status tick (6 s aligned with survival) | `HelperService` |
| Work task scheduling | `HelperService` → `HelperBehaviorRegistry` |
| Feed / cure remotes | `HelperService` |
| World NPC escort tracking | `HelperService` + escort spawn module |
| Sync | `PlayerSyncService.syncHelpersToClient` |

Profile:

```luau
type HelperState = {
  helperTypeId: string,
  nameKey: string,
  hunger: number,
  health: number,
  statusEffects: { StatusEffect },
  mode: "work" | "shelter",
  recruitedAt: number,
  weakSince: number?,
}

type HelperSnapshot = {
  helpers: { [string]: HelperState },
  lostHelpers: { string },
  maxHelpers: number,
  lastRemovedHelperId: string?, -- client toast once
}
```

Session: escort NPC instances keyed by player + helperTypeId until recruit or quest abandon.

**Alternative:** Helpers as camp structures — rejected; GDD treats helpers as entities with stats, not blueprints.

### HelperBehaviorRegistry + Lumberjack module

```
Shared/Features/Lumberjack/
  LumberjackDefinition.luau   -- helperTypeId, nameKey, workIntervalSeconds
  LumberjackModel.luau        -- readable NPC silhouette (2+ parts)
ServerScriptService/Features/
  HelperBehaviorRegistry.luau
  HelperBootstrap.luau
  Behaviors/
    LumberjackBehavior.luau   -- onWorkTick, canWork, onRecruit
```

Lumberjack work (GDD §2.13):

| Condition | Rule |
|-----------|------|
| Interval | 60 s |
| Output | 1× `wood` (50% chance if hunger 11–20) |
| Requires | `mode = work`, health > 0, not `weak`, hunger > 0 |
| Camp req | Active `bp_campfire` on plot OR any axe in camp chests |

Shelter mode: no work tick; hunger drain **1/min** (slower).

### Hunger / health / death (GDD §3.8 v0.1)

| Rule | Value |
|------|-------|
| Work hunger drain | −3/min |
| Shelter hunger drain | −1/min |
| Feed basic | +40 (`berry`, `stick` invalid — food items only) |
| Feed cooked | +60 (`cooked_*` if exists else treat `berry` as basic) |
| Weak | hunger = 0 → add `weak`, stop work |
| Death | HP ≤ 0 OR weak ≥ 20 min |
| Status tick | bleeding −4.8/min, poison −1.6/min (×0.8 of player) |

On death: remove from `helpers`, append type to `lostHelpers`, despawn world model, fire toast key.

### Recruitment & escort quest

**Quest `main_05_lumberjack`** (added to `Quests.luau`):

| Field | Value |
|-------|-------|
| prerequisites | `main_01_chest` |
| objectives | `escort_to_plot` ×1 for `lumberjack` |
| rewards | 120 XP; recruit lumberjack (not separate item) |

Flow:

1. Quest starts → spawn escort NPC at nearest `HelperSpawn` tagged `lumberjack` in `forest_deep` (or follow player from marker).
2. NPC follows player within 25 studs (simple `Humanoid:MoveTo` tick).
3. When player + NPC inside plot AABB → objective complete → `HelperService.recruit(player, "lumberjack")` → despawn escort.

`QuestService` gains `escort_to_plot` handler polled every 1 s or on `GameEvents` plot enter.

Auto-start: after `main_01_chest` complete, chain to `main_05_lumberjack` via `nextQuestId` on main_01 or explicit unlock in QuestService.

Update `main_01_chest` in Quests.luau: add `nextQuestId = "main_05_lumberjack"`.

### Remotes

| Remote | Direction | Payload |
|--------|-----------|---------|
| `HelperUpdatedEvent` | S→C | `HelperSnapshot` |
| `FeedHelperEvent` | C→S | `{ helperInstanceId, bagSlotKey }` |
| `CureHelperEvent` | C→S | `{ helperInstanceId, bagSlotKey }` |
| `SetHelperModeEvent` | C→S | `{ helperInstanceId, mode }` |

### UI

- **HelperPanel** — left side below quest tracker; key `H`.
- Reuse `StatBar` pattern for hunger/health per helper row.
- Feed opens slot picker from last inventory sync (same bag keys as inventory UI).

### World content

- Tag `HelperSpawn` parts in `forest_deep` with attribute `HelperTypeId = lumberjack`.
- `HelperService` scans on init like `AnimalService` spawn markers.

### Localization

- `helper.lumberjack.name`
- `helper.panel.title`, `helper.action.feed`, `helper.action.cure`, `helper.mode.work`, `helper.mode.shelter`
- `helper.death_toast`, `helper.hunger_warning`
- `quest.main_05_lumberjack.*`

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| Escort NPC stuck on terrain | Spawn near road; follow teleport if >40 studs |
| Wood inflation | 1/min cap; requires campfire upkeep |
| Circular require HelperService ↔ QuestService | QuestService polls escort via bindable `GameEvents.HelperEscortProgress` fired from HelperService |

## Migration Plan

1. Add `helpers = {}`, `lostHelpers = {}` to template with reconcile.
2. Existing profiles: empty helpers; quest chain adds main_05 when main_01 done.

## Open Questions

- **Cooked food ids:** only `berry` as basic in v0.1; +60 if item id starts with `cooked_` — **decision:** prefix check.
- **Escort without quest:** dev command or ProximityPrompt on spawn for Studio testing — **yes**, debug-only attribute on spawn marker.
