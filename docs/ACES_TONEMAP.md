# ACES Tone Mapping

**Locked mode:** `Environment.TONE_MAP_MODE_ACES`  
**Applied in:** `OpenSpaceBackdrop` (setup + every `apply_quality`)

## Why ACES for GALACTIC FRONTIER
- Filmic contrast fits dark space + bright engines.
- Extreme highlights **desaturate** instead of hard-clipping to white.
- Works with glow/bloom HDR spill on plumes and projectiles.
- SDR-monitor friendly (Godot ACES maps to display range).

## Parameters by preset

| | Low | Medium | High |
|--|-----|--------|------|
| **Mode** | ACES | ACES | ACES |
| **Exposure** | 0.88 | 0.94 | 1.00 |
| **White** | 6.0 | 7.5 | 10.0 |

- **Exposure** — pre-curve brightness. Lower keeps the void dark.
- **White** — headroom before the curve compresses brights. Higher = cyan plumes keep color longer.

Godot also applies an internal ~1.8 scale for ACES before the curve.

## Code path
```gdscript
env.tonemap_mode = Environment.TONE_MAP_MODE_ACES
env.tonemap_exposure = GraphicsQuality.tonemap_exposure()
env.tonemap_white = GraphicsQuality.tonemap_white()
```

Do **not** switch to Reinhard/Filmic/AgX without an explicit art decision — ACES is the project default for open space.

## Related
- Glow HDR: `docs/FSR1_AND_HDR.md`
- Quality tables: `scripts/graphics/graphics_quality.gd`
