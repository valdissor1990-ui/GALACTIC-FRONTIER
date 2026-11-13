# Post-processing and GPU shader notes

**Branch:** `grok/graphics-open-world-2025`  
**Author:** Grok

## Built-in Environment post (Forward+)

| Effect | Open space | Near stations (later) | Notes |
|--------|------------|------------------------|-------|
| ACES tonemap | ON | ON | Holds HDR engines |
| Glow / bloom | ON | ON | Primary “2020s” read for plumes |
| SSAO | OFF default | ON mild | Little contact AO in void |
| SSR | OFF | Optional | Empty sky wastes SSR |
| SDFGI | OFF | Interiors only | Expensive outdoors |
| Adjustment | mild contrast/sat | same | Cheap |

The GraphicsQuality autoload applies each preset directly to the active Environment resource. Project Settings values remain defaults, not the runtime source of truth.

## Custom screen post

- Shader: `assets/shaders/screen_cinematic.gdshader`
- Node: `scripts/vfx/screen_post_fx.gd` (`ScreenPostFx` CanvasLayer)
- Single pass: vignette + chromatic offset (3 screen reads) + contrast/saturation
- **Not** multi-pass blur (expensive). Toggle `enabled_fx` for low-end.

Wire under flight/combat roots:
```text
TestFlight
└── ScreenPostFx (CanvasLayer)
```

## GPU optimization applied

1. **Starfield** — 3,800 base stars plus six chromatic clusters (552 stars); Low/Medium reduce the primary starfield count.
2. **Hull** — `fract` panels instead of per-cell hash; one Fresnel term reused for rim/flash/heat.
3. **Asteroids** — NASA GLB geometry in a route-safe MultiMesh, with Kenney meteor variants; preset changes rebuild instance counts and collision proxies.
4. **Planets** — detailed gas giant, companion worlds, ring layers and a 2K Jupiter map with procedural fallback.
5. **Shadows** — `directional_shadow_max_distance = 280` on key light.
6. **Particles** — exhaust particle counts follow the active quality preset; dust fields scale with particle budget.
7. **Materials** — reuse same shader files; HitFlashFx duplicates only when flashing instances need isolation.

## Rules of thumb (Godot docs)

- Prefer fewer unique materials/shaders (batching).
- Measure with Debugger → Monitors: Draw Calls, 3D Primitives, Video Mem.
- Fill-rate test: smaller window; if FPS jumps a lot, simplify transparent/post.
- Avoid unique ShaderMaterial per rivet; share and vary uniforms.

## Status after integration

- Low/Medium/High presets drive FSR scale, tonemapping, glow, SSAO, star density, asteroid count, dust count and screen post FX.
- Dynamic resolution is wired into the flight scene and adjusts only internal 3D scale.
- Godot CI validates import, flight scenes and Windows export. Target-GPU profiling and interactive visual review remain pending.


## User controls

- Main menu: select GRAPHICS QUALITY to cycle Low / Medium / High.
- During flight: press F10 to cycle the same presets.
- Low and Medium permit adaptive 3D resolution; High keeps native 3D scale.
- UI remains at the configured Full HD viewport resolution; only internal 3D rendering scale changes.
