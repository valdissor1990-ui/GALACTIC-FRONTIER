# Content, assets and final installation size

## Why the current build is about 40 MB

The current Phase 1 artifact is a technical flight prototype, not the content-complete game. It contains:
- Godot runtime/export files;
- GDScript source and project configuration;
- one small test scene;
- primitive placeholder geometry (boxes and spheres) for the ship and distant planet;
- a basic HUD and a few simple materials;
- no large production textures, detailed ship/planet models, voice acting, music library, cinematic video, large environment sets or campaign content.

Therefore a roughly 40 MB Windows artifact is expected at this stage. It is not evidence that content has been lost, nor does it represent the eventual game's size.

## What a 50 GB game would mean

A 50 GB installed game is possible, but size alone is not a quality target. Large installations usually come from many high-resolution textures, detailed models, audio, animation, environments, cinematics and duplicated platform data. Poor compression or unused assets can also inflate a build without improving the game.

For GALACTIC FRONTIER, the target is a substantial, polished single-player space RPG. We should plan content quality and scope first, then measure actual build size. We should not artificially add files just to reach 50 GB.

## Provisional content-size planning bands

These are planning ranges, not promises or hard requirements. They describe possible later content-complete builds, not the current prototype.

| Stage | Illustrative installed size | What it could contain |
|---|---:|---|
| Phase 1 flight prototype | 30–100 MB | Engine/runtime, scripts, primitive test scene, basic HUD |
| First playable vertical slice | 1–5 GB | Several finished ships, one station, one small system, combat effects, UI, sound and music |
| Expanded campaign build | 10–30 GB | More systems, ships, stations, missions, characters, environments, voice and higher-quality assets |
| Large content-rich release | 30–60 GB or more | Extensive campaign/world content, high-resolution asset variants, large audio/animation library and optional high-quality packs |

Actual sizes depend heavily on texture resolution, compression, audio format, asset reuse, platform packaging and whether optional content is shipped separately.

## Asset production policy

- Use original or properly licensed assets only; record licenses and attribution in `THIRD_PARTY_NOTICES.md`.
- Prefer reusable materials, modular environment pieces, texture atlases and level-of-detail variants.
- Use high-resolution assets selectively; provide sensible mipmaps and compressed texture formats for the target renderer.
- Keep source assets and imported runtime assets organized; exclude Blender/Krita working files from the shipped build unless they are required.
- Avoid duplicate texture/audio variants and unused assets in export.
- Profile VRAM, RAM, load times and disk footprint on the target Windows PC before locking quality settings.
- Consider optional high-resolution texture/audio packs only if the game later justifies them.

## Current status

- Current Phase 1 CI artifact: about 39 MB (EXE/PCK artifact archive); this is the prototype package, not the final installed game.
- Production asset pipeline and final size target: NOT DEFINED.
- No 50 GB content is expected until detailed art, audio, world and campaign production phases.
