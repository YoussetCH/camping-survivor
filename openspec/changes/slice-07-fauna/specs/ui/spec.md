## ADDED Requirements

### Requirement: Status effect HUD row

The client SHALL display active status effects from `SurvivalUpdatedEvent` as an icon row below the survival stat bars. Each icon MUST use a localization tooltip key (`status.<effectId>.name`).

#### Scenario: Bleeding icon visible

- GIVEN the player has active `bleeding`
- WHEN the survival HUD updates
- THEN a bleeding icon appears in the status row
- AND tooltip resolves via localization

#### Scenario: Effect cleared removes icon

- GIVEN `bleeding` was active and bandage cures it
- WHEN `SurvivalUpdatedEvent` arrives without `bleeding`
- THEN the bleeding icon is removed

### Requirement: Fauna health bar display

The client SHALL render a passive health bar (`BillboardGui`) on fauna models when `FaunaUpdatedEvent` provides HP data. The bar MUST NOT mutate fauna HP locally.

#### Scenario: Health bar reflects server HP

- GIVEN a wolf at 30/40 HP per `FaunaUpdatedEvent`
- WHEN the client renders the billboard
- THEN the bar fill shows 75%

#### Scenario: Removed fauna hides bar

- GIVEN `FaunaUpdatedEvent` with `removed = true`
- WHEN the client processes the event
- THEN the health bar is destroyed

### Requirement: Fauna attack intent

The client SHALL fire `AttackFaunaEvent` with `faunaId` only when the player initiates attack on fauna while a tool is equipped. The client MUST NOT apply damage locally.

#### Scenario: Attack intent with tool

- GIVEN the player has a tool equipped and clicks a fauna model
- WHEN attack input is triggered within UI range
- THEN the client fires `AttackFaunaEvent` with the model's `FaunaId` attribute
