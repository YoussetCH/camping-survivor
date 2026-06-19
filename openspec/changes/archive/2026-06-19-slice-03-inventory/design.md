# Design — Slice 03: Inventory

## Context

- Profile already has `inventory: { InventoryItem }` and death penalty in `SurvivalService`
- `InventoryUpdatedEvent` and `ClientSyncController` cache exist
- Items defined in `Items.luau` with `maxStack` and `category`
- UI must be passive; all mutations via remotes → `InventoryService`

## Goals / Non-Goals

**Goals:** Authoritative 16-slot bag, 6-slot hotbar, 1 tool equip slot, stack merging, sync, minimal HUD.

**Non-Goals:** Chests, world nodes, dropping items, monetization slots, full item use catalog.

## Types

### `Shared/Types/Inventory.luau` (new)

```luau
export type EquippedItems = {
	toolItemId: string?,
	coatItemId: string?,
}

export type HotbarSlots = { string? } -- length 6; each entry is inventory index key or nil
```

### `PlayerProfile` extensions

- `hotbar: HotbarSlots` — 6 entries, values are string keys `"1"`..`"16"` mapping bag slot index
- `equipped: EquippedItems`

### `InventorySnapshot` (extend)

- `inventory`, `hotbar`, `equipped` always present in sync payload

## Constants

### `Shared/Constants/InventoryConstants.luau`

| Export | Value |
|--------|-------|
| `BAG_SLOT_COUNT` | 16 |
| `HOTBAR_SLOT_COUNT` | 6 |
| `getMaxStack(itemId)` | delegates to `Items.get(id).maxStack` |

Bag modeled as sparse map `{ [string]: InventoryItem }` keyed by slot index `"1"`–`"16"` for stable hotbar references.

## Services

### `InventoryService` (new)

Depends on `PlayerDataService`, `PlayerSyncService`, `Items`.

| Method | Role |
|--------|------|
| `grantItem(player, itemId, quantity)` | Server-only; merge stacks or fill empty slots |
| `removeItem(player, itemId, quantity)` | Server-only; used by future crafting/death |
| `equipTool(player, bagSlotKey)` | Validates `category == "tool"` |
| `setHotbarSlot(player, hotbarIndex, bagSlotKey?)` | Validates indices |
| `useItem(player, bagSlotKey)` | v0.1: `bandage` restores +15 HP via profile survival; consumes 1 |

Remote handlers validate types, permissions, slot bounds, item existence.

After mutation: `PlayerSyncService.syncInventoryToClient`.

### Existing

- `SurvivalService.applyDeathInventoryPenalty` — adapt to bag-slot model (remove random occupied slots)
- `PlayerSyncService.buildInventorySnapshot` — include hotbar + equipped

## Controllers

### `InventoryHUDController` (new)

- ScreenGui `InventoryHUD` (DisplayOrder 105)
- Hotbar row (6 `InventorySlot`) bottom-center
- Toggle key `I` / backpack button opens 4×4 grid panel
- Subscribes to `InventoryUpdatedEvent` via `ClientSyncController` cache (display only)
- Sends intent: `EquipItemEvent`, `SetHotbarSlotEvent`, `UseItemEvent`
- All labels via `Localization.get`; refresh on `LocaleChanged`

### `Shared/UI/InventorySlot.luau` (new)

- Icon placeholder (colored frame + quantity label + name on hover/select)
- Methods: `setItem(snapshot)`, `setSelected`, `setEmpty`

## Remotes

| Event | Direction | Payload |
|-------|-----------|---------|
| `EquipItemEvent` | C→S | `bagSlotKey: string` |
| `SetHotbarSlotEvent` | C→S | `hotbarIndex: number`, `bagSlotKey: string?` |
| `UseItemEvent` | C→S | `bagSlotKey: string` |

Register in `Remotes.luau` + Rojo `.model.json` instances.

## Dev testing

`Bootstrap/init.server.luau` (Studio only):

```luau
-- After services start: grant starter items to joining player once per session
```

Grants: `stick×5`, `flint×2`, `bandage×3` via `InventoryService.grantItem`.

## Security

- Client sends slot keys / hotbar index only — never itemId, quantity, or stats
- Server re-reads bag contents from profile session
- Reject out-of-range slots, unknown items, wrong categories for equip/use
- Rate-limit use/equip with short per-player cooldown (0.25 s)

## Persistence

- Bag/hotbar/equipped live in profile session; saved via existing ProfileStore autosave

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| Death penalty vs slot map | Penalty removes random occupied bag keys; clear hotbar refs pointing to removed keys |
| Sparse bag vs array | Slot keys stable for hotbar; sync sends array form sorted by key for UI |
