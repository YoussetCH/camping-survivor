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

The system SHALL move player temperature toward **biome ambient** from `BiomeService` (day/night aware) at **2 points/minute**. When world services are unavailable, ambient defaults to **45**.

#### Scenario: Drift from comfort

- GIVEN player temperature is 50 and biome ambient is 45
- WHEN 60 seconds pass
- THEN temperature moves approximately 2 points toward 45

#### Scenario: Night forest colder ambient

- GIVEN the player is in `forest_near` at night (ambient 25)
- WHEN 60 seconds pass
- THEN temperature moves approximately 2 points toward 25

### Requirement: Critical stat HP damage

The system SHALL apply HP damage from critical hunger, thirst, and temperature per GDD §3.2 with a cap of **−4 HP/min** total.

#### Scenario: Low hunger damage

- GIVEN hunger is 15 and no other critical conditions
- WHEN 60 seconds pass
- THEN health decreases by approximately 0.5

### Requirement: Health regeneration

The system SHALL regenerate HP at **+0.5/min** when hunger > 40, thirst > 30, and no blocking status effects (`bleeding`, `poison`, `infection`) are active. When the player owns a camp plot, regen rate SHALL be **+1/min** under the same conditions.

#### Scenario: Base regen

- GIVEN hunger 50, thirst 40, health 80, no status effects
- WHEN 60 seconds pass
- THEN health increases by approximately 0.5

#### Scenario: Regen blocked by poison

- GIVEN hunger 50, thirst 40, health 80, active `poison`
- WHEN 60 seconds pass
- THEN health does not increase from regen
- AND poison tick damage still applies

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

### Requirement: Status effect tick damage

The system SHALL apply periodic HP damage from active status effects during each survival tick per GDD §3.5: `bleeding` −1 HP every 10 s (−6/min), `poison` −0.2 HP per tick (−2/min), `infection` −0.1 HP per tick (−1/min). Status damage SHALL count toward the existing `HP_DAMAGE_CAP_PER_MINUTE` cap together with critical-stat damage.

#### Scenario: Bleeding tick damage

- GIVEN a player has active status effect `bleeding`
- WHEN one survival tick (6 s) completes
- THEN health decreases by approximately 1
- AND `SurvivalUpdatedEvent` fires with updated snapshot

#### Scenario: Poison tick damage

- GIVEN a player has active status effect `poison`
- WHEN 60 seconds pass (10 ticks)
- THEN health decreases by approximately 2

### Requirement: Bleeding to infection transition

The system SHALL transition `bleeding` to `infection` when `bleeding` remains uncured for **300 seconds** (5 min). `infection` SHALL block HP regeneration per existing blocking rules.

#### Scenario: Infection after untreated bleeding

- GIVEN a player has had `bleeding` for 300 seconds without cure
- WHEN the survival tick runs
- THEN `infection` is added to status effects
- AND `bleeding` may remain or be replaced per design (both block regen)

### Requirement: Authoritative damage and status application

The system SHALL expose `SurvivalService.applyDamage(player, amount, statusEffectIds?)` for server-only callers (e.g. `AnimalService`). The server MUST clamp health to 0–100, apply listed status effects, trigger death handling at 0 HP, and fire `SurvivalUpdatedEvent`.

#### Scenario: Fauna melee applies damage and status

- GIVEN a wolf attack hits a player for 15 damage with 60% bleeding chance
- WHEN `applyDamage` is called with amount 15 and status `bleeding`
- THEN player health decreases by 15
- AND `bleeding` appears in status effects when rolled
- AND death triggers if health reaches 0

### Requirement: Death clears status effects

When a player dies and respawns, the system SHALL remove all status effects from the profile.

#### Scenario: Respawn clears debuffs

- GIVEN a player dies with `bleeding` and `poison` active
- WHEN respawn completes
- THEN `statusEffects` is empty
- AND survival stats reset to respawn values

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
