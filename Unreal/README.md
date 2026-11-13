# GALACTIC FRONTIER — Unreal project

Target engine: Unreal Engine 5.8 stable (project association: 5.8).
Target platform: Windows PC.
Game model: single-player, offline-first.

Open `GalacticFrontier.uproject` with Unreal Engine 5.8. The C++ project must be compiled once before running the editor setup script.

## Current implementation

- C++ game module and game mode.
- `AGFPlayerShipPawn`: controllable ship pawn with chase/cockpit cameras, keyboard and mouse axes, boost, brake and primary-fire bindings.
- `UGFShipFlightComponent`: inertial flight with collision sweeps, independent braking, boost reserve/recharge, angular inertia and mouse-look. Unreal distances are centimeters; source Godot speed/acceleration are converted to 9500 cm/s and 3400 cm/s².
- `UGFDamageableComponent`: shield absorption, delayed regeneration, hull damage and destroyed state.
- `UGFWeaponComponent` + `AGFProjectile`: primary energy weapon, cooldown, projectile travel and damage application.
- `UGFSaveSubsystem` + `UGFPlayerProfileSave`: local pilot progression, schema version, backup slot, ship purchases/selection, module purchases, contract selection and story flags.
- `UGFGameCatalog`: ported definitions for all four flyable ships, five upgrade modules and three contracts, including the original Godot tuning values.
- Enemy AI includes approach/strafe/retreat states, vertical evasion and predictive projectile leading.

## First-time content setup

1. Compile the project in Unreal Engine 5.8.
2. Open the project in the Unreal Editor.
3. Choose **Tools → Execute Python Script** and run `Content/Python/setup_galactic_frontier.py`.
4. The script imports the existing ship and environment GLBs from the repository, creates `/Game/GF/Maps/L_FlightTest`, places a `PlayerStart`, and assigns the imported Player Fighter mesh as a fallback on the native pawn class. At runtime, the selected ship's catalog mesh replaces that fallback when its soft asset path resolves.
5. Inspect scale, forward axis, pivots and imported material assignments before visual acceptance.

The editor script creates the initial test map; it is not a substitute for checking the imported content in the editor.

## Not yet ported

Enemy AI and waves, target lock and scan, complete Silent Relay mission state machine, contract and ship catalogs, hangar/menu/HUD, story dialogue, VFX/audio, graphics settings, and Windows packaging remain migration work.

Do not remove the Godot source tree until the Unreal vertical slice and full migration pass the acceptance gates in `../UNREAL_MIGRATION_PLAN.md`.

Generated Unreal directories such as `Binaries/`, `Intermediate/`, `Saved/` and `DerivedDataCache/` must not be committed.
