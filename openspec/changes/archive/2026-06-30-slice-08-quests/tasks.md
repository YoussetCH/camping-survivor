# Tasks — Slice 08: Quests

## 1. Types & constants

- [x] 1.1 Extend `Shared/Types/Quest.luau` (`QuestState`, `QuestObjectiveProgress`, extended `QuestSnapshot`)
- [x] 1.2 Add `missionsCompleted: { string }` to `PlayerProfile` / `PlayerProfileTemplate` with reconcile
- [x] 1.3 Create `Shared/Constants/Quests.luau` (tutorial t01–t08, m00_wood, main_01, side_01, side_02 definitions)
- [x] 1.4 Add `quest.*` localization keys in `en.luau` and `es.luau`

## 2. GameEvents & service hooks

- [x] 2.1 Extend `GameEvents.luau` with `ItemHarvested`, `ItemCrafted`, `StructurePlaced`, `FaunaDefeated`, `BiomeEntered` bindables + fire helpers
- [x] 2.2 Fire `ItemHarvested` from `ResourceService` on successful harvest
- [x] 2.3 Fire `ItemCrafted` from `CraftingService` on successful craft
- [x] 2.4 Fire `StructurePlaced` from `CampService` on successful place
- [x] 2.5 Fire `FaunaDefeated` from `AnimalService` on fauna death (killer player)
- [x] 2.6 Fire `BiomeEntered` from `BiomeService` on biome change (if not already; add minimal hook)

## 3. Remotes

- [x] 3.1 Register `QuestTrackEvent`, `QuestUiOpenedEvent` in `Remotes.luau`
- [x] 3.2 Add Rojo RemoteEvent instances under `Remotes/Events/`

## 4. Server — QuestService

- [x] 4.1 Create `QuestService.luau` (start/complete, objective handlers, prerequisites, concurrency limits)
- [x] 4.2 Subscribe to all `GameEvents` quest hooks in `QuestService:Start()`
- [x] 4.3 Implement XP grant and level-up (levels 1–5 table)
- [x] 4.4 Implement reward grant (currency, items via `InventoryService`)
- [x] 4.5 Implement retroactive objective check on profile load
- [x] 4.6 Handle `QuestTrackEvent` and `QuestUiOpenedEvent` remotes
- [x] 4.7 Register `QuestService` in `ServerKernel` after dependencies

## 5. Server — sync & tutorial protection

- [x] 5.1 Add `PlayerSyncService.syncQuestToClient` with extended snapshot
- [x] 5.2 Tutorial invulnerability gate in `SurvivalService.applyDamage`
- [x] 5.3 Fauna safe-zone gate in `AnimalService` (80 studs from plot during tutorial)
- [x] 5.4 Scripted cold dip for `t06_cold` objective in `SurvivalService` or `QuestService`

## 6. Client — UI & controller

- [x] 6.1 Create `Shared/UI/Components/QuestTracker.luau`
- [x] 6.2 Create `Shared/UI/Components/QuestJournal.luau`
- [x] 6.3 Create lightweight `TutorialOverlay` hints (banner per active tutorial step)
- [x] 6.4 Create `QuestController.luau` (cache snapshot, tracker, journal `J` key, toasts)
- [x] 6.5 Register `QuestController` in client bootstrap

## 7. Specs & archive prep

- [x] 7.1 Run `verify.md` checklist in Studio
- [x] 7.2 Run `openspec validate slice-08-quests`
- [x] 7.3 Update `docs/Implementation-Plan.md` active slice entry
- [x] 7.4 Update `openspec/config.yaml` `workflow.active_change: slice-08-quests`
- [x] 7.5 Archive with `openspec archive slice-08-quests` (after user approval)
