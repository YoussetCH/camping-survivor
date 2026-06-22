# Proposal — Slice 05: Camp

## Why

Crafting (slice-04) produces blueprints like `bp_campfire`, but players have nowhere to place them — no plot, no build mode, no camp chest, and no world craft stations. GDD Cap. 6 requires a persistent home loop (parcela → colocar estructuras → nivel 1 → cofre + mesa) before world expansion (slice-06), fauna (slice-07), and quests (slice-08).

## What Changes

- `CampService` — assign plot on first join, place/demolish structures, recalculate camp level (0→1), persist `camp.structures[]`, spawn/despawn world instances
- Dev camp hub in Workspace — tagged plot parts (`CampPlot` + `PlotId`) until slice-06 builds full `camp_hub`
- `StructuresConstants` — starter blueprint defs (`bp_campfire`, `bp_chest`, `bp_craft_table`): grid size, footprint, HP, station type
- Extend `CampData` / `CampSnapshot` with `structures` and per-chest storage
- Remotes: `PlaceStructureEvent`, `DemolishStructureEvent`, `TransferItemEvent`; extend `CampUpdatedEvent` payload
- `BuildingController` — build mode (`B`), ghost preview, rotate (`R`), confirm/cancel; intent only
- `ChestController` + passive chest UI — open camp chest, transfer bag ↔ chest via `TransferItemEvent`
- Extend `CraftingService` — validate `craft_table` / `campfire` station proximity on player's plot
- Starter construction recipes (`recipe_craft_table`, `recipe_chest`) + item defs; unlock `starter` recipes when camp reaches level 1
- Localization keys for build mode, placement errors, chest UI
- Studio dev grant adds materials to craft and place starter camp

## Capabilities

### New Capabilities

_(none — camp spec already stubbed)_

### Modified Capabilities

- **camp** — define full requirements (was stub): plots, placement, level 0→1, chest storage, structure persistence
- **crafting** — ADDED camp station validation (`craft_table`, `campfire`) and starter recipe unlock on camp level 1
- **inventory** — ADDED chest transfer via `TransferItemEvent` (24-slot camp chest)
- **ui** — ADDED build mode HUD and chest panel requirements
- **foundation** — MODIFIED extended camp profile schema (`structures[]`, chest contents)

## Out of scope

- Full `camp_hub` world layout, biomes, resource nodes — slice-06
- Camp level 2+ structures (walls, door, shelter, pot, trap, alarm, dock) and their recipes — later slices
- `RepairStructureEvent` — no structure damage sources until fauna/raids (slice-07/12)
- Helper assignment (`AssignHelperEvent`, `LinkChestEvent`) — slice-09
- Clan plots, permissions, merged parcels — slice-11
- Raid defense, fauna entry, fogata fuel loop, pot-on-campfire rule — slice-07+
- Cooking recipes at campfire station — incremental after stations exist
- Camp level 3+ requirements (24 h stable, helpers alive, play-time gates)

## Impact

- `Camp.luau`, `PlayerProfile.luau`, `PlayerProfileTemplate.luau` — extended camp model
- New `StructuresConstants.luau`, `CampService`, `BuildingController`, `ChestController`
- `CraftingConstants.luau`, `CraftingService`, `Recipes.luau`, `Items.luau`
- `Remotes.luau` + Rojo RemoteEvent instances
- `PlayerSyncService` — richer `CampUpdatedEvent`; optional chest sync on transfer
- `Workspace/CampHub/` — dev plot placeholders (Rojo)
- `SurvivalService` — respawn at assigned plot when `plotId` set (minor)

## Success

Player joins → receives a plot → crafts `bp_campfire` → enters build mode → places campfire, chest, and craft table → camp reaches level 1 → stores items in chest → crafts a `starter` recipe at the placed craft table. All placement and transfers are server-validated; structures persist on rejoin.
