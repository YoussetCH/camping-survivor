# camping-survivor

Proyecto Roblox con **Rojo + Wally**, arquitectura **Services + Controllers** propia (sin Knit), **Trove** para lifecycle y **ProfileStore** para persistencia.

## Requisitos

- [Aftman](https://github.com/LPGhatguy/aftman) (o instala `rojo` y `wally` manualmente)
- Roblox Studio

## Setup

```bash
# Instalar herramientas (rojo, wally)
aftman install

# Instalar dependencias
wally install

# Compilar place file
rojo build -o camping-survivor.rbxlx

# Servir en vivo con Studio
rojo serve
```

Abre `camping-survivor.rbxlx` en Studio y conecta el plugin de Rojo.

## Estructura

```
src/
├── ReplicatedStorage/
│   ├── Shared/          # Types, Constants, Utilities, Networking
│   └── Remotes/         # Events/ y Functions/ (instancias)
├── ServerScriptService/
│   ├── Bootstrap/       # init.server.luau — arranque del servidor
│   ├── Kernel/          # ServerKernel, BaseService
│   ├── Repositories/    # PlayerDataRepository (ProfileStore)
│   └── Services/        # Lógica de negocio
└── StarterPlayer/
    └── StarterPlayerScripts/
        ├── Bootstrap/   # init.client.luau — arranque del cliente
        ├── Kernel/      # ClientKernel, BaseController
        └── Controllers/ # UI, Input, Camera, Audio
```

## Flujo de arquitectura

```
UI (passive)
  → Controller (input/intent)
    → RemoteEvent
      → Service (validación + lógica)
        → Repository (ProfileStore)
```

## Crear un Service

1. Crea `src/ServerScriptService/Services/MiService.luau`
2. Extiende `BaseService` con `Init`, `Start` y opcionalmente `Destroy`
3. Usa `self:GetTrove()` para conexiones y cleanup automático
4. El `ServerKernel` lo detecta y arranca automáticamente

## Crear un Controller

1. Crea `src/StarterPlayer/StarterPlayerScripts/Controllers/MiController.luau`
2. Extiende `BaseController` con `Init` y `Start`
3. Solo UI/input — nunca modifiques datos del jugador en el cliente
4. El `ClientKernel` lo detecta y arranca automáticamente

## Remotes

Registra nombres en `Shared/Constants/Remotes.luau`.  
`NetworkingService` crea las instancias al iniciar.  
Accede desde cualquier lado con `Shared/Networking/Networking.luau`.

## Dependencias (Wally)

| Paquete | Uso |
|---------|-----|
| Trove | Cleanup de conexiones e instancias |
| Signal | Señales tipadas (servicios) |
| Promise | Async (opcional) |
| ProfileStore | Persistencia server-side |

## Persistencia

- Solo el servidor guarda datos
- `PlayerDataRepository` usa ProfileStore con session locking
- Autosave + `PlayerRemoving` + `BindToClose`
