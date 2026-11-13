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

## Setup

1. Compile in UE 5.8.  
2. **Tools → Execute Python Script** → `Content/Python/setup_galactic_frontier.py`.  
3. Author Niagara systems (or use placeholders).  
4. Play `L_FlightTest` — boost, fire, and watch thrusters.  

Runtime is **not** verified in CI from this environment.

## Controls

WASD · arrows · Shift boost · Space brake · LMB fire · T/X target · V camera · F interact · ESC pause · F10 graphics

## Still open

UMG menu/hangar · polished Niagara graphs · production audio · Enhanced Input assets · Windows package · automated tests

Do not delete Godot until gates in `../UNREAL_MIGRATION_PLAN.md` pass.
