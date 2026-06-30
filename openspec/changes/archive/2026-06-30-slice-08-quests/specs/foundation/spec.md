# Foundation — Delta Spec (slice-08)

## MODIFIED Requirements

### Requirement: Extended player profile schema

The system SHALL persist an extended `PlayerProfile` including survival stats, status effects, camp data (plot id, level, structures array, per-chest storage maps), unlocked recipes, monetization purchase tracking, tutorial completion, extended stats (playTime, deaths, **missionsCompleted**), hotbar (6 entries), equipped tool/coat ids, and **typed quest progress** map `quests: { [questId]: QuestState }`.

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

## ADDED Requirements

### Requirement: QuestTrackEvent in remote registry

The system SHALL register `QuestTrackEvent` under `ReplicatedStorage.Remotes.Events` alongside existing domain sync events.

#### Scenario: QuestTrackEvent exists at server start

- GIVEN the server has finished `NetworkingService:Init`
- WHEN `QuestTrackEvent` is queried
- THEN a RemoteEvent instance exists with that name

### Requirement: Extended quest sync payload

`QuestProgressEvent` SHALL carry an extended `QuestSnapshot` including: `progress` (full quests map), `tutorialCompleted`, `trackedQuestId`, `activeQuestIds`, `stats.level`, and `stats.xp` sufficient for HUD tracker and journal without extra remotes.

#### Scenario: Initial sync includes quest state

- GIVEN a player profile loaded successfully
- WHEN initial sync runs
- THEN `QuestProgressEvent` fires with current quest progress, level, xp, and tracked quest id (if any)
