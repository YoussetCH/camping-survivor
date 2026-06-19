# UI — Technical Spec

**Status:** Partial (slice-02 survival HUD, slice-03 inventory HUD)  
**GDD:** Cap. 10  
**Layer:** Controllers + passive ScreenGui

## Purpose

HUD, menus, toasts, mobile-first layouts. UI sends intent only; never mutates authoritative data.

All player-visible copy uses **localization keys** (GDD §1.11, §10.22). See [localization/spec.md](../localization/spec.md).

## Requirements

### Requirement: Hotbar HUD

The client SHALL display a **6-slot** hotbar anchored bottom-center. Each slot shows item quantity when occupied.

#### Scenario: Hotbar visible on join

- GIVEN the client bootstrap completes
- WHEN the player spawns
- THEN the hotbar UI is visible without opening menus

#### Scenario: Hotbar updates from sync

- GIVEN the server fires `InventoryUpdatedEvent`
- WHEN the client receives the snapshot
- THEN hotbar slots reflect server hotbar and bag contents

### Requirement: Inventory panel

The client SHALL provide a toggleable inventory grid (**16 slots**, 4×4) opened via key `I` or an on-screen backpack control.

#### Scenario: Toggle panel

- GIVEN the inventory panel is closed
- WHEN the player presses `I`
- THEN the inventory grid becomes visible
- WHEN pressed again
- THEN the grid hides

### Requirement: Inventory UI intent only

Inventory UI SHALL send player intent via remotes only (`EquipItemEvent`, `SetHotbarSlotEvent`, `UseItemEvent`) and SHALL NOT mutate profile data locally.

#### Scenario: Equip from UI

- GIVEN the player selects a tool slot in the inventory panel
- WHEN the player clicks Equip
- THEN the client fires `EquipItemEvent` with the bag slot key only

### Requirement: Inventory localization

Hotbar and inventory panel labels SHALL use localization keys and refresh on locale change.

#### Scenario: Locale switch

- GIVEN the inventory panel is open in English
- WHEN the player switches to Spanish
- THEN panel title and action buttons display Spanish strings

## Localization

- Default locale: `en`
- HUD labels, alerts, and menus resolve via `Localization.get(key)`
- Controllers refresh on `LocaleChanged` when settings change
