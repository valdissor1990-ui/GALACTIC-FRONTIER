# Graphics pass — Grok open-world prototype (historical source)

This document records the original Grok branch work from grok/graphics-open-world-2025. The old OpenSpaceBackdrop/test_flight prototype is not the active production environment.

## What was retained

- Original SVG visual targets for player interceptor, enemy strike craft and deep-space environment.
- Quality presets, FSR scaling, HDR/tonemapping controls, dynamic resolution and cinematic post-processing.
- HitFlashFx and engine VFX concepts, selectively reused where they fit the production scenes.
- Gravitational lens shader and source marker, integrated into the current SpaceEnvironment with corrected CanvasLayer ordering and an idle-pass optimization.

## What was superseded

The production Full HD branch uses SpaceEnvironment, detailed GLB hero ships, NASA/Kenney environment assets and a more complete planetary/asteroid field. The old OpenSpaceBackdrop scene is retained only on its source branch; it is not duplicated into the active production scene.

## Validation

Godot CI validates imports, automated tests and Windows export. Visual inspection, combat feel and target-GPU profiling remain separate manual acceptance checks.
