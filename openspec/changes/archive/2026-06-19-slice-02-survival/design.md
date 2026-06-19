# Design — Slice 02: Survival Core

## Constants

### `Shared/Constants/SurvivalConstants.luau`

| Export | Purpose |
|--------|---------|
| `TICK_INTERVAL_SECONDS` | 6 |
| `HUNGER_DRAIN_PER_MINUTE` | 1 |
| `THIRST_DRAIN_PER_MINUTE` | 1.5 |
| `TEMPERATURE_DRIFT_PER_MINUTE` | 2 |
| `DEFAULT_AMBIENT_TEMPERATURE` | 45 (forest day placeholder) |
| `HP_DAMAGE_CAP_PER_MINUTE` | 4 |
| `DEATH_INVENTORY_LOSS_FRACTION` | 0.35 |
| `RESPAWN_STATS` | hunger 60, thirst 60, health 100, temp 50 |
| `ALERT_THRESHOLDS` | GDD §3.7 / §10.4 |

## Services

### `SurvivalService` (new)

- Depends on `PlayerDataService`, `PlayerSyncService`
- Recursive `task.delay(TICK_INTERVAL)` loop (no `while true`)
- Per tick per player with loaded profile + alive character:
  - Drain hunger/thirst
  - Drift temperature toward ambient
  - Compute HP damage from critical stats (capped)
  - Apply regen when hunger > 40, thirst > 30, no blocking status effects
  - Clamp stats 0–100 (integers)
  - If health ≤ 0 → `handleDeath`
- On change: `PlayerSyncService.syncSurvivalToClient`
- Death: inventory penalty unless `tutorialCompleted`; reset survival + clear effects; increment `stats.deaths`; `LoadCharacter`; sync survival + inventory

### Existing

- `PlayerSyncService` — add `syncSurvivalToClient` helper
- `PlayerDataService` — repository session holds mutated profile

## Controllers

### `SurvivalHUDController` (new)

- Creates ScreenGui with 4 `StatBar` instances (HP, Hunger, Thirst, Temperature)
- Subscribes to `SurvivalUpdatedEvent` (display only)
- Applies warning/danger colors via `SurvivalConstants.getAlertLevel(stat, value)`

### `StatBar` (`Shared/UI/StatBar.luau`)

- Reusable bar: label, fill, border alert states
- Methods: `setValue`, `setAlertLevel`, `setAlertMessage`

## Remotes

No new remotes. Uses existing `SurvivalUpdatedEvent` and `InventoryUpdatedEvent`.

## Security

- All stat math server-side only
- Client never sends survival values

## Persistence

- Stats live in profile session; saved via existing ProfileStore autosave / PlayerRemoving
