# Crafting — Technical Spec

**Status:** Implemented (slice-04 hands; slice-05 camp stations; slice-05b station registry)  
**GDD:** Cap. 4  
**Service:** CraftingService

## Purpose

Recipes, craft stations, experimentation, blueprint output.

## Requirements

### Requirement: Recipe catalog

The system SHALL define craft recipes in `Shared/Constants/Recipes.luau` with id, nameKey, unlockType, station, inputs, and outputs.

#### Scenario: Tutorial sparks recipe

- GIVEN recipe `recipe_sparks` exists
- WHEN the server loads the recipe definition
- THEN inputs are 1× `flint` and 1× `stick`
- AND output is 1× `sparks` at station `hands`

### Requirement: Tutorial recipe auto-unlock

The system SHALL unlock all recipes with `unlockType == "tutorial"` into `PlayerProfile.recipes.unlocked` when a profile is loaded if not already present.

#### Scenario: New player unlocks tutorial set

- GIVEN a new profile with empty `recipes.unlocked`
- WHEN the player data loads on the server
- THEN `recipe_sparks`, `recipe_tinder`, `recipe_bandage`, `recipe_campfire`, `recipe_craft_table`, and `recipe_chest` are in `recipes.unlocked`

### Requirement: Server-authoritative craft

The system SHALL process `CraftItemEvent` on the server. The client MUST send only `recipeId`. The server MUST validate unlock, station (including camp proximity for `craft_table` and `campfire`), inputs, output capacity, and cooldown before mutating inventory.

#### Scenario: Successful craft

- GIVEN a player has `recipe_sparks` unlocked and bag contains 1× `flint` and 1× `stick`
- WHEN the client fires `CraftItemEvent` with `recipe_sparks`
- THEN inputs are consumed and 1× `sparks` is granted
- AND `CraftResultEvent` fires with `success = true`
- AND `InventoryUpdatedEvent` reflects the new bag contents

#### Scenario: Missing inputs rejected

- GIVEN a player lacks required inputs for `recipe_bandage`
- WHEN the client fires `CraftItemEvent` with `recipe_bandage`
- THEN inventory is unchanged
- AND `CraftResultEvent` fires with `success = false` and reason key `craft.error.missing_items`

#### Scenario: Locked recipe rejected

- GIVEN `recipe_pick_crude` is not in `recipes.unlocked`
- WHEN the client fires `CraftItemEvent` with `recipe_pick_crude`
- THEN the request is rejected without mutation

#### Scenario: Wrong station rejected

- GIVEN a recipe requires station `craft_table`
- WHEN the player is not within range of their craft table
- THEN the request is rejected with reason key `craft.error.wrong_station`

### Requirement: Craft cooldown

The system SHALL enforce a **1 second** per-player cooldown between successful or attempted crafts.

#### Scenario: Cooldown blocks spam

- GIVEN a player crafted within the last second
- WHEN they fire `CraftItemEvent` again
- THEN the request is rejected with reason key `craft.error.cooldown`

### Requirement: Recipe sync

The server SHALL fire `RecipesUpdatedEvent` with `{ unlocked }` after profile load and when unlocks change.

#### Scenario: Recipes on join

- GIVEN a player joins with tutorial recipes unlocked
- WHEN sync runs
- THEN the client receives `RecipesUpdatedEvent` with the unlocked list

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

### Requirement: Starter construction recipes

The system SHALL define `recipe_craft_table` and `recipe_chest` in `Recipes.luau` with station `craft_table` / `hands` and outputs `bp_craft_table` / `bp_chest`.

#### Scenario: Craft table recipe exists

- GIVEN `recipe_craft_table` is loaded
- WHEN inputs are checked
- THEN recipe requires wood and stone per GDD starter construction table

### Requirement: Starter recipe unlock on camp level 1

The system SHALL unlock all recipes with `unlockType == "starter"` into `PlayerProfile.recipes.unlocked` when `camp.level` reaches 1 if not already present.

#### Scenario: Level 1 unlocks starter set

- GIVEN camp level transitions to 1
- WHEN level recalculation completes
- THEN starter recipes are added to `recipes.unlocked` if any exist
- AND `RecipesUpdatedEvent` fires

## Related

- [inventory/spec.md](../inventory/spec.md) — consume/grant items
- [ui/spec.md](../ui/spec.md) — crafting panel
- [camp/spec.md](../camp/spec.md) — craft stations and plot
