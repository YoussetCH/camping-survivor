## MODIFIED Requirements

### Requirement: Camp craft stations

The system SHALL allow crafting at station `craft_table` when the player is within **12 studs** of their own placed `bp_craft_table` on their assigned plot, and at station `campfire` when within **8 studs** of their own placed `bp_campfire`. Station proximity MUST be resolved through `StationRegistry.isPlayerNearStation` rather than direct calls to `CampService`.

#### Scenario: Craft at craft table

- GIVEN a player has `recipe_chest` unlocked and stands within 12 studs of their craft table
- WHEN the client fires `CraftItemEvent` with `recipe_chest`
- THEN the craft proceeds if other validations pass

#### Scenario: Craft table too far

- GIVEN a recipe requires station `craft_table`
- WHEN the player is not within range of their craft table
- THEN the request is rejected with reason key `craft.error.wrong_station`
