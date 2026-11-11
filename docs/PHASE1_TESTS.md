# Phase 1 — Automated tests

## FlightModel.integrate_velocity()

Deterministic unit tests for the pure movement helper used by the player ship.

### Scope

The tests cover only `FlightModel.integrate_velocity()` and do not touch input, scenes, cameras or the full ship controller.

The runner contains six test groups and nine assertions:

1. Acceleration direction is normalized before use.
2. Resulting speed is clamped to `max_speed` (initial velocity and post-acceleration).
3. When there is no acceleration input, exponential drag is applied: `v *= exp(-drag * delta)`.
4. When acceleration input is present, drag is **not** applied.
5. `delta = 0` leaves velocity unchanged (apart from the final `limit_length`).
6. A near-zero direction (below the internal threshold) is treated as "no input" and uses the drag path.

### How to run

From the project root (Godot 4.7.2-stable):

```bash
godot --headless --path . --script res://tests/flight/test_flight_model.gd
```

### Expected result

- Exit code `0` — all assertions passed.
- Exit code `1` — one or more assertions failed.

Successful console output ends with:

```
RESULT: PASS  (9 tests)
```

Failure output ends with:

```
RESULT: FAIL  (X passed, Y failed)
```

and lists each failed assertion.

### Status

| Check | Status |
|-------|--------|
| Test file added | PASS |
| Documentation added | PASS |
| Godot execution | NOT RUN — awaiting PR CI result |
| Production code modified | No (by design) |

The GitHub Actions workflow now includes this test command for pull requests targeting `phase-1/flight-prototype`. The command is skipped on the base branch until the test file is present, and runs in the pull-request merge checkout.
