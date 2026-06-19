# Proposal — Slice 02: Survival Core

## Why

Foundation (slice-01) provides profile fields and sync events, but stats are static. Cap. 3 requires authoritative server ticks, visible HUD bars, alert thresholds, and soft death with inventory penalty.

## What changes

- `SurvivalService` — 6 s server tick: hunger/thirst drain, temperature drift, HP damage/regen
- `SurvivalConstants` — GDD v0.1 rates and UI thresholds
- `SurvivalHUDController` + reusable `StatBar` component
- Death handler: respawn stats, 35% inventory loss (skipped during tutorial), sync events
- Merge survival spec delta into `openspec/specs/survival/`

## Out of scope

- Status effects (`bleeding`, `poison`, etc.) — slice-07
- Food/water consumption — slice-03/04
- Biome/day-night ambient temperature — slice-06 (placeholder ambient 45)
- Camp/fire temperature override — slice-05
- Running/combat drain modifiers
- NotificationController toasts — minimal inline HUD alerts only

## Success

In Studio: bars drain over time; regen when stats healthy; death at 0 HP applies penalty and respawn; HUD shows warning/danger colors per GDD thresholds.
