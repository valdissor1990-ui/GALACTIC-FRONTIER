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

The repository now contains a sequential production/import pipeline:

1. `scripts/blender/build_space_environment.py` generates a deep-space starfield/nebula backdrop and four original textured planets (ocean, desert, ice and ringed gas giant).
2. `tools/build_unreal_assets.bat` runs that Blender generator, then launches Unreal Editor with the import script.
3. Unreal imports one GLB at a time in this fixed order: **ships → environment props → space backdrop → planets**. The next model starts only after the previous import task has returned and its result has been recorded.
4. Each model is logged. The report is written to `Unreal/Saved/GFAssetManifests/asset_pipeline_report.json`.

Before first use, compile the C++ project once in UE 5.8.4. Install Blender 4.5 and Unreal Engine 5.8. If either executable is installed in a non-standard folder, set `BLENDER_EXE` and/or `UE_EDITOR_EXE` to its full path before launching the batch file. The project enables Unreal's PythonScriptPlugin and EditorScriptingUtilities for this workflow.

Run `tools/build_unreal_assets.bat` from Windows. Follow the `[GF Setup] PIPELINE` messages in Unreal's Output Log. This automates generation and sequential import; it does **not** yet prove visual acceptance or automatically assemble every multi-part ship into its final actor. GLB-to-StaticMesh node mapping, transform conversion and Editor visual validation remain separate acceptance gates.

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
