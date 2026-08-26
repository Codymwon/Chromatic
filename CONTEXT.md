# Chromatic Domain Context

Chromatic is a 2D optical puzzle game where players manipulate mirrors and prisms to direct split light beams into target sinks.

## Language

### Light & Optics

**Beam**:
The complete directed light path from a light source through all its bounces, splits, and segment children.
_Avoid_: Laser, line, raycast

**Ray Segment**:
A single straight line interval of light of a uniform color between an origin and a collision termination or max distance.
_Avoid_: Ray, vector, beam slice

**Ray Color**:
The chromatic identity of a ray segment (`WHITE`, `RED`, `GREEN`, `BLUE`).
_Avoid_: Tint, hue, shade

**Collider Type**:
The explicit optical identity of an intersected physics body (`WALL`, `MIRROR`, `PRISM`, `SINK`).
_Avoid_: Target class, hit category, body type

**Light Source**:
A fixed emitter on the game board that outputs a continuous white light beam in a fixed direction.
_Avoid_: Emitter, lamp, laser gun

**Mirror**:
A rotatable and draggable optical element with a two-sided reflective surface that reflects incoming light rays.
_Avoid_: Reflector, bounce pad

**Prism**:
A rotatable and draggable optical element that splits incident white light into a three-color fan (Red, Green, Blue) at fixed angles relative to its own rotation.
_Avoid_: Splitter, refractor

**Goal Sink**:
A target receptacle of a specific required Ray Color that must receive a matching light beam to become lit.
_Avoid_: Sensor, receiver, detector, bucket

**Wall**:
An immovable obstacle that absorbs and terminates all incident light rays.
_Avoid_: Barrier, block, obstacle

### Game Mechanics & Interaction

**Facing Normal**:
The outward unit vector representing an optical body's active orientation, computed directly from the node's rotation property.
_Avoid_: Surface normal, physics normal

**Drag Handle**:
The internal central touch target (radius <= 32px) on an optical body used for repositioning (translation) within the combined grab target (>= 48px).
_Avoid_: Body grip, translation handle

**Rotate Ring**:
The outer annular zone (radius > 32px) around an optical body used to adjust its facing angle within the combined grab target (>= 48px).
_Avoid_: Rotation dial, steering ring, angle gizmo

**Halo Line**:
The wider, outer Line2D component of a ray segment rendered with additive blending to produce a colored glow.
_Avoid_: Outer beam, glow aura

**Core Line**:
The narrower, central white Line2D component of a ray segment representing high-intensity light concentration.
_Avoid_: Center ray, inner line

**Dirty State**:
A flag on LevelBase signaling that an optical body has moved or rotated, requiring a retrace of all light beams on the next frame.
_Avoid_: Invalidation bit, recalc flag

**Exclusion RID**:
The physics Resource ID explicitly ignored during a ray query to prevent outgoing rays from immediately colliding with their emitter body.
_Avoid_: Ignore list, self-collision filter

**Glancing Absorption Threshold**:
The incidence cutoff threshold (|dot(d, n)| < 0.05) below which near-tangent rays are absorbed rather than reflected.
_Avoid_: Miss threshold, tangent cut

**Win Hold**:
The continuous duration (0.5 seconds) for which all required goal sinks must be simultaneously lit before triggering level completion.
_Avoid_: Win delay, debounce timer, completion lag

**Victory Modal**:
The overlay interface displayed upon level completion offering replay, stage select, and next-level progression.
_Avoid_: Win dialog, stage end popup

### Architecture & Pipeline

**Sacred Boundary**:
The immutable decoupling boundary separating pure beam tracing logic (`BeamTracer`) from visual representation (`BeamRenderer`) via the `Segment[]` array contract.
_Avoid_: Tracer seam, render split

**Gradle Build Template**:
The Android Gradle project structure installed into the Godot project root to enable Google Play AAB export.
_Avoid_: Custom build wrapper, export plugin
