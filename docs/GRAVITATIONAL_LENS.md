# Gravitational lens VFX

Screen-space approximation of light bending near compact masses.

## Pieces
| Path | Role |
|------|------|
| `assets/shaders/gravitational_lens.gdshader` | UV warp + Einstein-ring boost + chroma |
| `scripts/vfx/gravitational_lens_fx.gd` | Projects up to 2 masses to UV, drives shader |
| `scripts/environment/gravity_lens_mass.gd` | Marker + dark core / photon-sphere hint |
| `OpenSpaceBackdrop` | Spawns `GravityAnomaly` at `(-55, 25, -200)` |
| `test_flight.tscn` | Hosts `GravitationalLensFx` |

## Quality
| Preset | Lens | Strength | Chroma |
|--------|------|----------|--------|
| Low | off | 0 | 0 |
| Medium | on | 0.85 | 0.003 |
| High | on | 1.15 | 0.0055 |

## How to test
1. Run `test_flight.tscn` (Medium/High).
2. Fly toward the purple core near the gas giant (`~ -55, 25, -200`).
3. Stars / planet limb should warp; ring brightens near the characteristic radius.

## Adding more masses
Attach `GravityLensMass` (or add to group `gravity_lens_mass`) on any `Node3D`. Set exports / meta:
- `lens_strength` (default 1.0)
- `lens_radius` (UV scale, default 0.22)

## Limits
- Not a full GR solver — gameplay readable distortion only.
- Max **2** simultaneous masses (shader uniforms).
- Disabled on Low for fill-rate cost.

## NOT RUN
