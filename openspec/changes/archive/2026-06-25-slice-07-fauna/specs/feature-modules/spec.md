## ADDED Requirements

### Requirement: Fauna registry

The system SHALL provide a server-side `FaunaRegistry` mapping each `speciesId` to a registered fauna behavior module. The registry MUST expose `register(behavior)`, `get(speciesId)`, and `getAll()`. `AnimalService` MUST resolve species stats, model builders, and hooks through the registry without species-specific branches.

#### Scenario: Wolf behavior registered

- GIVEN `WolfBehavior` registers on server init via `FaunaBootstrap`
- WHEN `FaunaRegistry.get("wolf")` is called
- THEN a non-nil behavior with species stats and drop table is returned

#### Scenario: Unknown species has no behavior

- GIVEN no behavior is registered for `bear`
- WHEN `FaunaRegistry.get("bear")` is called
- THEN the result is nil
- AND `AnimalService` skips spawn for that species

### Requirement: Fauna feature module folder convention

Each fauna species SHALL live under `ReplicatedStorage/Shared/Features/<SpeciesName>/` with `<Species>Definition.luau` and `<Species>Model.luau`. Server hooks live in `ServerScriptService/Features/Behaviors/<Species>Behavior.luau`. Aggregated species lists MAY live in `FaunaDefinitions.luau` similar to `FeatureDefinitions.luau`.

#### Scenario: Wolf module isolation

- GIVEN the wolf feature folder and registry entry exist
- WHEN wolf is removed from `FaunaBootstrap` and registry
- THEN wolves no longer spawn and no wolf-specific code remains in `AnimalService`
