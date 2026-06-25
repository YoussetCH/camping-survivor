# Camping Survivor — Plan de implementación

> **Metodología:** [OpenSpec](https://github.com/Fission-AI/OpenSpec) — schema `roblox-slice`  
> **Product spec:** [GDD-Camping-Survivor.md](./GDD-Camping-Survivor.md) v1.2  
> **Idiomas:** English (default) · Español — extensible ([§1.11](./GDD-Camping-Survivor.md#111-localización-e-idiomas))
> **Specs técnicas:** [`openspec/specs/`](../openspec/specs/)  
> **Slice activo:** `—`  
> **Último completado:** [`archive/2026-06-25-slice-07-fauna`](../openspec/changes/archive/2026-06-25-slice-07-fauna/)

## Workflow OpenSpec (Cursor)

Flujo oficial — usar **slash commands** en el chat de Cursor:

```
/opsx:propose slice-05-camp         → proposal, specs, design, tasks, verify
/opsx:apply                         → implementa tasks.md del change activo
/opsx:archive                       → merge specs + archiva (tras verify + tu OK)
```

| Paso | Acción |
|------|--------|
| 1 | `/opsx:propose "<qué quieres>"` — crea `openspec/changes/<name>/` |
| 2 | Revisar artefactos; `openspec validate <name>` |
| 3 | `/opsx:apply` — código según tasks; marcar `[x]` |
| 4 | Completar `verify.md` en Studio |
| 5 | `/opsx:archive` — mueve a `openspec/changes/archive/YYYY-MM-DD-<name>/` |
| 6 | Actualizar `workflow.active_change` en `openspec/config.yaml` |

**CLI de apoyo** (mismo flujo):

```bash
openspec status --change <name> --json
openspec instructions apply --change <name> --json
openspec validate <name>
openspec archive <name> -y
openspec update    # refrescar comandos /opsx:* en Cursor
```

**Change activo:** `—` (listo para proponer `slice-08-quests`)

**Siguiente slice planificado:** `slice-08-quests` (tras archivar 07)

## Localización (cross-cutting, GDD v1.2)

| | |
|--|--|
| **Default** | `en` (English) |
| **Launch** | `en`, `es` |
| **Spec** | [openspec/specs/localization/spec.md](../openspec/specs/localization/spec.md) |
| **Implementación** | Slice dedicado **antes de slice-03** (recomendado) o primer bloque de slice-03 |
| **Regla** | Desde ahora: textos visibles = claves i18n, no strings hardcodeados en controllers |

## Vertical slices

| # | ID | Capability | GDD | Estado |
|---|-----|------------|-----|--------|
| 01 | `slice-01-foundation` | foundation | Infra | Completado |
| 02 | `slice-02-survival` | survival | Cap. 3 | Completado |
| 02b | `slice-02b-localization` | localization | §1.11 | Completado |
| 03 | `slice-03-inventory` | inventory | Cap. 4 | Completado |
| 04 | `slice-04-crafting` | crafting | Cap. 4 | Completado |
| 05 | `slice-05-camp` | camp | Cap. 6 | Completado |
| 05b | `slice-05b-feature-modules` | feature-modules + camp | Infra | Completado |
| 06 | `slice-06-world` | world | Cap. 5 | Completado |
| 07 | `slice-07-fauna` | survival + world | Cap. 3/5 | Completado |
| 08 | `slice-08-quests` | quests | Cap. 8 | Pendiente |
| 09 | `slice-09-helpers` | helpers | §2.13 | Pendiente |
| 10 | `slice-10-biomes-mid` | world + crafting | Cap. 5/4 | Pendiente |
| 11 | `slice-11-multiplayer` | multiplayer | Cap. 7 | Pendiente |
| 12 | `slice-12-raids` | multiplayer | Cap. 7 | Pendiente |
| 13 | `slice-13-economy` | economy | Cap. 9 | Pendiente |
| 14 | `slice-14-polish` | ui + content | Cap. 10 | Pendiente |

## Dependencias

```
01 Foundation → 02 Survival, 03 Inventory
03 → 04 Crafting → 05 Camp → 05b Feature Modules → 06 World
02 + 04 → 07 Fauna
05 + 07 → 08 Quests → 09 Helpers
06 → 10 Biomes | 05 → 11 Multiplayer → 12 Raids
01 → 13 Economy | 12 + 10 → 14 Polish
```

## Mapa GDD → specs

| Spec | Servicios |
|------|-----------|
| [foundation](../openspec/specs/foundation/spec.md) | PlayerData, Networking, tipos base |
| [survival](../openspec/specs/survival/spec.md) | SurvivalService |
| [inventory](../openspec/specs/inventory/spec.md) | InventoryService |
| [crafting](../openspec/specs/crafting/spec.md) | CraftingService |
| [camp](../openspec/specs/camp/spec.md) | CampService |
| [world](../openspec/specs/world/spec.md) | ResourceService, AnimalService, DayNightService |
| [helpers](../openspec/specs/helpers/spec.md) | HelperService |
| [quests](../openspec/specs/quests/spec.md) | QuestService |
| [multiplayer](../openspec/specs/multiplayer/spec.md) | ClanService, TradeService, RaidService |
| [economy](../openspec/specs/economy/spec.md) | EconomyService, MonetizationService |
| [ui](../openspec/specs/ui/spec.md) | Controllers |
| [localization](../openspec/specs/localization/spec.md) | LocalizationService, LocalizationController |
| [feature-modules](../openspec/specs/feature-modules/spec.md) | Registries, Behaviors, FeatureBootstrap |

## Extender features

Nuevo change en `openspec/changes/` con delta ADDED/MODIFIED en `specs/`. Ver [openspec/config.yaml](../openspec/config.yaml).

**Modularidad obligatoria:** toda estructura, mascota, estación o componente reutilizable debe seguir [Feature-Modules.md](./Feature-Modules.md) (carpeta propia + registry + sin acoplar orquestadores).
