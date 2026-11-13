# FSR 1.0 and HDR tuning (GALACTIC FRONTIER)

**Author:** Grok  
**Branch:** `grok/graphics-open-world-2025`

## FSR 1.0 (AMD FidelityFX Super Resolution 1.0)

### How it works in Godot 4
1. 3D scene renders into a **smaller** internal buffer (`scaling_3d_scale` < 1.0).
2. FSR 1.0 **spatially** upscales that buffer to the full viewport (edge-aware filter).
3. **No temporal history** (unlike FSR 2.2 / TAA): each frame is independent.
4. Available only on **Forward+**. Compatibility falls back to bilinear.
5. At `scale = 1.0` upscaling is effectively disabled (native 3D resolution).

### AMD recommended scale points (Godot docs)
| Label | Scale |
|-------|-------|
| Ultra Quality | **0.77** |
| Quality | 0.67 |
| Balanced | **0.59** |
| Performance | 0.50 |

### Our mapping
| Preset | Scale | Mode | FSR sharpness |
|--------|-------|------|----------------|
| Low | 0.59 | Bilinear | 0.35 |
| Medium | 0.77 | **FSR 1.0** | 0.20 |
| High | 1.00 | FSR 1.0 (idle) | 0.15 |

Sharpness: **0 = sharpest**, **2 = softest** (`Viewport.fsr_sharpness`).

### Practical notes
- FSR1 pairs best with **MSAA or TAA**; pure FSR1 can leave shimmer on thin lines.
- On very weak GPUs, FSR1 cost can exceed bilinear — that is why **Low uses bilinear**.
- Mip bias is adjusted automatically from scale: `-log2(1/scale) + bias`.
- Optional FPS adaptive mul: `DynamicResolution` × base scale.

### Runtime API
```gdscript
var vp := get_viewport()
vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR
vp.scaling_3d_scale = 0.77
vp.fsr_sharpness = 0.2
# or
GraphicsQuality.set_preset(GraphicsQuality.Preset.MEDIUM)
```

---

## HDR parameters (Environment)

We use **ACES tonemap** (film contrast, desaturates extreme brights). ACES outputs SDR-friendly range; good for monitors without true HDR display path.

### Tonemap
| Param | Low | Medium | High | Role |
|-------|-----|--------|------|------|
| exposure | 0.92 | 0.95 | 1.00 | Pre-tonemap brightness |
| white | 5.5 | 6.5 | 8.0 | Headroom before clip |

### Glow / bloom HDR
Glow appears when pixels exceed **HDR threshold** (relative to tonemap white), or when **bloom > 0** pulls dimmer areas in.

| Param | Low | Medium | High | Role |
|-------|-----|--------|------|------|
| intensity | 0.32 | 0.50 | 0.62 | Overall glow gain |
| strength | 0.95 | 1.05 | 1.12 | Level mix strength |
| bloom | 0.12 | 0.22 | 0.32 | Spill below threshold |
| hdr_threshold | 1.00 | 0.85 | 0.72 | Lower = more sources glow |
| hdr_scale | 1.6 | 2.0 | 2.4 | Soft onset around threshold |
| hdr_luminance_cap | 8 | 12 | 16 | Cap so one bolt cannot white-out |

Blend mode: **Softlight**. Levels 2–6 weighted for soft engine/projectile halos.

### Applied by
`OpenSpaceBackdrop.apply_quality()` ← `GraphicsQuality` tables.

### Not display-HDR
True OS HDR output (HDR10) needs separate project/window setup and different tonemapper (e.g. AgX/Reinhard). Current stack targets **SDR monitors with HDR-lit content** (engines brighter than mid-grey).

## NOT RUN
Validate plume bloom and FSR edge quality in `test_flight.tscn` on target GPU.
