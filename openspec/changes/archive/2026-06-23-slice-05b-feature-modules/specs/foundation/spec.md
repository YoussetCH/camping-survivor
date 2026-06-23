## ADDED Requirements

### Requirement: Server game events bus

The system SHALL provide a server-side `GameEvents` module exposing typed signals for cross-feature notifications that MUST NOT use direct service-to-service imports. At minimum, the bus MUST include `CampPlotAssigned(player, plotId)` and `CampLevelChanged(player, newLevel, oldLevel)`.

#### Scenario: Plot assignment fires event

- GIVEN a new player receives their first camp plot assignment
- WHEN assignment persists successfully
- THEN `GameEvents.CampPlotAssigned` fires with the player and plotId

#### Scenario: Survival listens without CampService import

- GIVEN `SurvivalService` needs to teleport a player to their plot on first assignment
- WHEN `CampPlotAssigned` fires
- THEN `SurvivalService` (or its bootstrap listener) teleports the player
- AND `SurvivalService` does not require `CampService` at runtime

#### Scenario: Camp level change fires event

- GIVEN camp level transitions from 0 to 1 after placing starter structures
- WHEN level recalculation completes
- THEN `GameEvents.CampLevelChanged` fires with newLevel 1 and oldLevel 0
