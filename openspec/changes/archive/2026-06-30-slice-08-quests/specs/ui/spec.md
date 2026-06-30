# UI — Delta Spec (slice-08)

## ADDED Requirements

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
