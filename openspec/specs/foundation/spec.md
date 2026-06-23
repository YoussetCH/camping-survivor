# Foundation — Technical Spec

**Status:** Implemented (slice-01, slice-02b locale, slice-03 inventory, slice-05 camp fields, slice-05b game events)  
**GDD:** Infrastructure  
**Services:** PlayerDataService, NetworkingService, PlayerSyncService, LocalizationService

## Purpose

Shared types, profile schema, remote registry, item/recipe constants, and initial client sync on join.

## Requirements

### Requirement: Extended player profile schema

The system SHALL persist an extended `PlayerProfile` including survival stats, status effects, camp data (plot id, level, structures array, per-chest storage maps), unlocked recipes, monetization purchase tracking, tutorial completion, extended stats (playTime, deaths), hotbar (6 entries), and equipped tool/coat ids.

#### Scenario: New player defaults

- GIVEN a player joins for the first time
- WHEN the profile is reconciled from template
- THEN survival.hunger and survival.thirst are 80
- AND survival.health is 100
- AND survival.temperature is 50
- AND camp.level is 0
- AND camp.plotId is nil until assigned
- AND camp.structures is an empty array
- AND camp.chests is an empty map
- AND tutorialCompleted is false
- AND `settings.locale` is `"en"`
- AND hotbar has 6 empty entries
- AND equipped.toolItemId and equipped.coatItemId are nil

### Requirement: Player locale preference (GDD v1.2)

The system SHALL persist `settings.locale` on the player profile with default `"en"`. Launch locales: `"en"`, `"es"`.

#### Scenario: New player locale default

- GIVEN a player joins for the first time
- WHEN the profile is reconciled from template
- THEN `settings.locale` is `"en"`

### Requirement: Domain sync remotes registry

The system SHALL register RemoteEvents: `SurvivalUpdatedEvent`, `InventoryUpdatedEvent`, `CampUpdatedEvent`, `QuestProgressEvent`, `SetLocaleEvent`, `LocaleChangedEvent`, `EquipItemEvent`, `SetHotbarSlotEvent`, `UseItemEvent` under `ReplicatedStorage.Remotes.Events`.

#### Scenario: Remote instances exist at server start

- GIVEN the server has finished `NetworkingService:Init`
- WHEN any registered event name is queried
- THEN a RemoteEvent instance exists with that name

### Requirement: Initial sync on join

The system SHALL fire domain sync events to the client after a successful profile load, projecting current profile data.

#### Scenario: Player joins with loaded profile

- GIVEN a player profile loaded successfully
- WHEN initial sync runs
- THEN `SurvivalUpdatedEvent` fires with current survival stats and status effects
- AND `InventoryUpdatedEvent` fires with current inventory, hotbar, and equipped
- AND `CampUpdatedEvent` fires with current camp data
- AND `QuestProgressEvent` fires with current quest progress

### Requirement: Item and recipe constants

The system SHALL expose static item and tutorial recipe definitions in `Shared/Constants/Items.luau` and `Shared/Constants/Recipes.luau` for use by future crafting/inventory slices.

#### Scenario: Tutorial item lookup

- GIVEN code requires item id `flint`
- WHEN `Items.get("flint")` is called
- THEN a valid `ItemDefinition` is returned

### Requirement: Client sync reception

The client SHALL subscribe to domain sync events and cache the latest payloads without applying gameplay logic.

#### Scenario: Client receives survival sync

- GIVEN the client is running
- WHEN `SurvivalUpdatedEvent` fires from server
- THEN `ClientSyncController` stores the snapshot without error

### Requirement: Server game events bus

The system SHALL provide a server-side `GameEvents` module exposing typed signals for cross-feature notifications that MUST NOT use direct service-to-service imports. At minimum, the bus MUST include `CampPlotAssigned(player, plotId)` and `CampLevelChanged(player, newLevel, oldLevel)`.

#### Scenario: Plot assignment fires event

- GIVEN a new player receives their first camp plot assignment
- WHEN assignment persists successfully
- THEN `GameEvents.CampPlotAssigned` fires with the player and plotId

#### Scenario: Survival listens without CampService import

- GIVEN `SurvivalService` needs to teleport a player to their plot on first assignment
- WHEN `CampPlotAssigned` fires
- THEN `SurvivalService` (or its bootstrap listener) teleports the player
- AND `SurvivalService` does not require `CampService` at runtime

#### Scenario: Camp level change fires event

- GIVEN camp level transitions from 0 to 1 after placing starter structures
- WHEN level recalculation completes
- THEN `GameEvents.CampLevelChanged` fires with newLevel 1 and oldLevel 0

## Related

- `src/ReplicatedStorage/Shared/Types/PlayerProfile.luau`
- `src/ReplicatedStorage/Shared/Constants/Remotes.luau`
- `src/ReplicatedStorage/Shared/Constants/Items.luau`
- `src/ReplicatedStorage/Shared/Constants/Recipes.luau`
- `src/ServerScriptService/Services/PlayerSyncService.luau`
- `src/StarterPlayer/StarterPlayerScripts/Controllers/ClientSyncController.luau`
