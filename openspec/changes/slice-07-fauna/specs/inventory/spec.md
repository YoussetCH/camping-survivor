## MODIFIED Requirements

### Requirement: Item use intent

The client SHALL fire `UseItemEvent` with bag slot key only. The server SHALL validate ownership and apply item effects authoritatively.

#### Scenario: Bandage cures bleeding

- GIVEN the player has `bandage` in bag slot `bag_1` and active `bleeding`
- WHEN the client fires `UseItemEvent` with `bag_1`
- THEN `bleeding` is removed from status effects
- AND health increases by 10 (clamped 0–100)
- AND one bandage is consumed
- AND `SurvivalUpdatedEvent` fires

#### Scenario: Bandage without bleeding

- GIVEN the player has `bandage` and no `bleeding`
- WHEN the client fires `UseItemEvent`
- THEN health increases by 10 only
- AND one bandage is consumed

## ADDED Requirements

### Requirement: Antidote item and poison cure

The system SHALL define item `antidote` in `Items.luau` with localization keys. Using antidote MUST remove `poison` from status effects and consume one antidote.

#### Scenario: Antidote cures poison

- GIVEN the player has `antidote` in bag and active `poison`
- WHEN the client fires `UseItemEvent` for the antidote slot
- THEN `poison` is removed
- AND one antidote is consumed
- AND `SurvivalUpdatedEvent` fires

### Requirement: Herb common item for snake drops

The system SHALL define item `herb_common` in `Items.luau` with localization keys for snake drop grants.

#### Scenario: Snake drop grant

- GIVEN a snake dies and drop roll succeeds
- WHEN `InventoryService` grants loot
- THEN `herb_common` is added to player bag if capacity allows
