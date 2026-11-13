# Graphics quality, dynamic resolution and post-processing

**Autoload:** GraphicsQuality (scripts/graphics/graphics_quality.gd)  
**FPS governor:** DynamicResolution (scripts/graphics/dynamic_resolution.gd)  
**Persisted in:** user://graphics.cfg  
**Controls:** main-menu GRAPHICS QUALITY button; F10 during flight.

## Presets

| Setting | Low | Medium | High |
|---|---:|---:|---:|
| Base 3D scale | 0.59 | 0.77 | 1.0 |
| Upscale mode | Bilinear | FSR 1.0 | FSR 1.0 |
| Shadows | Off | 160 m / 1 split | 280 m / 2 splits |
| SSAO | Off | Off | On |
| Glow intensity | 0.32 | 0.50 | 0.62 |
| Glow bloom | 0.12 | 0.22 | 0.32 |
| Screen post | Off | On | On |
| Asteroids | 80 | 160 | 240 |
| Primary stars | ~2,020 | ~3,074 | 3,800 |
| Dust particles | 840 | 1,680 | 2,400 |
| Planet segments | 48 | 80 | 96 |
| Gravitational lens | Off | On | On |

## Dynamic resolution

The DynamicResolution node is part of the inherited flight scene. It adjusts only internal 3D scale, never the Full HD UI/window resolution. On Low/Medium it lowers scale when measured FPS is below 92% of target and raises it above 108%, with a cooldown to prevent oscillation. High stays at native scale.

Effective scale is clamped to 0.4–1.25. Current max multiplier is 1.0, so the governor does not supersample.

## Runtime consumers

- SpaceEnvironment rebuilds starfield, asteroid MultiMesh/collision proxies, cosmic dust, nebula and galaxy detail, and adjusts planet tessellation.
- ShipVFX scales exhaust particle counts.
- ScreenPostFx enables the cinematic overlay.
- GravitationalLensFx controls lens enablement, strength, chroma and ring boost.
- WorldEnvironment and key light receive tonemapping, glow, SSAO and shadow settings.

## API

GraphicsQuality.set_preset(GraphicsQuality.Preset.HIGH)
GraphicsQuality.cycle_preset()
GraphicsQuality.set_dynamic_scale_mul(0.85)
print(GraphicsQuality.effective_scale_3d())

Godot CI checks the preset table and scene imports. Interactive FPS profiling and image-quality review on the target PC remain pending.
