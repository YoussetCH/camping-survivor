# Design — Slice 02b: Localization

## Types

- `Shared/Types/Locale.luau` — `LocaleCode = "en" | "es"`
- `PlayerProfile.settings.locale: LocaleCode` (typed via `PlayerSettings`)

## Shared modules

| Module | Role |
|--------|------|
| `LocaleRegistry.luau` | Default `en`, whitelist, validation |
| `Locales/en.luau` | English strings |
| `Locales/es.luau` | Spanish strings |
| `Localization.luau` | `get`, `format`, `getLocale`, `applyLocale`, `LocaleChanged` signal |

## Remotes

| Event | Direction | Payload |
|-------|-----------|---------|
| `SetLocaleEvent` | C→S | `locale: string` |
| `LocaleChangedEvent` | S→C | `locale: string` |

## Services

### `LocalizationService`

- Validates locale whitelist on `SetLocaleEvent`
- Saves to `profile.settings.locale`
- Fires `LocaleChangedEvent` to requesting client

## Controllers

### `LocalizationController`

- Top-right EN / ES toggle (DisplayOrder 110)
- On `PlayerDataLoadedEvent`: `Localization.applyLocale(profile.settings.locale)`
- On `LocaleChangedEvent`: apply + refresh UI
- On button click: `SetLocaleEvent:FireServer(locale)`

### `SurvivalHUDController` (modified)

- Bar labels and alert text via `Localization.get(key)`
- Subscribes to `Localization.LocaleChanged`

## Items

- `ItemDefinition.displayName` → `nameKey` (e.g. `item.stick.name`)
- Display resolved client-side via `Localization.get(item.nameKey)`

## Security

- Server whitelists locale codes; client cannot set arbitrary strings in profile
