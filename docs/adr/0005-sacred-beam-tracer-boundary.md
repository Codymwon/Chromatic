# 0005: Sacred BeamTracer Boundary and Future-Proofing Rules

## Context
Adding visual enhancements (custom shaders, 2D lighting, emitter particle animations) or future mechanics (curved light, gravity wells) could inadvertently bleed rendering dependencies into the physics/logic tracing engine or introduce non-deterministic frame-rate dependent ray paths.

## Decision
1. **Sacred Boundary**: The interface `BeamTracer.trace(...) -> Array[Segment]` is strictly decoupled from `BeamRenderer` and scene nodes. Rendering enhancements must never alter `BeamTracer` or the `Segment` data contract.
2. **Curved Light Compatibility**: Any future curved light features must use deterministic fixed-step numerical integration (no delta-time, `MAX_STEPS` cap, coarse steps during drag / refined on touch release) with stylized, predictable mathematical curvature rather than inverse-square physics.
3. **v2 Mechanics Order**: Future mechanics must follow the agreed complexity sequence: colored filters $\to$ curved mirrors $\to$ refraction blobs $\to$ gravity wells.

## Consequences
- Unit tests remain completely independent of scene graphics and rendering context.
- Guarantees puzzle determinism across all platforms and frame rates.
