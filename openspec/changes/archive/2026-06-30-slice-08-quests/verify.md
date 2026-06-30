# Verify — Slice 08: Quests

## Automated / code

- [x] All new files have `--!strict`
- [x] `QuestTrackEvent` and `QuestUiOpenedEvent` registered in `Remotes.luau` and exist under `ReplicatedStorage.Remotes.Events`
- [x] Quest progress is server-authoritative (client sends questId / panelId only)
- [x] No quest-specific branches in `CampService`, `CraftingService`, `ResourceService`, `AnimalService` (use `GameEvents` only)
- [x] All quest player-visible strings use localization keys
- [x] `rojo build` succeeds
- [x] `openspec validate slice-08-quests` passes

## Studio manual (Rojo serve)

1. [x] New player joins — quest tracker shows `t01_spawn` or advances to `t02_gather` automatically
2. [x] Gather 3 sticks + 2 stones — `t02_gather` completes; toast appears; XP increases
3. [x] Craft sparks → tinder → place campfire — tutorial steps advance sequentially
4. [x] `t06_cold` — temperature dip occurs; staying near fire completes objective
5. [x] Craft 2 bandages, place craft table — `tutorialCompleted` becomes true; tutorial protection ends
6. [x] `m00_wood` activates — gather 10 wood completes quest; Brasas reward visible in profile sync
7. [x] `main_01_chest` — place chest completes; rewards granted
8. [x] Open journal (`J`) — active and completed quests listed with localized text
9. [x] Track a side quest from journal — tracker updates to selected quest
10. [x] `side_02_wolf` — kill 3 wolves increments progress (fauna from slice-07)
11. [x] During tutorial — player cannot die to fauna; wolves near plot do not attack
12. [x] Switch locale EN → ES — tracker and journal text update

## Regression

- [x] Survival HUD, inventory (`I`), crafting (`C`), camp build mode, chest still work
- [x] World harvest, day/night, fauna combat (post-tutorial) still work
- [x] Localization settings panel still works
- [x] Client bootstrap completes without remote errors

## Done criteria

All checkboxes checked. `tasks.md` is 100% `[x]` except archive step. User approval required before archive.
