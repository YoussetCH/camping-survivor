# Verify — Slice 02: Survival Core

## Automated / code

- [x] All new files have `--!strict`
- [x] `SurvivalService` uses 6 s tick without `while true`
- [x] No client-side stat calculation
- [x] No linter errors on edited files
- [x] `rojo build` succeeds

## Studio manual (Rojo serve)

1. [x] Play solo — survival HUD visible (4 bars)
2. [x] Wait ~1 min — hunger/thirst bars decrease
3. [x] Set hunger/thirst low via debug or wait — HP bar decreases when critical
4. [x] Force death (wait or debug) — respawn with 60/60/100/50 stats
5. [x] With tutorial incomplete — inventory unchanged on death
6. [x] Alert colors: hunger ≤40 yellow, ≤20 red

## Regression

- [x] `PlayerDataLoadedEvent` and foundation sync still work
- [x] Profile persists survival stats on rejoin

## Done criteria

All checkboxes checked. `tasks.md` is 100% `[x]`.
