# Fauna Combat - Wolf, Snake y Dodge

Documento tecnico del estado actual de combate PvE para `wolf` y `snake`, incluyendo el sistema de `dodge` y los cambios aplicados hoy.

## 1) Arquitectura resumida

- Definiciones por especie: `src/ReplicatedStorage/Shared/Features/<Species>/<Species>Definition.luau`
- Registro y hooks de comportamiento: `src/ServerScriptService/Features/Behaviors/*Behavior.luau`
- Autoridad del combate (server): `src/ServerScriptService/Services/AnimalService.luau`
- Entrada y feedback de combate (client): `src/StarterPlayer/StarterPlayerScripts/Controllers/FaunaController.luau`
- Constantes compartidas: `src/ReplicatedStorage/Shared/Constants/FaunaConstants.luau`

Regla clave: el server siempre decide dano, cooldowns, stun, dodge y estados de IA. El cliente solo manda intencion.

## 2) Wolf (estado actual)

Fuente: `src/ReplicatedStorage/Shared/Features/Wolf/WolfDefinition.luau`

- `speciesId`: `wolf`
- `maxHp`: `40`
- `damage`: `18`
- `detectRangeStuds`: `40`
- `detectRangeNightStuds`: `52`
- `meleeRangeStuds`: `12`
- `attackCooldownSeconds`: `2`
- `attackWindupSeconds`: `0.65`
- `attackAnimationSeconds`: `0.9`
- `moveSpeedStuds`: `14`
- `statusOnHit`: `bleeding` con `0.6` de probabilidad
- `drops`: `fiber x1` con `0.5` de probabilidad
- `aggressiveByDay`: `false` (pasivo en dia, agresivo en dusk/night)

### Hooks de comportamiento Wolf

Fuente: `src/ServerScriptService/Features/Behaviors/WolfBehavior.luau`

- `onAttackTelegraphStart`:
  - Escribe atributos de telegraph (`WolfAttackStartedAt`, `WolfAttackDuration`)
  - Reproduce sonido de growl
- `onAttackTelegraphEnd`:
  - Limpia atributos de telegraph
- `onStunStart` / `onStunEnd`:
  - Llama `WolfModel.setStunnedVisual(model, true/false)`

### Visual de stun del Wolf

Fuente: `src/ReplicatedStorage/Shared/Features/Wolf/WolfModel.luau`

- Durante stun se aplica solo `Highlight` (`StunnedHighlight`)
- No hay estrellas ni orbita
- Al terminar stun, el `Highlight` se destruye

## 3) Snake (estado actual)

Fuente: `src/ReplicatedStorage/Shared/Features/Snake/SnakeDefinition.luau`

- `speciesId`: `snake`
- `maxHp`: `15`
- `damage`: `8`
- `detectRangeStuds`: `25`
- `meleeRangeStuds`: `8`
- `attackCooldownSeconds`: `1.5`
- `attackWindupSeconds`: `FaunaConstants.SNAKE_ATTACK_WINDUP_SECONDS` (`0.42`)
- `attackAnimationSeconds`: `FaunaConstants.SNAKE_ATTACK_TOTAL_SECONDS` (`1.0`)
- `moveSpeedStuds`: `10`
- `statusOnHit`: `poison` con `1.0` de probabilidad
- `drops`: `herb_common x1` con `0.3` de probabilidad
- `aggressiveByDay`: `true`

### Hooks de comportamiento Snake

Fuente: `src/ServerScriptService/Features/Behaviors/SnakeBehavior.luau`

- `onAttackTelegraphStart`:
  - Escribe atributos de telegraph (`SnakeAttackStartedAt`, `SnakeAttackDuration`)
  - Reproduce sonido de ataque
- `onAttackTelegraphEnd`:
  - Limpia atributos de telegraph

## 4) IA, ataque, stun y ventana de reaccion

Fuente principal: `src/ServerScriptService/Services/AnimalService.luau`

### Estado de IA

Estados usados: `idle`, `patrol`, `alert`, `chase`, `attack`, `stunned`.

### Tick de IA

- `AI_TICK_SECONDS = 0.25` (en `FaunaConstants`)
- En cada tick, `processFauna` evalua deteccion, fase dia/noche, melee range y ataque.

### Ventana de reaccion al entrar a melee

- `FAUNA_MELEE_APPROACH_WARNING_SECONDS = 1.2`
- Cuando entra por primera vez al melee range, se activa `approachWarningUntil`
- Mientras la ventana esta activa, no puede golpear
- Si el jugador tarda, luego si puede recibir dano

### Stun al golpear fauna

- `PLAYER_HIT_STUN_SECONDS = 2.2`
- Al pegarle (hit valido) se marca:
  - `stunnedUntil = now + 2.2`
  - estado `stunned`
  - `wasInMeleeRange = false` (para que vuelva a existir ventana al re-entrar)
- Durante stun, la fauna retrocede del jugador a velocidad reducida (`moveSpeed * 0.5`)

### Cancelacion de golpe de fauna por stun en windup

- Si el jugador pega durante el windup del ataque de fauna:
  - el impacto pendiente se cancela
  - se limpia telegraph cuando corresponde
  - no se aplica dano al jugador

## 5) Sistema Dodge (Q / boton)

### Constantes clave

Fuente: `src/ReplicatedStorage/Shared/Constants/FaunaConstants.luau`

- `DODGE_COOLDOWN_SECONDS = 3`
- `DODGE_IFRAME_SECONDS = 0.55`
- `DODGE_MOVE_STUDS = 6`
- `DODGE_MIN_WALKSPEED = 8`
- `DODGE_BLEED_FAIL_CHANCE = 0.55`
- `DODGE_POISON_FAIL_CHANCE = 0.3`

### Flujo client

Fuente: `src/StarterPlayer/StarterPlayerScripts/Controllers/FaunaController.luau`

- Input:
  - Tecla `Q`
  - Boton `DodgeButton` en HUD
- Al ejecutar dodge:
  - Dash lateral hacia la derecha (`DODGE_MOVE_STUDS`)
  - Boost temporal de `WalkSpeed` para sensacion de dash
  - Envia `DodgeEvent` al server
  - Marca cooldown visual del boton
- Feedback:
  - `DodgeResultEvent` muestra toast de `success`, `failed` o `cooldown`

### Flujo server

Fuente: `src/ServerScriptService/Services/AnimalService.luau`

- `DodgeEvent` crea estado por jugador:
  - `dodging = true`
  - `dodgeEndAt = now + 0.55`
  - `lastDodgeAt = now`
- En el momento de impacto de fauna:
  - si esta en iframe, se calcula exito real con `computeDodgeSuccessChance`
  - si exito: sin dano
  - si falla (lento/debuff): recibe dano

### Reglas de fallo por estado

- Si `WalkSpeed < DODGE_MIN_WALKSPEED`, chance de exito = `0`
- `bleeding` puede forzar hasta `55%` de fallo
- `poison` puede forzar hasta `30%` de fallo

## 6) Lo que hicimos hoy (resumen)

Fecha: `2026-06-25`

1. Se ajusto combate del wolf para que no pegue instantaneo al entrar en melee:
   - Se agrego ventana de reaccion de `1.2s`.
2. Se agrego stun al pegarle al wolf:
   - `2.2s` de stun, retroceso y bloqueo temporal de ataque.
3. Se permitio cancelar el ataque del wolf si recibe hit durante el windup.
4. Se agrego feedback visual de stun del wolf en hooks de comportamiento.
5. Se simplifico el feedback visual y se dejo solo brillo (`Highlight`), sin estrellas.
6. Se archivo el change de fauna:
   - `openspec/changes/archive/2026-06-25-slice-07-fauna/`

## 7) Checklist rapido de validacion manual

- Wolf entra en melee y no golpea instantaneamente (espera ventana inicial)
- Si jugador pega rapido, wolf entra en stun y retrocede
- Si jugador pega durante telegraph/windup, ataque del wolf se cancela
- Dodge con `Q` funciona con cooldown
- Dodge puede fallar con `bleeding`/`poison` o baja velocidad
- Visual de stun del wolf muestra solo brillo

