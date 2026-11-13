# Graphics Pass — Open World 2020–2025 baseline

**Branch:** `grok/graphics-open-world-2025`  
**Author:** Grok  
**Status:** Slice 3 — combat feedback shaders

## Shaders

| Shader | Role |
|--------|------|
| `space_starfield_sky.gdshader` | Stars, nebula, dust band |
| `hull_fresnel.gdshader` | Panels, rim, **hit_flash**, heat |
| `engine_plume.gdshader` | Additive thruster glow |
| `relay_pulse.gdshader` | Silent Relay ring |

## Slice 3
- `hit_flash` + `heat` uniforms on hull shader
- `scripts/vfx/hit_flash_fx.gd` listens to Damageable
- Enemy fighter uses red hull shader + HitFlashFx
- Starfield: brighter giants + dust plane

## How hit flash works
1. Damageable emits hull/shield/destroyed
2. HitFlashFx raises `hit_flash` on duplicated ShaderMaterials under Visual
3. Value decays in `_process`

Does not change combat numbers — visual only.

## Preview
`scenes/flight/test_flight.tscn` — shoot enemy, watch orange flash.  
Runtime **NOT RUN** here.

## Next
- Player HitFlashFx wiring in scene (params ready on shader)
- Explosion one-shot on destroyed
- GLB ship materials
