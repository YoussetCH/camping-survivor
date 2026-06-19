# Localization — Technical Spec

**Status:** Implemented (slice-02b)  
**GDD:** §1.11, §10.22  
**Services:** LocalizationService  
**Controllers:** LocalizationController

## Purpose

Multilingual player-facing text: **English (default)** and **Spanish** at launch, extensible to additional locales without refactoring UI or constants architecture.

## Requirements

### Requirement: Supported locales v1.0

The system SHALL support locale codes `en` (default) and `es`.

#### Scenario: New player without saved preference

- GIVEN a player joins for the first time
- WHEN profile is reconciled
- THEN `settings.locale` is `"en"`

### Requirement: Locale persistence

The system SHALL store the player's language preference in `PlayerProfile.settings.locale`.

#### Scenario: Player changes language

- GIVEN a player selects Spanish in settings
- WHEN the server validates and saves the preference
- THEN `settings.locale` is `"es"`
- AND the choice persists across sessions

### Requirement: Translation lookup

The client SHALL resolve visible strings via `Localization.get(key)` using the active locale with fallback to `en`.

#### Scenario: Missing translation in Spanish

- GIVEN active locale is `es`
- AND key `ui.new_feature` exists only in `en`
- WHEN `Localization.get("ui.new_feature")` is called
- THEN the English string is returned

### Requirement: No hardcoded player-facing strings

Controllers and UI modules SHALL NOT contain final player-visible copy; they use localization keys.

#### Scenario: HUD label

- GIVEN `SurvivalHUDController` renders hunger label
- WHEN the HUD is built or refreshed
- THEN text comes from `Localization.get("ui.hud.hunger")`

### Requirement: Extensible locale registry

Adding a new language SHALL require only a new locale table module and registry entry — no changes to controller logic.

#### Scenario: Add Portuguese

- GIVEN `Locales/pt.luau` is added and registered
- WHEN `settings.locale` is set to `"pt"`
- THEN UI resolves strings from the Portuguese table with `en` fallback

### Requirement: Server locale validation

The server SHALL whitelist locale values on change requests (`en`, `es` in v1.0).

#### Scenario: Invalid locale from client

- GIVEN client sends locale `"xx"`
- WHEN server validates
- THEN the request is rejected and preference unchanged

### Requirement: Localization module

The system SHALL provide `Shared/Localization/Localization.luau` with `get`, `format`, `getLocale`, `applyLocale`, and a client `LocaleChanged` signal.

#### Scenario: English default lookup

- GIVEN active locale is `en`
- WHEN `Localization.get("ui.hud.hunger")` is called
- THEN `"Food"` is returned

### Requirement: Locale remotes

The system SHALL expose `SetLocaleEvent` (C→S) and `LocaleChangedEvent` (S→C).

#### Scenario: Change to Spanish

- GIVEN a player selects `es` in the language panel
- WHEN the server validates the request
- THEN `settings.locale` becomes `"es"`
- AND the client receives `LocaleChangedEvent`

## Architecture

```
Shared/Localization/
  Localization.luau
  LocaleRegistry.luau
  Locales/en.luau
  Locales/es.luau

Services/LocalizationService.luau
Controllers/LocalizationController.luau
```

## Related

- `src/ReplicatedStorage/Shared/Types/PlayerSettings.luau`
- `src/ReplicatedStorage/Shared/Constants/Items.luau` (`nameKey`)
- `src/StarterPlayer/StarterPlayerScripts/Controllers/SurvivalHUDController.luau`
