# Design — Slice 08: Quests

## Context

- Foundation (slice-01) registers `QuestProgressEvent` and syncs stub `quests` map + `tutorialCompleted` via `PlayerSyncService`.
- `Shared/Types/Quest.luau` defines minimal `QuestSnapshot`; no `QuestService` or `Quests.luau` yet.
- Camp, crafting, inventory, world harvest, fauna combat, and survival are implemented — quest progress must hook via **`GameEvents`** (slice-05b pattern) without `if questId` branches in orchestrators.
- GDD §8.4 defines tutorial chain `t01`–`t08`; §8.6 defines early main `main_01`; §8.9 defines `side_01` / `side_02`.
- UI pattern: passive components in `Shared/UI/Components/`, controllers cache sync only.

## Goals / Non-Goals

**Goals:** Tutorial chain playable end-to-end, bridge + one main + two side quests, XP/level 1–5, quest tracker + journal, `QuestTrackEvent`, tutorial invulnerability + fauna safe zone, localized copy.

**Non-Goals:** NPC dialogue, POI missions, dailies/clan/env quests, achievements, full `main_02`–`main_18` content, helper recruitment, raid gates, discovery journal sections.

## Decisions

### QuestService architecture

| Responsibility | Owner |
|----------------|-------|
| Start / complete quests | `QuestService` |
| Validate objective increments | `QuestService` (subscribes to `GameEvents`) |
| Grant XP, currency, items | `QuestService` → `InventoryService` / profile mutation |
| Level-up threshold check | `QuestService` (GDD table levels 1–5) |
| Sync to client | `PlayerSyncService.syncQuestToClient` (extract from inline) |
| Track quest intent | `QuestTrackEvent` handler in `QuestService` |

Session cache:

```luau
type QuestSession = {
  trackedQuestId: string?,
}
```

Profile:

```luau
type QuestObjectiveProgress = {
  kind: string,
  current: number,
  target: number,
  itemId: string?,
  speciesId: string?,
  blueprintId: string?,
}

type QuestState = {
  status: "active" | "completed",
  objectives: { QuestObjectiveProgress },
  startedAt: number,
  completedAt: number?,
}
```

**Alternative:** Quest logic in each service — rejected; violates single authority and duplicates validation.

### GameEvents extensions

Add bindables (server-only) fired by existing services **after** successful authoritative action:

| Event | Fired by | Payload |
|-------|----------|---------|
| `ItemHarvested` | `ResourceService` | `player, itemId, quantity` |
| `ItemCrafted` | `CraftingService` | `player, recipeId, outputItemId, quantity` |
| `StructurePlaced` | `CampService` | `player, blueprintId` |
| `FaunaDefeated` | `AnimalService` | `player, speciesId` |
| `BiomeEntered` | `BiomeService` | `player, biomeId` |
| `QuestUiOpened` | `QuestController` via remote | `player, panelId` — tutorial `open_ui` only |

`QuestService:Start()` connects all listeners once.

### Tutorial chain (GDD §8.4 — v0.1 implementation)

| ID | Objectives | Rewards | Notes |
|----|------------|---------|-------|
| `t01_spawn` | `open_ui` stats panel | — | Auto-complete on first sync / plot assign |
| `t02_gather` | 3× `stick`, 2× `stone` | 10 XP | Highlight nearby nodes optional (client overlay) |
| `t03_sparks` | craft `sparks` ×1 | 15 XP | `hands` station |
| `t04_tinder` | craft `tinder` ×1 | 10 XP | |
| `t05_campfire` | place `bp_campfire` ×1 | 25 XP + grant `bp_craft_table` | |
| `t06_cold` | `survive_cold` 30 s near fire | 15 XP | SurvivalService simulates cold dip |
| `t07_bandage` | craft `bandage` ×2 | 20 XP + 5× `berry` | |
| `t08_complete` | place `bp_craft_table` ×1 | 25 XP; `tutorialCompleted=true` | |

**Chain after tutorial:**

| ID | Objectives | Rewards |
|----|------------|---------|
| `m00_wood` | gather `wood` ×10 | 30 XP + 25 Brasas |
| `main_01_chest` | place `bp_chest` ×1 | 50 XP + 3× `cooked_berry` |
| `side_01_berries` | gather `berry` ×20 | 40 XP + 5× `cooked_berry` |
| `side_02_wolf` | defeat `wolf` ×3 | 50 XP + 5× `fiber` |

`side_*` unlock when `tutorialCompleted` and player level ≥ 2 (after `m00_wood` XP).

### XP and level (levels 1–5 only)

| Level | Total XP required |
|-------|-------------------|
| 1 | 0 |
| 2 | 100 |
| 3 | 250 |
| 4 | 450 |
| 5 | 700 |

On level-up: fire toast key `quest.level_up` with `{ level }` via quest snapshot or reuse existing toast component.

### Tutorial protection

- `SurvivalService.applyDamage` early-return if `tutorialCompleted == false` (quest check via `QuestService.isTutorialActive(player)`).
- `AnimalService` AI tick: skip chase/attack for players where `QuestService.isTutorialActive(player)` AND fauna/player within 80 studs of plot center (`CampService.getPlotCenter`).

**Alternative:** Separate `TutorialService` — rejected; thin wrapper not needed for two rules.

### QuestProgressEvent snapshot (extended)

```luau
export type QuestSnapshot = {
  progress: { [string]: QuestState },
  tutorialCompleted: boolean,
  trackedQuestId: string?,
  activeQuestIds: { string },
  stats: { level: number, xp: number },
  lastCompletedQuestId: string?, -- drives client toast once
}
```

`PlayerSyncService` gains `syncQuestToClient`; `QuestService` calls it after every mutation.

### UI layout

- **QuestTracker** — top-right below survival bars; shows tracked quest; tap chevron to collapse on mobile.
- **QuestJournal** — center panel, tabs Active | Completed; Track button per active row.
- **TutorialOverlay** — lightweight banner + arrow hints (client-only visuals); driven by active tutorial quest id from snapshot (no server logic).

Controllers: `QuestController` owns ScreenGui, subscribes `QuestProgressEvent`, fires `QuestTrackEvent` and `QuestUiOpenedEvent` (new, tutorial only) on panel open.

### Remotes

| Remote | Direction | Payload |
|--------|-----------|---------|
| `QuestProgressEvent` | S→C | `QuestSnapshot` |
| `QuestTrackEvent` | C→S | `questId: string` |
| `QuestUiOpenedEvent` | C→S | `panelId: string` |

Register in `Remotes.luau` + Rojo instances.

### Localization

Keys pattern:

- `quest.t02_gather.title`
- `quest.t02_gather.objective.1`
- `quest.journal.title`
- `quest.tracker.track`
- `quest.completed_toast` — `"Quest complete: {title}"`

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| GameEvents missed → quest stuck | Unit-test style checklist in verify; each hook fires in one integration test path |
| Tutorial invulnerability abused | Only while `tutorialCompleted=false`; ends at `t08` |
| XP inflation from repeat sides | Side quests marked `repeatable: false`; completed ids in `missionsCompleted` block restart |
| Client tracker desync | Single source: `QuestProgressEvent`; no local progress |

## Migration Plan

1. Add `missionsCompleted` to `PlayerProfileTemplate` with reconcile default `[]`.
2. Existing profiles: empty `quests` → `QuestService` auto-starts tutorial on load.
3. Players who already have items/camp progress: tutorial objectives retroactively complete if counts already satisfied (check on start).

## Open Questions

- **Cold simulation for `t06_cold`:** trigger via `SurvivalService` scripted temperature dip on step start vs wait for natural night — **decision:** scripted −15 temperature for 45 s when `t06` becomes active.
- **Retroactive completion:** if player already placed campfire before slice deploy, auto-satisfy `t05` objective on quest init — **yes**, scan profile/camp state on load.
