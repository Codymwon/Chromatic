# 0001: Simplified Optical Laws for Deterministic Puzzles

## Context
Physical optics (Snell's law, incidence-dependent refraction, micro-surface physics collision normals) introduce non-linearities, precision drift, and unpredictable beam behavior when players rotate and drag puzzle pieces.

## Decision
1. **Prism Dispersion**: White light hitting a prism splits into three rays (Red at -12°, Green at 0°, Blue at +12°) oriented strictly relative to the prism's node rotation, completely independent of the incident beam's angle of approach. Colored rays pass straight through prisms without deflection.
2. **Mirror Reflection**: Reflection uses the mirror node's own orientation property (`d' = d - 2(d · n)n`) rather than the collision shape's contact normal. Mirrors are two-sided and reflect always; do not check the sign of `(d · n)` except for the glancing cutoff.
3. **Ray Termination**: Goal Sinks and Walls terminate all rays. Sinks verify color match upon termination.

## Consequences
- Puzzle states and beam paths are 100% deterministic and easy for players to reason about mentally.
- Headless unit tests can assert exact mathematical angles and bounce vectors without physics engine jitter or simulation tick discrepancies.
