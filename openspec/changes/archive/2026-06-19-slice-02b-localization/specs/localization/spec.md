## ADDED Requirements

### Requirement: Localization module

The system SHALL provide `Shared/Localization/Localization.luau` with `get`, `format`, `getLocale`, `applyLocale`, and a client `LocaleChanged` signal.

#### Scenario: English default lookup

- GIVEN active locale is `en`
- WHEN `Localization.get("ui.hud.hunger")` is called
- THEN `"Food"` is returned

### Requirement: Locale persistence and remotes

The system SHALL persist `settings.locale` and expose `SetLocaleEvent` (C→S) and `LocaleChangedEvent` (S→C).

#### Scenario: Change to Spanish

- GIVEN a player selects `es` in the language panel
- WHEN the server validates the request
- THEN `settings.locale` becomes `"es"`
- AND the client receives `LocaleChangedEvent`

### Requirement: HUD and constants migration

Survival HUD labels and alert messages SHALL use localization keys, not hardcoded strings.

#### Scenario: Switch language on HUD

- GIVEN the HUD is visible in English
- WHEN the player switches to Spanish
- THEN hunger label shows `"Comida"`
