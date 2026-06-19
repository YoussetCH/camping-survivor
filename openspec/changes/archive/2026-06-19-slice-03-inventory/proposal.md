# Proposal — Slice 03: Inventory

## Why

Foundation stores a flat `inventory` array and syncs it, but there is no authoritative inventory logic, hotbar, equip slots, or UI. GDD Cap. 4 and §10.4/§10.6 require slot limits, stacking, hotbar, and equip-before-use flows before crafting (slice-04) and camp chests (slice-05).

## What changes

- `InventoryService` — add/remove/stack, slot capacity (16), hotbar (6), equip tool slot
- `InventoryConstants` — GDD slot limits; stack rules delegate to `Items.maxStack`
- Extend `PlayerProfile` with `hotbar` and `equipped` (typed)
- Remotes: `EquipItemEvent`, `SetHotbarSlotEvent`, `UseItemEvent`
- `InventoryHUDController` + reusable `InventorySlot` UI (hotbar + toggleable grid)
- `PlayerSyncService` snapshot includes hotbar + equipped
- Studio-only dev grant helper for playtesting (server authoritative)

## Capabilities

### New Capabilities

_(none — inventory spec already stubbed)_

### Modified Capabilities

- **inventory** — define full requirements (was stub)
- **ui** — ADDED hotbar + inventory panel requirements
- **foundation** — MODIFIED profile schema + sync snapshot shape

## Out of scope

- Camp/clan chest transfer (`TransferItemEvent`) — slice-05
- World pickup and drop-to-ground — slice-06
- Game Pass +4 inventory slots — slice-13
- Full §10.6 chest split view
- Coat equip slot (typed stub only; behavior slice-07+)
- Crafting consumption — slice-04
- Journal clue protected slot — slice-08

## Impact

- `PlayerProfile` / template reconcile
- `Remotes.luau` + Rojo RemoteEvent instances
- New service + controller; `SurvivalService` death penalty uses same inventory model
- Localization keys for hotbar/inventory UI

## Success

Player sees a 6-slot hotbar and can open a 16-slot inventory grid. Server validates stack limits and equip/use. Changes sync via `InventoryUpdatedEvent`. Studio dev grant adds test items without client trust.
