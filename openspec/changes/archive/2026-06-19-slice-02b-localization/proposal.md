# Proposal — Slice 02b: Localization

## Why

GDD v1.2 requires English (default) + Spanish with extensible i18n. HUD and constants still hardcode Spanish strings.

## What changes

- `Shared/Localization/` — `Localization`, `LocaleRegistry`, `Locales/en`, `Locales/es`
- `PlayerProfile.settings.locale` (default `"en"`)
- `LocalizationService` + `SetLocaleEvent` / `LocaleChangedEvent`
- `LocalizationController` — language selector UI
- Migrate `SurvivalHUDController`, `SurvivalConstants` alerts, `Items` name keys

## Out of scope

- Full settings menu, quest/dialogue strings (keys seeded only where needed)
- Roblox auto-translate API
- Additional locales beyond `en` / `es`

## Success

Player sees HUD in English by default; can switch to Spanish; preference persists; alerts and bar labels update instantly.
