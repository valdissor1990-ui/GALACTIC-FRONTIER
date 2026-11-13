# Graphics continue slice

## Added
1. **Boost trails** — `EngineThrustFx` spawns GPU trail particles on boost; scales with quality.
2. **Hull heat** — thrust intensity drives `heat` on `hull_fresnel` materials.
3. **Parallax nebula layer** — soft additive billboards (`nebula_billboard.gdshader`) between ship and sky; off when gas clouds disabled (Low).

## Files
- `scripts/vfx/engine_thrust_fx.gd`
- `scripts/environment/parallax_nebula_layer.gd`
- `assets/shaders/nebula_billboard.gdshader`
- `scenes/environment/parallax_nebula_layer.tscn`
- `scenes/environment/open_space_backdrop.tscn`

## NOT RUN
Hold boost for trails + hull glow; look off-axis for soft nebula cards.
