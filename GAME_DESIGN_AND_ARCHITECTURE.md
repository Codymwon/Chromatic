# Chromatic (Mirror & Prism) — Complete Game Design & Technical Specification (v1.3)

This document provides a comprehensive, end-to-end breakdown of the **Chromatic** game design, mathematical optics, engine architecture, rendering pipeline, touch controls, level progression, edge cases, test harnesses, verified technical baselines, future-proofing rules, and development milestones.

---

## 1. Executive Summary & Vision

**Chromatic** is a 2D optical puzzle game developed for Android (mobile-first) in Godot 4.7.2-stable using typed GDScript. 

The player's goal in each level is to manipulate movable optical components (Mirrors and Prisms) to route and split white light from a fixed Light Source into designated Goal Sinks (Red, Green, and Blue). A level is completed when all required Goal Sinks are simultaneously and continuously illuminated with their matching light colors for a sustained window of 0.5 seconds.

### Core Design Philosophy
- **Deterministic & Mental-Model Friendly**: Optical physics are intentionally simplified so puzzles are intuitive and predictable. Prism dispersion angles and mirror reflection normals depend on node orientations rather than surface collision geometry or angle of incidence.
- **Zero-Allocation Hot Path**: Ray tracing and Line2D pooling run efficiently during touch drag events without runtime garbage collection spikes or physics jitter.
- **Mobile-First Touch Ergonomics**: Interaction is tailored for touchscreens with minimum 48px combined grab targets, distinct 32px internal move/rotate boundaries, and angular snapping.

---

## 2. Technical Stack & Engine Configuration

| Dimension | Specification | Rationale |
|---|---|---|
| **Engine** | **Godot 4.7.2-stable** | Pinned stable release; matching export templates installed |
| **Language** | **GDScript only (strictly typed)** | High development speed, clean syntax, native engine integration |
| **Platform Target** | Android (mobile) | Primary target; desktop testing uses `emulate_touch_from_mouse = true` |
| **Orientation** | Landscape | Ideal layout for 2D puzzle boards and optical path visualization |
| **Base Resolution** | 1920 × 1080 | Standard 16:9 Full HD canvas |
| **Stretch Mode** | `canvas_items` (aspect: `keep`) | Fixed 16:9 aspect ratio scaling with black bars on wider/taller screens |
| **Renderer** | **OpenGL Compatibility** | Maximal reach, mature drivers on budget hardware, lower battery use |
| **Input Handling** | `InputEventScreenTouch` / `InputEventScreenDrag` only (`emulate_touch_from_mouse = true`) | Single unified input pipeline; desktop testing uses built-in touch emulation |

### Renderer Decision Rationale (Locked)
Compatibility is locked for v1: pure-2D content, maximal device reach, mature OpenGL drivers on budget Android hardware, lower battery use. Vulkan-renderer advantages are 3D-only concerns we do not have. Do not propose switching. All visual upgrades must be achieved WITHIN Compatibility: shaders on Line2D, layered lines, PointLight2D 2D lighting, additive sprites, particles — all proven techniques in SDR.

---

## 3. Verified Technical Baseline (Official Sources, Checked)

- **Engine Pin**: Pinned to Godot 4.7.2-stable; matching export templates installed.
- **Compatibility Renderer Glow**: WorldEnvironment 2D glow works in Compatibility since v4.3, BUT 2D renders in SDR there, and `rendering/viewport/hdr_2d` is Forward+/Mobile ONLY — never use it. The dual-Line2D additive halo remains the PRIMARY glow. Environment glow is optional garnish layered ON TOP, never a replacement, with in-settings quality toggle kept.
- **Android Export Pipeline**: Debug keystore is auto-generated since v4.3 (no keytool step). The Gradle Build Template ("Project > Install Android Build Template") is REQUIRED because our ship target is a Google Play AAB — AAB requires the Gradle pipeline even for plugin-free apps. Debug-APK sideloading works with or without it.
- **Play Target API**: Preset `targetSdk = 36` (Play-mandatory after 31 Aug 2026); plan a bump to 37 before Aug 2027.
- **Manual Ray Queries**: `PhysicsRayQueryParameters2D` manual-query pattern is documented/supported; unchanged. `collide_with_areas = true` required (sinks are Area2D).
- **Headless Test Runner**: Built-in headless runner (`godot --headless --script res://tests/run_tests.gd`) confirmed sound. Do NOT adopt GUT or gdUnit4 now (GUT 9.7.0 tracks 4.7; gdUnit4 lags releases).
- **Known-Issue Posture**: No blocking open issues on 4.7.2 for APK export, manual ray queries, pooled Line2D, or ScreenTouch input. Upstream items to monitor, NOT architectural risks: Line2D tile+width-curve artifacts, multi-touch TouchScreenButton timing quirk.

---

## 4. Repository & Project Architecture

```
res://
├── SPEC.md                                  # Locked requirements, milestones, AI protocol (v1.3)
├── CONTEXT.md                               # Canonical domain vocabulary & anti-patterns
├── docs/
│   └── adr/
│       ├── 0001-simplified-optical-laws.md  # ADR: Deterministic optics & fixed dispersion
│       ├── 0002-beam-rendering-and-invalidation.md # ADR: Line2D pool & dirty flag
│       ├── 0003-compatibility-renderer-and-sdr-glow.md # ADR: Compatibility renderer & SDR glow
│       ├── 0004-android-gradle-build-pipeline.md # ADR: Gradle build template & targetSdk 36
│       └── 0005-sacred-beam-tracer-boundary.md # ADR: Pure BeamTracer decoupled boundary
├── autoload/
│   ├── game_state.gd                        # Global player preferences (glow toggle, audio)
│   └── level_manager.gd                     # Level loading, unlock persistence (save.cfg)
├── core/
│   ├── constants.gd                         # Central tuning parameters & thresholds
│   ├── beam_types.gd                        # Enums (RayColor, ColliderType), RayHit & Segment structs
│   └── beam_tracer.gd                       # Pure logic recursive ray tracer (injected cast)
├── scenes/
│   ├── main.tscn                            # Root game entry point
│   ├── level/
│   │   ├── level_base.tscn / level_base.gd  # Level lifecycle, drag controller, win orchestrator
│   │   └── levels.json                      # Versioned authored level definitions
│   ├── objects/
│   │   ├── light_source.tscn / .gd          # Fixed beam emitter
│   │   ├── mirror.tscn / .gd                # Draggable / rotatable two-sided reflective surface
│   │   ├── prism.tscn / .gd                 # Draggable / rotatable chromatic splitter
│   │   ├── goal_sink.tscn / .gd             # Color sensor receptacle with lit animations
│   │   └── wall.tscn / .gd                  # Static or dynamic opaque obstacle
│   ├── fx/
│   │   └── beam_renderer.tscn / .gd         # Pooled dual Line2D beam drawing system
│   └── ui/
│       ├── hud.tscn / .gd                   # Level title, reset button, snap toggle
│       ├── win_overlay.tscn / .gd           # Victory modal (stars, replay, next level)
│       └── pause_menu.tscn / .gd            # Settings (glow quality, audio)
├── tests/
│   └── run_tests.gd                         # Headless automated unit & scenario test runner
└── assets/ / audio/ / theme/                # SFX, shaders, UI themes, and placeholders
```

---

## 5. Collision Layer Matrix & Physics Query Model

### Query Mechanism
Beams do **not** use `RayCast2D` scene nodes. Ray tracing is executed procedurally using direct physics space queries:
`PhysicsDirectSpaceState2D.intersect_ray(PhysicsRayQueryParameters2D)` with `collide_with_areas = true`.

### Layer Allocation
Optical queries and touch interaction areas use strictly isolated collision layers to prevent player drag bodies from intercepting optical light queries.

| Layer Bit | Layer Name | Node Type | Optical Behavior |
|:---:|---|---|---|
| **1** | `walls` | `StaticBody2D` | Opaque. Blocks and terminates all light rays. |
| **2** | `mirrors` | `Area2D` / `StaticBody2D` | Reflective. Two-sided; reflects light hitting either face. |
| **3** | `prisms` | `Area2D` | Splitter. Splits white light into Red/Green/Blue; passes colored rays. |
| **4** | `sensors` | `Area2D` (`collide_with_areas=true`) | Goal Sinks. Terminates ray; verifies color match. |
| **5+** | `touch_targets`| `CollisionShape2D` | Player touch drag handles and rotate rings (ignored by tracer). |

---

## 6. Mathematical Optics & Gameplay Laws

Every optical interaction in the game obeys seven strict laws:

```
                      +-----------------------------+
                      |   Light Source (White)      |
                      +--------------+--------------+
                                     |
                                     v
                        +------------+------------+
                        |       Mirror Hit        |
                        +------------+------------+
                                     |
                         Reflect: d' = d - 2(d·n)n
                                     |
                                     v
                        +------------+------------+
                        |        Prism Hit        |
                        +------------+------------+
                                     |
                 +-------------------+-------------------+
                 |                   |                   |
                 v                   v                   v
            Red Ray (-12°)     Green Ray (0°)      Blue Ray (+12°)
                 |                   |                   |
                 v                   v                   v
          +------+------+     +------+------+     +------+------+
          |  Goal Sink  |     |  Goal Sink  |     |  Goal Sink  |
          |    (Red)    |     |   (Green)   |     |    (Blue)   |
          +-------------+     +-------------+     +-------------+
```

### Law 1: Polyline Ray Tracing & Dirty Invalidation
Light paths are polylines composed of `Segment` records (`{a: Vector2, b: Vector2, color: RayColor}`). Rays are recalculated whenever an optical body moves or rotates (via a signal-driven dirty flag evaluated once per frame in `_process()`).

### Law 2: Mirror Reflection & Facing Normals
- A Mirror reflects incoming light using the standard reflection formula:
  $$\mathbf{d}' = \mathbf{d} - 2(\mathbf{d} \cdot \mathbf{n})\mathbf{n}$$
- **Facing Normal ($\mathbf{n}$)**: Derived directly from the Mirror node's `rotation` property (`Vector2.UP.rotated(mirror.rotation)` or local `+Y`), **not** from the physics collision normal.
- **Two-Sided Reflectivity**: Mirrors are two-sided and reflect light always. Do not check the sign of $(\mathbf{d} \cdot \mathbf{n})$ except for the glancing cutoff.
- **Glancing Angle Absorption**: If $|\mathbf{d} \cdot \mathbf{n}| < 0.05$ (an angle $< \sim 2.86^\circ$ to the mirror plane), the ray is absorbed to avoid floating-point grazing errors.

### Law 3: Prism Chromatic Dispersion & Pass-Through
- **White Ray Splitting**: A white ray entering a Prism splits into **three distinct rays** (Red, Green, Blue) leaving from the prism center at fixed angles relative to the prism's node rotation:
  - **Red**: $\theta_{\text{prism}} - 12^\circ$
  - **Green**: $\theta_{\text{prism}} + 0^\circ$
  - **Blue**: $\theta_{\text{prism}} + 12^\circ$
- **Incidence Independence**: The split fan depends **only on the prism's rotation**, never on the angle of incidence of the incoming beam.
- **Single Split Guarantee**: Prisms only split white rays. Colored rays (Red, Green, Blue) pass straight through prisms in an unaltered straight line without deflection or re-splitting.

### Law 4: Walls & Goal Sink Termination
- Walls absorb and terminate all incoming light rays.
- Goal Sinks absorb and terminate all incoming light rays regardless of color match. If the incoming ray color matches the sink's designated color, the sink enters the **lit** state. If a mismatched color strikes the sink, it emits brief visual feedback (e.g. red flash).

### Law 5: Win Condition & Sustained Hold Hysteresis
- To complete a level, **all required Goal Sinks must be simultaneously lit**.
- The win state must be held continuously for **0.5 seconds (`WIN_HOLD_TIME`)**. If any beam flickers off target during touch dragging, the win timer immediately resets to 0.

### Law 6: Hard Bounce Cap & Loop Safety
- A recursive beam chain is capped at a maximum of **24 interactions (`MAX_BOUNCES`)**. Parallel facing mirrors or cyclical paths safely terminate on bounce 24 without causing infinite loops or frame drops.

### Law 7: Self-Hit Prevention & Positional Nudging
- When a ray bounces off a mirror or splits from a prism, the emitting body's physics RID is added to an exclusion list for that query.
- The new ray origin is nudged $0.5\text{px}$ along the outgoing ray direction to prevent false internal collisions.

---

## 7. Tuning Constants Reference (`core/constants.gd`)

```gdscript
class_name GameConstants

const MAX_BOUNCES: int = 24
const PRISM_HALF_ANGLE_DEG: float = 12.0
const BEAM_WIDTH: float = 6.0
const ROTATE_SNAP_DEG: float = 15.0
const WIN_HOLD_TIME: float = 0.5
const TOUCH_TARGET_MIN: float = 48.0 # px minimum combined target size
const GLANCING_DOT_THRESHOLD: float = 0.05
const RAY_STEP_NUDGE: float = 0.5 # px offset for secondary rays
const MAX_RAY_DISTANCE: float = 3000.0 # px for infinite/open rays
```

---

## 8. Pure Beam Tracer Engine (`core/beam_tracer.gd`)

The `BeamTracer` is a pure logic class decoupled from the Godot scene tree. It receives an injectable `cast_callable`, allowing 100% test coverage via scripted mock fakes.

### Type Definitions (`core/beam_types.gd`)
```gdscript
class_name BeamTypes

enum RayColor { WHITE, RED, GREEN, BLUE }
enum ColliderType { WALL, MIRROR, PRISM, SINK }

class RayHit:
    var point: Vector2
    var normal: Vector2
    var collider_type: ColliderType
    var collider: Object
    var rid: RID

class Segment:
    var a: Vector2
    var b: Vector2
    var color: RayColor
```

### Trace Contract
```gdscript
static func trace(
    cast_fn: Callable,
    origin: Vector2,
    direction: Vector2,
    color: BeamTypes.RayColor,
    max_bounces: int = GameConstants.MAX_BOUNCES,
    exclude_rids: Array[RID] = []
) -> Array[BeamTypes.Segment]:
```

---

## 9. Rendering Pipeline & Visual Effects

### BeamRenderer (`scenes/fx/beam_renderer.tscn`)
- **Dual Pooled Line2D**: For each active ray segment, the renderer pulls a pair of `Line2D` nodes from an instantiated pool:
  1. **Halo Line (Outer)**: Thicker line ($6\text{px}$ width), tinted to the segment color (White, Red, Green, or Blue), rendered with CanvasItem additive blend mode (`BlendMode.ADD`).
  2. **Core Line (Inner)**: Thinner line ($2\text{px}$ width), pure bright white, rendered on top to create an intense laser core.
- **Zero Allocations**: Unused `Line2D` nodes are hidden and recycled on subsequent frames.
- **Dirty-Flag Architecture**: Redrawing occurs only when `is_dirty == true`. Drags set the dirty flag on motion.

### Polish & Visual Effects (M7)
- **WorldEnvironment Glow**: Subtle SDR glow layered on top of halo lines (never `hdr_2d`). Includes an in-settings quality toggle for low-end mobile devices.
- **Sink Illumination FX**: Animated energy rings, pulsing core, and particle bursts upon sustained illumination.
- **Victory Fanfare**: Screen burst, haptic pulse (on Android), audio chord arpeggio, and transition to the Victory Modal.

---

## 10. Touch Interaction & Control Model

Optical bodies (Mirrors and Prisms) support direct single-finger touchscreen manipulation without complex mode switches.

```
       +------------------------------------+
       |   Combined Grab Target (>= 48px)   |
       |       [ Rotate Ring Zone ]         |
       |          (Radius > 32px)           |
       |      +----------------------+      |
       |      |  [ Drag Center Zone] |      |
       |      |     (Radius <= 32px) |      |
       |      |         (Move)       |      |
       |      +----------------------+      |
       |              (Rotate)              |
       +------------------------------------+
```

1. **Combined Grab Target ($\ge 48\text{px}$)**: The total interactive touch shape ensures accessible touch targets ($\ge 48\text{px}$).
2. **Translation (Move)**: Touching within the internal move boundary ($\text{radius} \le 32\text{px}$) and dragging translates the object across the playfield.
3. **Rotation**: Touching the outer annular zone ($\text{radius} > 32\text{px}$) within the grab target rotates the object around its center.
4. **Angle Snapping**: A toggle button on the HUD enables/disables snapping to $15^\circ$ increments (`ROTATE_SNAP_DEG`).
5. **Input Pipeline**: The controller handles `InputEventScreenTouch` and `InputEventScreenDrag` only. Desktop development and testing use Godot's `emulate_touch_from_mouse = true` as the single desktop-test path.

---

## 11. Level Data Schema & Progression System

### `levels.json` Schema
All authored levels are defined in a structured JSON dataset with explicit versioning. The level loader asserts loudly on any unknown object types:

```json
{
  "version": 1,
  "levels": [
    {
      "id": "level_01",
      "title": "Prism Split",
      "source": { "x": 200, "y": 540, "rot_deg": 0 },
      "objects": [
        {
          "type": "prism",
          "x": 600,
          "y": 540,
          "rot_deg": 0,
          "draggable": true,
          "rotatable": true
        },
        { "type": "sink", "color": "red", "x": 1400, "y": 300 },
        { "type": "sink", "color": "green", "x": 1400, "y": 540 },
        { "type": "sink", "color": "blue", "x": 1400, "y": 780 },
        { "type": "wall", "x": 960, "y": 100, "width": 1920, "height": 40 }
      ]
    }
  ]
}
```

### Progression & Persistence (`autoload/level_manager.gd`)
- Validates `version` and asserts on unknown object types during level instantiation.
- Tracks current level index, unlocked level progress, and completion times.
- Persists data to `user://save.cfg` using Godot's `ConfigFile`.
- Flow: `Level Completed` $\to$ `Victory Modal` $\to$ `Next Level` loads next entry from `levels.json`.

---

## 12. Future-Proofing Rules

- **Sacred Boundary**: The `BeamTracer` $\to$ `Segment[]` $\to$ `BeamRenderer` boundary is SACRED. Visual upgrades (shader beams, 2D light illumination, particles, animated source art) must never touch `BeamTracer` or alter the `Segment` contract.
- **Curved Light Integration**: Curved light (e.g., a gravity well / black hole) IS compatible with the polyline representation via fixed-step integration: deterministic (no delta-time), `MAX_STEPS` cap, coarse steps during drag / refined on release. Any such feature REQUIRES a spec addendum locking its bend law, step constants, and caps BEFORE coding. Design rule: the bend law must be stylized and player-predictable (e.g., constant curvature), never realistic inverse-square.
- **v2 Mechanic Candidates in Cost Order** (do NOT build now):
  1. Colored filters (absorption of non-matching hues)
  2. Curved mirrors (arc-derived normal, still single cast)
  3. Refraction blobs (offset pass-through)
  4. Gravity well (fixed-step integration)

---

## 13. Milestone Roadmap & Acceptance Gates

### Milestone 0: Shell & Android Pipeline
- Project initialized in **Godot 4.7.2-stable** (typed GDScript).
- Viewport 1920×1080, landscape, `canvas_items` stretch mode (aspect: `keep`), OpenGL compatibility renderer.
- Input map configured with `emulate_touch_from_mouse = true`.
- **Tasks to include:** Install Android Build Template; enable "Gradle Build" in export preset; set preset `targetSdk = 36`.
- **Done When**: Empty project installs and boots on an Android device via one-click deploy.

### Milestone 1: Light Core & Pure Beam Tracer
- `core/constants.gd`, `core/beam_types.gd`, and `core/beam_tracer.gd` implemented.
- Basic `LightSource` emitting static white beam; `BeamRenderer` drawing dual Line2D.
- Headless test suite in `tests/run_tests.gd`.
- **Done When**: Headless tests pass: open space infinite ray, obstacle termination, max bounce cap respected.

### Milestone 2: Mirror Reflection
- `wall.tscn` + `mirror.tscn` (facing normal derived from node rotation, two-sided reflection).
- Pure tracer recursively evaluates reflections up to bounce cap.
- **Done When**: Tests pass: $90^\circ$ corner bounces, Z-path double reflection, glancing angle absorption, parallel mirror infinite loop termination.

### Milestone 3: Prism & Chromatic Splitting
- `prism.tscn` splitting white rays into $\pm 12^\circ$ and $0^\circ$ fan.
- Colored rays pass through prisms unaltered.
- **Done When**: Tests assert exact fan angles regardless of incidence, single-split rule, zero self-hit on exit.

### Milestone 4: Goal Sinks & Win Condition
- `goal_sink.tscn` with color property and lit signals.
- `LevelBase` monitors sink states, manages $0.5\text{s}$ win hold timer, and emits completion signal.
- **Done When**: Scripted test verifies: all 3 matching sinks lit triggers win; losing a beam resets hold; mismatched ray absorbs without lighting.

### Milestone 5: Touch Interaction & Snapping
- Touch drag controller: move via center handle ($\le 32\text{px}$ radius), rotate via outer ring ($> 32\text{px}$ radius), total target $\ge 48\text{px}$.
- `InputEventScreenTouch`/`ScreenDrag` only (`emulate_touch_from_mouse=true` for desktop).
- Snap toggle ($15^\circ$) and reset level button.
- **Done When**: Playable on mobile device; smooth dragging with zero ray flicker and no tunneling.

### Milestone 6: Level System & Progression
- Versioned `levels.json` loader building full levels from data and asserting on unknown piece types.
- `level_manager.gd` handling level select, progression, and `user://save.cfg` persistence.
- 8 authored tutorial/puzzle levels.
- **Done When**: All 8 levels load and play seamlessly with progress persisted across game restarts.

### Milestone 7: Polish, Audio & Visual Feel
- Subtle SDR WorldEnvironment glow layered over halo lines (never `hdr_2d`), with quality toggle in settings.
- Sink particle bursts and beam pulse animations.
- Minimal SFX (sink hit blip, victory chord) and Android haptic feedback.
- **Done When**: Stable 60 FPS on target Android device with glow enabled.

### Milestone 8: Shipping & Release Preparation
- Performance audit ($< 40$ segments/level, $< 1\text{ms}$ ray recompute).
- Release build is AAB via Gradle (not legacy APK pipeline); re-check target SDK requirements within 1 month of submission.
- App icon, splash screen, package ID, orientation locks, release signing guide.
- **Done When**: Signed release AAB/APK installs and plays 20 minutes crash-free.

---

## 14. Suggested 8-Level Puzzle Arc

1. **Level 1 (The Split)**: Pre-aligned white beam hitting a movable prism. Player adjusts prism position to hit 3 pre-placed sinks (teaches dispersion).
2. **Level 2 (The Reflection)**: White beam hits a rotatable mirror feeding into a fixed prism (teaches mirror reflection).
3. **Level 3 (Reorientation)**: Move and rotate mirror around a central obstacle to reach an offset prism.
4. **Level 4 (Obstacle Bypass)**: Wall blocks direct path; requires 2 mirrors to route around wall before splitting.
5. **Level 5 (Partial Fan Block)**: Colored fan hits a partial barrier; player must reposition prism so all 3 colored rays clear obstacles.
6. **Level 6 (Tight Tolerances)**: Disabling $15^\circ$ snap to solve fine-angle fan routing across narrow gaps.
7. **Level 7 (Dynamic Sliding Wall)**: Moving obstacle moves rhythmically, requiring precise timing or routing through open windows.
8. **Level 8 (Chromatic Finale)**: Multi-mirror network reflecting individual colored rays after splitting to reach separated sinks across the board.

---

## 15. Canonical Domain Glossary (`CONTEXT.md`)

| Domain Term | Canonical Definition | Avoid Terms |
|---|---|---|
| **Beam** | The complete directed light path from a light source through all segments, bounces, and splits. | Laser, raycast, line |
| **Ray Segment** | A single straight line interval of light of uniform color between two points. | Ray, vector, beam slice |
| **Ray Color** | The chromatic identity of a ray segment (`WHITE`, `RED`, `GREEN`, `BLUE`). | Hue, tint, shade |
| **Collider Type** | The explicit category of an optical collider (`WALL`, `MIRROR`, `PRISM`, `SINK`). | Object type, target class |
| **Light Source** | A fixed emitter on the board outputting a white light beam in a fixed direction. | Emitter, laser gun, lamp |
| **Mirror** | A movable optical body with a two-sided reflective surface that reflects incoming light rays. | Reflector, bounce pad |
| **Prism** | A movable optical body that splits white light into Red, Green, and Blue rays at fixed angles. | Splitter, refractor |
| **Goal Sink** | A target receptacle of a specific required Ray Color that must receive matching light to light up. | Sensor, receiver, bucket |
| **Wall** | An immovable obstacle that absorbs and terminates all incident light rays. | Barrier, block, obstacle |
| **Facing Normal** | The outward unit vector representing an optical body's active orientation from node rotation. | Surface normal, physics normal |
| **Drag Handle** | The internal central touch zone (radius $\le 32\text{px}$) used for translation within the combined grab target ($\ge 48\text{px}$). | Body grip, center knob |
| **Rotate Ring** | The outer annular touch zone (radius $> 32\text{px}$) used for rotation within the combined grab target ($\ge 48\text{px}$). | Rotation dial, steering ring |
| **Halo Line** | The wider, outer Line2D component of a segment rendered with additive glow. | Outer beam, glow aura |
| **Core Line** | The narrower, inner white Line2D component representing high-intensity concentration. | Center ray, inner line |
| **Dirty State** | A flag indicating an optical element moved, requiring a retrace on the next frame. | Recalc flag, invalidation bit |
| **Win Hold** | The continuous 0.5s duration all goal sinks must be lit before triggering victory. | Win delay, debounce timer |
| **Glancing Threshold** | The incidence threshold ($|\mathbf{d} \cdot \mathbf{n}| < 0.05$) below which grazing rays terminate. | Miss threshold, tangent cut |
| **Sacred Boundary** | The immutable architectural decoupling contract separating pure BeamTracer logic from BeamRenderer. | Tracer seam, render split |

---

## 16. Architectural Decision Records (ADRs)

- **[ADR 0001: Simplified Optical Laws](file:///home/aadith/development/active-projects/Game/Chromatic/docs/adr/0001-simplified-optical-laws.md)**: Locked fixed-angle dispersion ($\pm 12^\circ$), rotation-derived normals, two-sided mirror reflection, straight-line color pass-through, and ray termination on sinks/walls for 100% deterministic puzzle math.
- **[ADR 0002: Dual Line2D Pooling & Signal-Driven Invalidation](file:///home/aadith/development/active-projects/Game/Chromatic/docs/adr/0002-beam-rendering-and-invalidation.md)**: Locked dual Line2D object pooling (additive halo + white core) and single-frame dirty re-evaluation for zero runtime allocations and maximum low-end mobile performance.
- **[ADR 0003: OpenGL Compatibility Renderer and SDR Glow](file:///home/aadith/development/active-projects/Game/Chromatic/docs/adr/0003-compatibility-renderer-and-sdr-glow.md)**: Locked Compatibility renderer for maximum Android reach and battery efficiency; halo line as primary glow, SDR Environment glow as optional garnish without `hdr_2d`.
- **[ADR 0004: Android Gradle Build Pipeline & Target SDK 36](file:///home/aadith/development/active-projects/Game/Chromatic/docs/adr/0004-android-gradle-build-pipeline.md)**: Locked mandatory Gradle build template for Play Store AAB generation and pinned `targetSdk = 36`.
- **[ADR 0005: Sacred BeamTracer Boundary](file:///home/aadith/development/active-projects/Game/Chromatic/docs/adr/0005-sacred-beam-tracer-boundary.md)**: Locked immutable `BeamTracer` $\to$ `Segment[]` $\to$ `BeamRenderer` interface and fixed-step integration guidelines for future curved light mechanics.

---

## 17. Post-v1 Stretch Backlog

- **Colored Filters**: Tinted glass blocks that absorb all colors except their matching hue.
- **Secondary Light Sources**: Multiple simultaneous white or colored emitters.
- **Beam-Powered Moving Platforms**: Mechanics where sustaining a beam on a sensor activates sliding walls or elevators.
- **Move-Par Star Ratings**: Awarding 1, 2, or 3 stars based on the number of piece adjustments used to solve the level.
- **Color Mixing (RYB/RGB)**: Overlapping colored beams to produce composite colors (Red + Blue $\to$ Magenta, Red + Green $\to$ Yellow).
- **In-Game Level Editor**: Grid-based sandbox editor allowing players to author and share custom puzzles.
