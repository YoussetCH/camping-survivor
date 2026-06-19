# UI — Technical Spec

**Status:** Stub (slice-02+)  
**GDD:** Cap. 10  
**Layer:** Controllers + passive ScreenGui

## Purpose

HUD, menus, toasts, mobile-first layouts. UI sends intent only; never mutates authoritative data.

All player-visible copy uses **localization keys** (GDD §1.11, §10.22). See [localization/spec.md](../localization/spec.md).

## Requirements

_To be defined incrementally per slice (survival HUD in slice-02, etc.)._

## Localization

- Default locale: `en`
- HUD labels, alerts, and menus resolve via `Localization.get(key)`
- Controllers refresh on `LocaleChanged` when settings change
