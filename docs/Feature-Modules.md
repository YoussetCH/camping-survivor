# Feature Modules — Guía de modularidad

> **Spec técnica:** [openspec/specs/feature-modules/spec.md](../openspec/specs/feature-modules/spec.md)  
> **Implementación de referencia:** slice `05b-feature-modules` (fogata, cofre, mesa de craft)

Cada **componente o feature de gameplay** (estructura, mascota, estación, helper, trampa, etc.) debe ser **enchufable**: añadirlo = crear carpeta + registrar; **no** editar servicios orquestadores con `if featureId == ...`.

---

## Principio

| Capa | Rol | Ejemplo |
|------|-----|---------|
| **Kernel** | Infra compartida | `PlayerDataService`, `InventoryService`, `NetworkingService` |
| **Orquestador** | Flujo genérico + validación común | `CampService` (grid, plots, place/demolish) |
| **Feature module** | Lógica de **un** elemento | `CampfireBehavior`, `ChestBehavior` |

**Regla de oro:** un feature solo habla **hacia abajo** (kernel) o **a través de contratos** (registries, `GameEvents`). Nunca `require` lateral entre features ni acoplar orquestadores a features concretos.

---

## Estructura de carpetas

### Estructuras de campamento (patrón actual)

```
ReplicatedStorage/Shared/Features/
  <FeatureName>/
    <FeatureName>Definition.luau   -- metadata (footprint, station, recipeId)
    <FeatureName>Model.luau          -- builder 3D → StructureModelRegistry

ServerScriptService/Features/
  Behaviors/
    <FeatureName>Behavior.luau       -- hooks servidor + registro
  StructureBehaviorRegistry.luau
  StationRegistry.luau
  GameEvents.luau
  FeatureBootstrap.luau
```

Agregadores (no editar para cada feature nuevo):

- `Shared/Features/FeatureDefinitions.luau` — lista de definiciones
- `Shared/Features/StructureModelRegistry.luau` — builders de modelos
- `Shared/Constants/StructuresConstants.luau` — API pública `get` / `getAll`

### Otros dominios (futuro)

Mismo patrón con registry propio:

| Dominio | Shared | Server | Registry |
|---------|--------|--------|----------|
| Helpers / mascotas | `Shared/Features/Wolf/` | `Behaviors/WolfBehavior.luau` | `HelperBehaviorRegistry` (slice-09) |
| Fauna | `Shared/Features/Bear/` | `Behaviors/BearBehavior.luau` | `FaunaRegistry` |
| UI reusable | `Shared/UI/Components/` | — | composición en controllers |

---

## Contratos

### StructureBehavior (estructuras)

Tipos en `Shared/Types/StructureBehavior.luau`.

```luau
export type StructureBehavior = {
  blueprintId: string,
  onPlace: ((ctx: StructureContext) -> ())?,
  onDemolish: ((ctx: StructureContext) -> ())?,
  validatePlacement: ((ctx: PlacementContext) -> (boolean, string?))?,
  onCampLevelRecalculate: ((ctx: CampLevelContext) -> ())?,
}
```

`CampService` delega hooks; **no** contiene lógica específica de fogata/cofre/mesa.

### StationRegistry (estaciones de craft)

Cada behavior con estación registra en init:

```luau
StationRegistry.register({
  stationId = "campfire",
  blueprintId = "bp_campfire",
  rangeStuds = CampConstants.CAMPFIRE_RANGE,
})
```

Consumidores (`CraftingService`, etc.) usan `StationRegistry.isPlayerNearStation` — **nunca** `CampService`.

### GameEvents (notificaciones cross-feature)

Bus servidor en `ServerScriptService/Features/GameEvents.luau`.

| Evento | Uso |
|--------|-----|
| `CampPlotAssigned` | Teleport al asignar parcela |
| `CampLevelChanged` | Desbloquear recetas starter |
| `RequestPlotTeleport` | Respawn en parcela (survival) |

**Prohibido:** `SurvivalService` → `require(CampService)` para efectos secundarios. Disparar evento o usar registry.

---

## Checklist — nueva estructura (`bp_*`)

- [ ] Crear `Shared/Features/<Name>/<Name>Definition.luau`
- [ ] Crear `Shared/Features/<Name>/<Name>Model.luau` y registrar en `StructureModelRegistry`
- [ ] Añadir definición a `FeatureDefinitions.luau`
- [ ] Crear `Behaviors/<Name>Behavior.luau` y registrar en `StructureBehaviorRegistry`
- [ ] Si tiene estación craft: registrar en `StationRegistry`
- [ ] Si tiene remotes propios: bind en `FeatureBootstrap` (no en `CampService`)
- [ ] `require` del behavior en `FeatureBootstrap.init()`
- [ ] **No** añadir `if blueprintId == "bp_..."` en `CampService`
- [ ] Claves i18n en `Locales/en.luau` + `es.luau`
- [ ] Entrada en OpenSpec (spec delta) antes de implementar

---

## Checklist — nuevo componente UI

- [ ] Módulo en `Shared/UI/Components/` (presentacional, sin lógica de negocio)
- [ ] Controller solo: mostrar datos + enviar intent (remote)
- [ ] Textos visibles = claves `Localization.get(key)`
- [ ] Sin `require` de Services del servidor
- [ ] Reutilizable sin depender de un solo feature (props/callbacks explícitos)

---

## Dependencias permitidas vs prohibidas

**Permitido**

```
CampfireBehavior → InventoryService
CampfireBehavior → StructureBehaviorRegistry.register
CraftingService → StationRegistry
Cualquier feature → GameEvents.fire*
```

**Prohibido**

```
CampfireBehavior → ChestBehavior
CraftingService → CampService (para proximidad)
CampService → if blueprintId == "bp_chest" { ... }
Feature A → require(Feature B) para lógica de negocio cruzada
```

Usar **eventos** o **registries** para coordinación.

---

## Bootstrap e init

1. `FeatureBootstrapService` corre en `ServerKernel.INIT_ORDER` **antes** de camp/crafting.
2. `FeatureBootstrap.init()` hace `require` de todos los behaviors (efecto lateral: registro).
3. `CampService:Init()` conecta `GameEvents` y remotes delegados (ej. cofre).

---

## Ejemplos en el repo

| Feature | Definition | Model | Behavior |
|---------|------------|-------|----------|
| Fogata | `Shared/Features/Campfire/CampfireDefinition.luau` | `CampfireModel.luau` | `Behaviors/CampfireBehavior.luau` |
| Cofre | `Shared/Features/Chest/ChestDefinition.luau` | `ChestModel.luau` | `Behaviors/ChestBehavior.luau` |
| Mesa craft | `Shared/Features/CraftTable/CraftTableDefinition.luau` | `CraftTableModel.luau` | `Behaviors/CraftTableBehavior.luau` |

---

## OpenSpec

Cambios que añadan o modifiquen features deben:

1. Tener delta en `openspec/specs/feature-modules/spec.md` o capability relacionada
2. Documentar en `design.md` qué registry/eventos usa
3. Incluir en `verify.md` que no se añadió acoplamiento lateral

Ver también: [AGENTS.md](../AGENTS.md) · [.cursor/rules/roblox-feature-modules.mdc](../.cursor/rules/roblox-feature-modules.mdc)
