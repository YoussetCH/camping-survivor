# Design — Slice 01: Foundation

## Types

### New modules

| File | Exports |
|------|---------|
| `Shared/Types/Survival.luau` | `SurvivalStats`, `StatusEffect`, `SurvivalSnapshot` |
| `Shared/Types/Camp.luau` | `CampData`, `CampSnapshot` |
| `Shared/Types/Quest.luau` | `QuestProgress`, `QuestSnapshot` |
| `Shared/Types/Item.luau` | `ItemDefinition`, `ItemCategory` |
| `Shared/Types/Recipe.luau` | `RecipeDefinition`, `RecipeUnlockType` |

### Extended `PlayerProfile.luau`

```luau
survival: SurvivalStats
statusEffects: { StatusEffect }
camp: CampData
recipes: { unlocked: { string } }
clanId: string?
monetization: { purchases: { [string]: unknown } }
tutorialCompleted: boolean
stats.playTime: number
stats.deaths: number
```

Default values (new profile):

| Field | Value |
|-------|-------|
| survival.hunger/thirst | 80 |
| survival.health | 100 |
| survival.temperature | 50 |
| camp.level | 0 |
| tutorialCompleted | false |

## Remotes (register in `Remotes.luau`)

| Event | Direction | Payload |
|-------|-----------|---------|
| `PlayerDataLoadedEvent` | S→C | Full `PlayerProfile` (existing) |
| `SurvivalUpdatedEvent` | S→C | `SurvivalSnapshot` |
| `InventoryUpdatedEvent` | S→C | `{ inventory, hotbar? }` |
| `CampUpdatedEvent` | S→C | `CampSnapshot` |
| `QuestProgressEvent` | S→C | `QuestSnapshot` |

## Services

### `PlayerSyncService` (new)

- Depends on `PlayerDataService` repository
- Called after profile load (hook from `PlayerDataService` or own `PlayerAdded` after data ready)
- Fires `SurvivalUpdatedEvent`, `InventoryUpdatedEvent`, `CampUpdatedEvent`, `QuestProgressEvent` with current profile slices
- No gameplay logic; read-only projection

### Existing

- `NetworkingService` — auto-creates remotes from `Remotes.luau`
- `PlayerDataService` — loads profile, fires `PlayerDataLoadedEvent`; extended to call sync

## Controllers

### `ClientSyncController` (new)

- Subscribes to all sync events
- Caches latest snapshots in module state (for future HUD controllers)
- Logs via `Logger.debug` on receive
- `UIController` remains; may read cache later

## Constants

### `Items.luau`

Tutorial subset: `stick`, `stone`, `flint`, `leaf`, `fiber`, `tinder`, `berry`, `bandage`, `sparks`, `wood`

### `Recipes.luau`

Tutorial recipes: `recipe_sparks`, `recipe_tinder`, `recipe_bandage`, `recipe_campfire`

## Security

- All sync events are server→client only in this slice
- No new client→server remotes

## Persistence

- `PlayerProfileTemplate` updated; ProfileStore `Reconcile()` fills missing keys for returning players
