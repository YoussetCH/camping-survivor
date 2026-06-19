## ADDED Requirements

### Requirement: Crafting panel

The client SHALL provide a toggleable crafting panel opened via key `C` or an on-screen craft control. The panel lists unlocked recipes available at station `hands` (v0.1).

#### Scenario: Toggle crafting panel

- GIVEN the crafting panel is closed
- WHEN the player presses `C`
- THEN the crafting panel becomes visible
- WHEN pressed again
- THEN the panel hides

### Requirement: Crafting UI intent only

Crafting UI SHALL send player intent via `CraftItemEvent` with `recipeId` only and SHALL NOT mutate inventory or unlocks locally.

#### Scenario: Craft from UI

- GIVEN the player selects `recipe_sparks` in the crafting panel
- WHEN the player clicks Craft
- THEN the client fires `CraftItemEvent` with `"recipe_sparks"`

### Requirement: Craft result feedback

The client SHALL display localized feedback when `CraftResultEvent` is received (success toast or error reason key).

#### Scenario: Craft success toast

- GIVEN the player initiated a craft
- WHEN `CraftResultEvent` arrives with `success = true`
- THEN a localized success message is shown

### Requirement: Crafting localization

Crafting panel labels and result messages SHALL use localization keys and refresh on locale change.

#### Scenario: Locale switch

- GIVEN the crafting panel is open in English
- WHEN the player switches to Spanish
- THEN recipe names and buttons display Spanish strings
