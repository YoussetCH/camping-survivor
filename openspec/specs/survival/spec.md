# Survival — Technical Spec

**Status:** Implemented (slice-02)  
**GDD:** Cap. 3  
**Service:** SurvivalService

## Purpose

Vital stats (hunger, thirst, temperature, health), server tick every 6 seconds, soft death with inventory penalty, HUD display with alert thresholds.

## Requirements

### Requirement: Server survival tick

The system SHALL run `SurvivalService` on a **6 second** interval and apply authoritative stat changes for each player with a loaded profile.

#### Scenario: Passive drain

- GIVEN a player with hunger 80 and thirst 80
- WHEN 60 seconds pass (10 ticks)
- THEN hunger decreases by approximately 1
- AND thirst decreases by approximately 1.5

### Requirement: Temperature drift

The system SHALL move player temperature toward ambient at **2 points/minute** until slice-06 provides biome context; ambient defaults to **45**.

#### Scenario: Drift from comfort

- GIVEN player temperature is 50 and ambient is 45
- WHEN 60 seconds pass
- THEN temperature moves approximately 2 points toward 45

### Requirement: Critical stat HP damage

The system SHALL apply HP damage from critical hunger, thirst, and temperature per GDD §3.2 with a cap of **−4 HP/min** total.

#### Scenario: Low hunger damage

- GIVEN hunger is 15 and no other critical conditions
- WHEN 60 seconds pass
- THEN health decreases by approximately 0.5

### Requirement: Health regeneration

The system SHALL regenerate HP at **+0.5/min** when hunger > 40, thirst > 30, and no blocking status effects are active.

#### Scenario: Base regen

- GIVEN hunger 50, thirst 40, health 80, no status effects
- WHEN 60 seconds pass
- THEN health increases by approximately 0.5

### Requirement: Player death and soft penalty

When survival health reaches **0**, the system SHALL respawn the player with GDD respawn stats and apply **35%** random inventory slot loss unless `tutorialCompleted` is false.

#### Scenario: Death inventory loss

- GIVEN tutorial is completed and inventory has 10 slots
- WHEN the player dies from 0 HP
- THEN 4 inventory slots are removed (ceil 35%)
- AND survival stats reset to respawn values
- AND `stats.deaths` increments by 1

#### Scenario: Tutorial death protection

- GIVEN `tutorialCompleted` is false
- WHEN the player dies
- THEN inventory is unchanged

### Requirement: Survival HUD

The client SHALL display HP, hunger, thirst, and temperature bars using `StatBar` and update from `SurvivalUpdatedEvent`.

#### Scenario: Alert thresholds

- GIVEN hunger is 18
- WHEN the HUD updates
- THEN the hunger bar shows danger (red) state per GDD §10.4

### Requirement: Survival sync on change

The server SHALL fire `SurvivalUpdatedEvent` after tick changes or death respawn.

#### Scenario: Tick sync

- GIVEN a survival tick modifies stats
- WHEN the tick completes
- THEN the client receives `SurvivalUpdatedEvent` with updated snapshot

## Related

- `src/ReplicatedStorage/Shared/Constants/SurvivalConstants.luau`
- `src/ReplicatedStorage/Shared/UI/StatBar.luau`
- `src/ServerScriptService/Services/SurvivalService.luau`
- `src/StarterPlayer/StarterPlayerScripts/Controllers/SurvivalHUDController.luau`

## Deferred (later slices)

- Status effects (`bleeding`, `poison`, etc.) — slice-07
- Biome/day-night ambient temperature — slice-06
- Food/water consumption — slice-03/04
- Camp/fire temperature override — slice-05
