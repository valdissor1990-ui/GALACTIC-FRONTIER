# Graphics quality, dynamic resolution, bloom

**Autoload:** `GraphicsQuality` (`scripts/graphics/graphics_quality.gd`)  
**FPS adaptive:** `scripts/graphics/dynamic_resolution.gd`  
**Persist:** `user://graphics.cfg`  
**Cycle:** F10 → `cycle_graphics_quality`

## Presets

| | Low | Medium | High |
|--|-----|--------|------|
| 3D scale | 0.59 | 0.77 | 1.0 |
| Upscale mode | Bilinear | FSR 1.0 | FSR 1.0 |
| Shadows | OFF | 160 m, 1 split | 280 m, 2 splits |
| SSAO | OFF | OFF | ON |
| Glow intensity | 0.32 | 0.50 | 0.62 |
| Glow bloom | 0.12 | 0.22 | 0.32 |
| HDR threshold | 1.0 | 0.85 | 0.70 |
| Screen post | OFF | ON | ON |

Default: **Medium** (scale 0.77 ≈ FSR “Ultra Quality”).

## Dynamic resolution

1. **Preset base scale** — `Viewport.scaling_3d_scale` from table above.  
2. **Optional FPS loop** — attach `DynamicResolution`:

```gdscript
# e.g. under TestFlight
var dr := DynamicResolution.new()
dr.target_fps = 60.0
add_child(dr)
```

On Low/Medium, if FPS < 90% of target → lower `dynamic_scale_mul` (floor 0.65).  
If FPS > 108% → raise toward 1.0. High stays at full internal scale.

Effective scale = `clamp(base_scale * dynamic_scale_mul, 0.4, 1.25)`.

## Bloom (Environment glow)

Built-in Forward+ glow (not a second fullscreen blur):

- Levels 2–6 weighted for soft engine/projectile halo  
- `glow_bloom` + `glow_hdr_threshold` drive HDR spill  
- Blend: Softlight; strength ~1.05  

Tuned via `OpenSpaceBackdrop.apply_quality()`.

## API

```gdscript
GraphicsQuality.set_preset(GraphicsQuality.Preset.HIGH)
GraphicsQuality.cycle_preset()
GraphicsQuality.set_dynamic_scale_mul(0.85)
print(GraphicsQuality.effective_scale_3d())
```

## NOT RUN

Measure FPS / 3D resolution on target GPU before locking defaults.
