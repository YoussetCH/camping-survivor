## MODIFIED Requirements

### Requirement: Extended player profile schema

The system SHALL persist an extended `PlayerProfile` including survival stats, status effects, camp data, unlocked recipes, monetization purchase tracking, tutorial completion, extended stats (playTime, deaths), **hotbar (6 entries)**, and **equipped tool/coat ids**.

#### Scenario: New player defaults

- GIVEN a player joins for the first time
- WHEN the profile is reconciled from template
- THEN survival.hunger and survival.thirst are 80
- AND survival.health is 100
- AND survival.temperature is 50
- AND camp.level is 0
- AND tutorialCompleted is false
- AND hotbar has 6 empty entries
- AND equipped.toolItemId and equipped.coatItemId are nil

## ADDED Requirements

### Requirement: Inventory sync snapshot shape

`InventoryUpdatedEvent` SHALL include `inventory`, `hotbar`, and `equipped` matching the authoritative profile state.

#### Scenario: Initial sync on join

- GIVEN a player profile loaded successfully
- WHEN initial sync runs
- THEN `InventoryUpdatedEvent` fires with inventory, hotbar, and equipped fields
