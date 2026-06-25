# Tasks — Slice 07: Fauna

## 1. Constants & types

- [x] 1.1 Create `Shared/Constants/FaunaConstants.luau` (species ids, AI ranges, caps, attack cooldowns)
- [x] 1.2 Create `Shared/Constants/StatusEffectConstants.luau` (tick rates, infection threshold)
- [x] 1.3 Extend `Shared/Types/Survival.luau` or add `Shared/Types/Fauna.luau` (FaunaSnapshot, AI state enum)
- [x] 1.4 Add `antidote` and `herb_common` to `Items.luau` with locale keys in `en.luau` / `es.luau`

## 2. Fauna feature modules

- [x] 2.1 Create `Shared/Features/Wolf/` (WolfDefinition, WolfModel — readable silhouette)
- [x] 2.2 Create `Shared/Features/Snake/` (SnakeDefinition, SnakeModel — readable silhouette)
- [x] 2.3 Create `FaunaDefinitions.luau` aggregator
- [x] 2.4 Create `ServerScriptService/Features/FaunaRegistry.luau`
- [x] 2.5 Create `WolfBehavior.luau` and `SnakeBehavior.luau` with register on init
- [x] 2.6 Create `FaunaBootstrap.luau` and wire in server bootstrap before `AnimalService`

## 3. Remotes

- [x] 3.1 Register `AttackFaunaEvent`, `FaunaUpdatedEvent` in `Remotes.luau`
- [x] 3.2 Add Rojo RemoteEvent instances under `Remotes/Events/`

## 4. Server — AnimalService

- [x] 4.1 Create `AnimalService.luau` (spawn from FaunaSpawn tags, AI tick, cap per player)
- [x] 4.2 Implement fauna→player melee via `SurvivalService.applyDamage`
- [x] 4.3 Implement player→fauna attack handler on `AttackFaunaEvent`
- [x] 4.4 Implement death, drop rolls, model cleanup, `FaunaUpdatedEvent` broadcast
- [x] 4.5 Integrate `DayNightService` for wolf day/night aggression rules
- [x] 4.6 Register service init order in `ServerKernel`

## 5. Server — Survival & inventory

- [x] 5.1 Add `SurvivalService.applyDamage`, `addStatusEffect`, `removeStatusEffect`, `clearStatusEffects`
- [x] 5.2 Apply status tick damage in survival tick (`bleeding`, `poison`, `infection`)
- [x] 5.3 Implement bleeding→infection transition after 300 s
- [x] 5.4 Clear status effects on death respawn
- [x] 5.5 Update `InventoryService.useItem`: bandage cures bleeding; antidote cures poison
- [x] 5.6 Add antidote to studio dev grant

## 6. Dev world spawns

- [x] 6.1 Create `Workspace/World/FaunaSpawns/` with ≥3 wolf and ≥2 snake markers in `forest_near`
- [x] 6.2 Ensure `WorldBootstrap` or `AnimalService` parents spawned models under `Workspace/World/Fauna/`

## 7. Client controllers

- [x] 7.1 Create `FaunaController.luau` (FaunaUpdatedEvent cache, health bars, attack intent)
- [x] 7.2 Extend `SurvivalHUDController` with status-effect icon row
- [x] 7.3 Add localization keys: `status.*`, `fauna.*`, `combat.*` in `en` / `es`
- [x] 7.4 Register `FaunaController` in client bootstrap

## 8. Specs & archive prep

- [ ] 8.1 Merge deltas into `openspec/specs/world`, `survival`, `inventory`, `ui`, `feature-modules`
- [ ] 8.2 Run `verify.md` checklist in Studio
- [x] 8.3 Run `openspec validate slice-07-fauna`
- [x] 8.4 Update `docs/Implementation-Plan.md` active slice entry
- [ ] 8.5 Archive with `openspec archive slice-07-fauna` (after user approval)

## 9. Dodge mechanic (player skill — speed-based)

- [x] 9.1 Add `DODGE_COOLDOWN_SECONDS`, `DODGE_IFRAME_SECONDS`, `DODGE_MOVE_STUDS`, `DODGE_BLEED_FAIL_CHANCE`, `DODGE_POISON_FAIL_CHANCE`, `DODGE_MIN_WALKSPEED` to `FaunaConstants`
- [x] 9.2 Register `DodgeEvent` (Client→Server) and `DodgeResultEvent` (Server→Client) in `Remotes.luau` + Rojo `.model.json` files
- [x] 9.3 Extend `AnimalService` with dodge-state tracking (`playerDodgeStates`), `isPlayerDodging`, `computeDodgeSuccessChance`; gate fauna→player damage on dodge check
- [x] 9.4 Increase wolf `attackWindupSeconds` (0.25→0.65) so players have a fair reaction window
- [x] 9.5 Add `DodgeButton` (Q / mobile) and `performDodge` to `FaunaController`; listen `DodgeResultEvent` for toast feedback
- [x] 9.6 Add `combat.dodge.*` and `ui.combat.dodge` keys in `en` / `es`
- [x] 9.7 Add wolf stun feedback visuals (model tint + dizzy stars) while stunned after player hit
