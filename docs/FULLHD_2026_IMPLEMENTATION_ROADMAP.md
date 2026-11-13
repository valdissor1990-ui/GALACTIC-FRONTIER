# Full HD 2026 — implementation roadmap

This roadmap turns the technical audit dated 2026-11-13 into small, verifiable repository changes. It is a production plan, not a claim that every target is already implemented.

## Accepted project constraints

- Godot 4.7.2-stable, GDScript, Windows single-player, offline-first.
- Free tools and assets only; every third-party asset needs a license record.
- Native design viewport: 1920×1080.
- Forward+ is the product renderer. Compatibility captures are not visual acceptance evidence.
- No direct pushes to protected/base branches; work lands through focused PRs.
- Report parser/import, headless tests, rendered screenshots, performance tests and human playtest as separate evidence classes.

## P0 — correctness and Full HD foundation

| Order | Work | Acceptance evidence |
|---|---|---|
| 1 | Full HD project viewport and UI anchor audit | 1920×1080 screenshots; UI safe-area checks |
| 2 | Forward+ visual capture in CI | Capture logs identify Forward+ / Vulkan; native PNGs inspected |
| 3 | Projectile swept collision | Regression test with a fast projectile crossing a thin target in one physics tick |
| 4 | Seed all gameplay RNG sources | Same seed produces identical encounter and environment layouts |
| 5 | Ship mesh consolidation and LOD0/1/2 | Per-ship GLB report: mesh/material/triangle budgets; visual comparison |
| 6 | Limit projectile lights and scope SSAO to interior scenes | Scene inspection plus Forward+ captures |
| 7 | RU/EN localization foundation | Translation catalog, fallback test, Cyrillic font coverage |

## P1 — strongest visual improvement

1. PBR ship texture sets: albedo, tangent-space normal, ORM (AO/roughness/metallic), emissive.
2. Blender high-to-low baking, UV density and overlap validation.
3. Shared Godot material template and per-ship material masks.
4. ACES tone mapping, controlled glow, MSAA/TAA evaluation and a restrained grading LUT.
5. Engine plume, shield impact and hull damage visual states.
6. Planet atmosphere and baked surface maps.

Texture targets: 2K ship sets, no 4K fighter maps, no more than three texture sets per ship, mipmaps and GPU compression. Do not claim texel-density or VRAM compliance until measured from exported assets/runtime.

## P2 — world simulation and campaign architecture

- Convert the campaign into data-driven MissionDefinition resources and a reusable MissionRunner.
- Keep story flags in the persistent pilot profile, not flight/combat scripts.
- Seed system generation, asteroid placement and enemy decision randomness.
- Add station set-pieces, seeded NPC traffic, AI LOD and economy tables.
- Expand the current three contract loops into the canon M01–M05 campaign spine, then acts II–IV.

## P3 — quality-of-life and extension

- Settings menu, controller support and accessible render presets.
- Data-only mod support only after save compatibility is stable.
- Terrain3D and branching dialogue tooling only when a concrete mission needs them.

## Current verified baseline and known gaps

- The project already has three contract/system entries, local saves, seven ship GLBs and a playable vertical slice.
- The campaign director is still a large orchestration script; it is not yet a generic data-driven mission runner.
- The ship asset pipeline recently gained UV generation/validation, but actual textured PBR maps and runtime material quality remain NOT VERIFIED.
- Runtime FPS, frame time and VRAM on GTX 1660 / RX 580 class hardware remain NOT VERIFIED.
- CI captures previously used Compatibility/OpenGL even though the product project uses Forward+. This branch switches capture commands to Forward+ Vulkan; CI must prove the runner can render it before the change is accepted.

## First implementation slice in this branch

1. Adopt Grok's unified canon and preserve the original M01–M05 mission sheets.
2. Add validated persistent story-flag storage to PlayerProfile.
3. Set the project viewport to Full HD and switch visual capture to Forward+ Vulkan.
4. Run Godot CI and inspect the new screenshot artifact.
5. Continue with swept projectile collision and the Blender mesh/LOD budget as separate changes after the first validation.

## Definition of done

Each implementation PR must state its base/head commit, changed files, test run IDs, visual artifact links, and unverified items. No PR is merged automatically. A green CI badge is not a substitute for inspecting the relevant output.
