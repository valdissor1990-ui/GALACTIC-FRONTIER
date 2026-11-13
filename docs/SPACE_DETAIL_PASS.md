# Space detail pass — production status

The original Grok notes described a separate OpenSpaceBackdrop scene. The active Full HD branch now uses scripts/environment/space_environment.gd and the SpaceEnvironment scene instead.

## Production detail

- MultiMesh asteroid field with NASA asteroid geometry and procedural fallback.
- Route-safe relay debris cluster with collision proxies.
- Layered starfield, six chromatic star clusters, nebula sheets and distant galaxy.
- Gas giant, companion worlds, atmosphere/cloud layers and three subtle ring sub-bands.
- Interplanetary dust scaled by graphics preset.
- Planet tessellation and star/nebula/galaxy brightness respond to Low/Medium/High.
- Gravitational lens landmark and screen-space distortion, disabled on Low.
- All environment instance counts are adjusted by GraphicsQuality.

## Performance model

- Asteroid and dust fields use MultiMesh rather than one draw call per instance.
- Collision proxies are kept separate from visual MultiMeshes.
- FSR and dynamic resolution change internal 3D scale only; HUD remains Full HD.
- Gravitational lensing is hidden when no mass is visible.

## Validation status

Headless environment tests cover asteroid/collision counts, star/dust population, planet tessellation and lens behaviour. Visual review and GPU profiling remain pending.
