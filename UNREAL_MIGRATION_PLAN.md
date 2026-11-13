# GALACTIC FRONTIER — Unreal Engine migration

Status: migration started, not yet playable.
Target: Unreal Engine 5.8.4 stable, Windows PC, single-player, offline-first.
Working branch: `chatgpt/unreal-migration-ue5.8`.

## Safety and source of truth

- This branch is isolated from `main`; do not merge or delete the Godot project during migration.
- The Godot project remains a read-only reference until the Unreal vertical slice passes acceptance.
- Reuse existing Blender source files, GLB ships, textures, story canon, mission definitions, audio and UI references. Do not recreate assets that already exist.
- Keep the original GALACTIC FRONTIER setting and gameplay intent. Do not copy protected Freelancer assets or designs.
- No paid plugins, assets, subscriptions, backend services, telemetry or multiplayer dependencies.
- Any third-party asset or code must be license-checked and recorded in `THIRD_PARTY_NOTICES.md`.
- Never report an Unreal build or runtime test as passing unless it was actually run with the target engine.

## Why UE 5.8.4

UE 5.8.4 is the current stable UE 5.8 hotfix. UE 5.9 is only a preview build and is not the migration baseline. Keep the engine association pinned to 5.8 until a separately reviewed stable upgrade is available.

## Existing game scope to preserve

The Godot prototype currently defines:
- Windows 1920x1080 target and a single-player offline game.
- The Silent Relay vertical slice: travel, two combat zones, six enemy waves, return to carrier.
- Flight with inertia, acceleration, braking, boost, keyboard rotation, mouse look, chase and cockpit cameras.
- Target lock/clear, scan, primary energy weapon, projectiles, hull, shields and damage.
- Pilot profile, credits, ship unlocks, modules, contract progression and story flags.
- Local save/checkpoint flow and menu/hangar/contract UI.
- Seven existing ship source models and their GLB exports.

The authoritative story and mission documents remain in `docs/CANON_STORY_UNIFIED.md`, `docs/CAMPAIGN_STORY.md`, `docs/NARRATIVE_BIBLE.md` and related existing docs. Grok must identify any conflicts before code migration.

## Work split

### ChatGPT — implementation and integration
1. Maintain the isolated Unreal branch and project scaffold.
2. Build the Unreal C++ foundation and project settings.
3. Port systems in dependency order: input/configuration, flight model, cameras, damage/shields, weapons/projectiles, save/profile, mission flow, UI/audio.
4. Import and validate existing GLB assets and preserve Blender sources.
5. Produce a playable Unreal vertical slice and automated validation where feasible.
6. Review Grok's inventory and reconcile omissions without blindly copying code.

### Grok — independent audit and migration specification
1. Audit the current Godot source and assets, including the integration branch.
2. Produce a complete system-by-system migration matrix with source paths, behavior, dependencies, data, acceptance tests and Unreal destination.
3. Identify Godot-only assumptions and required Unreal equivalents.
4. Audit all existing ship/environment assets for import readiness, scale, pivots, materials, UVs, collision and LOD needs.
5. Verify story/mission canon and save-data requirements.
6. Write findings only to `docs/UNREAL_GROK_AUDIT.md`. Do not edit Unreal C++ files, `.uproject`, project config or shared asset generators; ChatGPT owns those files to avoid conflicts.
7. Do not create replacement ships or duplicate systems. Reuse existing work.

## Migration order and acceptance gates

### Gate 0 — project foundation
- Unreal project opens in UE 5.8.4.
- C++ module builds successfully in the actual engine toolchain.
- Git ignores generated Unreal files but tracks source/config/content.

### Gate 1 — Player Fighter vertical slice
- Import the existing Player Fighter Mk.I GLB and textures.
- Correct scale, orientation, pivot, collision and material assignments.
- Flight controls preserve inertia, boost, braking and keyboard/mouse behavior.
- Chase and cockpit cameras work.
- Weapon, projectile, target lock, damage, hull and shield loops work.
- Visual review shows the ship clearly under representative space lighting.

### Gate 2 — playable mission
- Recreate The Silent Relay mission flow and encounter sequencing.
- Preserve rewards, checkpoints, failure/retry behavior and local save progression.
- No regression in controls or gameplay state.

### Gate 3 — full project migration
- Migrate remaining ships, environment, VFX, audio, menus, hangar, contracts, story and settings.
- Port and replace Godot-specific CI/tests with Unreal-compatible checks.
- Verify clean checkout, editor open, packaged Windows build and manual playtest.

## Not accepted as completion

- A bare empty Unreal project.
- Imported meshes without working materials/lighting.
- A document-only migration.
- A successful static scan presented as a successful build.
- Removing Godot before the Unreal build is accepted.

## Current status — implementation in progress

Implemented in C++ source (not yet compiled in the Unreal toolchain):
- Project/game mode scaffold and Windows-oriented project configuration.
- Player ship Pawn with chase/cockpit cameras and keyboard/mouse bindings.
- Inertial flight, acceleration, braking, boost reserve/recharge, angular inertia, mouse look and collision sweep movement.
- Hull/shield damage, shield regeneration delay and destroyed-state handling.
- Primary energy weapon, projectile actor, hit damage and cooldown.
- Target acquisition/clear using range and forward cone.
- Enemy fighter approach/strafe/retreat AI, vertical evasion, predictive lead targeting and firing behavior.
- Ported catalogs for four flyable ships, five upgrade modules and three contracts; local profile supports ship purchase/selection, module purchase, contract unlock/selection and story flag persistence. Selected ship stats and module multipliers are applied to the player pawn.
- Initial The Silent Relay flow: relay interaction, three waves at relay, wreck interaction, three waves at wreck, return-to-carrier completion and 5000-credit reward.
- Local pilot SaveGame data with schema field, migration hook and backup slot.
- Native HUD with velocity, hull, shields, boost, target and mission stage.
- Editor Python setup script imports existing ship/environment GLBs, inventories every imported StaticMesh path, flags multi-mesh sources, creates a flight-test map and spawns PlayerStart plus a mission director. It may assign a uniquely identified enemy mesh to the director. It does not yet assemble complete multi-node ships, assign the Player Fighter to the pawn, or verify imported asset paths/materials/transforms in the Editor.

Not yet verified:
- C++ compilation against the installed Unreal Engine 5.8 toolchain.
- GLB import output, scale, axis, pivots, materials and collision in the editor.
- Runtime possession, flight feel, weapon hits, enemy balance, mission completion and save recovery.
- Windows packaged build.

The migration is not accepted yet. Do not remove Godot source or merge to main.
