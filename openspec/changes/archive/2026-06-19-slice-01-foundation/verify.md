# Verify — Slice 01: Foundation

## Automated / code

- [x] All new files have `--!strict`
- [x] `Remotes.luau` lists all sync event names
- [x] `PlayerProfileTemplate` matches `PlayerProfile` shape for ProfileStore reconcile
- [x] No linter errors on edited files

## Studio manual (Rojo serve)

1. [x] Run `rojo serve` and connect Studio
2. [x] Play solo — no errors in Output on join
3. [x] Output shows `PlayerDataService` profile loaded
4. [x] Output shows `ClientSyncController` received survival/inventory/camp/quest sync (debug logs)
5. [x] Rejoin same player — profile persists extended fields (check via print or Data tab if Studio API enabled)

## Regression

- [x] Existing `PlayerDataLoadedEvent` still fires with full profile
- [x] `UIController` still receives profile without error

## Done criteria

All checkboxes above are checked. `tasks.md` is 100% `[x]`.
