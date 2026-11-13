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

Quality presets for SSAO/Glow live in **Project Settings → Rendering → Environment**, not only on the Environment resource (Godot 4 design).

## Custom screen post

- Shader: `assets/shaders/screen_cinematic.gdshader`
- Node: `scripts/vfx/screen_post_fx.gd` (`ScreenPostFx` CanvasLayer)
- Single pass: vignette + soft chroma + contrast/sat
- **Not** multi-pass blur (expensive). Toggle `enabled_fx` for low-end.

Wire under flight/combat roots:
```text
TestFlight
└── ScreenPostFx (CanvasLayer)
```

## GPU optimization applied

1. **Starfield** — 2 star layers (was 3), cheaper `hash13`, shared `dir.y`.
2. **Hull** — `fract` panels instead of per-cell hash; one Fresnel term reused for rim/flash/heat.
3. **Asteroids** — MultiMesh + lower sphere segments (8×5).
4. **Planets** — 48×24 segments (was 64×32).
5. **Shadows** — `directional_shadow_max_distance = 280` on key light.
6. **Materials** — reuse same shader files; HitFlashFx duplicates only when flashing instances need isolation.

## Rules of thumb (Godot docs)

- Prefer fewer unique materials/shaders (batching).
- Measure with Debugger → Monitors: Draw Calls, 3D Primitives, Video Mem.
- Fill-rate test: smaller window; if FPS jumps a lot, simplify transparent/post.
- Avoid unique ShaderMaterial per rivet; share and vary uniforms.

## Not done yet

- Quality preset enum (Low/Med/High) driving SSAO + ScreenPostFx + particle counts
- Profile captures on target GPU
- Explosion one-shot pool
