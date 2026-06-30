# Proposal — Slice 08: Quests

## Why

Fauna (slice-07) and camp (slice-05) give players systems to master, but nothing ties them into a guided progression arc — new players lack the tutorial chain from GDD §2.5/§8.4, veterans have no mission tracker, and XP/level remain inert on the profile. GDD Cap. 8 requires `QuestService`, tutorial gates, and a journal before helpers (slice-09) and raids (slice-12) can reference escort, recruitment, and unlock missions.

## What Changes

- Add **`QuestService`** — server-authoritative quest lifecycle: auto-start tutorial chain, objective validation via `GameEvents` hooks, completion rewards (XP, Brasas, items), and profile persistence in `quests`.
- Add **`Quests.luau`** constants — tutorial steps `t01_spawn`–`t08_complete`, bridge `m00_wood`, early main `main_01_chest`, and two side quests `side_01_berries` / `side_02_wolf` with typed objective kinds (`gather`, `craft`, `place_structure`, `survive_cold`, `defeat_fauna`).
- Extend **`GameEvents`** — `ItemHarvested`, `ItemCrafted`, `StructurePlaced`, `FaunaDefeated`, `BiomeEntered` bindables for quest progress without coupling orchestrators.
- Implement **XP and level-up** — grant XP on quest completion; level curve per GDD §8.3 table (levels 1–5 in v0.1); sync via extended `QuestProgressEvent` snapshot.
- Add **`QuestTrackEvent`** remote — client sends `questId` only; server validates ownership and active state.
- Add **`QuestController`** — caches `QuestProgressEvent`, drives HUD tracker and journal panel.
- Add **UI components** — `QuestTracker` (always-visible active quest, collapsible on mobile) and `QuestJournal` (toggle `J` key: active / completed lists).
- **Tutorial rules** — invulnerability and fauna suppression within 80 studs of assigned plot during `tutorial_main`; guided overlay prompts per step.
- Localization keys for all quest titles, objectives, rewards, tracker, and journal copy (`quest.*` in `en` / `es`).

## Out of scope

- **main_02+** hermit chain, POI interactions, NPC `DialogueController` — slice-09/10
- **Helper recruitment / replace quests** (`main_05_lumberjack`, `replace_*`) — slice-09
- **Daily missions** (`daily_*`) pool, UTC reset, reroll — slice-10+ (constants stub only)
- **Clan weekly quests** (`clan_*`) — slice-11
- **Environmental missions** (`env_*`) tied to POI discovery — slice-10
- **Achievements** (`ach_*`) and discovery journal (recipes/biomes sections) — slice-14
- **Raid unlock gate** (`main_12_fortify`) — slice-12
- **Trade / raid side quests** (`side_04_trade`, `side_05_raid`) — slice-11/12
- **Full main chain** `main_03`–`main_18` — content added incrementally post-v0.1
- **Brasas from dailies** economy tuning — slice-13

## Capabilities

### New Capabilities

_(none — quests spec exists as stub; filled via delta)_

### Modified Capabilities

- **quests**: ADDED full requirements — `QuestService`, objective types, tutorial chain, early main/side quests, XP rewards, persistence, sync.
- **foundation**: MODIFIED profile quest fields (`quests` typed progress, `missionsCompleted`), ADDED `QuestTrackEvent` remote, extended `QuestSnapshot` payload (active quests, tracked id, level/xp).
- **ui**: ADDED quest tracker HUD and quest journal panel; passive intent via `QuestTrackEvent` only.

## Impact

| Area | Change |
|------|--------|
| New service | `QuestService` |
| New constants | `Shared/Constants/Quests.luau` |
| Types | Extend `Shared/Types/Quest.luau` |
| `GameEvents` | New bindables for harvest/craft/place/fauna/biome |
| `PlayerSyncService` | Richer `QuestProgressEvent` snapshot |
| `ResourceService`, `CraftingService`, `CampService`, `AnimalService`, `BiomeService` | Fire `GameEvents` on success (no quest logic inline) |
| `SurvivalService` | Tutorial invulnerability + fauna-safe radius hook |
| Remotes | `QuestTrackEvent` (client→server) |
| Controllers | `QuestController`; register in client bootstrap |
| UI | `Shared/UI/Components/QuestTracker`, `QuestJournal` |
| Localization | `quest.*` keys in `en` / `es` |
| Profile | `missionsCompleted: { string }` on stats |

## Success

New player joins → tutorial auto-starts at `t01_spawn` → guided gather/craft/place campfire steps advance objectives → `t08_complete` sets `tutorialCompleted` → `m00_wood` and `main_01_chest` unlock sequentially → completing quests grants XP and visible level-up → side quest `side_02_wolf` increments on wolf kills from slice-07 → journal (`J`) lists active/completed quests → tracker shows current objective text in player's locale. Prior slices (survival, inventory, camp, world, fauna) still work.
