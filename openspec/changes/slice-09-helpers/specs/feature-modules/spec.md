# Feature Modules — Delta Spec (slice-09)

## ADDED Requirements

### Requirement: Helper behavior registry

The system SHALL provide a server-side `HelperBehaviorRegistry` that maps each `helperTypeId` to a registered helper behavior module. The registry MUST expose `register(behavior)`, `get(helperTypeId)`, and `getAll()`. `HelperService` SHALL delegate task execution and recruitment validation to registry lookups — no `if helperTypeId ==` branches in the orchestrator.

#### Scenario: Lumberjack behavior lookup

- GIVEN `LumberjackBehavior` is registered for `lumberjack`
- WHEN `HelperService` runs a work tick for a lumberjack instance
- THEN the registry returns lumberjack behavior
- AND `onWorkTick` is invoked with player, profile, and helper state context

### Requirement: Helper feature module folder convention

Each helper type SHALL live under `ReplicatedStorage/Shared/Features/<HelperName>/` (definition + model) and `ServerScriptService/Features/Behaviors/<HelperName>Behavior.luau`. `HelperBootstrap` MUST require all helper behavior modules at server init before `HelperService` starts.

#### Scenario: Disable lumberjack by module removal

- GIVEN lumberjack folder and registry entry are removed
- WHEN the server starts
- THEN no lumberjack recruitment or work ticks run
- AND other helpers (future) remain unaffected if registered separately
