# Ship Art Direction — GALACTIC FRONTIER

## Current production priority

Ship art is the active production gate. Mission content and environment expansion are paused until the player fighter and Raider interceptor pass visual review.

## Visual target

Target a polished 2018–2020 AAA-era real-time game presentation at Full HD (1920×1080). The goal is strong art direction, readable silhouettes and convincing materials—not 4K assets or maximum polygon counts:
- Distinct, readable silhouettes at gameplay distance and convincing construction when viewed close-up.
- Layered hard-surface forms: primary hull, secondary armor, recessed seams, access hatches, vents, heat exchangers, actuators, hardpoints and fasteners.
- Purposeful cockpit glazing and framing, readable engine architecture, weapon mounts and navigation/sensor hardware.
- PBR materials with controlled roughness/metalness variation, subtle micro-surface detail and restrained emissive elements.
- Lighting that reveals form without crushing the hull into black or clipping emissive surfaces into flat neon shapes.
- Performance-conscious geometry and materials suitable for Godot Forward+.
- Texture budget: generally 1K for small/secondary assets and up to 2K for hero ships and major environment surfaces. Do not author 4K textures for the first playable release.
- Capture and review gameplay at 1920×1080. Target stable 60 FPS on a reasonable mid-range Windows gaming PC; profile before increasing geometry, texture size or post-processing.
- Prefer detail from silhouette, layered geometry, material breakup, decals, lighting and restrained effects over oversized textures or excessive mesh density.

This is a quality target, not a claim that the project already has AAA production values.

## Fleet identity

### Player Fighter Mk.I
- Friendly, disciplined aerospace-industrial language.
- Midnight ceramic/titanium hull, cool cyan identification lights, panoramic cockpit, twin ion engines and paired forward energy cannons.
- Strong central fuselage with swept wings and readable wing/engine separation.

### Raider Interceptor Mk.I
- Must not reuse the player fighter mesh or merely apply a red tint.
- Narrow armored spine, split delta wings, twin tail booms, triple recessed ion drives, exposed weapon hardpoints and vermilion hostile IFF marks.
- Dark obsidian ceramic and titanium armor, red identification accents and restrained blue plasma cores.

## Acceptance gate before returning to mission/environment work

1. Blender source files, Godot-ready GLBs and high-resolution studio previews exist for each ship.
2. Inspect front, side, top, rear-three-quarter and close-up views. Confirm no overlapping or misplaced parts, floating details, broken normals, transparent-material artifacts or clipped silhouette.
3. Confirm player and Raider silhouettes are immediately distinguishable without relying on color.
4. Import both GLBs into Godot 4.7.2 and validate scale, orientation, material preservation and static-mesh stability.
5. Capture both ships in-game at chase-camera distance and in a close inspection view. The ship must remain a focal object, not a tiny shape at the edge of the frame.
6. Tune exposure, key/rim/fill lighting, bloom and engine emissives so armor detail remains visible.
7. Run the Godot parser/import and Windows export smoke tests after asset integration.
8. Human interactive Windows playtest remains a separate required step and must never be marked complete by headless CI.

## Current implementation

- Player Fighter Mk.I remains generated from scripts/blender/build_player_fighter.py.
- Raider Interceptor Mk.I has a separate generator at scripts/blender/build_enemy_interceptor.py.
- .github/workflows/blender-fleet-assets.yml builds both editable Blender files, GLBs and studio previews, then publishes generated assets to the development branch.
- The enemy scene now references assets/models/ships/enemy_fighter.glb, not the player model plus a red overlay.

## Status

The separate Raider asset pipeline is implemented in source. Blender execution, generated previews, Godot import, and in-game visual acceptance are pending CI and inspection. No ship is approved as final yet.
