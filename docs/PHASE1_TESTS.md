# Phase 1 — Automated tests

Headless deterministic tests for Phase 1 flight systems. All runners use only built-in Godot 4.7.2 APIs (no third-party frameworks).

GitHub Actions (`.github/workflows/godot-ci.yml`) runs every present test script after project import and Godot 4.7.2 version verification. A failing test fails the job; there is no `continue-on-error`.

---

## 1. FlightModel.integrate_velocity()

**Script:** `tests/flight/test_flight_model.gd`

Covers pure movement math: direction normalization, max-speed clamp, exponential drag, no-drag-while-accelerating, zero delta, near-zero direction.

```bash
godot --headless --path . --script res://tests/flight/test_flight_model.gd
```

- Exit code `0` — all assertions passed.
- Successful output ends with: `RESULT: PASS  (9 assertions)`

| Check | Status |
|-------|--------|
| Godot execution | PASS — CI run #39 (ID `43119139328`), exit code 0 |
| Interactive feel | NOT RUN |

---

## 2. CameraRig switching

**Script:** `tests/flight/test_camera_rig.gd`

**CI command:**
```bash
godot --headless --path . --script res://tests/flight/test_camera_rig.gd
```

Covers:

1. Initial mode is Chase.
2. Toggle Chase → Cockpit.
3. Toggle Cockpit → Chase.
4. Toggle does not change ship transform.
5. Toggle does not change ship velocity.
6. Missing `Visual` node does not crash (`push_error` is expected and accepted).
7. Cameras still switch correctly without `Visual`.

Initialization relies on Godot calling `_ready()` once when the node enters the tree; tests do not call `_ready()` manually.

| Check | Status |
|-------|--------|
| Wired into CI | Yes |
| Godot execution | **NOT RUN** — waiting for a successful GitHub Actions run of this branch/PR |
| Interactive camera feel | NOT RUN |

---

## 3. Pause and mouse input

**Script:** `tests/flight/test_pause_and_mouse.gd`

**CI command:**
```bash
godot --headless --path . --script res://tests/flight/test_pause_and_mouse.gd
```

Covers:

1. Mouse delta is not accumulated while the tree is paused.
2. Single large mouse event is capped at `MAX_MOUSE_DELTA_PER_PHYSICS_TICK`.
3. Multiple sequential mouse events stay within the same cap.
4. Focus-out clears mouse delta and releases capture.
5. Focus-in clears stale mouse delta.
6. Focus-in captures mouse when not paused.
7. Focus-in does **not** capture mouse while paused.
8. Full pause/resume cycle via real production `HUD._toggle_pause()`:
   - pause enables, PausePanel becomes visible, mouse is released;
   - resume disables pause, PausePanel hides, mouse is captured again.
9. Mouse sensitivity stays within `[0.02, 0.5]`.

| Check | Status |
|-------|--------|
| Wired into CI | Yes |
| Godot execution | **NOT RUN** — waiting for a successful GitHub Actions run of this branch/PR |
| Interactive mouse / pause feel | NOT RUN |

---

## Important distinction

Headless tests verify **logic and contracts**. They do **not** replace interactive playtesting of:

- real mouse look feel;
- camera transition smoothness;
- pause overlay visibility on a real desktop session;
- window-focus behaviour with a real OS window.

Those remain **NOT RUN** until a manual Windows playtest is performed.

## Production code

Test scripts and this document do not modify production gameplay scripts or scenes. The only non-test change in the hardening package is the CI workflow step list above.
