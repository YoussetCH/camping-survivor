# Verify — Slice 07: Fauna

## Automated / code

- [ ] All new files have `--!strict`
- [ ] Remotes registered in `Remotes.luau` and exist under `ReplicatedStorage.Remotes.Events`
- [ ] Fauna combat is server-authoritative (client sends faunaId only)
- [ ] Server validates distance, tool equipped, attack cooldown for player hits
- [ ] Fauna AI and damage run server-side only
- [ ] No species-specific branches in `AnimalService` (uses `FaunaRegistry`)
- [ ] Wolf and snake models are readable silhouettes (not single placeholder cubes)
- [ ] `rojo build` succeeds
- [ ] `openspec validate slice-07-fauna` passes

## Studio manual (Rojo serve)

1. [ ] Play — wolves and snakes spawn in `forest_near` (visible in Explorer under `World/Fauna/`)
2. [ ] Daytime — wolf detects player but does not chase aggressively
3. [ ] Night/dusk — wolf chases and attacks; player loses HP
4. [ ] Wolf bite — observe `bleeding` icon on survival HUD (may need multiple hits due to 60% chance)
5. [ ] Use bandage — bleeding icon clears; HP increases slightly
6. [ ] Equip `stone_axe`, click/attack wolf — wolf HP bar decreases; wolf dies after enough hits
7. [ ] Wolf death — `fiber` may appear in bag (50% roll)
8. [ ] Snake ambush — snake reveals and applies `poison`; HP drains over time
9. [ ] Use antidote — poison icon clears
10. [ ] Attack from >10 studs — no damage (server rejects)
11. [ ] Attack without tool — no damage
12. [ ] Player death from fauna — respawn clears all status effects

## Regression

- [ ] World: harvest nodes, day/night HUD, biome temperature still work
- [ ] Camp: plot assign, build mode, chest, craft table still work
- [ ] Survival HUD, inventory (`I`), crafting (`C`), localization panel still work
- [ ] Client bootstrap completes without remote errors
- [ ] Studio dev grant still provides starter items (+ antidote)

## Done criteria

All checkboxes checked. `tasks.md` is 100% `[x]` except archive step. User approval required before archive.
