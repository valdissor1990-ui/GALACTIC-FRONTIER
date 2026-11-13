# GALACTIC FRONTIER — Unreal project

Target engine: **Unreal Engine 5.8** stable (`EngineAssociation`: 5.8).
Target platform: Windows PC.
Game model: single-player, offline-first.

Open `GalacticFrontier.uproject` with UE 5.8 and compile the C++ module before running the content setup script.

## Already ported (C++)

| System | Classes |
|--------|---------|
| Flight | `UGFShipFlightComponent`, `AGFPlayerShipPawn` |
| Combat | `UGFWeaponComponent`, `AGFProjectile`, `UGFDamageableComponent`, `UGFTargetingComponent` |
| Enemy | `AGFEnemyShip` (approach/strafe/retreat + lead) |
| Mission | `AGFMissionDirector` (Silent Relay stages, scan, waves) |
| Meta | `UGFSaveSubsystem`, `UGFPlayerProfileSave`, `UGFGameCatalog` |
| Hangar API | `UGFHangarSubsystem` |
| Dialogue data | `UGFDialogueService` (M01 / Silent Relay seeds) |
| Graphics | `UGFGraphicsSettings` (Low/Med/High scalability) |
| HUD | `AGFSpaceHUD` |
| GameMode | `AGFGameModeBase` (auto-spawns MissionDirector) |

Godot remains in-repo as reference until gates in `../UNREAL_MIGRATION_PLAN.md` pass.

## First-time content setup

1. Compile in UE 5.8.
2. Open the project.
3. **Tools → Execute Python Script** → `Content/Python/setup_galactic_frontier.py`.
4. Inspect every imported GLB (multi-mesh ships must be assembled manually).
5. Play `L_FlightTest` — do **not** treat compile success as a playtest pass.

## Still incomplete / not runtime-verified

- Full UMG main menu + hangar screens (API ready; widgets TBD)
- Remaining dialogue M02–M05 branching UI
- Production space environment / Niagara VFX / audio assets
- Enhanced Input assets (project enables plugin; legacy axis bindings still used)
- Windows packaged build
- **No automated UE test run claimed in this repository state**

## Generated folders (do not commit)

`Binaries/`, `Intermediate/`, `Saved/`, `DerivedDataCache/`
