# Quests — Delta Spec (slice-09)

## ADDED Requirements

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
