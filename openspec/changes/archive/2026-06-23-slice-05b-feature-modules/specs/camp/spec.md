## ADDED Requirements

### Requirement: Structure-specific logic delegation

The camp orchestrator (`CampService`) SHALL NOT contain inline branches on `blueprintId` for structure-specific placement, demolition, storage, or level side-effects. All such logic MUST delegate to the registered `StructureBehavior` for that blueprint via `StructureBehaviorRegistry`.

#### Scenario: No inline chest init in CampService

- GIVEN the codebase implements chest storage initialization
- WHEN reviewing `CampService` placement flow
- THEN chest storage init is invoked through `ChestBehavior.onPlace`
- AND `CampService` does not contain `if blueprintId == "bp_chest"` for storage init

#### Scenario: Camp level side-effects via events or behaviors

- GIVEN camp level transitions from 0 to 1
- WHEN level recalculation completes
- THEN starter recipe unlock is triggered without `CampService` directly requiring `CraftingService`

### Requirement: Chest transfer via chest behavior

The system SHALL handle `TransferItemEvent` in the chest feature behavior module (or a dedicated chest handler registered by `FeatureBootstrap`). Validation rules MUST remain: owner-only, 24 slots per chest, server-authoritative stack limits.

#### Scenario: Transfer handler location

- GIVEN a player transfers an item from bag to chest
- WHEN the server processes `TransferItemEvent`
- THEN the handler lives in the chest feature module tree
- AND ownership and slot validation behave identically to slice-05
