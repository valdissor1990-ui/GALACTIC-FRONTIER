---
name: godot-scene-validation
description: Validate Godot project resources and changed scenes without confusing import with runtime loading.
---

# Godot scene validation

1. Confirm the CI Godot version matches `AGENTS.md` (4.7.2).
2. Run project import as a separate step; record its exit code.
3. Explicitly load every changed `.tscn` and its referenced dependencies in headless Godot. A successful `--editor --headless --import` alone does not prove all scenes load.
4. Run the relevant GDScript tests and verify the workflow invokes them.
5. Inspect logs for missing resources, parse errors, script errors, invalid UIDs, and warnings promoted to errors.
6. For graphical changes, run the screenshot workflow and inspect PNG files; headless scene load is not visual verification.

Report PASS/FAIL/BLOCKED/NOT VERIFIED separately for import, scene load, tests, graphical capture, and human playtest.
