# Tasks — Slice 02b: Localization

## Shared

- [x] Create `Shared/Types/Locale.luau`, `PlayerSettings.luau`
- [x] Create `Shared/Localization/LocaleRegistry.luau`
- [x] Create `Shared/Localization/Localization.luau`
- [x] Create `Shared/Localization/Locales/en.luau`, `es.luau`
- [x] Extend `PlayerProfile` / template with `settings.locale = "en"`
- [x] Register `SetLocaleEvent`, `LocaleChangedEvent`

## Server

- [x] Create `Services/LocalizationService.luau`
- [x] Normalize settings locale in `PlayerDataService`

## Client

- [x] Create `Controllers/LocalizationController.luau`
- [x] Migrate `SurvivalHUDController` to localization keys
- [x] Migrate `SurvivalConstants` alerts to keys
- [x] Migrate `Items` / `Recipes` to `nameKey`
- [x] Add `StatBar.setLabel`

## Specs & docs

- [x] Merge delta into `openspec/specs/localization/spec.md`
- [x] Merge foundation locale requirement (implemented)
- [x] Archive change

## Verification

- [x] Run `verify.md` checklist
