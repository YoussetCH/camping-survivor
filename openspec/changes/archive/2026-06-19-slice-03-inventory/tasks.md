# Tasks — Slice 03: Inventory

## 1. Types & constants

- [x] 1.1 Create `Shared/Types/Inventory.luau` (`EquippedItems`, `HotbarSlots`, bag slot key helpers)
- [x] 1.2 Extend `PlayerProfile` + template with `hotbar` and `equipped`
- [x] 1.3 Create `Shared/Constants/InventoryConstants.luau`

## 2. Remotes

- [x] 2.1 Register `EquipItemEvent`, `SetHotbarSlotEvent`, `UseItemEvent` in `Remotes.luau`
- [x] 2.2 Add Rojo RemoteEvent instances under `Remotes/Events/`

## 3. Server

- [x] 3.1 Create `Services/InventoryService.luau` (grant, remove, equip, hotbar, use)
- [x] 3.2 Update `PlayerSyncService.buildInventorySnapshot` for hotbar + equipped
- [x] 3.3 Adapt `SurvivalService` death penalty to bag-slot model + hotbar cleanup
- [x] 3.4 Studio dev grant starter items on join (server-only)

## 4. Client UI

- [x] 4.1 Create `Shared/UI/InventorySlot.luau`
- [x] 4.2 Create `Controllers/InventoryHUDController.luau` (hotbar + toggle grid)
- [x] 4.3 Add localization keys (`ui.inventory.*`, actions) in `en` / `es`

## 5. Specs & archive prep

- [x] 5.1 Merge deltas into `openspec/specs/inventory/spec.md`, `ui/spec.md`, `foundation/spec.md`
- [x] 5.2 Run `verify.md` checklist
- [x] 5.3 Archive with `openspec archive slice-03-inventory` (after user approval)

## Verification

- [x] Run `verify.md` — all items checked
