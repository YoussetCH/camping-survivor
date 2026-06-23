# Tasks — Slice 06: World

## 1. Constants & types

- [x] 1.1 Create `Shared/Constants/WorldConstants.luau` (biome ids, ambient day/night table, cycle durations)
- [x] 1.2 Create `Shared/Constants/ResourceNodesConstants.luau` (node types, respawn times, tool patterns)
- [x] 1.3 Create `Shared/Types/World.luau` (phase enum, WorldSnapshot, harvest result types)

## 2. Dev world (Workspace)

- [x] 2.1 Create `Workspace/World/BiomeZones/` with `camp_hub` and `forest_near` zone parts (BiomeZone tag + BiomeId)
- [x] 2.2 Create `Workspace/World/ResourceNodes/` with ≥6 starter nodes (ResourceNode tag + attributes)
- [x] 2.3 Expand dev baseplate in bootstrap if needed for hub + forest ring

## 3. Remotes

- [x] 3.1 Register `HarvestResourceEvent`, `HarvestResourceResultEvent`, `WorldUpdatedEvent` in `Remotes.luau`
- [x] 3.2 Add Rojo RemoteEvent instances under `Remotes/Events/`

## 4. Server world services

- [x] 4.1 Create `DayNightService.luau` (cycle tick, Lighting sync, WorldUpdatedEvent broadcast)
- [x] 4.2 Create `BiomeService.luau` (zone scan, ambient lookup integrated with day/night phase)
- [x] 4.3 Create `ResourceService.luau` (node registry, harvest validation, respawn timers, depleted attribute)
- [x] 4.4 Wire `SurvivalService` to use `BiomeService.getAmbientForPlayer` instead of fixed constant
- [x] 4.5 Add service init order entries if DayNight must start before Biome

## 5. Inventory integration

- [x] 5.1 Expose or use `InventoryService` grant helper for multi-item harvest grants
- [x] 5.2 Ensure harvest failure leaves node undepleted when bag full

## 6. Client controllers

- [x] 6.1 Create `ResourceController.luau` (proximity prompts, harvest intent, result toasts)
- [x] 6.2 Create `WorldController.luau` (day/night HUD indicator from WorldUpdatedEvent)
- [x] 6.3 Add localization keys in `en.luau` / `es.luau`
- [x] 6.4 Register controllers in client bootstrap

## 7. Specs & archive prep

- [x] 7.1 Merge deltas into `openspec/specs/world/spec.md`, `survival/spec.md`, `inventory/spec.md`, `ui/spec.md`
- [x] 7.2 Run `verify.md` checklist in Studio
- [x] 7.3 Run `openspec validate slice-06-world`
- [x] 7.4 Update `docs/Implementation-Plan.md` active slice entry
- [x] 7.5 Archive with `openspec archive slice-06-world` (after user approval)

## Verification

- [x] Run `verify.md` — all items checked
