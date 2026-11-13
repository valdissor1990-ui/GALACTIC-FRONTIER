# Rendering Technology Plan — GALACTIC FRONTIER (2026)

## Goal and hardware floor

Target output: 1920x1080, stable 60 FPS, Windows desktop, Godot 4.7.2 Forward+.
Optimization reference GPUs: NVIDIA GTX 1660 (6 GB class) and AMD Radeon RX 580 (4/8 GB class).
The game must remain visually coherent without RTX-only or RDNA4-only features. No 4K rendering or 4K texture requirement.

This plan separates broadly compatible techniques from vendor-specific neural rendering. "AI graphics" is not a free quality switch: most neural methods require supported matrix hardware, SDK integration, motion/depth inputs, driver/runtime dependencies, and additional VRAM.

## Findings: technologies that matter

### 1. Godot's built-in FSR 2.2 — first implementation candidate

Godot 4.7 Forward+ includes FSR 2.2 temporal upscaling through Viewport scaling mode `VIEWPORT_SCALING_3D_MODE_FSR2`. It is vendor-agnostic and can run on supported GPUs from different vendors. It can upscale a lower internal 3D resolution to the 1080p output and also supplies temporal antialiasing.

Recommended test presets at 1920x1080 output:
- Native: scale 1.00, compare TAA and FSR2 native AA.
- Ultra Quality: scale 0.77 (about 1478x832 internal).
- Quality: scale 0.67 (about 1286x724 internal).
- Balanced: scale 0.59 (about 1133x637 internal) only if GPU-bound and image quality remains acceptable.

Start with 0.77, not 0.59. Inspect thin ship details, cockpit wires, emissive particles, HUD edges, rapid camera turns, and transparent effects for ghosting/shimmer. FSR2 at native resolution costs more than TAA; use it only if measured quality justifies the cost.

Godot references:
- https://docs.godotengine.org/en/4.7/classes/class_viewport.html
- https://docs.godotengine.org/en/4.7/tutorials/3d/resolution_scaling.html
- https://docs.godotengine.org/en/4.7/tutorials/3d/3d_antialiasing.html

### 2. Dynamic resolution — do not assume it exists in this Godot version

Godot 4.7 documentation says dynamic resolution scaling is not yet supported. Do not write code that assumes an engine-native dynamic resolution controller. A custom scale controller can be evaluated later, but it must use stable frame-time sampling, hysteresis, cooldowns, and a small set of validated scale steps. Avoid constant scale oscillation.

### 3. FSR 4 / FSR Redstone neural upscaling — optional future path, not baseline

AMD FSR SDK 2.4 includes ML-based FSR Upscaling 4.1.2 and analytical FSR 3.1.6 fallbacks. The ML-based FSR 4.1.2 GPU list is Radeon RX 9000/7000/6000 and select Ryzen APUs. Therefore it is not a universal path for GTX 1660 or RX 580. The SDK supports Vulkan 1.2, but integrating the SDK into Godot is native-renderer work, not a project setting. Keep this out of the baseline until a maintained Godot integration and target-GPU tests exist.

FSR 3.1.6 analytical upscaling/frame generation has broader hardware support than FSR 4 ML, but integration still requires correct motion vectors, depth, reactive/transparency masks and swapchain/frame-pacing work. Godot's built-in FSR2 is the lower-risk first step.

Reference: https://gpuopen.com/amd-fsr-sdk/

### 4. Frame generation — not a substitute for real 60 FPS

Generated frames can improve displayed motion smoothness, but they do not reduce the simulation's CPU work or input latency. FSR Frame Generation 4.0.2 ML is RX 9000-class; analytical FSR 3.1.6 is broader but needs deeper integration. Do not prioritize frame generation for the GTX 1660 / RX 580 floor. First make the game render a stable 60 FPS without interpolation.

### 5. NVIDIA DLSS and neural rendering — hardware-specific, not baseline

DLSS 5 3D-Guided Neural Rendering (announced 2026) is designed for GeForce RTX 50 Series. It is not usable on GTX 1660. DLSS 4.5 Super Resolution requires RTX Tensor hardware and an NVIDIA integration path; it is not a cross-vendor Godot switch.

RTX Neural Texture Compression, Neural Shading, RTX Mega Geometry, and RTX Neural Materials are promising developer technologies, but rely on NVIDIA-specific GPU/SDK paths. They may be explored for optional high-end builds only; do not make project assets or runtime dependent on them.

References:
- https://developer.nvidia.com/blog/whats-new-for-game-developers-dlss-5-with-3d-guided-neural-rendering-nvidia-ace-updates-and-new-rtx-kit-capabilities
- https://developer.nvidia.com/rtx-kit

### 6. High-return techniques that do not require new GPU features

Prioritize these before vendor-specific neural rendering:
- Material consolidation and mesh instancing for repeated ship details; merge only static geometry sharing material and visibility lifetime. Keep hardpoints, damage zones, moving parts and independently culled parts separate.
- Automatic mesh LOD on import, then manual LOD/HLOD for large ships and distant set dressing. Validate silhouette preservation.
- Mipmaps, anisotropic filtering and sensible 1K/2K texture budgets; use packed ORM maps (occlusion/roughness/metallic) where appropriate.
- Decals and trim sheets for panel seams, stencils, warning labels, fasteners and wear instead of hundreds of tiny meshes.
- Normal maps and roughness breakup to add machined surface detail at low polygon cost.
- Instancing for repeated debris, lights, asteroids and distant traffic; use MultiMesh where per-instance independent scene behavior is not needed.
- Occlusion culling in hangars/interiors and other spaces with real occluders. It is less useful in open space.
- Bake static lighting where possible; use a small number of shadow-casting dynamic lights. Use emissive engine elements plus carefully controlled bloom rather than many shadowed point lights.
- Use reflection probes selectively; avoid updating many probes every frame.
- Particle LOD and screen-size-based reduction for exhaust, sparks and debris.
- Texture streaming / distance-aware loading if environment scale grows; monitor VRAM rather than only disk size.
- Use depth prepass and avoid expensive transparent overdraw for large engine glows, nebula cards and shield effects.

Godot references:
- https://docs.godotengine.org/en/4.7/tutorials/3d/mesh_lod.html
- https://docs.godotengine.org/en/4.7/tutorials/3d/occlusion_culling.html
- https://docs.godotengine.org/en/4.7/engine_details/architecture/internal_rendering_architecture.html

## Project-specific priorities

Current project inspection confirms:
- Renderer is already Forward+.
- Engine target is Godot 4.7.2.
- Project display viewport is currently 1600x900; 1920x1080 is the QA/output target and must be tested explicitly.
- The fleet QA report counted 1,555 mesh objects across seven ships and 150,620 triangles. Object/draw-call reduction is a stronger immediate optimization candidate than triangle reduction alone.
- Existing art direction already calls for 1K secondary textures and up to 2K hero assets, restrained PBR and no 4K requirement.

Do not change the default renderer or globally lower output resolution as a speculative optimization.

## Benchmark plan

Run the same deterministic 1080p flight/hangar scenes on:
1. Native 3D scale 1.00 + current AA baseline.
2. FSR2 scale 0.77.
3. FSR2 scale 0.67.
4. FSR2 scale 0.59 only as a lower-bound stress option.

For each run record:
- GPU frame time and CPU frame time separately (median, p95 and worst sustained window).
- Average FPS and 1% low where measurement tooling supports it.
- VRAM and system RAM.
- Draw calls / render primitives where available.
- Screenshot comparisons from identical camera transforms and exposure.
- Temporal artifacts during camera pans, ship roll, fast particles, thin geometry and HUD overlay.
- Loading/import time and package size.

Acceptance:
- Stable 60 FPS target on GTX 1660 and RX 580 is not claimed until tested on physical hardware.
- No preset is accepted solely from synthetic or llvmpipe CI.
- Prefer the highest-quality preset that meets frame-time budget with headroom.
- Keep a native-resolution fallback.
- Report generated frames separately from genuinely rendered frames if frame generation is ever added.

## Recommended order

1. Capture a native 1080p baseline and profile CPU/GPU bottlenecks.
2. Run Godot built-in FSR2 0.77 and 0.67 A/B captures.
3. Reduce mesh-object/draw-call count while preserving material/hardpoint contracts.
4. Configure automatic LOD and add manual HLOD for large ships and hangar contents.
5. Improve PBR via trim sheets, decals, normal/roughness maps and material reuse.
6. Tune lighting, shadows, reflections, volumetrics and particle overdraw based on GPU timings.
7. Consider optional vendor SDK experiments only after the cross-vendor baseline is stable.

## Decision

For GALACTIC FRONTIER, the practical 2026 graphics stack is **Godot Forward+ + built-in FSR2.2 where useful + LOD/HLOD + instancing/material consolidation + efficient PBR + disciplined lighting and particles**. This gives a credible route to better perceived quality on older GPUs without betting the game on RTX-only neural features.
