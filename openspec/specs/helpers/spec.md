# Helpers — Technical Spec

**Status:** Stub (slice-09)  
**GDD:** §2.13, §3.8  
**Service:** HelperService

## Purpose

Recruitable NPC helpers, hunger/health, permanent death, camp stations.
## Requirements

_To be defined in slice-09-helpers._

### Requirement: Helper definitions registry

The system SHALL expose static helper type definitions in `Shared/Constants/Helpers.luau` including at minimum `lumberjack` with `helperTypeId`, task description keys, biome origin, max per camp (1 per type), and work requirements (e.g. campfire active or axe in chest for lumberjack).

#### Scenario: Helper type lookup

- GIVEN code requires helper type `lumberjack`
- WHEN `Helpers.getType("lumberjack")` is called
- THEN a valid `HelperTypeDefinition` is returned with task id `gather_wood`

### Requirement: Helper instance persistence

The system SHALL persist active helpers in profile field `helpers` as `{ [instanceId]: HelperState }` where `HelperState` includes `helperTypeId`, display `nameKey`, `hunger`, `health`, `statusEffects`, `mode` (`work` | `shelter`), `recruitedAt`, and `weakSince` timestamp when applicable. Permanently lost helper type ids SHALL append to `lostHelpers` for memorial UI.

#### Scenario: Recruited helper persisted

- GIVEN a player recruits a lumberjack
- WHEN the profile saves
- THEN `helpers` contains one entry with `helperTypeId = "lumberjack"` and hunger 100, health 100

### Requirement: HelperService authoritative lifecycle

The system SHALL implement `HelperService` as the sole authority for recruiting helpers, ticking hunger/health, applying status damage, executing tasks, handling death, and syncing to clients. Controllers SHALL NOT mutate helper stats directly.

#### Scenario: Max helpers enforced

- GIVEN a solo player already has 2 active helpers
- WHEN recruitment would add a third
- THEN the request is rejected without mutation

### Requirement: Helper hunger and weak chain

`HelperService` SHALL drain helper hunger at **3/min** while `mode = work` and helper is alive. At hunger **0**, helper enters `weak` status and stops task execution. If hunger remains **0** for **20 minutes**, the helper SHALL die permanently.

#### Scenario: Weak stops wood gathering

- GIVEN a lumberjack with hunger 0 and `weak` active
- WHEN a work tick would grant wood
- THEN no items are granted

#### Scenario: Permanent death from neglect

- GIVEN a helper in `weak` for 20 minutes
- WHEN the hunger tick runs
- THEN the helper is removed from `helpers`
- AND `lumberjack` is recorded in `lostHelpers`

### Requirement: Feed and cure helpers

The system SHALL register `FeedHelperEvent` and `CureHelperEvent` (client→server). Client sends `helperInstanceId` and item bag slot key only. Server validates ownership, distance to plot helper anchor, item type, and applies +40 hunger (basic food) or +60 (cooked food) and status cures matching player rules (`bandage` → `bleeding`, `antidote` → `poison`).

#### Scenario: Feed lumberjack

- GIVEN an active lumberjack with hunger 30
- WHEN the player fires `FeedHelperEvent` with valid `berry` slot
- THEN hunger increases by 40 (capped at 100)
- AND `HelperUpdatedEvent` fires

### Requirement: Helper work tasks v0.1

Registered helper behaviors SHALL execute type-specific work on a server tick interval. **Lumberjack** SHALL grant **1× `wood`** every **60 s** while on player plot, `mode = work`, hunger > 20, health > 0, no blocking status, and camp has active `bp_campfire` OR player chest contains an axe tool.

#### Scenario: Lumberjack grants wood

- GIVEN a fed lumberjack in work mode near plot with active campfire
- WHEN 60 seconds pass
- THEN player receives 1× `wood` via `InventoryService`
- AND hunger decreased per tick rules

### Requirement: Helper recruitment via escort quest

Completing escort objective for quest `main_05_lumberjack` SHALL recruit one lumberjack helper if under cap and no lumberjack of that type is already active. Escort NPC SHALL despawn on successful recruitment.

#### Scenario: Escort completes at plot

- GIVEN quest `main_05_lumberjack` active and escort NPC within player plot bounds
- WHEN server validates escort objective
- THEN lumberjack helper is added to profile
- AND quest completes with configured rewards

### Requirement: HelperUpdatedEvent sync

The system SHALL fire `HelperUpdatedEvent` with `HelperSnapshot` (helpers map, lostHelpers, max helpers) after recruit, tick mutation, feed, cure, mode change, or death.

#### Scenario: Initial sync includes helpers

- GIVEN a player with one helper
- WHEN initial domain sync runs
- THEN `HelperUpdatedEvent` includes helper hunger and health values

### Requirement: Helper localization

All helper names, panel labels, alerts, and death messages SHALL use localization keys (`helper.*`). No hardcoded player-visible helper strings in controllers.

#### Scenario: Helper panel locale switch

- GIVEN the helper panel is open in English
- WHEN locale switches to Spanish
- THEN helper names and action labels update

