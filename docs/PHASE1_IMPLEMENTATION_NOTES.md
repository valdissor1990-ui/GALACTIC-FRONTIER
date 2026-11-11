# Phase 1 — Implementation notes

## Current implementation state

The first Godot project skeleton and flight prototype source files have been added to the branch. This is a source-code milestone only.

- Engine target: Godot 4.7.2-stable.
- Renderer: GL Compatibility, selected as a conservative initial baseline.
- Main scene: `scenes/bootstrap/main.tscn`.
- Flight scene: `scenes/flight/test_flight.tscn`.
- Player body: `CharacterBody3D` with manually integrated translation and rotation.
- Ship tuning: `resources/ships/player_ship.tres`.
- Cameras: chase and cockpit; the placeholder ship mesh is hidden in cockpit mode when the optional `Visual` node exists.
- Boost: finite energy that recharges when not used.
- HUD: speed, camera mode, boost and mouse sensitivity; missing flight configuration is handled without a HUD division error.
- Pause: Escape; mouse capture is released on pause and restored on resume.
- Window focus: mouse capture is released when the application loses focus and restored when it regains focus while the game is not paused.
- Windows export preset: source configuration added; export templates and Windows runtime are not verified.

## Flight input model

The two rotation input methods intentionally behave differently:

- **Keyboard rotation:** rate-based. Angular velocity accelerates toward the requested rotation rate and is damped after the rotation key is released.
- **Mouse look:** immediate adjustment, not integrated into keyboard angular inertia. This provides direct aiming/view control rather than a second inertia layer.
- Mouse movement accumulated between physics ticks is capped at 250 pixels per tick and consumed once. This prevents a delayed physics tick from applying an unbounded rotation jump.
- Mouse input is cleared when the application loses or regains focus.

The cap is a defensive starting value, not a playtested tuning result. It may be adjusted after runtime testing.

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

Mouse look is captured while flying. Escape pauses and releases the mouse; Escape again resumes and captures it. If the application loses focus, mouse capture is released; it is restored when focus returns unless the game is paused.

## Verification status

| Check | Status |
|---|---|
| Files written to GitHub | PASS |
| Static review of changed logic | PASS (source inspection only) |
| Project configuration parsed by Godot 4.7.2 | NOT RUN |
| GDScript static parse by Godot | NOT RUN |
| Scene import/open | NOT RUN |
| Flight physics and input feel | NOT RUN |
| Camera switching in runtime | NOT RUN |
| Pause/HUD in runtime | NOT RUN |
| Window focus behavior in runtime | NOT RUN |
| Windows export | NOT RUN |
| Windows executable launch | NOT RUN |

No performance, FPS, stability or playability claim is made until the project is opened and run in Godot.

## Known prototype limitations

- The ship is a procedural primitive-mesh placeholder, not final art.
- The distant planet is a simple sphere placeholder.
- No combat, stations, economy, NPCs, save system, galaxy map or landing zones are included.
- Keyboard bindings are the initial defaults; a full in-game key rebinding screen is not implemented yet.
- The first flight tuning values and mouse-delta cap are starting values and require real playtesting.
