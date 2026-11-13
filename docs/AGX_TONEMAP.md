# AgX tonemapper (Godot 4.4+)

**Preset High** uses `Environment.TONE_MAP_MODE_AGX`.  
Medium stays ACES; Low stays Filmic.

## Why AgX for GALACTIC FRONTIER
- Bright **cyan/orange engine plumes** and weapon bolts keep hue longer.
- Highlights **roll toward white** instead of ACES mid-highlight hue shift.
- Closer to modern Blender / Unity / UE experimental defaults for emissive scenes.
- Path toward **display HDR** (Godot 4.7): AgX was reworked for variable EDR; ACES/Filmic `white` is SDR-oriented.

## Godot behaviour
| Item | Detail |
|------|--------|
| Available since | Godot **4.4** |
| Cost | ≈ ACES after curve optimization (~1.05 ms ref); was slower on exact curve |
| `tonemap_white` | **Ignored** on classic AgX (fixed ~**16.29**, Blender match) |
| `agx_white` / `agx_contrast` | Added in later 4.6+ builds; we set them if present |
| Mobile | Historically weak dynamic range; Forward+ is our target |

## Project mapping

| Preset | Mode | Exposure | Notes |
|--------|------|----------|-------|
| Low | Filmic | 0.90 | Perf |
| Medium | ACES | 0.94 | Default cinematic |
| **High** | **AgX** | **1.05** | Hue-safe engines + grade |

High also bumps adjustment contrast/sat slightly (AgX is more neutral out of the box).

## Code
```gdscript
env.tonemap_mode = Environment.TONE_MAP_MODE_AGX
env.tonemap_exposure = 1.05
# optional (4.6+):
# env.tonemap_agx_white = 16.29
# env.tonemap_agx_contrast = 1.05
GraphicsQuality.apply_tonemap_extras(env)
```

## A/B tip
F10 cycles presets. Compare Medium (ACES) vs High (AgX) on the same engine plume — watch for orange→yellow shift (ACES) vs clean desat to white (AgX).

## NOT RUN
Confirm AgX enum exists on the project’s Godot 4.7.2 build and that plumes still bloom correctly under fixed white ~16.29.
