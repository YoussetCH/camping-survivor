# Verify — Slice 03: Inventory

## Automated / code

- [x] All new files have `--!strict`
- [x] Remotes registered in `Remotes.luau` and exist under `ReplicatedStorage.Remotes.Events`
- [x] No client-side inventory mutation (controllers fire remotes only)
- [x] Server validates slot keys, indices, item ids, and categories
- [x] `rojo build` succeeds
- [x] `openspec validate slice-03-inventory` passes

## Studio manual (Rojo serve)

1. [x] Play — hotbar visible (6 slots) bottom-center
2. [x] Starter items appear after join (sticks, flint, bandage, stone axe from dev grant)
3. [x] Press `I` — 16-slot inventory grid opens/closes (X, Escape, I toggle)
4. [x] Assign item to hotbar — persists in sync after re-open panel
5. [x] Equip a tool (stone axe) — equipped state syncs
6. [x] Use bandage — quantity decreases, health increases
7. [x] Stack display correct when granting duplicate items
8. [x] Switch locale — inventory UI strings update (EN ↔ ES)
9. [x] Death with tutorial complete — bag penalty still works; hotbar refs cleaned

## Regression

- [x] Survival HUD and language panel still work
- [x] `Client bootstrap complete` in Output without remote errors
- [x] Profile persists inventory/hotbar/locale on rejoin (Studio API Services enabled)

## Done criteria

All checkboxes checked. `tasks.md` is 100% `[x]` except archive step. Verified by user 2026-06-19.
