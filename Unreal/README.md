# GALACTIC FRONTIER — Unreal project

Target engine: Unreal Engine 5.8.4 stable (project association: 5.8).
Target platform: Windows PC.
Game model: single-player, offline-first.

Open `GalacticFrontier.uproject` with Unreal Engine 5.8.4.

## Current implementation

- C++ game module and game mode scaffold.
- `UGFShipFlightComponent`: inertial flight with collision sweeps, independent braking, boost reserve/recharge, angular inertia and mouse-look. Unreal distances are centimeters; source Godot speed/acceleration are converted from 95 m/s and 34 m/s² to 9500 cm/s and 3400 cm/s².
- `AGFPlayerShipPawn`: player pawn with chase/cockpit cameras and keyboard/mouse input bindings.
- `UGFDamageableComponent`: shield absorption, delayed regeneration, hull damage and destroyed state.
- `UGFWeaponComponent` + `AGFProjectile`: primary energy weapon with cooldown, projectile travel and damage application.
- Existing Godot tuning defaults are copied from `resources/ships/player_ship.tres`.

This is not yet a playable port. The flight component exposes velocity; a Pawn movement/collision layer and Enhanced Input bindings still need to be integrated. Camera, weapons, damage, saves, missions, UI, audio and environment are not yet ported.

Do not remove the Godot source tree until the Unreal vertical slice and full migration pass their acceptance gates in `../UNREAL_MIGRATION_PLAN.md`.

Generated Unreal directories such as `Binaries/`, `Intermediate/`, `Saved/` and `DerivedDataCache/` must not be committed.
