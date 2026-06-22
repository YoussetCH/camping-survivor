## ADDED Requirements

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
