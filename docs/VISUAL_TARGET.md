# Visual target — GALACTIC FRONTIER

This document is the permanent visual-direction source of truth. The project has no user-supplied hand sketches; the original concept studies below are authored for this project and establish the first approved visual direction.

## Canonical concept studies
- `../art_source/references/player_interceptor.svg` — player fighter silhouette, top view, materials and design language.
- `../art_source/references/enemy_strike_craft.svg` — hostile fighter silhouette and contrasting faction palette.
- `../art_source/references/deep_space_environment.svg` — space lighting, planet, orbital relay and asteroid scale.

These vector studies are the design targets for the prototype. Update them deliberately when the art direction changes; do not silently drift away from their silhouettes and palette.

## Art direction
- Original single-player science-fiction universe with premium indie space-sim presentation, without copying protected designs from other games.
- Player craft: wide swept delta wings, narrow armored central spine, recessed cockpit, separated twin vectoring engines; cool steel/blue palette with restrained amber signals.
- Enemy craft: compact aggressive forward silhouette, short swept wings, dark red-brown armor, red-orange threat lights and hot-core exhaust.
- Space: deep navy-black base, sparse sharp point stars, subtle non-repeating nebula, readable planetary terminators and atmospheric rim, varied irregular asteroids, restrained bloom.
- Coherent PBR materials: painted and bare metal, heat-darkened engine parts, glass, navigation lights, restrained wear, purposeful panel seams and decals.
- Avoid box-only ships, toy-like proportions, arbitrary neon outlines, and decorative lines without physical purpose.

## Technical constraints
- Godot 4.7.2 Forward+; Blender for 3D authoring.
- Target resolution: 1920×1080.
- Performance target: 60 FPS on GTX 1660 / RX 580 class hardware. Use LODs, instancing, sensible material counts, and measured post-processing.
- Free tools and assets only. Verify third-party licenses and record source/license in `THIRD_PARTY_NOTICES.md`.
- Preserve gameplay, flight physics, controls, cameras, collision, and HUD during visual-only work.

## Review checklist
1. Compare every ship directly with its concept study before export.
2. Check silhouette at thumbnail size and from first- and third-person cameras.
3. Inspect materials under neutral light and in the actual space environment.
4. Verify scale, collision, pivots, normals, UVs, LODs, and exhaust direction.
5. Run Godot import and scene-load checks; capture 1920×1080 screenshots.
6. Profile frame time on target hardware; do not claim 60 FPS without measurement.
