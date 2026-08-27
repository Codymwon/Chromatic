# Mirror & Prism — Development Plan for AI-Assisted Coding (SPEC v1.3)

Save this entire document as `SPEC.md` in your repo root. Every AI session should be pointed at it. It locks decisions, defines architecture, and chunks work into verifiable milestones so the AI never wanders.

---

## 0. Locked Decisions (agree to these before coding)

| Decision | Value |
|---|---|
| Engine | Godot 4.7.2-stable, **GDScript only**, typed |
| Target | Android, landscape, base viewport 1920×1080, stretch mode `canvas_items` (aspect: `keep`) |
| Art | Placeholder shapes/colors until M7 — no asset dependencies |
| Physics | Manual ray queries (`PhysicsDirectSpaceState2D.intersect_ray`) — **not** RayCast2D nodes |

### Renderer decision rationale (locked)
Compatibility is locked for v1: pure-2D content, maximal device reach, mature OpenGL drivers on budget Android hardware, lower battery use. Vulkan-renderer advantages are 3D-only concerns we do not have. Do not propose switching. All visual upgrades must be achieved WITHIN Compatibility: shaders on Line2D, layered lines, PointLight2D 2D lighting, additive sprites, particles — all proven techniques in SDR.

**Gameplay law (put verbatim in every prompt):**
1. Beams are polylines of colored segments, recomputed whenever anything moves (dirty flag) or during dragging.
2. Mirror reflects with `d' = d − 2(d·n)n`, where `n` is the mirror's facing normal (**derived from the mirror's own rotation property**, not the physics shape — more reliable). Mirrors are two-sided; reflect always. Do not check the sign of `(d·n)` except for the glancing cutoff.
3. Prism: only **WHITE** rays split. Output = 3 rays (red/green/blue) leaving at `prism_rotation + {−12°, 0°, +12°}`. Fan depends **only on prism rotation, never on incidence angle** (keeps puzzles solvable and checkable). Colored rays pass through prisms untouched.
4. Walls block all rays. Any ray terminates on a sink body; the sink lights only if the color matches (mismatch = brief red-flash feedback).
5. **Win = all 3 sinks lit simultaneously for 0.5 s** (hysteresis so dragging jitter doesn't flicker the win).
6. Hard cap: 24 interactions per ray chain (loop safety).
7. Prisms only split once per ray (white → 3 colors; those colors never re-split).

Tuning constants file (`core/constants.gd`) so the AI doesn't invent magic numbers:
```gdscript
const MAX_BOUNCES := 24
const PRISM_HALF_ANGLE_DEG := 12.0
const BEAM_WIDTH := 6.0
const ROTATE_SNAP_DEG := 15.0
const WIN_HOLD_TIME := 0.5
const TOUCH_TARGET_MIN := 48.0  # px (combined grab target; 32px is internal move/rotate boundary)
const GLANCING_DOT_THRESHOLD := 0.05
```

---

## 1. Verified Technical Baseline (official sources, checked)

- **Engine Pin**: Pinned to Godot 4.7.2-stable; matching export templates installed.
- **Compatibility Renderer**: Confirmed WorldEnvironment 2D glow works in Compatibility since v4.3, BUT 2D renders in SDR there, and `rendering/viewport/hdr_2d` is Forward+/Mobile ONLY — never use it. The dual-Line2D additive halo remains the PRIMARY glow. Environment glow is optional garnish layered ON TOP, never a replacement, quality toggle kept.
- **Android Export**: Debug keystore auto-generated since v4.3 (no keytool step). The Gradle Build Template ("Project > Install Android Build Template") is REQUIRED because our ship target is a Google Play AAB — AAB requires the Gradle pipeline even for plugin-free apps. Debug-APK sideloading works with or without it.
- **Play Target API**: Preset targetSdk = 36 (Play-mandatory after 31 Aug 2026); plan a bump to 37 before Aug 2027.
- **PhysicsRayQueryParameters2D**: Manual-query pattern is documented/supported; unchanged. `collide_with_areas = true` required (sinks are Area2D).
- **Testing**: Built-in headless runner confirmed sound. Do NOT adopt GUT or gdUnit4 now (reference only: GUT 9.7.0 tracks 4.7; gdUnit4 lags releases).
- **Known-Issue Posture**: No blocking open issues on 4.7.2 for APK export, manual ray queries, pooled Line2D, or ScreenTouch input. Upstream items to monitor, NOT architectural risks: Line2D tile+width-curve artifacts, multi-touch TouchScreenButton timing quirk.

---

## 2. Architecture

```
res://
├── SPEC.md
├── autoload/          game_state.gd, level_manager.gd
├── core/
│   ├── constants.gd
│   ├── beam_tracer.gd     # PURE logic — takes injected cast() callable, unit-testable
│   └── beam_types.gd      # enums: RayColor {WHITE,RED,GREEN,BLUE}, ColliderType {WALL,MIRROR,PRISM,SINK}, structs
├── scenes/
│   ├── main.tscn
│   ├── level/  level_base.tscn/gd, levels.json
│   ├── objects/ light_source, mirror, prism, goal_sink, wall (.tscn+.gd each)
│   ├── fx/     beam_renderer.tscn  (Line2D pool)
│   └── ui/     hud, win_overlay, pause_menu
├── tests/run_tests.gd     # runs headless: godot --headless --script res://tests/run_tests.gd
└── theme/, audio/, assets/
```

**Collision layers**

| Layer | Name | Purpose |
|---|---|---|
| 1 | walls | block light |
| 2 | mirrors | reflect |
| 3 | prisms | split white |
| 4 | sensors | goal sinks (Area2D, `collide_with_areas=true`) |

Draggable play objects go on separate layers (5+) so light rays ignore player bodies; only their dedicated "optical" collision shapes interact with rays.

**BeamTracer contract:** `trace(cast_callable, origin, dir, color, max_bounces) -> Array[Segment]`, where Segment = `{a: Vector2, b: Vector2, color: RayColor}`. Production `cast_callable` wraps the physics query and returns `RayHit` `{point: Vector2, normal: Vector2, collider_type: ColliderType, collider: Object, rid: RID}`. Tests inject a scripted fake. Production tracing builds an exclusion list (the source, and any body already emitted-from) to prevent self-hits.

**Rendering:** pooled `Line2D`s (one pair per segment: additive colored halo + inner white core), additive-blend material, outer soft line + inner white-core line. Recompute only on `mark_dirty()`; drags set dirty every frame.

**Input handling:** Drag controller processes `InputEventScreenTouch` and `InputEventScreenDrag` only. `emulate_touch_from_mouse = true` is the single desktop-test path.

---

## 3. Milestones

Each milestone = one AI task (or 2–3 small ones). "Done when" lines are your acceptance gates — don't proceed until they pass.

### M0 — Shell + Android pipeline ⚠️ do first
Project created (Godot 4.7.2-stable), folders above, git initialized, input map, `project.godot` configured: landscape, 1920×1080, canvas_items stretch (aspect: `keep`), touch→mouse off (`emulate_touch_from_mouse = true`), OpenGL compatibility renderer (mobile-friendly).
**Tasks to include:** Install Android Build Template; enable "Gradle Build" in the export preset; set preset targetSdk = 36.
**Done when:** empty project installs and runs on a real Android device via one-click deploy. Export templates + debug keystore set up. *Do not discover keystore pain at the end.*

### M1 — Light core
`beam_tracer.gd` + `constants.gd` + placeholder `LightSource` emitting a static white ray into empty space; `beam_renderer` draws it.
**Done when:** headless test verifies: infinite ray hits nothing; ray stops on a wall rect; length/bounce cap respected.

### M2 — Mirrors
`wall.tscn` + `mirror.tscn` (rotated rectangle, known-facing-normal). Tracer reflects recursively up to cap.
**Done when:** headless tests cover 90° corner bounce, double-bounce Z-path, glancing-angle case, mirror↔mirror infinite loop terminating at cap. Visual: white beam bounces in-scene correctly.

### M3 — Prism + colors
`prism.tscn`: white ray in → 3 colored rays out per gameplay law 3; renderer tints segments; colored rays pass through prisms.
**Done when:** tests assert fan angles = ±12° about prism rotation regardless of incidence; ray counts/cap; no self-hit on exit (exclusion works).

### M4 — Sinks + win
`goal_sink.tscn` (Area2D, color, lit signal), level_base orchestrates: traces beams → sets lit states → holds 0.5 s → emits `level_completed`.
**Done when:** test with a scripted layout proves simultaneous-all-three wins; removing one beam mid-hold cancels; mismatched color absorbed with feedback flag.

### M5 — Touch interaction
Global drag controller in level_base: combined grab handles ≥48px (32px internal move/rotate boundary); drag body = move; drag ring/knob = rotate (with `ROTATE_SNAP_DEG` toggle button). Controller handles `InputEventScreenTouch`/`ScreenDrag` only (`emulate_touch_from_mouse=true` for desktop testing). Recalc dirty during drag. `reset_level` button.
**Done when:** playable on device; no ray flicker while dragging; snapping feels precise; grabbing never tunnels through objects.

### M6 — Level system
`levels.json` schema wrapped in `{ "version": 1, "levels": [...] }` (source/mirrors/prisms/walls/goals with pos+rot), loader builds scenes and asserts loudly on unknown piece types, `level_manager` autoload: select, unlock persistence (`user://save.cfg`), next-level flow, HUD (level name, reset).
**Done when:** 8 authored levels load purely from data with zero code changes; win advances; progress persists across app restart.

### M7 — Feel/polish
Glow: subtle WorldEnvironment glow layered on top of halo lines, SDR-appropriate, never `hdr_2d`, with in-settings quality toggle (it costs FPS on weak phones); beam pulse animation, particles on lit sink, satisfying win burst, minimal SFX (blip per sink, chord on win), short haptic on win, placeholder theme pass.
**Done when:** 60 fps on your test device with glow on; still playable with glow off.

### M8 — Ship prep
Performance audit (segment count < 40/level, beam recompute < 1 ms), icon, name/package ID, version code, release build is AAB via Gradle (not legacy APK pipeline), re-check developer.android.com/google/play/requirements/target-sdk within 1 month of submission, release keystore warnings documented, test both orientations-lock behavior, app size check.
**Done when:** signed APK/AAB installs from sideload; 20-minute device playthrough crash-free.

---

## 4. Suggested Level Arc (feeds M6)

1. Pre-placed prism already hit by white — adjust prism position so fan lands in sinks (teaches split).
2. Rotate-only mirror feeding the prism (teaches reflection).
3. Move + rotate mirror, prism offset from source line.
4. Wall forces a detour; two mirrors.
5. Colored fan hits a wall partially — position matters.
6. Fan crosses obstacles; tight rotations (snap off).
7. Optional: introduce a sliding wall (animated obstacle, mark_dirty per frame).
8. Finale: mirrored fan, layered blocks. (Later: par-move stars.)

---

## 5. Driving the AI — Prompt Protocol

**Ground rules (append to every session):**
```
Stack: Godot 4.7.2-stable, GDScript only (typed), Android target per SPEC.md.
Follow SPEC.md gameplay law exactly — especially prism/reflect/math rules.
No new addons/plugins/autoloads without approval. No refactors outside scope.
Style: snake_case files, class_name per script, signals named in past tense,
tuning values only from constants.gd.
Deliverables per task: complete files, diff summary, headless-test updates,
and a 5-item manual test checklist for me to run.
First outline your implementation plan; wait for my OK before writing code.
```

**Task card format for each milestone:**
```
GOAL: M2 — mirror reflection
FILES: core/beam_tracer.gd, scenes/objects/{mirror,wall}.tscn+gd
REQUIREMENTS: (paste M2 line + relevant gameplay law items)
ACCEPTANCE: (paste Done-when list, plus "tests/run_tests.gd exits 0")
OUT OF SCOPE: prism, colors, UI
REFERENCE: current beam_tracer.gd (paste it)
```

**Workflow tips:**
- One milestone (or fewer) per conversation; long sessions cause drift.
- **Branch & Test Loop**: `git checkout -b m<N>-<slug>` $\to$ apply $\to$ `godot --headless --script res://tests/run_tests.gd`.
- **Commit Granularity**: Commit in logical chunks (e.g. `M3(core): fan angle math per Law 3 (#14)`, then `M3(tests): fan assertions (#14)`) — not one mega-commit. Include issue number in every message.
- After each delivery: run `godot --headless --script res://tests/run_tests.gd` and open the editor; **paste back any error text verbatim** — AI fixes fastest with real output.
- If AI breaks the spec (e.g., angles depending on incidence), quote the gameplay law line and demand a fix — don't let exceptions accumulate.

---

## 6. Edge Cases Checklist (hand to AI proactively)

- Glancing-angle hits ≈ tangent: reject (absorb or treat as miss) instead of reflecting garbage (`|dot(d, n)| < 0.05`).
- Rays starting inside geometry: rely on `intersect_ray` `hit_from_inner` settings; also offset emission point from source face.
- Fan exit self-hit: exclude prism RID for the 3 emitted rays; emit from a point offset outward.
- Goal overlap: generous sensor radius (≈24px) but ray **terminates** at it.
- Sink unlit flicker during micro-jitter: solved by 0.5 s hold, not per-frame latching hacks.
- Two mirrors perfectly parallel facing: bounce cap saves you — verify visually in tests.

**Risk table**

| Risk | Mitigation |
|---|---|
| Android SDK/export pain late | M0 forces day-one Gradle + AAB device deploy |
| Physics normals unreliable | Normals from object rotation properties |
| Infinite loops hang game | Bounce cap + tests |
| Fiddly touch aiming | 48px combined targets, snap toggle, forgiving sensor sizes |
| Glow tanks old phones | Quality toggle, compatibility renderer SDR glow |

---

## 7. Future-Proofing Rules

- **Sacred Boundary**: The `BeamTracer` $\to$ `Segment[]` $\to$ `BeamRenderer` boundary is SACRED. Visual upgrades (shader beams, 2D light illumination, particles, animated source art) must never touch `BeamTracer` or alter the `Segment` contract.
- **Curved Light Integration**: Curved light (e.g., a gravity well / black hole) IS compatible with the polyline representation via fixed-step integration: deterministic (no delta-time), `MAX_STEPS` cap, coarse steps during drag / refined on release. Any such feature REQUIRES a spec addendum locking its bend law, step constants, and caps BEFORE coding. Design rule: the bend law must be stylized and player-predictable (e.g., constant curvature), never realistic inverse-square.
- **v2 Mechanic Candidates in Cost Order** (do NOT build now):
  1. Colored filters (absorption of non-matching hues)
  2. Curved mirrors (arc-derived normal, still single cast)
  3. Refraction blobs (offset pass-through)
  4. Gravity well (fixed-step integration)

---

## 8. Stretch Backlog (post-v1)

Colored filters (glass passing only one hue), second light source, beam-powered moving platforms, move-par star ratings, hint system (ghost solution overlay), undo stack, level editor, RYB mixing level archetype (overlapping beams form yellow etc.).
