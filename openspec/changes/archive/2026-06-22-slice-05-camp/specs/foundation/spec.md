## MODIFIED Requirements

### Requirement: Extended player profile schema

The system SHALL persist an extended `PlayerProfile` including survival stats, status effects, camp data (plot id, level, structures array, per-chest storage maps), unlocked recipes, monetization purchase tracking, tutorial completion, extended stats (playTime, deaths), hotbar (6 entries), and equipped tool/coat ids.

#### Scenario: New player defaults

- GIVEN a player joins for the first time
- WHEN the profile is reconciled from template
- THEN survival.hunger and survival.thirst are 80
- AND survival.health is 100
- AND survival.temperature is 50
- AND camp.level is 0
- AND camp.plotId is nil until assigned
- AND camp.structures is an empty array
- AND camp.chests is an empty map
- AND tutorialCompleted is false
- AND `settings.locale` is `"en"`
- AND hotbar has 6 empty entries
- AND equipped.toolItemId and equipped.coatItemId are nil
