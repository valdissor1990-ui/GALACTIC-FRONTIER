# Gravitational lens VFX

Quality-aware, screen-space approximation of light bending near a compact mass.

## Production integration

| Path | Role |
|---|---|
| assets/shaders/gravitational_lens.gdshader | Screen UV warp, Einstein-ring emphasis and mild chromatic fringe |
| scripts/vfx/gravitational_lens_fx.gd | Projects up to two visible masses into screen UV and drives the shader |
| scripts/environment/gravity_lens_mass.gd | Registers a lens source and creates a dark core / photon-sphere hint |
| scripts/environment/space_environment.gd | Spawns the production landmark at approximately (-240, 72, -430) |
| scenes/flight/test_flight.tscn | Hosts the full-screen effect |
| scripts/graphics/graphics_quality.gd | Controls effect strength and enablement |

The lens CanvasLayer is layer 2: above screen post-processing (layer 1), below HUD layers 10/11. The effect hides itself when no mass is visible, avoiding a permanent full-screen pass.

## Quality

| Preset | Lens | Strength | Chroma |
|---|---:|---:|---:|
| Low | Off | 0 | 0 |
| Medium | On | 0.58 | 0.0015 |
| High | On | 1.0 | 0.0035 |

## How to test

Run the Full HD visual flight scene on Medium or High and look toward the compact purple/blue core offset to the left of the initial flight path. The starfield and planet limb should warp subtly as the camera approaches. On Low the lens layer must be disabled.

Automated coverage: tests/environment/test_gravitational_lens.gd. The test verifies source registration, camera projection, CanvasLayer ordering and preset enablement.

## Limits

- This is a readable game VFX approximation, not a general-relativistic solver.
- At most two simultaneous masses are evaluated.
- Three screen samples are used for the chromatic split; the pass is hidden when no source is in range.
- Interactive visual review and target-GPU fill-rate profiling remain pending.
