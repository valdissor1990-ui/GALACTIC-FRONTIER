# Graphics quality presets

**Autoload:** `GraphicsQuality` → `scripts/graphics/graphics_quality.gd`  
**Persist:** `user://graphics.cfg`  
**Cycle (dev):** action `cycle_graphics_quality` = **F10**

## Presets

| Setting | Low | Medium | High |
|---------|-----|--------|------|
| Directional shadows | OFF | ON, 160 m, 1 split | ON, 280 m, 2 splits |
| Shadow atlas size | 1024 | 2048 | 4096 |
| SSAO | OFF | OFF | ON |
| Glow intensity | 0.28 | 0.45 | 0.55 |
| Screen post | OFF | ON, light chroma | ON, full |
| Asteroids | 80 | 160 | 240 |
| Particle scale | 0.35 | 0.70 | 1.00 |
| Planet segments | 24 | 40 | 48 |

Default: **Medium**.

## API

```gdscript
GraphicsQuality.set_preset(GraphicsQuality.Preset.HIGH)
GraphicsQuality.cycle_preset()
print(GraphicsQuality.get_preset_name())
```

Nodes with `apply_quality(gq)`:
- `OpenSpaceBackdrop` — env, key light shadows, asteroid count at build
- `ScreenPostFx` — enable + vignette/chroma
- `EngineThrustFx` — particle amount

## Shadow optimization notes

- Fill light never casts shadows.
- Low disables key shadows entirely (biggest GPU win in open space).
- Medium uses one cascade and short distance for sharper near ship contact.
- High uses 2 cascades and 280 m — enough for fighter-scale, not system-wide.

## Wiring F10 in a scene

Add a Node with `scripts/graphics/graphics_quality_input.gd`, or from HUD:

```gdscript
if event.is_action_pressed("cycle_graphics_quality"):
    GraphicsQuality.cycle_preset()
```

## NOT RUN

Presets are static tables; FPS impact must be measured on target hardware.
