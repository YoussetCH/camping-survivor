# Quests — Technical Spec

**Status:** Stub (slice-08)  
**GDD:** Cap. 8  
**Service:** QuestService

## Purpose

Tutorial chain, main/side/daily missions, XP and Brasas rewards.
## Requirements

_To be defined in slice-08-quests._

### Requirement: Quest definitions registry

The system SHALL expose static quest definitions in `Shared/Constants/Quests.luau` including at minimum: tutorial chain `t01_spawn` through `t08_complete`, bridge `m00_wood`, main `main_01_chest`, and side quests `side_01_berries` and `side_02_wolf`. Each definition SHALL include `questId`, `questType` (`tutorial` | `main` | `side`), `objectives` array, `rewards` (xp, currency, items), `prerequisites` (quest ids or `tutorialCompleted`), and localization keys for title and objective text.

#### Scenario: Quest lookup by id

- GIVEN code requires quest id `t02_gather`
- WHEN `Quests.get("t02_gather")` is called
- THEN a valid `QuestDefinition` is returned with objective kind `gather` for `stick` ×3 and `stone` ×2

### Requirement: Quest progress persistence

The system SHALL persist per-player quest state in profile field `quests` as a map `{ [questId]: QuestState }` where `QuestState` includes `status` (`active` | `completed`), `objectives` progress counters, and `startedAt` / `completedAt` timestamps. Completed quest ids SHALL also be recorded in `stats.missionsCompleted`.

#### Scenario: Tutorial step completion persisted

- GIVEN a player completes objective for `t02_gather`
- WHEN the server saves the profile
- THEN `quests.t02_gather.objectives` reflect gathered counts
- AND `stats.missionsCompleted` includes `t02_gather` after full quest completion

### Requirement: QuestService authoritative lifecycle

The system SHALL implement `QuestService` as the sole authority for starting quests, incrementing objectives, completing quests, and granting rewards. Controllers and remotes SHALL NOT mutate quest progress directly.

#### Scenario: Auto-start tutorial on first join

- GIVEN a new player with `tutorialCompleted = false` and empty `quests`
- WHEN the profile loads successfully
- THEN `QuestService` starts `t01_spawn` as active
- AND fires `QuestProgressEvent` with updated snapshot

### Requirement: Objective kinds v0.1

`QuestService` SHALL support objective kinds: `gather` (item id + count), `craft` (recipe or output item + count), `place_structure` (blueprint id + count), `survive_cold` (maintain temperature above threshold near campfire for duration), `defeat_fauna` (species id + count), and `open_ui` (panel id for tutorial UI step).

#### Scenario: Gather objective increments on harvest

- GIVEN quest `t02_gather` is active with objective gather 3× `stick`
- WHEN the player harvests 1 `stick` validated by `ResourceService`
- THEN quest progress for `stick` increments by 1 server-side
- AND `QuestProgressEvent` fires if progress changed

#### Scenario: Defeat fauna objective

- GIVEN quest `side_02_wolf` is active
- WHEN the player kills a `wolf` validated by `AnimalService`
- THEN wolf defeat count increments by 1

### Requirement: Quest completion and rewards

When all objectives of an active quest are satisfied, `QuestService` SHALL mark the quest completed, grant configured rewards (XP to `stats.xp`, Brasas to `currency`, items via `InventoryService`), apply level-up when XP threshold crossed per GDD §8.3 table (levels 1–5), start the next quest in chain if defined, and fire sync events.

#### Scenario: Tutorial final step rewards

- GIVEN player completes `t08_complete`
- WHEN all objectives are satisfied
- THEN `tutorialCompleted` becomes true
- AND player receives configured XP reward
- AND `m00_wood` becomes available/active per chain rules

### Requirement: Quest prerequisites and concurrency

The system SHALL enforce prerequisites before starting a quest. At most **one** `main` quest and **two** `side` quests MAY be active simultaneously. Tutorial steps SHALL run sequentially (only one active tutorial quest at a time).

#### Scenario: Main quest blocked until tutorial done

- GIVEN `tutorialCompleted = false`
- WHEN the player attempts to start `main_01_chest`
- THEN the request is rejected without mutation

### Requirement: QuestTrackEvent remote

The system SHALL register `QuestTrackEvent` (client→server). The client SHALL send `questId` only. The server SHALL validate the quest exists, is active or completed, and belongs to the player before setting `trackedQuestId` on session cache and echoing via `QuestProgressEvent`.

#### Scenario: Track active quest

- GIVEN quest `m00_wood` is active for the player
- WHEN the client fires `QuestTrackEvent("m00_wood")`
- THEN server sets tracked quest to `m00_wood`
- AND subsequent `QuestProgressEvent` includes `trackedQuestId = "m00_wood"`

### Requirement: Tutorial protection rules

During active tutorial chain (`tutorialCompleted = false`), the system SHALL grant player invulnerability to survival damage and SHALL prevent fauna aggression within **80 studs** of the player's assigned camp plot center.

#### Scenario: Tutorial player cannot die to fauna

- GIVEN tutorial is in progress and fauna attacks the player
- WHEN damage would be applied
- THEN survival health does not decrease
- AND fauna within 80 studs of plot center do not enter chase/attack against tutorial players

### Requirement: Quest localization

All quest titles, objective descriptions, tracker labels, and completion toasts SHALL use localization keys (`quest.<id>.*`). No hardcoded player-visible quest strings in controllers.

#### Scenario: Quest tracker locale switch

- GIVEN the quest tracker displays an active quest in English
- WHEN the player switches locale to Spanish
- THEN tracker text updates to Spanish keys without rejoining

### Requirement: Escort to plot objective kind

`QuestService` SHALL support objective kind `escort_to_plot` with target `helperTypeId` (e.g. `lumberjack`). Progress increments when the escort NPC associated with that helper type enters the player's assigned camp plot bounds while the owning player is present.

#### Scenario: Lumberjack escort progress

- GIVEN quest `main_05_lumberjack` is active
- WHEN the lumberjack escort NPC and player are both within plot bounds
- THEN escort objective progress reaches target
- AND quest completion flow runs

### Requirement: Main quest main_05_lumberjack

The system SHALL define quest `main_05_lumberjack` (main type) with prerequisite `main_01_chest`, objective escort `lumberjack` to plot, rewards per GDD §8.6 (120 XP + recruit lumberjack), and localization keys under `quest.main_05_lumberjack.*`.

#### Scenario: Quest unlocks after chest quest

- GIVEN player completed `main_01_chest` and tutorial
- WHEN `QuestService` evaluates available mains
- THEN `main_05_lumberjack` may start when no other main is blocking

