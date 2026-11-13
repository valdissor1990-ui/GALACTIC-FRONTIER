# Space detail pass

**Branch:** `grok/graphics-open-world-2025`  
**Goal:** denser, more readable open space without breaking quality presets.

## Sky (`space_starfield_sky.gdshader`)
- 3 star layers (far / mid / near)
- Colored stars + rare warm/cool giants
- Soft fbm nebulae (3 tint colors)
- Galactic plane band + dust lane
- Params driven by `GraphicsQuality.sky_*`

| Preset | density | brightness | nebula | dust | galactic |
|--------|---------|------------|--------|------|----------|
| Low | 1.4 | 1.05 | 0.35 | 0.15 | 0.18 |
| Medium | 2.2 | 1.25 | 0.55 | 0.28 | 0.35 |
| High | 3.0 | 1.40 | 0.75 | 0.40 | 0.50 |

## World geometry (`open_space_backdrop.gd`)
- Main asteroid belt (quality count)
- Inner cluster (~1/4 count)
- Outer debris field (~1/3 count)
- Gas giant **ice ring** (TorusMesh, unshaded alpha)
- Third body: distant **IceWorld** for parallax depth
- Higher planet mesh segments on Med/High

| Preset | main belt | planet segs |
|--------|-----------|-------------|
| Low | 120 | 28 |
| Medium | 280 | 48 |
| High | 420 | 64 |

## Perf notes
- Rocks remain MultiMesh (1 draw call per field).
- Sky is fullscreen sky shader — cost scales with resolution/FSR, not asteroid count.
- Outer debris uses long `visibility_range_end` so it fades, not pops hard.

## NOT RUN
Play `test_flight.tscn`, orbit toward gas giant ring and out through the belt; F10 through presets.


## Художественное ограничение

Плотность объектов не является самостоятельной целью. Не добавлять новые слои звёзд и не увеличивать число астероидов только ради заполнения экрана. Сначала улучшать силуэты, геометрию, масштаб, распределение, материалы и освещение. Общий стандарт — `GRAPHICS_ART_BIBLE.md`.
