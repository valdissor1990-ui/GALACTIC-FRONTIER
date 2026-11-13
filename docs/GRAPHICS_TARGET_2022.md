# Graphics target — 2022 high-end PC standard

**Project:** GALACTIC FRONTIER  
**Reference cutoff:** 31 December 2022  
**Product target:** polished high-end 2018–2022 PC presentation at 1920×1080, 60 FPS target  
**Engine:** Godot 4.7.2, Forward+ / Vulkan  
**Status:** acceptance specification; not a claim that the current build already meets it.

## 1. What “2022-level graphics” means

The reference is not path-tracing at any cost. The 2022 high-end bar combined strong art direction, detailed authored assets, convincing physically based materials, coherent lighting, rich effects and stable frame pacing. The 2022 graphics roundups highlighted Horizon Forbidden West, The Callisto Protocol, Portal RTX, Dying Light 2, A Plague Tale: Requiem and others for different strengths. Space-combat references include Chorus (released 2021) and Everspace 2 (early access during 2022; full release later). Their useful lessons are readable ships, strong silhouettes, material response, layered planetary/nebula vistas, debris, engine trails, combat effects and a coherent visual identity—not copying their protected designs.

## 2. Production acceptance matrix

| Area | Minimum acceptance target | Evidence required | Priority |
|---|---|---|---|
| Art direction | One coherent industrial sci-fi language; distinct faction/class palettes; no placeholder primitives in hero shots | Approved style sheet and matched gameplay captures | P0 |
| Player / enemy fighters | Recognizable silhouettes at gameplay distance; layered hull, armor plates, recessed seams, cockpit frame/glass, intakes, engine nacelles, hardpoints, antennas, service panels | Front/side/top/rear/3⁄4 renders; in-game chase and hangar views | P0 |
| Heavy ships / capital ships | Scale-appropriate structure: command bridge, hangars, armor volumes, propulsion clusters, turrets, docking structures; must not look like enlarged fighters | Seven-ship comparison sheet and in-game fly-by | P1 |
| Geometry | Clean normals, bevels on hard edges, no intersecting/floating parts; consolidated static meshes by material/section; named hardpoints and animated parts preserved | Blender validation, GLB bounds, object/triangle/draw-call report | P0 |
| LOD | LOD0 hero, LOD1 mid-distance, LOD2 far silhouette; smooth transitions and no visible popping | Automated distance captures and frame-time profile | P1 |
| Materials | PBR metal/roughness workflow; albedo + tangent normal + ORM + emissive where justified; controlled roughness variation, edge wear and decals; no flat plastic/overbright neon | Material turntable under neutral and gameplay lighting | P0 |
| Textures | Hero ship/environment surfaces up to 2K; secondary assets 1K; mipmaps, anisotropic filtering and platform GPU compression; avoid 4K for this 1080p target | Texture inventory, dimensions, VRAM estimate and mip validation | P0 |
| UVs | Consistent texel density; no unintended overlaps/stretching; mirrored UVs only where material/decals permit | UV checker renders and automated validation | P0 |
| Cockpit | Framed canopy with believable glass, interior silhouette, instrument glow and readable reflections; cockpit camera does not clip | Cockpit screenshots at 1080p, day/night lighting cases | P1 |
| Engines | Distinct nozzle geometry, hot core + soft plume, animated flicker/length under thrust, restrained bloom and heat distortion only where affordable | Boost/idle/turning captures and GPU profile | P1 |
| Planets | High-resolution authored/procedural surface breakup, limb atmosphere, cloud layer with independent motion, terminator/night lights where appropriate; rings with gaps and shadowing | Planet close/mid/far shots, day/night orbit | P1 |
| Nebulae / deep space | Multi-scale volumetric-looking layers, dark dust lanes, star clusters, distant galaxy and parallax depth; preserve black level and contrast | 1080p wide shots and camera movement sequence | P0 |
| Stations / debris / traffic | Silhouette-rich station modules, antennae, lights, windows, docking arms; debris with varied scale/orientation; sparse traffic with navigation lights | Fly-by and approach shots; instance-count report | P1 |
| Lighting | Readable key/fill/rim separation; contact shadows and self-shadowing; no crushed hulls or clipped emissives; use baked lighting for stable large set-pieces where suitable | Neutral lighting turntable + gameplay captures | P0 |
| Reflections / AO / GI | Use screen-space or probe reflections and SSAO/SSIL/SDFGI selectively where supported and visually beneficial; do not enable expensive effects blindly | A/B captures and GPU timing by pass | P1 |
| Combat VFX | Layered muzzle flash, projectile core/trail, impact sparks, shield ripple, hull hit flash, explosion debris/smoke, death breakup; readable at speed | Eight repeatable combat captures | P0 |
| Particles | GPU particles or MultiMesh for high-count debris/dust; bounded lifetimes and overdraw; avoid full-screen opaque smoke | Particle stress scene and GPU timing | P1 |
| Post-processing | ACES/filmic tonemapping, restrained bloom, exposure control, subtle color grade; optional vignette/chromatic aberration only when justified; no permanent blur/grain that hides detail | Before/after 1080p stills and motion test | P1 |
| Anti-aliasing / scaling | Evaluate MSAA/TAA and FSR2/FSR1 options by renderer/device; preserve sharp HUD; native 1080p High preset is reference | Edge/shimmer motion captures and resolution matrix | P1 |
| HUD / UI | Crisp 1080p typography, consistent spacing, hierarchy, localization-safe layout; no overlap/cropping; readable against bright and dark backgrounds | Full-screen UI safe-area and localization captures | P0 |
| Animation | Ship banking/thruster vectoring, moving hardpoints/landing gear where designed, antenna/ring/cloud motion, smooth camera easing; no static showroom-only assets | 30-second continuous gameplay capture | P1 |
| Performance | High preset target 60 FPS at 1080p on declared mid-range PC; frame-time target ≤16.7 ms average with stable pacing; measure 1% lows, GPU/CPU time and VRAM; Low/Medium presets scale density/effects | Repeatable 3×60-second benchmark on named hardware | P0 |
| Reliability | No shader compile stutter in first combat, missing materials, import warnings, visual regressions or renderer fallback | Clean import, warm-up capture, regression CI | P0 |

## 3. Preset policy

| Setting | Low | Medium | High (reference) |
|---|---|---|---|
| Output | 1920×1080 UI; reduced 3D render scale allowed | 1920×1080 UI; balanced 3D scale | Native 1920×1080 3D |
| Ships | LOD1/2 earlier; reduced small decals | Full hero ship; normal LOD | LOD0 hero, full material set |
| Space density | Reduced stars/dust/asteroids | Baseline density | Full authored density, still bounded |
| Shadows | Reduced distance/resolution | Medium distance/resolution | High-quality selected shadows |
| AO/reflections | Off or cheapest supported | Selective | Selective SSAO/SSR/probes where measured |
| Volumetrics | Off / cheap layered shader | Limited | Selective hero volumes only |
| VFX | Reduced particle count/lifetime | Standard | Full combat VFX within budget |
| Post | Tonemap, minimal glow | Tonemap + restrained glow | Full approved grade, restrained glow |
| Target | Stable play on lower-end supported GPU | Balanced | 1080p60 target on declared mid-range PC |

The preset must change already-instantiated world content as well as future spawns. UI stays at output resolution. Never use post-processing to compensate for missing geometry or poor materials.

## 4. Visual review checklist

A visual pass is accepted only when all these views exist at 1920×1080:
1. Main ship: front, side, top, rear, rear three-quarter, close-up.
2. All seven ships: same camera scale and neutral studio lighting.
3. Planet: wide establishing shot, mid-distance, atmosphere/cloud close-up.
4. Space: starfield, nebula/dust, planet + station + debris composition.
5. Combat: idle flight, boost, firing, shield hit, hull hit, explosion, enemy destruction.
6. HUD: dark background, bright planet background, combat clutter, RU and EN.
7. Motion: continuous 30-second capture; inspect temporal shimmer, popping, shader compilation and exposure shifts.

Technical PASS and visual-art PASS are separate. A parser/import/build success is not a visual acceptance. A screenshot capture is not a human playtest.

## 5. Current repository baseline (13 Nov 2026)

The current product branch documents a playable vertical slice, seven original ship GLBs, procedural space landmarks and a Full HD capture pipeline. The seven-ship asset QA reports 1,555 mesh objects and 150,620 triangles total, but explicitly flags visual art acceptance, mesh consolidation, LOD, runtime draw calls and physical GPU performance as not verified. The ship art direction document already sets 1920×1080, Forward+, PBR and 1K/2K texture goals.

PR #90 currently reports Godot CI **success** for commit `edf0b2e01a63e069dd6bbad69d19024071678917`, but the associated gameplay visual-capture workflow is **cancelled**. Therefore there is no current proof that the latest combined branch passes visual capture. PR #91 remains a separate draft; its current change adds mostly identification markings and stencils to the Player Fighter generator, not a full geometry/material detail pass.

## 6. Required execution order — continue until all gates pass

1. Restore and complete Forward+ Vulkan visual capture; inspect PNGs, not only exit codes.
2. Fix hero Player Fighter geometry/material shortcomings: canopy, armor layers, engine/nozzle construction, weapon hardpoints, UVs and PBR maps. Preserve root, scale, orientation and flight attachment.
3. Apply the same material/geometry standards across the other six existing ships; prioritize silhouette and class language, then consolidate meshes.
4. Finish planets, station, asteroid/debris and nebula composition to the visual review checklist.
5. Complete combat VFX, engine trails, shield/hull damage and destruction states.
6. Finish lighting, reflections/AO, tonemapping, antialiasing and quality presets with A/B captures.
7. Add LOD and optimize object count, draw calls, overdraw, shader cost and texture memory.
8. Run clean Godot import, all regression suites, Windows export/smoke test, visual capture and repeatable performance benchmark.
9. Review every required screenshot and a continuous gameplay capture; record unresolved defects. Do not mark final until every P0 gate passes and P1 gates are either passed or explicitly justified.

## 7. Sources and reference basis

- DSOGaming, “Best PC Game Graphics of 2022” (29 Dec 2022): examples of authored lighting, high-fidelity environments, particle effects and selective ray-traced GI/AO.
- Digital Foundry’s 2022 graphics selection (reported 28 Dec 2022): Horizon Forbidden West, The Callisto Protocol and Portal RTX; highlights detail, lighting, animation and particles.
- Tom’s Guide, “Best games of 2022”: Horizon Forbidden West’s volumetric fog, detailed surfaces and animation.
- PC Gamer, Everspace 2 review: layered space vistas, dust, wreckage, planetary rings, installation lights, bloom and screen-space GI; 4K performance on RTX 3080 was reported by the reviewer.
- Tom’s Guide, Chorus review (7 Dec 2021): space-combat reference for metallic ship highlights, art direction and the risk of visually empty space.
- Godot 4.x renderer documentation: Forward+ is the desktop high-feature renderer; Mobile/Compatibility have different feature and performance limits. Select effects by renderer support and measured cost.

This is a project-specific 2022-quality target, not a promise to reproduce the most expensive ray-tracing showcase on arbitrary hardware. The game must prioritize art direction, authored assets, material quality, lighting and stable 1080p performance.
