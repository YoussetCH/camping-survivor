## ADDED Requirements

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

## MODIFIED Requirements

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
