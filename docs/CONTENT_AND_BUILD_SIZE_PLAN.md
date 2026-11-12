# Content, assets and final installation size

## Why the current build is small

The current 0.1.0 Windows demo archive is about **56.8 MB**. It contains:
- Godot runtime/export files and GDScript project;
- one playable mission, The Silent Relay;
- seven original ship GLBs and their Blender source files in the repository;
- procedural starfield, nebulae, planet and asteroid field;
- combat effects, UI, audio hooks and a small amount of mission content.

This is a deliberately small vertical slice. It is not the content-complete game. A small artifact at this stage is expected and is not evidence that quality work is being skipped.

## What a 50 GB game would mean

A 50 GB installed game is possible, but size alone is not a quality target. Large installations usually come from many high-resolution textures, detailed models, audio, animation, environments, cinematics and duplicated platform data. Poor compression or unused assets can also inflate a build without improving the game.

For GALACTIC FRONTIER, the target is a substantial, polished single-player space RPG. We should plan content quality and scope first, then measure actual build size. **Do not add files or low-value assets just to reach 50 GB.**

## Provisional content-size planning bands

These are planning ranges, not promises or hard requirements. They describe possible later content-complete builds, not the current prototype.

| Stage | Illustrative installed size | What it could contain |
|---|---:|---|
| Current 0.1.0 demo | 50–100 MB | One mission, seven ships, procedural environment, basic progression |
| First expanded playable slice | 1–5 GB | More finished ships, one station, one small system, combat effects, UI, sound and music |
| Expanded campaign build | 10–30 GB | More systems, ships, stations, missions, characters, environments, voice and higher-quality assets |
| Large content-rich release | 30–60 GB or more | Extensive campaign/world content, high-resolution asset variants, large audio/animation library and optional high-quality packs |

Actual sizes depend heavily on texture resolution, compression, audio format, asset reuse, platform packaging and whether optional content is shipped separately.

## Asset production policy

- Use original or properly licensed assets only; record licenses and attribution in `THIRD_PARTY_NOTICES.md`.
- Prefer reusable materials, modular environment pieces, texture atlases and level-of-detail variants.
- Use high-resolution assets selectively; provide sensible mipmaps and compressed texture formats for the target renderer.
- Keep source assets and imported runtime assets organized; exclude Blender/Krita working files from the shipped build unless required.
- Avoid duplicate texture/audio variants and unused assets in export.
- Profile VRAM, RAM, load times and disk footprint on the target Windows PC before locking quality settings.
- Full HD 1920×1080 is the target for the first playable release. Use mostly 1K textures and up to 2K for hero ships/major surfaces; 4K textures are out of scope for now.
- Consider optional high-resolution texture/audio packs only if the game later justifies them.

## Current status

- 0.1.0 Windows artifact archive: approximately 56.8 MB; Windows export and smoke test passed in CI.
- Seven ship classes exist; four are pilotable in the current demo and three are display-only.
- Full HD gameplay and showroom screenshots are captured in CI.
- Full-game size target: NOT DEFINED. Content and quality milestones take priority over disk size.
