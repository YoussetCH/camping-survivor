# Design — Slice 05: Camp

## Context

- `PlayerProfile.camp` has `plotId` and `level` only; `CampUpdatedEvent` already syncs on join
- `Camp.luau` types are minimal; no `structures[]` or chest storage yet
- Crafting v0.1 allows only `hands` station (`CraftingConstants.isStationAvailable`)
- `bp_campfire` exists; `recipe_campfire` outputs blueprint to bag
- Workspace has baseplate + spawn only — no plots until this slice adds dev hub
- Survival already grants +1 HP/min regen when `plotId ~= nil` (placeholder for camp benefit)

## Goals / Non-Goals

**Goals:** Plot assignment, authoritative structure place/demolish, camp level 0→1, 24-slot chest with transfer, craft at placed `craft_table`/`campfire`, build-mode UI, persistence + world respawn on rejoin.

**Non-Goals:** Level 2+ structures, repair, helpers, clans, raids, fauna defense, fogata fuel, full camp_hub art pass, cooking recipes beyond station plumbing.

## Decisions

### Dev plots in Workspace (not slice-06 world)

Create `Workspace/CampHub/Plots/` with 8 parts tagged `CampPlot` and attribute `PlotId` (`plot_01`…`plot_08`). `CampService` scans at start and tracks occupancy in memory. Full hub layout moves to slice-06 without changing service API.

**Alternative:** Procedural plots — rejected; GDD expects authored hub.

### Extended camp profile

```luau
export type CampStructure = {
  structureId: string,
  blueprintId: string,
  position: Vector3,
  rotation: number, -- 0, 90, 180, 270
  hp: number?,
}

export type CampData = {
  plotId: string?,
  level: number,
  structures: { CampStructure },
  chests: { [string]: InventorySlotMap }, -- keyed by structureId
}
```

Chest contents live under `camp.chests[structureId]`; only `bp_chest` structures use this map.

### Plot assignment on profile load

When `plotId == nil`, assign nearest unoccupied plot to spawn. Persist immediately. Fire `CampUpdatedEvent`. Teleport character to plot center once per session on assign.

### Structure placement validation (server)

| Check | Rule |
|-------|------|
| Ownership | Player owns `plotId` |
| Blueprint | `blueprintId` item in bag (consumed on place) |
| Bounds | Footprint AABB inside 48×48 plot, max height +16 studs |
| Overlap | No AABB intersection with existing structures |
| Camp level | Blueprint allowed at current level (v0.1: all starter blueprints at level 0) |
| Cap | Max 10 structures at level 0–1 |

Client sends `{ blueprintId, position, rotation }`. Server snaps position to 4-stud grid center.

### Demolish

`DemolishStructureEvent` with `structureId`. Owner only. Remove world instance + profile entry. Return 50% of blueprint craft inputs as raw items (from recipe lookup) if bag/chest has space; else drop skipped (log warn).

### Camp level recalculation

After place/demolish, recompute level:

| Level | Requirement (v0.1) |
|-------|---------------------|
| 0 | Default |
| 1 | Placed `bp_campfire` + `bp_chest` + `bp_craft_table` each ≥1 |

When level becomes 1, `CraftingService.ensureStarterRecipesUnlocked` adds `unlockType == "starter"` recipes.

### Craft station proximity

Extend `CraftingConstants`:

| Station | Available when |
|---------|----------------|
| `hands` | Always |
| `craft_table` | Player within **12 studs** of own placed `bp_craft_table` on own plot |
| `campfire` | Player within **8 studs** of own placed `bp_campfire` on own plot |

`CraftingService` queries `CampService.getNearbyStation(player, station)`.

### Chest transfer

`TransferItemEvent` payload: `{ direction: "toChest" | "toBag", chestStructureId, bagSlotKey?, chestSlotKey?, quantity? }`.

Server validates chest belongs to player's plot, slot keys, stack rules via `InventoryService` helpers. Sync bag via `InventoryUpdatedEvent`; sync chest via `CampUpdatedEvent` or dedicated `ChestUpdatedEvent` (use `CampUpdatedEvent` with full camp snapshot for simplicity).

### Remotes

| Event | Direction | Payload |
|-------|-----------|---------|
| `PlaceStructureEvent` | C→S | `{ blueprintId, position, rotation }` |
| `PlaceStructureResultEvent` | S→C | `{ success, reasonKey?, structureId? }` |
| `DemolishStructureEvent` | C→S | `structureId: string` |
| `DemolishStructureResultEvent` | S→C | `{ success, reasonKey? }` |
| `TransferItemEvent` | C→S | transfer payload (see above) |

Extend existing `CampUpdatedEvent` snapshot to include `structures` and `chests` (client needs chest UI).

### BuildingController

- Toggle build mode `B` when player has ≥1 blueprint in bag
- List placeable blueprints from inventory
- Ghost part preview (client-only); confirm fires `PlaceStructureEvent`
- Rotate `R` (90° steps)
- Invalid preview tint red when client-side bounds check fails (server still authoritative)
- Mobile: build button + tap confirm

### ChestController

- Proximity prompt on placed chest (12 studs)
- Opens passive 24-slot grid UI; drag or button transfer with bag panel
- All mutations via `TransferItemEvent`

### World structure instances

`ServerStorage/StructureTemplates/` with simple Models per blueprint. `CampService` clones on place, parents under `Workspace/CampHub/Structures/{plotId}/`, sets attributes `StructureId`, `BlueprintId`, `OwnerUserId`.

### Services & modules

| Module | Role |
|--------|------|
| `CampService` | Plots, place/demolish, level, world instances, station queries |
| `CampRepository` | Read/write `camp` slice of profile (optional thin wrapper) |
| `StructuresConstants` | Blueprint metadata |
| `BuildingController` | Build mode UI + preview |
| `ChestController` | Chest UI + transfer intent |
| `CraftingService` | Station proximity hook |
| `PlayerSyncService` | Extended camp snapshot |

### Security validations

- Never trust client position without grid snap + bounds check
- Reject place if blueprint not in inventory
- Reject transfer if chest not on player's plot
- Reject demolish of other player's structures
- Sanitize all string ids and numeric rotation (must be 0/90/180/270)

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| Plot exhaustion in dev hub (8 plots) | Enough for solo dev; slice-06 adds 24 |
| Large camp sync payload | Only 3 starter structures in v0.1; chest maps small |
| Client ghost desync | Server result event replaces ghost; reload on `CampUpdatedEvent` |
| Demolish material refund without space | Skip overflow with log; player can reclaim from ground later (future) |
| Placeholder art | Low-poly templates; art pass in slice-14 |

## Migration Plan

Existing profiles: reconcile `camp.structures = {}`, `camp.chests = {}` on load. No datastore migration beyond ProfileStore template reconciliation.

## Open Questions

- _(none blocking v0.1)_ — Level 2 structure recipes deferred to a follow-up change within camp capability or slice-10.
