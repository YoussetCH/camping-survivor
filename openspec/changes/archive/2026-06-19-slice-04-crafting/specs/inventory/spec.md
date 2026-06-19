## ADDED Requirements

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
