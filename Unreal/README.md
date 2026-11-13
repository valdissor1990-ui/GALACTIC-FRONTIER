# GALACTIC FRONTIER — Unreal project

Target engine: **Unreal Engine 5.8** (`EngineAssociation`: 5.8).  
Windows PC · single-player · offline-first.

Open `GalacticFrontier.uproject` → compile C++ → run content setup script.

## Ported systems (C++)

| Area | Classes |
|------|---------|
| Boot | `UGFGameInstance` (loads profile) |
| Control | `AGFPlayerController` (ESC pause, F10 graphics) |
| Flight | `UGFShipFlightComponent`, `AGFPlayerShipPawn` |
| Combat | weapon / projectile / damageable / targeting |
| Enemy | `AGFEnemyShip` |
| Mission | `AGFMissionDirector` (Silent Relay full loop) |
| Meta | save, catalog, `UGFHangarSubsystem` |
| Story | `UGFDialogueService` (M01–M05 line data) |
| Audio | `UGFAudioSubsystem` (volumes + optional 2D SFX) |
| Graphics | `UGFGraphicsSettings` |
| HUD | `AGFSpaceHUD` (telemetry, mission, credits, pause) |

## Setup

1. Compile in UE 5.8.  
2. **Tools → Execute Python Script** → `Content/Python/setup_galactic_frontier.py`.  
3. Inspect GLB imports (multi-mesh ships need manual assembly).  
4. Play `L_FlightTest`. Runtime is **not** verified in CI from this environment.

## Controls

WASD move · arrows rotate · Shift boost · Space brake · LMB fire · T/X target · V camera · F interact · **ESC pause** · **F10 graphics**

## Still open

UMG main menu / hangar screens · Niagara VFX · production audio assets · Enhanced Input asset pack · Windows package · automated UE tests

Do not delete Godot until gates in `../UNREAL_MIGRATION_PLAN.md` pass.

Ignore: `Binaries/`, `Intermediate/`, `Saved/`, `DerivedDataCache/`
