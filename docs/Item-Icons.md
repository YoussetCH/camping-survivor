# Item icons — guía

Documentación para **agregar**, **cambiar** o **depurar** iconos de items en inventario y crafting.

## Cómo funciona

```
assets/icons/items/*.png     →  subir a Roblox  →  iconAssetId en Items.luau
                                                          ↓
                                              ItemIcon.luau (rbxassetid://…)
                                                          ↓
                              InventorySlot · CraftingHUDController (lista de recetas)
```

| Pieza | Ubicación | Rol |
|-------|-----------|-----|
| PNG fuente | `assets/icons/items/` | Archivo editable en el repo |
| Definición del item | `src/ReplicatedStorage/Shared/Constants/Items.luau` | `iconAssetId` por item |
| Tipo | `src/ReplicatedStorage/Shared/Types/Item.luau` | `iconAssetId: number` obligatorio en cada item |
| Helper UI | `src/ReplicatedStorage/Shared/UI/ItemIcon.luau` | Resuelve `itemId` → `ImageLabel.Image` |
| Slots inventario | `src/ReplicatedStorage/Shared/UI/InventorySlot.luau` | Muestra icono en hotbar e inventario |
| Recetas | `src/ReplicatedStorage/Shared/Constants/Recipes.luau` | Icono = **primer output** (`Recipes.getIconItemId`) |

Los iconos **no** van en locale files ni en el perfil del jugador: son constantes de cliente/servidor referenciadas por `itemId`.

---

## Requisitos de imagen

| Propiedad | Recomendación |
|-----------|---------------|
| Formato | PNG (preferido) o JPG |
| Tamaño | 64×64 a 128×128 px (cuadrado) |
| Fondo | Transparente o oscuro uniforme |
| Estilo | Plano / legible a tamaño pequeño (48 px en UI) |
| Nombre archivo | Igual al `itemId` (ej. `iron_ore.png`) |

---

## Cambiar el icono de un item existente

### 1. Editar o reemplazar el PNG

Sustituye el archivo en:

```text
assets/icons/items/<itemId>.png
```

Ejemplo: nuevo icono de `flint` → `assets/icons/items/flint.png`.

### 2. Subir la imagen a Roblox

Roblox necesita un **asset ID** (`rbxassetid://…`). El PNG local no basta por sí solo.

#### Opción A — Creator Dashboard (manual)

1. [create.roblox.com](https://create.roblox.com) → **Development Items** → **Decals/Images** → **Upload**.
2. Sube el PNG y copia el **Asset ID** numérico.

#### Opción B — Studio MCP + servidor local (desarrollo con Cursor)

1. Abre **Roblox Studio** con el place del proyecto y Rojo conectado.
2. En terminal, desde la carpeta de iconos:

```bash
cd "assets/icons/items"
python3 -m http.server 8765
```

3. En Cursor, con el MCP **Roblox Studio**, usa `upload_image` con URL:

```text
http://localhost:8765/flint.png
```

4. La respuesta incluye el nuevo ID, por ejemplo:

```text
"http://localhost:8765/flint.png" → "rbxassetid://105442743288171"
```

5. Detén el servidor (`Ctrl+C`) cuando termines.

### 3. Actualizar `Items.luau`

Cambia solo el número de `iconAssetId` del item:

```luau
flint = {
	id = "flint",
	nameKey = "item.flint.name",
	category = "raw",
	maxStack = 10,
	iconAssetId = 105442743288171, -- ← nuevo Asset ID
},
```

### 4. Verificar en Studio

1. `rojo serve` + **Sync** en Studio.
2. **Play** → inventario (`I`) y crafting (`C`).
3. Si no cambia, reinicia Play (los `ImageLabel` cargan la textura al spawn).

---

## Agregar icono a un item nuevo

Sigue la checklist completa al definir un item nuevo:

### 1. PNG

```text
assets/icons/items/mi_item.png
```

### 2. Subir a Roblox

Mismo proceso que [Cambiar icono](#cambiar-el-icono-de-un-item-existente) → obtén el Asset ID.

### 3. Definición en `Items.luau`

```luau
mi_item = {
	id = "mi_item",
	nameKey = "item.mi_item.name",
	category = "raw",
	maxStack = 30,
	iconAssetId = 12345678901234,
},
```

### 4. Tipo (ya definido)

`Item.luau` exige `iconAssetId` en todo `ItemDefinition`. No hace falta tocar el tipo salvo que cambies el contrato.

### 5. Localización (nombre visible, no icono)

En `Locales/en.luau` y `Locales/es.luau`:

```luau
["item.mi_item.name"] = "My Item",
```

### 6. UI

No suele hacer falta código extra: `InventorySlot` y `ItemIcon` ya leen `Items.getIconAssetId(itemId)`.

---

## Recetas (crafting)

Las recetas **no** tienen `iconAssetId` propio. El panel de crafting usa el icono del **primer output**:

```luau
Recipes.getIconItemId("recipe_sparks") -- → "sparks"
```

Para cambiar el icono de una receta en la lista:

- Cambia el icono del **item de salida**, o
- Reordena `outputs` en `Recipes.luau` (solo si el diseño lo permite).

Si en el futuro una receta necesita icono distinto al output, añade `iconItemId` opcional en `RecipeDefinition` y úsalo en `CraftingHUDController`.

---

## API rápida (`ItemIcon`)

Desde cualquier controller o módulo UI del cliente:

```luau
local ItemIcon = require(ReplicatedStorage.Shared.UI.ItemIcon)

-- Cadena para ImageLabel.Image
local content = ItemIcon.getImageContent("stick") -- "rbxassetid://80155224613147"

-- Aplicar a un ImageLabel existente
ItemIcon.applyTo(myImageLabel, "stick")
ItemIcon.applyTo(myImageLabel, nil) -- limpia / oculta
```

Desde lógica compartida (solo lectura del ID):

```luau
local Items = require(ReplicatedStorage.Shared.Constants.Items)
local assetId = Items.getIconAssetId("stick")
```

---

## Solución de problemas

| Síntoma | Causa probable | Qué hacer |
|---------|------------------|-----------|
| Cuadrado vacío / gris | Asset ID incorrecto o imagen no aprobada | Verifica ID en Dashboard; espera moderación si acabas de subir |
| Icono antiguo | Caché de Studio | Stop Play → Sync Rojo → Play de nuevo |
| Solo texto, sin imagen | Falta `iconAssetId` o item desconocido | Revisa entrada en `Items.luau` |
| Receta sin icono | Output sin definición en `Items` | Añade el item output con `iconAssetId` |
| MCP upload falla | URL no HTTP | Usa `http://localhost:…`, no ruta local directa |

---

## Mapa de archivos actuales

Fuente PNG e IDs vivos en código — consulta `assets/icons/items/README.md` para la tabla item → archivo.

**Regla del proyecto:** todo item jugable en v0.1 debe tener PNG en `assets/icons/items/` e `iconAssetId` en `Items.luau` antes de merge.
