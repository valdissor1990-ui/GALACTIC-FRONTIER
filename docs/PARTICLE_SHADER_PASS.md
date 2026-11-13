# Particle shader pass (2nd graphics pass)

## Branch audit
- **Our branch:** `grok/graphics-open-world-2025` owns open-space VFX shaders.
- **chatgpt/deep-space-detail-pass:** no `assets/shaders` tree on ref checked.
- **chatgpt/fractal-noise-planet-nebula-pass:** only `gravitational_lens` + `screen_cinematic` (already present; no particle shaders).
- **No duplicate** soft/spark particle spatial shaders found elsewhere → safe to add.

## Added
| File | Role |
|------|------|
| `soft_particle.gdshader` | Soft circular billboard draw |
| `thrust_spark_particle.gdshader` | Hot-core sparks |
| `particle_draw_factory.gd` | Shared mesh+budget helper |
| `muzzle_flash_fx.gd` | One-shot flash |

## Wired
- `LocalSpaceDust` → soft_particle + AABB + quality budget
- `EngineThrustFx` trails/sparks → soft/spark shaders + fixed_fps on Low
- `WeaponSystem` optional `muzzle_flash_path` → `MuzzleFlashFx` in test_flight

## Render opts
- `visibility_aabb` on GPU particles
- amount scaled via `GraphicsQuality.particle_amount_scale()`
- `fixed_fps = 30` when scale < 0.5
- Additive unshaded, no shadows

## NOT RUN
