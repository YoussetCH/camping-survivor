# UI — Technical Spec

**Status:** Partial (slice-02 survival HUD, slice-03 inventory HUD, slice-04 crafting HUD, slice-05 build/chest)  
**GDD:** Cap. 10  
**Layer:** Controllers + passive ScreenGui

## Purpose

HUD, menus, toasts, mobile-first layouts. UI sends intent only; never mutates authoritative data.

All player-visible copy uses **localization keys** (GDD §1.11, §10.22). See [localization/spec.md](../localization/spec.md).
## Requirements
### Requirement: Hotbar HUD

The client SHALL display a **6-slot** hotbar anchored bottom-center. Each slot shows item quantity when occupied.

#### Scenario: Hotbar visible on join

- GIVEN the client bootstrap completes
- WHEN the player spawns
- THEN the hotbar UI is visible without opening menus

#### Scenario: Hotbar updates from sync

- GIVEN the server fires `InventoryUpdatedEvent`
- WHEN the client receives the snapshot
- THEN hotbar slots reflect server hotbar and bag contents

### Requirement: Inventory panel

The client SHALL provide a toggleable inventory grid (**16 slots**, 4×4) opened via key `I` or an on-screen backpack control.

#### Scenario: Toggle panel

- GIVEN the inventory panel is closed
- WHEN the player presses `I`
- THEN the inventory grid becomes visible
- WHEN pressed again
- THEN the grid hides

### Requirement: Inventory UI intent only

Inventory UI SHALL send player intent via remotes only (`EquipItemEvent`, `SetHotbarSlotEvent`, `UseItemEvent`) and SHALL NOT mutate profile data locally.

#### Scenario: Equip from UI

- GIVEN the player selects a tool slot in the inventory panel
- WHEN the player clicks Equip
- THEN the client fires `EquipItemEvent` with the bag slot key only

### Requirement: Inventory localization

Hotbar and inventory panel labels SHALL use localization keys and refresh on locale change.

#### Scenario: Locale switch

- GIVEN the inventory panel is open in English
- WHEN the player switches to Spanish
- THEN panel title and action buttons display Spanish strings

### Requirement: Crafting panel

The client SHALL provide a toggleable crafting panel opened via key `C` or an on-screen craft control. The panel lists unlocked recipes available at station `hands` (v0.1).

#### Scenario: Toggle crafting panel

- GIVEN the crafting panel is closed
- WHEN the player presses `C`
- THEN the crafting panel becomes visible
- WHEN pressed again
- THEN the panel hides

### Requirement: Crafting UI intent only

Crafting UI SHALL send player intent via `CraftItemEvent` with `recipeId` only and SHALL NOT mutate inventory or unlocks locally.

#### Scenario: Craft from UI

- GIVEN the player selects `recipe_sparks` in the crafting panel
- WHEN the player clicks Craft
- THEN the client fires `CraftItemEvent` with `"recipe_sparks"`

### Requirement: Craft result feedback

The client SHALL display localized feedback when `CraftResultEvent` is received (success toast or error reason key).

#### Scenario: Craft success toast

- GIVEN the player initiated a craft
- WHEN `CraftResultEvent` arrives with `success = true`
- THEN a localized success message is shown

### Requirement: Crafting localization

Crafting panel labels and result messages SHALL use localization keys and refresh on locale change.

#### Scenario: Locale switch crafting

- GIVEN the crafting panel is open in English
- WHEN the player switches to Spanish
- THEN recipe names and buttons display Spanish strings

### Requirement: Build mode UI

The client SHALL provide a build mode toggled via key `B` or an on-screen build control when the player has at least one blueprint item in the bag. Build mode SHALL show a ghost preview, allow rotation via `R`, and confirm placement via click/tap sending `PlaceStructureEvent` only.

#### Scenario: Enter build mode

- GIVEN the player bag contains `bp_campfire`
- WHEN the player presses `B`
- THEN build mode activates with a ghost preview at the grid cursor
- AND a list of placeable blueprints is visible

#### Scenario: Build UI intent only

- GIVEN build mode is active
- WHEN the player confirms placement
- THEN the client fires `PlaceStructureEvent` with blueprint id, position, and rotation
- AND the client does not mutate inventory or camp data locally

#### Scenario: Placement feedback

- GIVEN the server rejects placement
- WHEN `PlaceStructureResultEvent` arrives with `success = false`
- THEN the client shows a localized toast using `reasonKey`

### Requirement: Build mode localization

Build mode labels, buttons, and error toasts SHALL use localization keys and refresh on locale change.

#### Scenario: Locale switch in build mode

- GIVEN build mode is open in English
- WHEN the player switches to Spanish
- THEN build UI strings display Spanish text

### Requirement: Camp chest panel

The client SHALL provide a toggleable chest panel when the player interacts with their own placed chest within interaction range. The panel displays **24** chest slots and supports transfer intent via `TransferItemEvent` only.

#### Scenario: Open chest

- GIVEN the player stands within range of their chest
- WHEN the player triggers chest interaction
- THEN the chest grid becomes visible with current chest contents from `CampUpdatedEvent`

#### Scenario: Chest UI intent only

- GIVEN the chest panel is open
- WHEN the player transfers an item
- THEN the client fires `TransferItemEvent` with slot keys only
- AND the client does not mutate chest or bag data locally

### Requirement: Resource harvest feedback

The client SHALL display harvest results from `HarvestResourceResultEvent` using localization keys. Success and error feedback MUST NOT mutate inventory locally.

#### Scenario: Successful harvest toast

- GIVEN the player triggers a harvest prompt
- WHEN the server responds with `success = true`
- THEN the client shows a localized success message

#### Scenario: Error toast

- GIVEN the server responds with `reasonKey = "resource.error.depleted"`
- WHEN the client receives `HarvestResourceResultEvent`
- THEN the client shows the localized error for that key

### Requirement: Day/night HUD indicator

The client SHALL display a passive day/night phase indicator updated from `WorldUpdatedEvent`.

#### Scenario: Phase icon updates

- GIVEN the server broadcasts phase `night`
- WHEN `WorldController` receives `WorldUpdatedEvent`
- THEN the HUD shows the night phase indicator

#### Scenario: Localization on phase label

- GIVEN the HUD shows a phase label
- WHEN the player changes locale
- THEN the label uses keys `ui.world.phase.*` in the active locale

### Requirement: Status effect HUD row

The client SHALL display active status effects from `SurvivalUpdatedEvent` as an icon row below the survival stat bars. Each icon MUST use a localization tooltip key (`status.<effectId>.name`).

#### Scenario: Bleeding icon visible

- GIVEN the player has active `bleeding`
- WHEN the survival HUD updates
- THEN a bleeding icon appears in the status row
- AND tooltip resolves via localization

#### Scenario: Effect cleared removes icon

- GIVEN `bleeding` was active and bandage cures it
- WHEN `SurvivalUpdatedEvent` arrives without `bleeding`
- THEN the bleeding icon is removed

### Requirement: Fauna health bar display

The client SHALL render a passive health bar (`BillboardGui`) on fauna models when `FaunaUpdatedEvent` provides HP data. The bar MUST NOT mutate fauna HP locally.

#### Scenario: Health bar reflects server HP

- GIVEN a wolf at 30/40 HP per `FaunaUpdatedEvent`
- WHEN the client renders the billboard
- THEN the bar fill shows 75%

#### Scenario: Removed fauna hides bar

- GIVEN `FaunaUpdatedEvent` with `removed = true`
- WHEN the client processes the event
- THEN the health bar is destroyed

### Requirement: Fauna attack intent

The client SHALL fire `AttackFaunaEvent` with `faunaId` only when the player initiates attack on fauna while a tool is equipped. The client MUST NOT apply damage locally.

#### Scenario: Attack intent with tool

- GIVEN the player has a tool equipped and clicks a fauna model
- WHEN attack input is triggered within UI range
- THEN the client fires `AttackFaunaEvent` with the model's `FaunaId` attribute

### Requirement: Wolf stun visual feedback

When a wolf enters `stunned` state due to a valid player hit, clients SHALL see clear visual feedback on the wolf model (tint and dizzy stars) for the stun duration.

#### Scenario: Wolf shows dizzy feedback while stunned

- GIVEN a player lands a valid hit on a wolf
- WHEN the server applies stun time
- THEN the wolf model shows stun feedback (`Highlight` + stars billboard)
- AND the visual clears automatically when stun ends

### Requirement: Quest tracker HUD

The client SHALL display an always-visible quest tracker showing the **tracked** active quest (default: first active main, else first active quest). The tracker SHALL show localized title and current objective progress (e.g. `2/3`). On mobile, the tracker SHALL be collapsible to a compact chip.

#### Scenario: Tracker visible with active tutorial quest

- GIVEN the player has active quest `t02_gather`
- WHEN the client bootstrap completes
- THEN the quest tracker is visible without opening menus
- AND displays localized title and gather progress

#### Scenario: Tracker updates from sync

- GIVEN the server fires `QuestProgressEvent` with incremented objective
- WHEN the client receives the snapshot
- THEN the tracker progress text updates

### Requirement: Quest journal panel

The client SHALL provide a toggleable quest journal opened via key `J` or an on-screen journal control. The journal SHALL list **active** and **completed** quests with localized titles and objective summaries. Completed quests SHALL appear in a separate section.

#### Scenario: Toggle journal

- GIVEN the quest journal is closed
- WHEN the player presses `J`
- THEN the journal panel becomes visible
- WHEN pressed again
- THEN the panel hides

### Requirement: Quest UI intent only

Quest UI SHALL send player intent via `QuestTrackEvent` with `questId` only and SHALL NOT mutate quest progress or rewards locally.

#### Scenario: Track quest from journal

- GIVEN the journal lists active quest `main_01_chest`
- WHEN the player clicks Track
- THEN the client fires `QuestTrackEvent("main_01_chest")`
- AND waits for server `QuestProgressEvent` before updating tracked highlight

### Requirement: Quest completion toast

The client SHALL show a brief toast on quest completion using localization key `quest.completed_toast` with quest title parameter, driven by snapshot diff or dedicated completion flag in `QuestProgressEvent`.

#### Scenario: Toast on tutorial step complete

- GIVEN quest `t07_bandage` completes server-side
- WHEN the client receives updated `QuestProgressEvent`
- THEN a completion toast appears with localized quest name

### Requirement: Quest UI localization

Quest tracker, journal, and toasts SHALL use localization keys and refresh on locale change.

#### Scenario: Journal locale switch

- GIVEN the journal is open in English
- WHEN the player switches to Spanish
- THEN quest titles and labels display Spanish strings

### Requirement: Helper panel

The client SHALL provide a toggleable helper panel opened via key `H` or an on-screen helper control. The panel SHALL list active helpers with localized name, hunger bar, health bar, status icons, current mode, and Feed / Cure / Work / Shelter action buttons.

#### Scenario: Toggle helper panel

- GIVEN the helper panel is closed
- WHEN the player presses `H`
- THEN the helper panel becomes visible
- WHEN pressed again
- THEN the panel hides

### Requirement: Helper UI intent only

Helper UI SHALL send player intent via `FeedHelperEvent`, `CureHelperEvent`, and `SetHelperModeEvent` with validated ids only (helper instance id, bag slot key, mode id) and SHALL NOT mutate helper stats locally.

#### Scenario: Feed from panel

- GIVEN the helper panel shows a lumberjack with low hunger
- WHEN the player selects a food item and clicks Feed
- THEN the client fires `FeedHelperEvent` with helper id and slot key only

### Requirement: Helper alert toasts

The client SHALL show toasts for helper death (`helper.death_toast`) and urgent low hunger (`helper.hunger_warning`) driven by `HelperUpdatedEvent` diffs.

#### Scenario: Death toast

- GIVEN a helper dies server-side
- WHEN the client receives updated `HelperUpdatedEvent`
- THEN a localized death toast appears with helper name

### Requirement: Helper panel localization

Helper panel labels, buttons, and toasts SHALL use localization keys and refresh on locale change.

#### Scenario: Panel locale switch

- GIVEN the helper panel is open in English
- WHEN locale switches to Spanish
- THEN action button labels display Spanish strings

## Localization

- Default locale: `en`
- HUD labels, alerts, and menus resolve via `Localization.get(key)`
- Controllers refresh on `LocaleChanged` when settings change
