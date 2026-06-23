# Verify — Slice 06: World

## Automated / code

- [x] All new files have `--!strict`
- [x] Remotes registered in `Remotes.luau` and exist under `ReplicatedStorage.Remotes.Events`
- [x] Harvest flow is server-authoritative (client sends nodeId only)
- [x] Server validates distance, depleted state, tool, bag capacity, per-player cooldown
- [x] No client-side inventory mutation on harvest
- [x] `rojo build` succeeds
- [x] `openspec validate slice-06-world` passes

## Studio manual (Rojo serve)

1. [x] Play — dev world loads with biome zones and resource nodes visible in Explorer
2. [x] Walk from camp plots into `forest_near` — survival temperature drifts toward forest ambient (observe over ~1 min)
3. [x] Wait for or observe day/night transition — HUD phase indicator updates; sky/lighting changes
4. [x] Approach a berry/gather node — proximity prompt appears (localized)
5. [x] Harvest node — items appear in bag; node shows depleted state
6. [x] Second player or re-approach before respawn — harvest rejected (depleted)
7. [x] Wait ~3 min — node respawns and is harvestable again
8. [x] Approach chop node without axe — error toast, no grant
9. [x] Equip `stone_axe`, harvest chop node — wood/stick granted
10. [x] Fill bag completely, attempt harvest — `bag_full` error, node not depleted
11. [x] Harvest from >12 studs (exploit attempt) — rejected server-side

## Regression

- [x] Camp: plot assign, build mode, chest, craft table, camp level 1 still work
- [x] Survival HUD, inventory (`I`), crafting (`C`), localization panel still work
- [x] Client bootstrap completes without remote errors
- [x] Studio dev grant still provides starter items

## Done criteria

All checkboxes checked. `tasks.md` is 100% `[x]` except archive step. User approval required before archive.
