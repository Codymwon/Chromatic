# 0003: OpenGL Compatibility Renderer and SDR Glow Architecture

## Context
Mobile device performance on Android varies significantly across GPU chipsets. While Vulkan (Forward+/Mobile) offers advanced graphical features, it increases battery consumption and introduces driver instability on budget Android devices. Godot's `rendering/viewport/hdr_2d` is not supported in the Compatibility renderer (it is Forward+/Mobile only).

## Decision
1. **Renderer Lock**: The project is locked to the OpenGL Compatibility renderer for v1.
2. **Primary Glow**: Visual beam glow is primarily produced via additive dual `Line2D` rendering (thicker colored halo line underneath a white core).
3. **Environment Glow**: WorldEnvironment 2D glow is applied strictly in standard dynamic range (SDR) as an optional visual enhancement with an in-game quality toggle. `hdr_2d` is strictly prohibited.

## Consequences
- Guarantees 60 FPS performance and stability across low-end and budget Android hardware.
- Prevents unsupported renderer feature toggles from causing silent visual bugs or performance degradation.
