# Camping Survivor — Plan de implementación

> **Metodología:** OpenSpec-compatible (sin CLI obligatorio)  
> **Product spec:** [GDD-Camping-Survivor.md](./GDD-Camping-Survivor.md) v1.2  
> **Idiomas:** English (default) · Español — extensible ([§1.11](./GDD-Camping-Survivor.md#111-localización-e-idiomas))
> **Specs técnicas:** [`openspec/specs/`](../openspec/specs/)  
> **Slice activo:** Próximo — `slice-03-inventory`  
> **Último completado:** [`archive/2026-06-19-slice-02b-localization`](../openspec/changes/archive/2026-06-19-slice-02b-localization/)

## Workflow IA

1. Leer `openspec/changes/<slice>/` (proposal → design → specs → tasks → verify)
2. Implementar tasks en orden; marcar `[x]` en `tasks.md`
3. Ejecutar `verify.md`
4. Merge delta → `openspec/specs/`; archivar change en `openspec/changes/archive/`
5. Siguiente slice solo tras aprobación del usuario

**Prompt estándar:** *"Ejecuta slice-XX según openspec/changes/slice-XX-*/. No avances hasta verify.md completo."*

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
| 03 | `slice-03-inventory` | inventory | Cap. 4 | Próximo |
| 04 | `slice-04-crafting` | crafting | Cap. 4 | Pendiente |
| 05 | `slice-05-camp` | camp | Cap. 6 | Pendiente |
| 06 | `slice-06-world` | world | Cap. 5 | Pendiente |
| 07 | `slice-07-fauna` | survival + world | Cap. 3/5 | Pendiente |
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
03 → 04 Crafting → 05 Camp → 06 World
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

## Extender features

Nuevo change en `openspec/changes/` con delta ADDED/MODIFIED en `specs/`. Ver [openspec/config.yaml](../openspec/config.yaml).
