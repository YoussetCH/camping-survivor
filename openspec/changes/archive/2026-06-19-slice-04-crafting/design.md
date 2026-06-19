# Design — Slice 04: Crafting

## Context

- `PlayerProfile.recipes.unlocked` exists (empty array in template)
- `Recipes.luau` defines 4 tutorial `hands` recipes matching GDD §4.8
- `InventoryService.grantItem` works; no batch consume or output-capacity helpers yet
- No camp structures — only `hands` station is usable in v0.1

## Goals / Non-Goals

**Goals:** Authoritative craft-by-recipe-id, tutorial unlock bootstrap, sync unlocked recipes, minimal crafting HUD, inventory integration.

**Non-Goals:** World stations, experimentation, non-tutorial recipes, journal, clue/mission unlock triggers.

## Decisions

### Client sends `recipeId` only

Server reads inputs from `Recipes.get(recipeId)`. Client never sends item ids or quantities (security).

### Tutorial auto-unlock on profile load

When `PlayerDataService` loads a profile, `CraftingService.ensureTutorialRecipesUnlocked` adds all `unlockType == "tutorial"` recipe ids if missing. Persisted via existing autosave.

### Station validation v0.1

| Station | Slice 04 behavior |
|---------|-------------------|
| `hands` | Always allowed |
| Other | Rejected with `craft.error.wrong_station` until slice-05 |

### Inventory helpers (server-only)

| Method | Role |
|--------|------|
| `countItem(data, itemId)` | Sum quantity across bag |
| `removeItems(player, data, inputs)` | Consume recipe inputs in slot order; sync once |
| `canFitOutputs(data, outputs)` | Check merge + empty slots before craft |

### Remotes

| Event | Direction | Payload |
|-------|-----------|---------|
| `CraftItemEvent` | C→S | `recipeId: string` |
| `CraftResultEvent` | S→C | `{ success: boolean, recipeId: string, reasonKey: string? }` |
| `RecipesUpdatedEvent` | S→C | `{ unlocked: { string } }` |

### CraftingService flow

1. Validate `recipeId`, cooldown (1 s), unlock, station
2. `countItem` ≥ inputs; `canFitOutputs`
3. `removeItems` → `grantItem` for each output
4. Fire `CraftResultEvent`; sync inventory (grant/remove already sync)

### CraftingHUDController

- ScreenGui `CraftingHUD` (DisplayOrder 106), toggle key `C`
- Lists unlocked recipes for current station filter (`hands` only in v0.1)
- Shows inputs/outputs via localization keys; Craft button fires `CraftItemEvent`
- Subscribes to `RecipesUpdatedEvent` + `CraftResultEvent`; toasts via localization on result

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| Partial consume on failure | Check all preconditions before any mutation |
| Non-hands recipes visible but unusable | UI filters by station `hands` until slice-05 |
| Cooldown spam | Per-player `lastCraftAt` map, 1 s minimum |
