# Visual target — GALACTIC FRONTIER

This is the permanent visual-direction reference for the project. It is a production target, not a claim that the current prototype already meets it.

## Source of truth
- The user's original sketches are authoritative for silhouettes, proportions, cockpit placement, wing geometry, engines, and recognizable details.
- Do not invent replacement concepts or approve placeholder geometry as final design.
- Keep original references unchanged in `art_source/references/`; preserve source dimensions and use descriptive filenames.
- Keep editable Blender files in `art_source/blender/`; put Godot-ready exports in `assets/models/`.
- Each production model must have a preview render and a note linking it to its reference image.

## Art direction
- Original single-player science-fiction universe with premium indie space-sim presentation, without copying protected designs from other games.
- Strong readable ship silhouettes. Avoid box-only ships, toy-like proportions, arbitrary neon outlines, and decorative lines without physical purpose.
- Coherent PBR materials: painted and bare metal, heat-darkened engine parts, glass, navigation lights, restrained wear, panel seams, and purposeful decals.
- Layered space depth: sparse point stars, subtle non-repeating nebulae, distant planets with readable terminators and atmosphere, varied asteroids, restrained bloom.
- Planets and stations should feel like physical places, not flat colored spheres or unstructured primitive collections.

## Technical constraints
- Godot 4.7.2 Forward+; Blender for 3D authoring.
- Target resolution: 1920×1080.
- Performance target: 60 FPS on GTX 1660 / RX 580 class hardware. Use LODs, instancing, sensible material counts, and measured post-processing.
- Free tools and assets only. Verify third-party licenses and record source/license in `THIRD_PARTY_NOTICES.md`.
- Preserve gameplay, flight physics, controls, cameras, collision, and HUD during visual-only work.

## Review checklist
1. Compare every ship directly with its approved sketch before export.
2. Check silhouette at thumbnail size and from first- and third-person cameras.
3. Inspect materials under neutral light and in the actual space environment.
4. Verify scale, collision, pivots, normals, UVs, LODs, and exhaust direction.
5. Run Godot import and scene-load checks; capture 1920×1080 screenshots.
6. Profile frame time on target hardware; do not claim 60 FPS without measurement.

## Original sketches pending
The original sketches are not available in the accessible conversation attachments or repository history inspected for this task. The references folder is prepared, but no substitute images have been fabricated. Add the user's original files before approving final ship silhouettes.
