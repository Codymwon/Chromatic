# 0002: Dual Line2D Pooling and Signal-Driven Beam Invalidation

## Context
Rendering dynamic multi-segment laser beams on mobile targets with the OpenGL compatibility renderer requires high rendering performance without incurring frequent shader compilation overhead or garbage collection spikes from allocating nodes per frame.

## Decision
1. **Rendering**: `BeamRenderer` manages a reusable object pool of dual `Line2D` nodes per segment (an outer thicker colored halo line with additive blending + an inner thinner white core line).
2. **Invalidation**: Interactive bodies emit a `transformed` signal during translation or rotation. `LevelBase` marks `is_dirty = true` and retraces all beams once per frame during `_process()`, minimizing duplicate ray queries during rapid touch event bursts.

## Consequences
- Zero per-frame node allocations/deallocations during dragging.
- Broad compatibility across low-end mobile GPUs without custom shader compilation quirks.
