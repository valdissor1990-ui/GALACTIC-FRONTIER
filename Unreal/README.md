# GALACTIC FRONTIER — Unreal project

Target engine: Unreal Engine 5.8.4 stable (project association: 5.8).
Target platform: Windows PC.
Game model: single-player, offline-first.

Open `GalacticFrontier.uproject` with Unreal Engine 5.8.4.

## Current implementation

- C++ game module and game mode scaffold.
- `UGFShipFlightComponent`: first port of the Godot flight integration behavior, including acceleration, inertial drag, independent braking, boost reserve/recharge, angular inertia and mouse-look delta handling.
- Existing Godot tuning defaults are copied from `resources/ships/player_ship.tres`.

This is not yet a playable port. The flight component exposes velocity; a Pawn movement/collision layer and Enhanced Input bindings still need to be integrated. Camera, weapons, damage, saves, missions, UI, audio and environment are not yet ported.

Do not remove the Godot source tree until the Unreal vertical slice and full migration pass their acceptance gates in `../UNREAL_MIGRATION_PLAN.md`.

Generated Unreal directories such as `Binaries/`, `Intermediate/`, `Saved/` and `DerivedDataCache/` must not be committed.
