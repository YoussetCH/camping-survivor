# Verify — Slice 04: Crafting

## Automated / code

- [x] All new files have `--!strict`
- [x] Remotes registered in `Remotes.luau` and exist under `ReplicatedStorage.Remotes.Events`
- [x] No client-side craft mutation (controller fires remotes only)
- [x] Server validates recipeId, unlock, station, inputs, output space, cooldown
- [x] Client sends recipeId only — never item quantities
- [x] `rojo build` succeeds
- [x] `openspec validate slice-04-crafting` passes

## Studio manual (Rojo serve)

1. [x] Play — press `C` — crafting panel opens/closes
2. [x] Tutorial recipes listed (sparks, tinder, bandage, campfire)
3. [x] Craft sparks with flint + stick — sparks appear in bag
4. [x] Craft bandage with leaf + fiber — bandages granted
5. [x] Craft without inputs — error toast, inventory unchanged
6. [x] Rapid double-craft — second attempt blocked (cooldown)
7. [x] Switch locale — crafting UI strings update (EN ↔ ES)
8. [x] Rejoin — unlocked recipes persist and panel still works

## Regression

- [x] Survival HUD, inventory HUD (`I`), language panel still work
- [x] Client bootstrap complete without remote errors
- [x] Studio dev grant still provides starter items

## Done criteria

All checkboxes checked. `tasks.md` is 100% `[x]` except archive step. Verified by user 2026-06-19.
