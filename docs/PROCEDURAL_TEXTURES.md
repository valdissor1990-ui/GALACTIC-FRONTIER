# Procedural textures and fractal noise

The current implementation lives primarily in `scripts/environment/space_environment.gd`.
Older references to standalone `planet_gas.gdshader`, `planet_rocky.gdshader`,
`planet_atmosphere.gdshader`, `rock_surface.gdshader` and
`ProceduralTextureGen` describe a planned architecture, not files present in
this repository snapshot. Do not treat those names as implemented resources.

## Current implementation

| System | Current source | Noise / detail |
|---|---|---|
| Nebula layers | `_add_nebula()` | Value noise, normalized fBm, one domain-warp pass, ridged fBm filaments |
| Nacreon gas giant | `_build_companion_worlds()` | Authored Jupiter albedo blended with warped procedural bands and storm ridges |
| Aurelia rocky/ocean planet | `_create_planet_texture()` | FastNoiseLite Simplex fBm, separate ridged Simplex layer, cellular modulation and fine detail |
| Nacreon moon | Inline shader in `_build_companion_worlds()` | Grid-cell crater placement, crater rims and terrain noise |
| Distant galaxy | `_build_distant_galaxy()` | Existing multi-scale value-noise cloud field and spiral-arm mask |

## Quality budgets

`GraphicsQuality.procedural_noise_octaves()` is the common octave budget:
- Low: 3 octaves
- Medium: 4 octaves
- High: 5 octaves

Lacunarity is 2.05. Gain is held in the 0.48–0.52 range. The nebula and gas-giant shaders stop their fixed maximum loop at the selected octave count; the CPU planet bake uses the same selected octave count for its main FastNoiseLite fBm.

## Important visual caveat

The 2K authored Jupiter surface is retained and now blended with the procedural gas bands/storm layer. The CPU-baked Aurelia texture is still a single albedo image; a production PBR pass should add baked normal and ORM maps, validated UVs and mip/VRAM budgets. This noise pass does not claim those PBR tasks are complete.

## Validation

Automated quality tests cover the Low/Medium/High octave settings, lacunarity and gain range. The Godot parser/import and Forward+ Vulkan screenshots must still pass before the change is accepted visually. CPU/GPU frame-time measurements on a physical GTX 1660/RX 580 class GPU remain separate acceptance gates.
