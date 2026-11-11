# Phase 1 — Implementation notes

## Current implementation state

The first Godot project skeleton and flight prototype source files have been added to the branch. This is a source-code milestone only.

- Engine target: Godot 4.7.2-stable.
- Renderer: GL Compatibility, selected as a conservative initial baseline.
- Main scene: `scenes/bootstrap/main.tscn`.
- Flight scene: `scenes/flight/test_flight.tscn`.
- Player body: `CharacterBody3D` with manually integrated translation and rotation.
- Ship tuning: `resources/ships/player_ship.tres`.
- Cameras: chase and cockpit; the placeholder ship mesh is hidden in cockpit mode.
- Boost: finite energy that recharges when not used.
- HUD: speed, camera mode, boost and mouse sensitivity.
- Pause: Escape.
- Windows export preset: source configuration added; export templates and Windows runtime are not verified.

## Controls

| Action | Key |
|---|---|
| Forward / reverse | W / S |
| Strafe left / right | A / D |
| Vertical up / down | Space / Z |
| Yaw left / right | Q / E |
| Pitch up / down | I / K |
| Roll left / right | J / L |
| Boost | Left Shift |
| Brake | X |
| Switch chase / cockpit camera | C |
| Pause / resume | Escape |
| Mouse sensitivity down / up | [ / ] |
| Mouse look | Mouse movement |

Mouse look is captured while flying. Escape pauses and releases the mouse; Escape again resumes and captures it.

## Verification status

| Check | Status |
|---|---|
| Files written to GitHub | PASS |
| Project configuration parsed by Godot 4.7.2 | NOT RUN |
| GDScript static parse | NOT RUN |
| Scene import/open | NOT RUN |
| Flight physics and input feel | NOT RUN |
| Camera switching in runtime | NOT RUN |
| Pause/HUD in runtime | NOT RUN |
| Windows export | NOT RUN |
| Windows executable launch | NOT RUN |

No performance, FPS, stability or playability claim is made until the project is opened and run in Godot.

## Known prototype limitations

- The ship is a procedural primitive-mesh placeholder, not final art.
- The distant planet is a simple sphere placeholder.
- No combat, stations, economy, NPCs, save system, galaxy map or landing zones are included.
- Keyboard bindings are the initial defaults; a full in-game key rebinding screen is not implemented yet.
- The first flight tuning values are starting values and require real playtesting.
