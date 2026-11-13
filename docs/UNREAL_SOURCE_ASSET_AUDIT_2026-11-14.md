# Unreal source and asset-pipeline audit — 2026-11-14 (corrected)

Scope: static review of the Unreal migration branch `chatgpt/unreal-migration-ue5.8`. This is a source-level review only. Unreal Header Tool, Unreal Build Tool, Editor import, runtime playtest and packaged build have not been run in this environment.

## Confirmed state from the current setup script

- The Editor script imports GLBs from `assets/models/ships` and `assets/models/environment`.
- It records imported object paths and lists StaticMesh assets per GLB.
- It now parses each source GLB JSON chunk before import, walks the selected scene hierarchy, composes each mesh node's world matrix from all parent transforms, records node-to-mesh references and primitive material names, and writes a JSON manifest under `Saved/GFAssetManifests`. A nested-rotation/translation self-check runs before the import workflow. Matrices remain in glTF source coordinates and units; they are deliberately not passed to Unreal components until coordinate/unit conversion is validated against actual Interchange imports.
- It explicitly warns when a source GLB produces multiple StaticMesh assets; this is inventory/diagnostic behavior, not ship assembly.
- It creates `/Game/GF/Maps/L_FlightTest`, lighting, a PlayerStart and a GFMissionDirector.
- It attempts to assign an enemy mesh only when the imported-path token lookup yields exactly one StaticMesh.
- It logs a Player Fighter candidate but does not assign that mesh to the player pawn.
- The manifest is not yet mapped to the exact StaticMesh assets produced by Interchange, and it does not yet populate `AGFShipAssemblyActor.Parts` automatically. Materials, pivots, scale, axis and collision still require Editor validation.
- A reusable C++ `AGFShipAssemblyActor` has now been added. It accepts an explicit list of source-node mesh assets, composed root-relative transforms and optional material overrides, then builds one `UStaticMeshComponent` per part. Missing mesh references are logged rather than silently skipped.
- This actor is an assembly primitive, not a completed asset pipeline: the Editor script does not yet populate its `Parts` array from the manifest, and no actual imported GLB has been reconstructed or visually checked.

## P0 — Unreal compile and UHT gate remains open

No Unreal Engine 5.8 installation is available in this execution environment. C++ source has not been compiled. Header parsing, generated code, module dependencies and linker correctness remain unverified. The catalog automation test exists but has not been executed.

## P0 — Existing ship models are not yet restored as complete Unreal assets

The current import script inventories StaticMesh outputs but does not create a reusable assembled ship Blueprint/Actor from all GLB nodes. A multi-node ship may therefore remain a collection of separate imported assets without a complete in-game representation. This blocks acceptance of the Player Fighter visual slice.

Required implementation:
1. Inspect actual GLB node hierarchy, mesh references, transforms and material bindings from source files.
2. Import every node and preserve source-relative transforms.
3. Populate a Blueprint subclass of `AGFShipAssemblyActor` with one part descriptor per source mesh node, using composed root-relative transforms and preserved material slots.
4. Verify all expected source nodes are represented exactly once.
5. Verify materials, scale, forward axis, pivots and collision in Unreal Editor.

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
3. Reconstruct the Player Fighter from every GLB mesh node and verify visual completeness/materials.
4. Confirm exact imported paths and update catalog references.
5. Inspect scale, forward axis, pivot, collision and cockpit camera placement.
6. Playtest flight, cameras, targeting, weapons, enemy AI, mission progression and save/reload.
7. Run catalog automation tests and package a Windows development build.

## Branch safety

All migration work remains on `chatgpt/unreal-migration-ue5.8`. PR #99 remains draft. Do not merge it or modify `main` until the user explicitly approves.
