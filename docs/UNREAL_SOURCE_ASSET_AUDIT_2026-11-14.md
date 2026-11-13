# Unreal source and asset-pipeline audit — 2026-11-14

Scope: static review of the Unreal migration branch at PR #99. This is a source-level review only. Unreal Header Tool, Unreal Build Tool, Editor import, runtime playtest and packaged build have not been run in this environment.

## Confirmed improvements in this pass

- Fixed the setup script's unused Player Fighter lookup: it now assigns the imported Player Fighter mesh as a fallback mesh on the native `GFPlayerShipPawn` class default object. The runtime catalog-selected mesh still takes precedence when its soft reference resolves.
- Corrected `Unreal/README.md` so it no longer says that already-authored first-pass AI, targeting, HUD, catalogs and mission foundations are entirely unported.
- Corrected the setup instructions to describe the actual PlayerStart/GameMode spawn flow.

## Findings requiring validation or follow-up

### P0 — Unreal compile and UHT gate is still open

No Unreal Engine 5.8 installation is available in this execution environment. The C++ source has not been compiled. Header parsing, generated code, module dependencies and linker correctness therefore remain unverified. The catalog automation test exists but has not been executed.

### P0 — GLB import hierarchy and mesh completeness are not proven

The Editor script imports GLBs and then selects the first imported `StaticMesh` whose object path contains a token. This is not sufficient evidence that a multi-node GLB ship is reconstructed as a complete ship. It may select only one mesh node and discard the source hierarchy/transforms at the pawn level. Imported materials, pivots, forward axis, scale, collision and all mesh nodes must be inspected in Unreal Editor.

### P1 — Catalog soft-object paths are assumptions until Editor import is run

The catalog currently expects:
- `/Game/GF/Ships/player_fighter.player_fighter`
- `/Game/GF/Ships/enemy_fighter.enemy_fighter`
- `/Game/GF/Ships/heavy_fighter.heavy_fighter`
- `/Game/GF/Ships/bomber.bomber`

The source GLB filenames match these names, but Unreal's actual imported asset names and paths have not been observed. If the Interchange importer generates different names, catalog loading will fail and the fallback mesh will mask only the Player Fighter case.

### P1 — Enhanced Input is enabled but not used

The project enables the EnhancedInput plugin and lists it as a module dependency, while pawn controls are currently bound through legacy `UInputComponent` axis/action mappings in `DefaultInput.ini`. This is functional as a first pass but should be modernized after the initial compile/runtime gate.

### P1 — Mission flow is a foundation, not a complete campaign implementation

The current director has a two-encounter relay/wreck loop and reward persistence. It does not yet implement the full authored campaign, all three contracts' unique objective logic, complete scan interactions, dialogue, branching story state, or production objective presentation. The scan enum values currently exist but are not used as distinct interaction phases.

## Required acceptance sequence

1. Build the project with the exact target Unreal Engine 5.8 installation; resolve all UHT/compiler/linker errors.
2. Run the Editor Python setup script and capture its import log.
3. Inspect the Player Fighter GLB hierarchy and verify every visual component/material survives import; do not accept a single-mesh approximation if the source is multi-part.
4. Verify actual imported object paths and update catalog soft references to those exact paths.
5. Inspect scale, forward axis, pivot, collision and cockpit camera position in the Editor.
6. Run flight, camera, targeting, weapon, enemy AI, mission progression and save/reload playtests.
7. Run the catalog automation test and package a Windows development build.

## Branch safety

This audit and its fixes belong only to `chatgpt/unreal-migration-ue5.8`. PR #99 remains draft. Do not merge it or modify `main` until the user explicitly approves.
