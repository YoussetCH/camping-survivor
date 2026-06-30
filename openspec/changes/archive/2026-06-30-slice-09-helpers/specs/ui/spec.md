# UI — Delta Spec (slice-09)

## ADDED Requirements

### Requirement: Helper panel

The client SHALL provide a toggleable helper panel opened via key `H` or an on-screen helper control. The panel SHALL list active helpers with localized name, hunger bar, health bar, status icons, current mode, and Feed / Cure / Work / Shelter action buttons.

#### Scenario: Toggle helper panel

- GIVEN the helper panel is closed
- WHEN the player presses `H`
- THEN the helper panel becomes visible
- WHEN pressed again
- THEN the panel hides

### Requirement: Helper UI intent only

Helper UI SHALL send player intent via `FeedHelperEvent`, `CureHelperEvent`, and `SetHelperModeEvent` with validated ids only (helper instance id, bag slot key, mode id) and SHALL NOT mutate helper stats locally.

#### Scenario: Feed from panel

- GIVEN the helper panel shows a lumberjack with low hunger
- WHEN the player selects a food item and clicks Feed
- THEN the client fires `FeedHelperEvent` with helper id and slot key only

### Requirement: Helper alert toasts

The client SHALL show toasts for helper death (`helper.death_toast`) and urgent low hunger (`helper.hunger_warning`) driven by `HelperUpdatedEvent` diffs.

#### Scenario: Death toast

- GIVEN a helper dies server-side
- WHEN the client receives updated `HelperUpdatedEvent`
- THEN a localized death toast appears with helper name

### Requirement: Helper panel localization

Helper panel labels, buttons, and toasts SHALL use localization keys and refresh on locale change.

#### Scenario: Panel locale switch

- GIVEN the helper panel is open in English
- WHEN locale switches to Spanish
- THEN action button labels display Spanish strings
