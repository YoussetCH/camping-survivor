# Tasks — Slice 09: Helpers

## 1. Types & constants

- [x] 1.1 Create `Shared/Types/Helper.luau` (`HelperState`, `HelperSnapshot`, modes)
- [x] 1.2 Add `helpers` and `lostHelpers` to `PlayerProfile` / template with reconcile
- [x] 1.3 Create `Shared/Constants/HelperConstants.luau` (max helpers, tick rates, weak death threshold)
- [x] 1.4 Create `Shared/Constants/Helpers.luau` (lumberjack type definition + stubs for future types)
- [x] 1.5 Add `helper.*` and `quest.main_05_lumberjack.*` keys in `en.luau` / `es.luau`

## 2. Lumberjack feature module

- [x] 2.1 Create `Shared/Features/Lumberjack/` (Definition, Model — readable NPC silhouette)
- [x] 2.2 Create `HelperBehaviorRegistry.luau` and `LumberjackBehavior.luau`
- [x] 2.3 Create `HelperBootstrap.luau` and wire in server bootstrap before `HelperService`

## 3. Remotes

- [x] 3.1 Register `HelperUpdatedEvent`, `FeedHelperEvent`, `CureHelperEvent`, `SetHelperModeEvent` in `Remotes.luau`
- [x] 3.2 Add Rojo RemoteEvent instances under `Remotes/Events/`

## 4. Server — HelperService

- [x] 4.1 Create `HelperService.luau` (recruit, tick, feed, cure, mode, death)
- [x] 4.2 Implement lumberjack work tick via registry
- [x] 4.3 Implement escort NPC spawn/follow for `main_05_lumberjack`
- [x] 4.4 Handle feed/cure/mode remotes with validation
- [x] 4.5 Register `HelperService` in `ServerKernel` init order

## 5. Quest integration

- [x] 5.1 Add `main_05_lumberjack` to `Quests.luau`; chain from `main_01_chest`
- [x] 5.2 Add `escort_to_plot` objective kind in `QuestService`
- [x] 5.3 On escort complete, recruit lumberjack via `HelperService`

## 6. Sync & world

- [x] 6.1 Add `PlayerSyncService.syncHelpersToClient` and include in initial sync
- [x] 6.2 Add `HelperSpawn` markers + `forest_deep` lumberjack spawn in dev world
- [x] 6.3 Spawn helper world models on plot when recruited

## 7. Client — UI & controller

- [x] 7.1 Create `Shared/UI/Components/HelperPanel.luau`
- [x] 7.2 Create `HelperController.luau` (panel `H` key, toasts, remotes)
- [x] 7.3 Register `HelperController` in client bootstrap

## 8. Specs & archive prep

- [x] 8.1 Run `verify.md` checklist in Studio
- [x] 8.2 Run `openspec validate slice-09-helpers`
- [x] 8.3 Update `docs/Implementation-Plan.md` active slice entry
- [x] 8.4 Update `openspec/config.yaml` `workflow.active_change: slice-09-helpers`
- [x] 8.5 Archive with `openspec archive slice-09-helpers` (after user approval)
