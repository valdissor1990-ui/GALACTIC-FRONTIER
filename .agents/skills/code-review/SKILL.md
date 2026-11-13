---
name: code-review
description: Review GALACTIC FRONTIER changes for correctness, architecture, Godot compatibility, regression risk, and evidence.
---

# Code review

1. Read the complete diff and surrounding implementation, not only the patch.
2. Check Godot 4.7.2 API correctness, typed GDScript, lifecycle, signal ownership, resource cleanup, physics delta, and null/freed-node handling.
3. Trace affected call sites, scenes, resources, and save compatibility.
4. Check tests for meaningful assertions, negative/edge cases, determinism, and CI inclusion.
5. Check workflows for false-positive success, skipped tests, wrong branch filters, and stale HEADs.
6. Check assets for real source files, valid paths, license, import settings, orientation, and scale.
7. Report findings first, sorted by severity, with exact file/line and a concrete fix.
8. State what was not verified. Do not approve based on code style if runtime/resource integrity is unknown.
