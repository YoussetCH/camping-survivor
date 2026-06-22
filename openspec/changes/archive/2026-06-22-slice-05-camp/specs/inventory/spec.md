## ADDED Requirements

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
