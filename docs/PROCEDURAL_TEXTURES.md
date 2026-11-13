# Procedural textures

No external art pipeline required. Two paths:

## 1. Shader noise (preferred for planets / rocks)
| Shader | Use |
|--------|-----|
| `planet_gas.gdshader` | Bands, warp, storms |
| `planet_rocky.gdshader` | Terrain layers, craters, ice caps |
| `planet_atmosphere.gdshader` | Additive limb on inverted sphere |
| `rock_surface.gdshader` | Asteroid MultiMesh surface |

Pros: infinite resolution, cheap on GPU, no VRAM bitmaps.

## 2. Baked `Image` / `NoiseTexture2D`
`scripts/graphics/procedural_texture_gen.gd` (`ProceduralTextureGen`):
- `noise_texture2d()` → `NoiseTexture2D`
- `albedo_from_noise()` / `orm_from_noise()` → `ImageTexture`
- `apply_noise_to_standard()` → fills StandardMaterial3D albedo + ORM

Use when a tool or mesh expects real UV textures (hull panels, decals).

## Wired in scene
`OpenSpaceBackdrop`:
- Gas giant → gas shader + blue atmosphere shell
- Rocky / Ice worlds → rocky shader + thin atmo
- Asteroid fields → `rock_surface` material

## NOT RUN
Fly toward GasGiant and RockyWorld in `test_flight.tscn`.
