# Star Citizen → GALACTIC FRONTIER (Godot 4)

We study **design principles**, not CIG proprietary code. Goal: the same *feel* of scale and scalable detail on a free stack.

Sources (public): Digital Foundry planet/gas tech focus; CIG graphics settings descriptions (Object Detail, View Distance, Gas Clouds, Fog, Planet Clouds, Shader Quality); community render-pipeline notes.

## What Star Citizen actually does (relevant bits)

| Pillar | SC approach | Why it reads as “premium” |
|--------|-------------|---------------------------|
| **Hierarchical scale** | Object containers + streaming: planet / station / POI nested | Macro silhouette stays while micro detail loads near player |
| **LOD policy** | Object Detail = LOD switch distances (+ tessellation on high) | Same asset looks denser up close without paying far away |
| **View distance** | Separate Object View Distance slider | Controls draw horizon for clutter |
| **Volumetrics** | Solar-scale gas (voxel/froxel), planet clouds at half/quarter res | You fly *into* medium; quality scales with cost |
| **Atmosphere** | Limb + distant fog; later height-aware planetary fog | Planets are spheres *with air*, not painted balls |
| **Materials** | PBR + detail textures + POM on high Shader Quality | Hull/terrain read as manufactured/organic up close |
| **Quality axes** | Independent: textures, shadows, fog, gas, clouds, post | Player tunes bottleneck, not one blurry “Low” |

## What we **cannot** port 1:1
- Object Container Streaming / 64-bit zone graph
- Planet Tech terrain + Substance tiling library
- Houdini→voxel solar gas with full lit raymarch
- CIG Vulkan path / DLSS Transformer menu

## What we **do** implement in GF

| SC idea | GF implementation |
|---------|-------------------|
| Macro → meso → micro | Sky (macro) → FogVolume gas + planets (meso) → MultiMesh rocks / relay / lens (micro) |
| Object View Distance | `object_view_distance()` scales `visibility_range_end` on fields & POI |
| Object Detail | `planet_segments()`, asteroid counts, particle scale already in presets |
| Gas Clouds quality | `gas_cloud_enabled()` + density/size; `FogVolume` at gas giant |
| Local fog quality | Environment fog density tied to preset (optional depth cue) |
| Shader Quality | Procedural planet/rock shaders; hull fresnel; lens off on Low |
| Upscaling | Existing FSR / `scaling_3d_scale` ladder |
| Post quality | Bloom / AgX / lens / flare tables |

## Preset mapping (SC vocabulary → GF)

| Preset | View dist | Gas cloud | Shadows | Tonemap |
|--------|-----------|-----------|---------|---------|
| Low | 0.55× | off | off | Filmic |
| Medium | 1.0× | on, medium density | 160 m | ACES |
| High | 1.35× | on, denser | 280 m | AgX |

## Next SC-inspired slices (not all done)
1. Multi-mesh LOD shells (far impostor count vs near dense)
2. Hero ship detail layer (panel POM-like in shader)
3. Nested “containers”: sector root streams belt/POI when player enters radius
4. Half-res friendly volumetrics only on Forward+

## Runtime
Changes ship as NOT RUN until playtest on `test_flight.tscn`.
