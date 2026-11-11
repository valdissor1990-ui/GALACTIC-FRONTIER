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
- Windows export preset: source configuration added. GitHub Actions run #12 completed successfully on 2026-11-11. It installed Godot 4.7.2, imported/parsed the project, launched both the bootstrap and flight scenes headlessly, exported the Windows build, uploaded the EXE/PCK artifact, downloaded it on a Windows runner, and launched the EXE headlessly with a successful process exit code. The PR workflow checked the synthetic merge commit `5efaffab8cd6c98a37aaa5e6a3889fbc34666714`, combining branch HEAD `99196571c795544b59133668fdba8addea62bb65` with base `main` at `725167438d1f04cd6771fdfc1bfa06315a06246a`.

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

Latest completed workflow: GitHub Actions run #12, run ID `43116298734`, source branch HEAD `99196571c795544b59133668fdba8addea62bb65`; result: **success**. For the `pull_request` event, GitHub checked the merge ref commit `5efaffab8cd6c98a37aaa5e6a3889fbc34666714` (PR head merged with the current `main` base).

| Check | Status |
|---|---|
| Workflow file committed to GitHub | PASS |
| Godot 4.7.2 installed and exact version verified | PASS |
| Project import and GDScript parsing by Godot | PASS |
| Headless bootstrap-scene smoke test | PASS |
| Direct headless flight-scene smoke test | PASS |
| Windows Desktop export | PASS |
| EXE/PCK artifact upload | PASS |
| Windows artifact download and SHA-256 digest match | PASS |
| Windows EXE headless launch and process exit code 0 | PASS |
| Interactive flight physics and input feel | NOT RUN |
| Mouse capture and real mouse look | NOT RUN |
| Camera switching by user input in an interactive session | NOT RUN |
| Pause/HUD and window-focus behavior in an interactive session | NOT RUN |
| Visual quality and normal Windows desktop session | NOT RUN |

The CI result confirms import/parsing, scene startup in headless mode, export, artifact transfer and headless executable startup. It does not establish interactive playability, visual quality, performance/FPS, or a complete game loop. Those remain unverified until a real interactive playtest.

## Known prototype limitations

- The ship is a procedural primitive-mesh placeholder, not final art.
- The distant planet is a simple sphere placeholder.
- No combat, stations, economy, NPCs, save system, galaxy map or landing zones are included.
- Keyboard bindings are the initial defaults; a full in-game key rebinding screen is not implemented yet.
- The first flight tuning values and mouse-delta cap are starting values and require real playtesting.
