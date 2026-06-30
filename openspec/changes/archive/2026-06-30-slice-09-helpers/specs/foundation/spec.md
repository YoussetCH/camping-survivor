# Foundation — Delta Spec (slice-09)

## MODIFIED Requirements

### Requirement: Extended player profile schema

The system SHALL persist an extended `PlayerProfile` including survival stats, status effects, camp data (plot id, level, structures array, per-chest storage maps), unlocked recipes, monetization purchase tracking, tutorial completion, extended stats (playTime, deaths, missionsCompleted), hotbar (6 entries), equipped tool/coat ids, typed quest progress map `quests`, **`helpers` map**, and **`lostHelpers` array**.

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
- AND `quests` is an empty map
- AND `stats.missionsCompleted` is an empty array
- AND `helpers` is an empty map
- AND `lostHelpers` is an empty array

## ADDED Requirements

### Requirement: Helper remotes registry

The system SHALL register `HelperUpdatedEvent`, `FeedHelperEvent`, `CureHelperEvent`, and `SetHelperModeEvent` under `ReplicatedStorage.Remotes.Events`.

#### Scenario: Helper remotes exist at server start

- GIVEN the server has finished `NetworkingService:Init`
- WHEN `FeedHelperEvent` is queried
- THEN a RemoteEvent instance exists with that name
