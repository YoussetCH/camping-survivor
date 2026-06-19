# Proposal — Slice 04: Crafting

## Why

Inventory (slice-03) can hold and use items, but players cannot combine resources into tools, medicine, or blueprints. GDD Cap. 4 requires server-authoritative crafting with recipe unlocks, station rules, and a basic UI before camp placement (slice-05) and world gathering expansion.

## What Changes

- `CraftingService` — validate unlock, station (`hands` v0.1), inputs, output space, 1 s cooldown; consume via `InventoryService`; grant outputs; persist unlocks
- Auto-unlock **tutorial** recipes (`recipe_sparks`, `recipe_tinder`, `recipe_bandage`, `recipe_campfire`) for new profiles
- Remotes: `CraftItemEvent` (C→S `recipeId`), `CraftResultEvent` (S→C result), `RecipesUpdatedEvent` (sync unlocked list)
- `CraftingConstants` — cooldown, common items for future experiment rules
- Extend `InventoryService` with server-only `countItem`, `removeItems`, `canFitOutputs`
- Add missing item defs (`bp_campfire`) and studio dev grants for craft testing
- `CraftingHUDController` + passive recipe list UI (toggle `C`)
- Localization keys for crafting UI and error toasts

## Capabilities

### New Capabilities

_(none — crafting spec already stubbed)_

### Modified Capabilities

- **crafting** — define full requirements (was stub)
- **ui** — ADDED crafting panel requirements
- **inventory** — ADDED server helpers for batch consume / output capacity check

## Out of scope

- Craft stations in world (`craft_table`, `campfire`, `pot`) and distance validation — slice-05
- Mesa experimentation, clue/mission unlock flows — slice-08 / later
- Full recipe table (tools, medicine, construction) — incremental; v0.1 ships tutorial `hands` recipes only
- Journal / discovery UI — slice-08
- `TransferItemEvent` — slice-05

## Impact

- `Recipes.luau` (tutorial set already present; no new recipes this slice)
- `Items.luau` — `bp_campfire` blueprint item
- `Remotes.luau` + Rojo RemoteEvent instances
- New `CraftingService` + `CraftingHUDController`
- `PlayerSyncService` recipes sync; `ClientSyncController` cache
- Studio dev grant adds `leaf`, `fiber`, `wood` for playtesting

## Success

Player opens crafting panel, selects an unlocked tutorial recipe, crafts if inputs exist, sees inventory update and success/failure feedback. Server rejects invalid crafts; unlocks persist in profile.
