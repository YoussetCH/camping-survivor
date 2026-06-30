# Tasks — Slice 09: Helpers

## 1. Types & constants

- [ ] 1.1 Create `Shared/Types/Helper.luau` (`HelperState`, `HelperSnapshot`, modes)
- [ ] 1.2 Add `helpers` and `lostHelpers` to `PlayerProfile` / template with reconcile
- [ ] 1.3 Create `Shared/Constants/HelperConstants.luau` (max helpers, tick rates, weak death threshold)
- [ ] 1.4 Create `Shared/Constants/Helpers.luau` (lumberjack type definition + stubs for future types)
- [ ] 1.5 Add `helper.*` and `quest.main_05_lumberjack.*` keys in `en.luau` / `es.luau`

## 2. Lumberjack feature module

- [ ] 2.1 Create `Shared/Features/Lumberjack/` (Definition, Model — readable NPC silhouette)
- [ ] 2.2 Create `HelperBehaviorRegistry.luau` and `LumberjackBehavior.luau`
- [ ] 2.3 Create `HelperBootstrap.luau` and wire in server bootstrap before `HelperService`

## 3. Remotes

- [ ] 3.1 Register `HelperUpdatedEvent`, `FeedHelperEvent`, `CureHelperEvent`, `SetHelperModeEvent` in `Remotes.luau`
- [ ] 3.2 Add Rojo RemoteEvent instances under `Remotes/Events/`

## 4. Server — HelperService

- [ ] 4.1 Create `HelperService.luau` (recruit, tick, feed, cure, mode, death)
- [ ] 4.2 Implement lumberjack work tick via registry
- [ ] 4.3 Implement escort NPC spawn/follow for `main_05_lumberjack`
- [ ] 4.4 Handle feed/cure/mode remotes with validation
- [ ] 4.5 Register `HelperService` in `ServerKernel` init order

## 5. Quest integration

- [ ] 5.1 Add `main_05_lumberjack` to `Quests.luau`; chain from `main_01_chest`
- [ ] 5.2 Add `escort_to_plot` objective kind in `QuestService`
- [ ] 5.3 On escort complete, recruit lumberjack via `HelperService`

## 6. Sync & world

- [ ] 6.1 Add `PlayerSyncService.syncHelpersToClient` and include in initial sync
- [ ] 6.2 Add `HelperSpawn` markers + `forest_deep` lumberjack spawn in dev world
- [ ] 6.3 Spawn helper world models on plot when recruited

## 7. Client — UI & controller

- [ ] 7.1 Create `Shared/UI/Components/HelperPanel.luau`
- [ ] 7.2 Create `HelperController.luau` (panel `H` key, toasts, remotes)
- [ ] 7.3 Register `HelperController` in client bootstrap

## 8. Specs & archive prep

- [ ] 8.1 Run `verify.md` checklist in Studio
- [ ] 8.2 Run `openspec validate slice-09-helpers`
- [ ] 8.3 Update `docs/Implementation-Plan.md` active slice entry
- [ ] 8.4 Update `openspec/config.yaml` `workflow.active_change: slice-09-helpers`
- [ ] 8.5 Archive with `openspec archive slice-09-helpers` (after user approval)
