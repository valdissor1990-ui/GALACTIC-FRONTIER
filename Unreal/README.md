# GALACTIC FRONTIER — Unreal project

Target engine: **Unreal Engine 5.8** (`EngineAssociation`: 5.8).  
Windows PC · single-player · offline-first.

Open `GalacticFrontier.uproject` → compile C++ → run content setup script.

## Ported systems (C++)

| Area | Classes |
|------|---------|
| Boot | `UGFGameInstance` |
| Control | `AGFPlayerController` (ESC pause, F10 graphics) |
| Flight | `UGFShipFlightComponent`, `AGFPlayerShipPawn` |
| Combat | weapon / projectile / damageable / targeting |
| **VFX** | **`UGFShipVfxComponent` (Niagara: thrust, boost, muzzle, dust, impact)** |
| Enemy | `AGFEnemyShip` |
| Mission | `AGFMissionDirector` (Silent Relay) |
| Meta | save, catalog, hangar, dialogue M01–M05 |
| Audio / GFX | `UGFAudioSubsystem`, `UGFGraphicsSettings` |
| HUD | `AGFSpaceHUD` |

## Niagara

See **`docs/NIAGARA_VFX.md`**. Setup script creates `/Game/GF/VFX/NS_*` placeholders; author emitters in the Niagara editor (`User.Intensity`, `User.Boost`).

## Automated asset production

After all seven source builders finish, the cloud pipeline keeps the editable multi-part `.blend` files intact and consolidates each exported ship GLB into **one complete StaticMesh with all material slots preserved**. This makes each ship easier to import and assign in Unreal without losing the editable source parts. The validator rejects any ship GLB that does not contain exactly one mesh and one mesh node.



The repository now contains a sequential production/import pipeline:

1. Blender rebuilds the complete seven-ship fleet in sequence using the existing original builders: Player Fighter, Raider Interceptor, Heavy Fighter, Bomber, Cargo Hauler, Frigate and Cruiser. The generated files pass a structural integrity check (mesh geometry, UVs, materials, bounds, GLB structure and preview files) before they replace the tracked source/export files. This is not a visual-quality acceptance test.
2. `scripts/blender/build_space_environment.py` generates a deep-space starfield/nebula backdrop and four original textured planets (ocean, desert, ice and ringed gas giant).
3. `tools/build_unreal_assets.bat` runs the ship builders, fleet validation, space/planet generator, then launches Unreal Editor with the import script.
4. Unreal imports one GLB at a time in this fixed order: **ships → environment props → space backdrop → planets**. The next model starts only after the previous import task has returned and its result has been recorded.
5. Each model is logged. The import report is written to `Unreal/Saved/GFAssetManifests/asset_pipeline_report.json`.

Before first use, compile the C++ project once in UE 5.8.4. Install Blender 4.5 and Unreal Engine 5.8. If either executable is installed in a non-standard folder, set `BLENDER_EXE` and/or `UE_EDITOR_EXE` to its full path before launching the batch file. The project enables Unreal's PythonScriptPlugin and EditorScriptingUtilities for this workflow.

Run `tools/build_unreal_assets.bat` from Windows. Follow the `[GF Setup] PIPELINE` messages in Unreal's Output Log. This automates rebuilding and sequential import; the pre-import check is structural only and does **not** prove visual acceptance or automatically assemble every multi-part ship into its final actor. GLB-to-StaticMesh node mapping, transform conversion and Editor visual validation remain separate acceptance gates.


### Cloud execution (no local Blender required)

The GitHub Actions workflow `.github/workflows/build-3d-assets.yml` runs automatically when Blender production scripts change on the Unreal migration branch. It downloads Blender 4.5.3 on a GitHub-hosted runner, builds all seven ships in order, validates the outputs, generates the space backdrop and four planets, and publishes the validated assets back into the migration branch under `assets/models`, `art_source/ships` and `assets/previews`. It also uploads a 30-day artifact package and writes a build report.

The workflow is intended to remove the need to install or run Blender locally. It does not require a local user command.

**Unreal Editor import and C++ compilation remain separate:** the GitHub-hosted runner does not contain Unreal Engine 5.8.4. The Python import script is prepared, but actual import, shader/material verification, C++ compilation and gameplay testing are not claimed as complete until an Unreal 5.8.4 runner is available.

## Setup

1. Compile in UE 5.8.4 once.  
2. Run `tools/build_unreal_assets.bat` (or use the Editor Python script after generating the space assets).  
3. Author Niagara systems (or use placeholders).  
4. Play `L_FlightTest` — boost, fire, and watch thrusters.  

Runtime is **not** verified in CI from this environment.

## Controls

WASD · arrows · Shift boost · Space brake · LMB fire · T/X target · V camera · F interact · ESC pause · F10 graphics

## Still open

UMG menu/hangar · polished Niagara graphs · production audio · Enhanced Input assets · Windows package · automated tests

Do not delete Godot until gates in `../UNREAL_MIGRATION_PLAN.md` pass.
