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
- Windows export preset: source configuration added. A GitHub Actions workflow now installs Godot 4.7.2, imports/parses the project, performs a headless main-scene smoke test, exports a Windows build and attempts a Windows executable smoke test. The workflow has not yet completed; these checks remain unverified until GitHub reports a result.

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

## Automated validation workflow

`.github/workflows/godot-ci.yml` runs on pushes to `phase-1/flight-prototype`, pull requests targeting `main`, and manual dispatch. It is designed to:

1. Install the pinned Godot 4.7.2 release and export templates on an Ubuntu runner.
2. Import the project and ask the Godot editor to parse/load project scripts in headless mode.
3. Start the configured bootstrap scene headlessly, then launch `res://scenes/flight/test_flight.tscn` directly for a separate smoke test.
4. Export the `Windows Desktop` preset and upload the executable plus PCK as a 14-day artifact.
5. Download that artifact on a Windows runner, start the exported executable in headless mode, wait for completion, and check its process exit code.

A successful headless smoke test does not verify interactive flight feel, mouse capture, camera switching by user input, visual rendering quality, or a normal interactive Windows session. Those still require manual playtesting.

## Verification status

| Check | Status |
|---|---|
| Workflow file committed to GitHub | PASS |
| GitHub Actions first run | NOT RUN / pending trigger |
| Godot 4.7.2 installed by CI | NOT RUN |
| Project import and script parsing by Godot | NOT RUN |
| Headless main-scene smoke test | NOT RUN |
| Windows export | NOT RUN |
| Windows executable headless smoke test | NOT RUN |
| Flight physics and input feel | NOT RUN |
| Camera switching by user input | NOT RUN |
| Pause/HUD and window focus behavior | NOT RUN |

No performance, FPS, stability, interactive playability or export-success claim is made until the corresponding automated or manual check has actually completed.

## Known prototype limitations

- The ship is a procedural primitive-mesh placeholder, not final art.
- The distant planet is a simple sphere placeholder.
- No combat, stations, economy, NPCs, save system, galaxy map or landing zones are included.
- Keyboard bindings are the initial defaults; a full in-game key rebinding screen is not implemented yet.
- The first flight tuning values and mouse-delta cap are starting values and require real playtesting.
