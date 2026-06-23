# Inventory — Technical Spec

**Status:** Implemented (slice-03, extended slice-04, slice-05 chest transfer)  
**GDD:** Cap. 4  
**Service:** InventoryService

## Purpose

Player inventory, hotbar, stacks, equip slots. Authoritative bag model with client HUD.

## Requirements

### Requirement: Bag slot capacity

The system SHALL store player items in up to **16** bag slots keyed `"1"` through `"16"`. Each slot holds one stack of an item id with quantity ≥ 1.

#### Scenario: Bag full

- GIVEN a player occupies all 16 bag slots with non-stackable or full stacks
- WHEN the server attempts to grant another item that cannot merge
- THEN the grant fails without mutating inventory
- AND the client receives no erroneous sync

### Requirement: Stack limits

The system SHALL enforce per-item `maxStack` from `Items` when merging stacks in the same bag slot or granting items.

#### Scenario: Merge sticks

- GIVEN bag slot `"1"` contains `stick` × 28 (maxStack 30)
- WHEN the server grants `stick` × 3
- THEN slot `"1"` becomes `stick` × 30
- AND remaining quantity fills the next available slot or fails if none

### Requirement: Hotbar

The system SHALL persist a **6-slot** hotbar referencing bag slot keys. Hotbar entries MAY be empty.

#### Scenario: Assign hotbar slot

- GIVEN bag slot `"3"` contains `flint` × 2
- WHEN the client fires `SetHotbarSlotEvent` with hotbarIndex 1 and bagSlotKey `"3"`
- THEN hotbar slot 1 references bag slot `"3"`
- AND `InventoryUpdatedEvent` includes the updated hotbar

#### Scenario: Invalid hotbar index rejected

- GIVEN a client sends hotbarIndex 0 or 7
- WHEN the server validates the request
- THEN the request is rejected without mutation

### Requirement: Tool equip slot

The system SHALL allow equipping one tool from the bag. Equipped tool id is stored in `equipped.toolItemId`.

#### Scenario: Equip tool

- GIVEN bag slot `"2"` contains a `tool` category item
- WHEN the client fires `EquipItemEvent` with bagSlotKey `"2"`
- THEN `equipped.toolItemId` matches that item id
- AND inventory sync reflects equipped state

#### Scenario: Non-tool rejected

- GIVEN bag slot `"1"` contains `stick`
- WHEN the client fires `EquipItemEvent` with bagSlotKey `"1"`
- THEN the request is rejected

### Requirement: Item use (v0.1)

The system SHALL process `UseItemEvent` server-side. v0.1 supports `bandage`: consume 1 and increase survival health by **15** (clamped to 100).

#### Scenario: Use bandage

- GIVEN bag slot `"4"` contains `bandage` × 1 and health is 70
- WHEN the client fires `UseItemEvent` with bagSlotKey `"4"`
- THEN quantity becomes 0 and the slot is cleared
- AND health becomes 85
- AND survival and inventory sync events fire

### Requirement: Inventory sync payload

The server SHALL fire `InventoryUpdatedEvent` after any inventory, hotbar, or equip mutation with `{ inventory, hotbar, equipped }`.

#### Scenario: After grant

- GIVEN the server grants items to a player
- WHEN the grant completes
- THEN the client receives `InventoryUpdatedEvent` with the full snapshot

### Requirement: Death penalty compatibility

Random inventory loss on death (GDD 35%) SHALL operate on occupied bag slots and clear hotbar references to removed slots.

#### Scenario: Death removes slot referenced by hotbar

- GIVEN hotbar slot 2 references bag slot `"5"`
- WHEN death penalty removes bag slot `"5"`
- THEN hotbar slot 2 becomes empty
- AND sync reflects both changes

### Requirement: Batch item consumption

`InventoryService` SHALL provide server-only methods to count items across bag slots and remove quantities matching recipe inputs without trusting client payloads.

#### Scenario: Remove recipe inputs

- GIVEN bag contains `leaf` × 4 across two slots
- WHEN the server removes 2× `leaf` for a craft
- THEN total `leaf` quantity decreases by 2
- AND empty slots are cleared
- AND hotbar references to removed slots are cleared

### Requirement: Output capacity check

`InventoryService` SHALL verify the bag can accept craft outputs (merge stacks or empty slots) before consuming inputs.

#### Scenario: Bag full blocks craft

- GIVEN all 16 bag slots are occupied with non-mergeable full stacks
- WHEN the server checks output for a new item
- THEN `canFitOutputs` returns false and craft does not consume inputs

### Requirement: Camp chest transfer

The system SHALL process `TransferItemEvent` server-side to move items between the player's bag and a camp chest on their own plot. The client MUST send direction, `chestStructureId`, and slot keys only — never item quantities beyond what the server validates from slot state.

#### Scenario: Deposit to chest

- GIVEN bag slot `"1"` contains `wood` × 5 and the player's chest has free space
- WHEN the client fires `TransferItemEvent` with direction `toChest`, valid bag and chest slot keys
- THEN bag quantity decreases and chest slot receives the items
- AND `InventoryUpdatedEvent` and `CampUpdatedEvent` fire

#### Scenario: Withdraw from chest

- GIVEN chest slot contains `flint` × 2 and bag has space
- WHEN the client fires `TransferItemEvent` with direction `toBag`
- THEN chest slot decreases and bag receives the items

#### Scenario: Foreign chest rejected

- GIVEN a chest structure on another player's plot
- WHEN the client fires `TransferItemEvent` targeting that chest
- THEN no inventory mutation occurs

#### Scenario: Chest full blocks deposit

- GIVEN all 24 chest slots are occupied with non-mergeable full stacks
- WHEN the client attempts to deposit a non-mergeable item
- THEN the transfer fails without mutation

### Requirement: Camp chest slot capacity

Camp chest storage SHALL use up to **24** slots keyed `"1"` through `"24"` per chest structure, with the same stack rules as the player bag.

#### Scenario: Chest stack merge

- GIVEN chest slot `"1"` contains `stick` × 28 (maxStack 30)
- WHEN the server deposits `stick` × 2 into that slot
- THEN slot `"1"` becomes `stick` × 30

### Requirement: Resource harvest grant

The system SHALL grant items to the player's bag when `ResourceService` validates a successful harvest. Grants MUST respect stack limits and bag capacity; failed grants MUST NOT deplete the node.

#### Scenario: Grant after harvest

- GIVEN a valid harvest of `stick` × 2 and bag has space
- WHEN `ResourceService` completes validation
- THEN bag receives `stick` × 2
- AND `InventoryUpdatedEvent` fires with the full snapshot

#### Scenario: Partial stack merge

- GIVEN bag slot `"1"` contains `berry` × 28 (maxStack 30)
- WHEN harvest grants `berry` × 3
- THEN slot `"1"` becomes `berry` × 30
- AND remaining `berry` × 1 fills another slot or fails the harvest if no slot remains

## Related

- [foundation/spec.md](../foundation/spec.md) — profile schema
- [ui/spec.md](../ui/spec.md) — inventory HUD
- [survival/spec.md](../survival/spec.md) — death penalty
- [camp/spec.md](../camp/spec.md) — chest transfer
- [crafting/spec.md](../crafting/spec.md) — batch consume for crafts
