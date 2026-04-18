# Design System — 4 Cartas BLITZ

Sistema de diseño construido integrando skills:
- **ui-ux-pro-max** — paleta, tipografía, guidelines UX (touch targets, contraste, safe areas).
- **emil-design-eng** — animaciones (timing, curves, interruptibility, press feedback).
- **animate** — patrones (card-flip, toast-stacking, score-reveal, multi-step-flow).
- **ckm-design-system** — arquitectura de tokens 3 capas (primitive → semantic → component).

Descartadas (no aplican a Flutter): `ckm-ui-styling` (Tailwind/shadcn), `ckm-design` (branding web), `ckm-brand`.

---

## Filosofía visual

**Tema**: casino moderno oscuro. Fieltro verde en la mesa principal, navy profundo fuera de juego, acento dorado para acciones premium y azul eléctrico para "tu turno". Cartas con papel crema cálido (no blanco puro — menos fatiga visual).

**Tono**: rápido, claro, táctil. Cada acción del jugador debe tener feedback inmediato (<120ms) y las transiciones de estado importante (volver carta, revelar puntaje, ganador) deben sentirse ceremoniales (480–640ms con curva spring).

---

## Baraja — cartas de poker estándar

Todo el engine y la UI se construyen sobre **baraja inglesa / poker**: 52 cartas + 2 jokers (total 54). Decisión ya plasmada en `lib/engine/models/card.dart`.

- **Palos**: ♥ Hearts, ♦ Diamonds (tinta roja `cardInkRed`) / ♣ Clubs, ♠ Spades (tinta negra `cardInkBlack`).
- **Ranks**: A, 2, 3, 4, 5, 6, 7, 8, 9, 10, J, Q, K.
- **Joker**: tinta violeta `cardInkJoker`, glyph estilizado "★" o "JKR".
- **Valor en scoring**: A=1, 2-10=face, J=11, Q=12, K=13, Joker=-2.
- **Render**: dibujadas con Container + Text (sin assets externos — decisión MVP del plan). Corner rank arriba-izquierda (rotada 180° arriba-derecha opcional), palo grande al centro. Glyphs Unicode: `♠ ♥ ♦ ♣`.

No se usan barajas españolas, francesas alternativas ni símbolos custom.

---

## Arquitectura de tokens — `lib/core/`

### `design_tokens.dart`
Tres capas:

| Capa | Clases | Ejemplos |
|------|--------|----------|
| Primitive | `_midnight900`, `_gold500` | Hex crudo, privados |
| Semantic | `AppColors.primary`, `AppColors.textPrimary` | Roles por función |
| Component | `AppColors.cardFace`, `AppColors.turnGlow` | Ligados a un widget específico |

Además: `AppSpacing`, `AppRadius`, `AppElevation`, `AppCardDims`.

### `motion.dart`
`AppDurations` (micro/fast/base/slow/emphasis), `AppCurves` (standard/enter/exit/emphasized/spring/decelerate), `AppMotion` (presets nombrados: `cardFlip`, `pressFeedback`, `dealOne`, `turnBanner`, `scoreReveal`, `mirrorPulse`). `AppPressScale` para feedback táctil (0.92–0.97).

### `typography.dart`
Escala: `display` 36 / `headline` 28 / `title` 20 / `titleSmall` 16 / `body` 15 / `label` 13 / `caption` 12 / `hero` 48 / `scoreNumeric` 24 (tabular) / `cardRank` 28 / `cardCorner` 14.

### `theme.dart`
Compone `ThemeData` para MaterialApp. Incluye `_FadeSlidePageTransitionBuilder` unificado para go_router.

---

## Paleta semántica

| Rol | Color | Uso |
|-----|-------|-----|
| bgBase | `#111826` | Fondo Scaffold |
| bgDeepest | `#0A0E17` | Fondo gradiente inferior |
| bgTable | `#0E2A22` | Mesa de juego |
| surface | `#1A2236` | Tarjetas UI, paneles |
| surfaceElevated | `#27304A` | Modales, dropdowns |
| primary | `#F5B642` | CTA principal, código de sala, winGlow |
| accent | `#4DA3FF` | Turno del jugador, links, turnGlow |
| success | `#34D399` | Estado OK, mirror correcto |
| danger | `#F04B4B` | Cut, errores, mirror fallido |
| warning | `#F59E0B` | Última ronda, timer bajo |
| cardFace | `#F7F5EF` | Carta revelada |
| cardBack | `#27304A` | Carta boca abajo |
| cardInkRed | `#D63D3D` | Hearts/Diamonds |
| cardInkBlack | `#1F2430` | Spades/Clubs |
| cardInkJoker | `#A78BFA` | Joker |

---

## Sistema de movimiento

| Momento | Preset | Duración | Curva |
|---------|--------|----------|-------|
| Press en carta | pressFeedback | 120 ms | standard |
| Voltear carta | cardFlip | 480 ms | spring |
| Repartir 4 cartas (stagger 80ms) | dealOne | 320 ms c/u | decelerate |
| Banner "tu turno" | turnBanner | 320 ms | emphasized |
| Revelar puntaje de ronda | scoreReveal | 480 ms | emphasized |
| Toast / snackbar | toastEnter | 200 ms | standard |
| Botón Espejito (pulse loop) | mirrorPulse | 900 ms | easeInOut |
| Transición entre pantallas | routeTransition | 320 ms | standard |

**Regla**: ninguna animación bloquea la entrada del usuario. Todas deben ser interrumpibles (usar `AnimationController.stop()` o `AnimatedSwitcher` que acepte cambios mid-flight).

---

## Pantallas — plan visual

### Home
Fondo con gradiente `bgBase → bgDeepest`. Hero logo "4 CARTAS" (48 gold) + "BLITZ" (title). Input de nickname, botón primario "Crear partida" (gold), outlined "Unirse con código". Animación de entrada: fade + slide 4% desde abajo.

### Lobby
Código de sala gigante (`hero` 48, gold, letter-spacing 2, tabular). Animación: `scoreReveal` al aparecer + tap-to-copy con feedback flash. Avatar + nickname de cada jugador; el slot vacío pulsa suave (`mirrorPulse`) hasta que entre el rival.

### Game (mesa principal)
```
┌──────────────────────────────────┐
│        TurnBanner (slide)        │  ← accent si es tu turno, muted si no
│  ScorePanel: R 2/5 · Partida 1/3 │
├──────────────────────────────────┤
│        OpponentHandWidget        │  ← 4 cartas boca abajo, row
│     ┌───┐  ┌───┐  ┌───┐  ┌───┐   │
│     └───┘  └───┘  └───┘  └───┘   │
│                                  │
│        [ Deck ]    [ Discard ]   │  ← central, gold glow si drawn disponible
│                                  │
│     ┌───┐  ┌───┐  ┌───┐  ┌───┐   │
│     └───┘  └───┘  └───┘  └───┘   │
│         PlayerHandWidget         │  ← tus cartas, tap para seleccionar
├──────────────────────────────────┤
│   ActionBar: Cut · Draw · ...    │  ← contextuales según phase/pending
└──────────────────────────────────┘
```
Fondo: `bgTable`. Cartas conservan aspect 2.5:3.5. Mirror button flota esquina inferior derecha, `mirrorPulse` loop mientras haya descarte nuevo.

### PowerPrompt (modal)
Aparece solo para el descartador cuando `pending != null`. Fade + scale 0.96→1.0 (200ms, standard). Copy corto: "Rey: espiá 2 cartas, después decidí si intercambiar".

### MatchResult
Confetti no (descarte por scope), pero hero winner con `winGlow` + scoreboard por partida (tabla semibold). Botón único "Volver al inicio".

---

## Componentes críticos (cuando lleguemos al Step 11)

### `CardWidget`
- Tamaño `AppCardDims.defaultWidth` (72 por defecto) con aspect fijo.
- Radio `AppRadius.card` (14).
- Dos caras: `cardFace` con rank y palo, `cardBack` con patrón dorado suave.
- Flip via `Transform(Matrix4.rotationY)` + `AnimatedBuilder` con `AppMotion.cardFlip`.
- Press feedback: `AnimatedScale` a `AppPressScale.card` (0.97) durante `AppMotion.pressFeedback`.
- Props: `faceDown`, `selected`, `highlighted` (glow accent en tu turno), `disabled`.

### `PlayerHandWidget` / `OpponentHandWidget`
Row de 4 slots con spacing `AppSpacing.md`. Slot vacío (post-mirror success) se encoge con AnimatedSize + fade. Slot extra (post-mirror fail) entra con scale+fade.

### `DeckAndDiscardWidget`
Dos stacks horizontales centrales. Deck con sombra para dar grosor (elevation raised). Discard muestra top card con leve rotación (-3 a 3 deg) para look orgánico.

### `ActionBar`
Row de botones contextuales — aparecen/desaparecen con `AnimatedSwitcher` (fast duration). Mínimo 48px touch target.

### `TurnBanner`
Slide desde arriba + pulse suave de borde (`turnGlow` accent) mientras sea tu turno.

### `MirrorButton`
FAB esquina inferior derecha. Loop `mirrorPulse` solo si `state.lastDiscardRank != null` y ventana abierta (<3s).

---

## Checklist de aplicación (antes de Step 11)

Cuando llegue el momento de construir UI:
- [ ] Todo widget usa tokens de `core/` — prohibido hardcodear hex, px, ms.
- [ ] Todo press interactivo tiene feedback (`AnimatedScale` o `InkWell`).
- [ ] Todo touch target ≥ `AppSpacing.touchTarget` (48).
- [ ] Toda navegación usa la transición compuesta del theme.
- [ ] Toda revelación de carta usa `AppMotion.cardFlip`.
- [ ] Toda notificación usa snackBarTheme (no hardcoded).
- [ ] Test en pantalla pequeña (5") y grande (6.7") — Row de 4 cartas debe caber sin scroll horizontal.
