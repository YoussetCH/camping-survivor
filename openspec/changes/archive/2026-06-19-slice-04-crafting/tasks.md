# Tasks — Slice 04: Crafting

## 1. Constants & items

- [x] 1.1 Create `Shared/Constants/CraftingConstants.luau` (cooldown, station helpers)
- [x] 1.2 Add `bp_campfire` item definition to `Items.luau`

## 2. Remotes

- [x] 2.1 Register `CraftItemEvent`, `CraftResultEvent`, `RecipesUpdatedEvent` in `Remotes.luau`
- [x] 2.2 Add Rojo RemoteEvent instances under `Remotes/Events/`

## 3. Inventory extensions

- [x] 3.1 Add `countItem`, `removeItems`, `canFitOutputs` to `InventoryService`

## 4. Server crafting

- [x] 4.1 Create `Services/CraftingService.luau` (unlock bootstrap, craft handler, cooldown)
- [x] 4.2 Extend `PlayerSyncService` + hook profile load for `RecipesUpdatedEvent`
- [x] 4.3 Extend studio dev grant with `leaf`, `fiber`, `wood` for craft testing

## 5. Client UI

- [x] 5.1 Extend `ClientSyncController` with recipes cache
- [x] 5.2 Create `Controllers/CraftingHUDController.luau` (panel, recipe list, craft intent)
- [x] 5.3 Add localization keys (`ui.craft.*`, `craft.error.*`, `craft.success.*`) in `en` / `es`

## 6. Specs & archive prep

- [x] 6.1 Merge deltas into `openspec/specs/crafting/spec.md`, `ui/spec.md`, `inventory/spec.md`
- [x] 6.2 Run `verify.md` checklist
- [x] 6.3 Archive with `openspec archive slice-04-crafting` (after user approval)

## Verification

- [x] Run `verify.md` — all items checked
