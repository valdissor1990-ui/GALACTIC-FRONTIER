# Unreal source and asset-pipeline audit — 2026-11-14 (corrected)

Scope: source and asset-pipeline review of the Unreal migration branch `chatgpt/unreal-migration-ue5.8`. Blender 4.5.3 generation and structural validation have been executed on GitHub Actions. Unreal Header Tool, Unreal Build Tool, Editor import, runtime playtest and packaged build have not been run because no Unreal Engine 5.8.4 runner is connected.

## Confirmed state from the current setup script

- The Editor script now runs a deterministic sequential queue: `assets/models/ships` → `assets/models/environment` → `assets/models/space` → `assets/models/planets`. Each synchronous import task is inventoried before the next model starts; failures are recorded and do not silently stop the remaining queue.
- Cloud build run 43524316351 completed successfully with Blender 4.5.3 on a GitHub-hosted Ubuntu 24.04 runner. All seven ship generators completed; the source geometry/UV/material/bounds gate passed 7/7; each editable multi-part `.blend` was retained while its exported GLB was consolidated to exactly one mesh and one mesh node with all material slots preserved. The space generator exported one backdrop plus four planet GLBs. The validated outputs were committed to this migration branch under `art_source/ships`, `assets/models/ships`, `assets/models/space`, `assets/models/planets` and `assets/previews`. The local Windows launcher was not run.
- The Unreal Editor pipeline is configured to write `Unreal/Saved/GFAssetManifests/asset_pipeline_report.json` with each imported model's source, destination, imported objects, StaticMesh paths and status. The completed Blender structural report is committed at `assets/models/ships/fleet-build-validation.json`; it records per-ship polygon counts, source mesh-object counts, materials and dimensions. The single-mesh export contract is recorded at `assets/models/ships/single-mesh-report.json`. These reports check generated asset structure, not final visual quality in Unreal.
- It records imported object paths and lists StaticMesh assets per GLB.
- The import gate now checks every source independently: all imported object paths must load; every model must produce at least one StaticMesh; and each ship GLB must have exactly one source mesh node and exactly one imported StaticMesh. Violations are marked `failed`, not merely logged as warnings.
- The machine-readable report now includes source mesh-node count, imported StaticMesh count, expected count, object-load status, per-model validation status, total validated count, failed source list and an overall pass/fail result. Stage summaries use the same validation status.
- The Editor script now separately loads and type-checks all four exact ship soft-object paths used by `GFGameCatalog` (player fighter, interceptor, heavy fighter and bomber). The result records the expected and actual object paths and marks the catalog gate failed if any path is missing or is not a `StaticMesh`. These paths are still assumptions until this check is executed inside Unreal Editor.
- Every single-mesh GLB (ships, backdrop and single-mesh planets/environment props) now receives a deterministic object name based on its source filename inside its destination folder. The importer refuses to overwrite an existing conflicting target, records rename outcome, updates the in-memory imported-object inventory after a successful rename, and fails validation unless the final path matches the naming contract. Multi-mesh GLBs are not renamed as a single asset. This is implemented but not yet executed in Unreal Editor; `EditorAssetLibrary.rename_asset` behavior and actual Interchange naming remain to be confirmed in UE 5.8.4.
- Added standalone Python CI checks at `scripts/validate_unreal_asset_contract.py` and `scripts/validate_unreal_source_contract.py`. Workflow `.github/workflows/unreal-source-asset-contract.yml` now runs on gameplay C++/config changes as well as asset/import-script changes. GitHub Actions run **43567055278** completed successfully: all three Python files passed syntax compilation, the player camera/fallback, catalog paths, GameMode/map setup, flight-level props and import-report gates passed static source checks, and all seven ship GLBs passed the structural contract. This does not execute Unreal's Interchange importer, UnrealHeaderTool, UBT or runtime.
- It now parses each source GLB JSON chunk before import, walks the selected scene hierarchy, composes each mesh node's world matrix from all parent transforms, records node-to-mesh references and primitive material names, and writes a JSON manifest under `Saved/GFAssetManifests`. A nested-rotation/translation self-check runs before the import workflow. Matrices remain in glTF source coordinates and units; they are deliberately not passed to Unreal components until coordinate/unit conversion is validated against actual Interchange imports.
- A broader GLB visual-source validator now scans every available model category (ships, environment, space and planets), not only the ship fleet. It checks GLB chunk integrity, reachable scene hierarchy, node transforms, mesh/primitive/accessor references, material assignments, metallic-roughness PBR values, texture/image references, UV sets and normals. Missing normals/UVs are reported as visual warnings; invalid references or malformed PBR data fail the gate. This is a source-file quality check and cannot judge the final Unreal shader appearance.
- Blender batch run **43567803385** completed successfully after the shared utility import path was corrected. All seven ship generators, mesh consolidation, fleet structural validation, space/planet generation, package verification, and the new post-export GLB/PBR validator passed. The generated files and reports were committed to the migration branch in commit `70cf35a21209b2dd0479c0ec84bb051b7e7c2d8b`.
- The regenerated fleet report now records embedded image counts of 9 for Player Fighter and 7 for each of the other six ships; all seven retain 5–7 material slots and complete UV coverage. The all-category GLB validator passed after the assets were copied into the repository. The new Helios gas giant export also passed the single-mesh source contract after joining its rings and surface.
- The committed fleet validation report exposed an export gap: Player Fighter contained 9 embedded images, while the other six ship GLBs contained 0. Their Blender-only procedural noise was therefore not a reliable Unreal texture source. A shared `scripts/blender/pbr_surface_maps.py` utility now stages file-backed albedo, roughness and tangent-space normal maps for the Raider Interceptor and all five fleet-expansion ships. The source contract requires this utility in both builders, and the GLB validator now requires each ship export to contain embedded PBR images, complete UV coverage and normals on every primitive. The seven-ship Blender batch must be rerun to regenerate the committed GLBs and build report; until that run completes, the new textures are code changes rather than verified output assets.
- Planet surface materials now use a subtle bump response derived from the generated terrain albedo, so ridges and surface transitions can respond to directional lighting rather than appearing completely flat. The starfield texture uses nearest-neighbour sampling to keep tiny star points crisp instead of blurring them.
- The Helios gas giant's ring mesh is joined to its sphere before export while preserving separate material slots. This makes the planet and rings one self-contained StaticMesh import, avoiding ambiguous asset lookup and simplifying the Unreal scene.
- The all-category validator now explicitly requires every backdrop and planet GLB to contain exactly one mesh definition and one reachable mesh node, so a future ring/surface split cannot silently reintroduce ambiguous Unreal asset lookup.
- The 1024-pixel quality pass completed in Blender batch **43568733770** and was committed in **fbe9c764e108f30092674dcf3a32bdc98998a894**. All seven ships were regenerated with 1024×1024 albedo/roughness/normal maps; planet textures are 1024 pixels wide and the space backdrop is 2048 pixels wide. Planet sphere tessellation is 256×128 and the gas-giant ring is 256×32. The updated validator reads embedded PNG headers from GLB binary bufferViews/data URIs and enforces actual dimensions rather than trusting generator settings. All 19 GLB models passed the updated geometry/PBR validation, including the 1024/2048-pixel texture thresholds.
- UV diagnostics now distinguish between a missing UV set that breaks texture-based shading and a flat-color asset that does not need UVs. The imported 1999 asteroid has no UV layer but no texture-based material, so it remains a non-blocking source asset rather than a false-positive visual defect. Ship meshes still require complete UV and normal coverage.
- The Unreal source contract now checks that the all-category PBR validator, planet relief shader, one-mesh ring export and crisp starfield settings remain present. The GitHub workflow watches all four model directories for changes. The workflow YAML initially contained malformed escaped line breaks; this was corrected and a fresh run is in progress.
- The generated ship GLBs now contain exactly one complete mesh each, while editable Blender sources retain their component meshes. This avoids requiring Unreal to assemble hundreds of imported mesh assets for the visual ship body. It does not yet produce separate gameplay-damage modules or validate imported material/transform results in Unreal.
- It creates `/Game/GF/Maps/L_FlightTest`, key/fill lighting, a forward-facing PlayerStart, a two-sided emissive space backdrop, all four planet actors (Verdant, Dune, Glacius and Helios gas giant), and a GFMissionDirector. The new Dune and Helios placements are source-level setup and still require an Editor visual check. Imported visual actors have collision disabled so they do not block flight.
- Single-mesh imports are normalized to source-filename object paths, allowing deterministic lookup of the enemy fighter, backdrop and planet meshes. The mission director receives the enemy fighter when the lookup returns exactly one StaticMesh.
- The player pawn resolves the selected ship's catalog soft-object path at runtime. If no saved selection exists it selects Player Fighter Mk.I; if a non-default selected ship mesh is missing it uses Player Fighter visuals while retaining the selected ship's gameplay stats. Missing all fallback mesh assets is logged as an error.
- Chase and cockpit camera positions are calculated from the selected StaticMesh local bounds. This removes the previous one-size-fits-all offsets, but camera framing still requires an in-engine visual check.
- The manifest is not yet mapped to exact StaticMesh assets produced by Interchange, and `AGFShipAssemblyActor.Parts` is not populated automatically. Current ship GLBs are intentionally consolidated to one complete mesh each, so the player visual path uses one StaticMesh rather than the assembly actor. Materials, pivots, scale, axis and collision still require Editor validation.
- A reusable C++ `AGFShipAssemblyActor` has now been added. It accepts an explicit list of source-node mesh assets, composed root-relative transforms and optional material overrides, then builds one `UStaticMeshComponent` per part. Missing mesh references are logged rather than silently skipped.
- This actor is an assembly primitive, not a completed asset pipeline: the Editor script does not yet populate its `Parts` array from the manifest, and no actual imported GLB has been reconstructed or visually checked.

## P0 — Unreal compile and UHT gate remains open

No Unreal Engine 5.8 installation is available in this execution environment. C++ source has not been compiled. Header parsing, generated code, module dependencies and linker correctness remain unverified. The catalog automation test exists but has not been executed.

## P0 — Unreal import and Player Fighter visual acceptance remain open

The source-side path is now implemented: the seven ship GLBs are each a single complete mesh; the Editor script imports and normalizes their object names; the catalog paths are checked; the pawn resolves the selected mesh; and the flight-test level receives a backdrop and planets. However, no Unreal Editor has executed this import script yet. Therefore there is still no evidence that Interchange produces the expected object paths, that the materials render correctly, or that the pawn/camera/planet framing looks correct in UE 5.8.4.

The retained multi-part `.blend` files preserve the original editable geometry. `AGFShipAssemblyActor` remains available for future modular damage/upgrade variants, but is not required to assemble the current consolidated single-mesh ship bodies.

## P1 — Catalog soft-object paths remain assumptions

The catalog expects:
- `/Game/GF/Ships/player_fighter.player_fighter`
- `/Game/GF/Ships/enemy_fighter.enemy_fighter`
- `/Game/GF/Ships/heavy_fighter.heavy_fighter`
- `/Game/GF/Ships/bomber.bomber`

These paths have not been confirmed by an actual Editor import. Update them only after observing exact imported object paths.

## P1 — Enhanced Input is enabled but not used

The project enables the EnhancedInput plugin and lists it as a module dependency, while pawn controls are bound through legacy `UInputComponent` axis/action mappings in `DefaultInput.ini`. Modernize to Enhanced Input after compile/runtime baseline is established, preserving the original control response.

## P1 — Mission flow is a foundation, not a complete campaign

A source review also found that mission completion originally checked the world origin as the carrier return point. This has been corrected in the migration branch: `CarrierPosition` is now an editable mission property and both the return-range check and objective marker use it. The actual carrier coordinates still must be set and playtested in the Editor. Relay and wreck interactions now enter explicit `ScanRelay`/`ScanWreck` stages. Progress advances while the player remains inside the interaction radius and starts the encounter after the editable scan duration; leaving range resets progress. The native HUD now displays scan percentage during either scan stage. This source-level UI addition and the timed scan flow remain unverified in the Unreal runtime.

The current first-pass implementation includes a relay/wreck encounter loop and reward persistence, but the full authored campaign, all three contracts' unique objectives, distinct scan interactions, dialogue, branching story state and production objective presentation remain incomplete or unverified.

## Required acceptance sequence

1. Build with the exact Unreal Engine 5.8.4 toolchain; resolve UHT/compiler/linker errors.
2. Run the Editor Python setup script and capture the import log.
3. Execute the automated import and confirm all four catalog ship paths plus backdrop/planet assets resolve exactly.
4. Open `L_FlightTest`; inspect Player Fighter materials, scale, forward axis, pivot, collision, cockpit view and chase-camera framing.
5. Playtest flight and verify planet/backdrop placement and mission enemy spawn.
6. Playtest flight, cameras, targeting, weapons, enemy AI, mission progression and save/reload.
7. Run catalog automation tests and package a Windows development build.

## Branch safety

All migration work remains on `chatgpt/unreal-migration-ue5.8`. PR #99 remains draft. Do not merge it or modify `main` until the user explicitly approves.
