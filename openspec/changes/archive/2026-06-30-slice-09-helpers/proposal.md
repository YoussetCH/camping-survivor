# Proposal — Slice 09: Helpers

## Why

Quests (slice-08) and fauna (slice-07) give players goals and danger, but camp automation and emotional stakes from GDD §2.13 are missing — no recruitable companions, no hunger/care loop, and `main_05_lumberjack` was explicitly deferred. Helpers are prerequisites for raid injury (slice-12), clan plots (slice-11), and mid-game biomes (slice-10) that reference specialized workers.

## What Changes

- Add **`HelperService`** — server-authoritative helper lifecycle: recruit, hunger/health tick, status effects, permanent death, task execution, and profile persistence in `helpers`.
- Add **`HelperBehaviorRegistry`** and **Lumberjack** feature module (`Shared/Features/Lumberjack/`, `LumberjackBehavior.luau`) with readable NPC model and wood-gather task on plot radius.
- Extend **profile** — `helpers: { [instanceId]: HelperState }`, `lostHelpers: { string }` memorial log; max **2** active helpers per solo player.
- Add quest **`main_05_lumberjack`** — escort lumberjack NPC from `forest_deep` to assigned plot; reward recruits first Lumberjack helper (integrates with existing `QuestService`).
- Add **recruitment POI** — dev `HelperSpawn` marker for lumberjack in `forest_deep`; server spawns escort NPC until recruited.
- Remotes: `HelperUpdatedEvent` (S→C sync), `FeedHelperEvent`, `CureHelperEvent`, `SetHelperModeEvent` (work / shelter — client sends `helperInstanceId` + mode id only).
- Add **`HelperController`** + **`HelperPanel`** UI — list helpers with hunger/health bars, status icons, feed/cure actions, mode toggle; toasts on death and low hunger.
- **Helper survival rules** (GDD §3.8 v0.1): hunger drain −3/min while working; feed +40/+60; `weak` at 0 hunger stops work; permanent death at HP ≤ 0 or 20 min in `weak`; status cures via same items as player (`bandage`, `antidote`).
- Localization keys for helper names, panel, alerts, and death toast (`helper.*` in `en` / `es`).

## Out of scope

- **Cook, Herbalist, Guardian, Miner, Fisher** helper types — constants stubs only; no spawn
- **Clan helpers** (max 4, shared plot) — slice-11
- **Raid / storm damage** to helpers — slice-12 / slice-10 weather
- **Auto-feed from chest** toggle — UI stub only; manual feed in v0.1
- **Guardian raid damage reduction** — slice-12
- **Replace quests** (`side_replace_*`, 24 h cooldown) — slice-10+
- **Full POI authoring** (ermitaño, torre, naufragio) — slice-10
- **Helper combat** — helpers do not attack fauna
- **Monetization healing boost** on helpers — slice-13
- **AssignHelperEvent / LinkChestEvent** full camp UI — deferred; `SetHelperModeEvent` covers work/shelter v0.1

## Capabilities

### New Capabilities

_(none — helpers spec exists as stub; filled via delta)_

### Modified Capabilities

- **helpers**: ADDED full requirements — `HelperService`, Lumberjack module, survival subset, recruitment, sync, UI.
- **foundation**: MODIFIED profile schema (`helpers`, `lostHelpers`); ADDED helper remotes registry.
- **quests**: ADDED `main_05_lumberjack` escort quest and `escort_to_plot` objective kind.
- **feature-modules**: ADDED `HelperBehaviorRegistry` and helper feature-module folder convention.
- **ui**: ADDED helper panel HUD and passive feed/cure/mode intent remotes.

## Impact

| Area | Change |
|------|--------|
| New service | `HelperService` |
| New registry | `HelperBehaviorRegistry`, `HelperBootstrap` |
| Feature module | `Lumberjack/` (Definition, Model, Behavior) |
| Types | `Shared/Types/Helper.luau` |
| Constants | `Shared/Constants/Helpers.luau`, `HelperConstants.luau` |
| `QuestService` | New objective kind `escort_to_plot`; quest `main_05_lumberjack` |
| `Quests.luau` | Add main_05 definition + chain from `main_01_chest` |
| `PlayerSyncService` | `syncHelpersToClient` |
| Remotes | `HelperUpdatedEvent`, `FeedHelperEvent`, `CureHelperEvent`, `SetHelperModeEvent` |
| Controllers | `HelperController` |
| UI | `Shared/UI/Components/HelperPanel` |
| World | `HelperSpawn` tag + lumberjack marker in `forest_deep` |
| Localization | `helper.*` keys in `en` / `es` |
| Profile | `helpers`, `lostHelpers` |

## Success

Player completes `main_01_chest` → `main_05_lumberjack` unlocks → finds lumberjack in `forest_deep` → escorts to plot → helper joins roster → Lumberjack gathers wood periodically when fed and in work mode → player feeds via panel when hunger low → bandage cures bleeding → helper death removes from profile and shows memorial toast → max 2 helpers enforced. Quests, camp, fauna, and survival still work.
