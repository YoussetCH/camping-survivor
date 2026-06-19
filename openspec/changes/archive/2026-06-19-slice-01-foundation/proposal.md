# Proposal — Slice 01: Foundation

## Why

The GDD defines full gameplay systems, but the codebase only has a minimal profile (`currency`, `inventory`, `stats`, `quests`, `settings`) and one remote (`PlayerDataLoadedEvent`). We need shared infrastructure before any vertical slice (survival, inventory, etc.).

## What changes

- Extend `PlayerProfile` with survival, camp, recipes, monetization, tutorial flags
- Register domain sync RemoteEvents (survival, inventory, camp, quests)
- Add `Items.luau` and `Recipes.luau` constants (tutorial subset)
- Add `PlayerSyncService` to fire initial sync payloads on join
- Add `ClientSyncController` to receive sync events (passive logging/state cache)
- Merge foundation spec delta into `openspec/specs/foundation/`

## Out of scope

- Survival tick logic (slice-02)
- Inventory mutations (slice-03)
- Crafting execution (slice-04)
- Studio map / camp plots (slice-05)
- Full HUD UI (slice-02+)

## Success

Player joins in Studio via Rojo; profile loads with new fields; sync events fire without errors; client receives payloads.
