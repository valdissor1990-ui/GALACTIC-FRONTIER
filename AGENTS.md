# GALACTIC FRONTIER — AI Studio Instructions

This repository is an existing Godot 4.7.2 / GDScript single-player space RPG. Preserve the established game direction: original IP, Freelancer-inspired open-space combat and exploration, polished ship silhouettes, readable HUD, and a playable vertical slice.

## Working agreement
- The user has authorized autonomous implementation, repository edits, tests, CI work, and reasonable technical decisions. Do not ask for approval for every file edit.
- Ask before changing the game's core vision, monetization, licensing, paid services, external accounts, or making irreversible public/release actions.
- Inspect the current branch and relevant files before editing. Do not assume old reports still describe HEAD.
- Make the smallest coherent change; keep work on a feature branch and use a PR for integration.
- Never claim a test, import, render, playtest, or screenshot passed unless its current run/artifact was actually inspected.
- Distinguish static review, parser/import validation, headless runtime tests, graphical capture, and human playtest.
- Never replace missing real 3D assets with fake GLBs or placeholder binaries. Clearly report missing source assets.
- Do not add dependencies, secrets, telemetry, network calls, or shell hooks without a concrete need and review.

## Engine and project constraints
- Engine: Godot 4.7.2. Language: GDScript 2.0.
- Follow the project's existing node/scene architecture and naming conventions; do not impose a generic architecture that conflicts with working code.
- Prefer typed GDScript, explicit signal contracts, deterministic tests, and data-driven tuning.
- Keep gameplay logic separate from presentation where practical. Use delta time for motion and avoid allocations in hot loops.
- Preserve compatibility with the project's CI workflows and Windows desktop target.
- Treat visual changes as unverified until a real Godot render/capture artifact is inspected.

## Definition of Done
1. Acceptance criteria are explicit and tied to the requested outcome.
2. Relevant automated tests are added or updated.
3. Godot headless project/scene validation is run in CI where available.
4. The PR reports exact branch, commit, changed files, test run IDs, and any unverified areas.
5. No unrelated generated files or binary assets are included.

## Agent routing
Use the focused roles in `.codex/agents/` when the active Codex harness supports subagents:
- `producer`: sequencing, scope, dependencies, milestone and risk tracking.
- `technical-director`: architecture, engine constraints, cross-system decisions.
- `godot-gdscript-specialist`: GDScript, scene lifecycle, signals, performance.
- `qa-lead`: test strategy, regression coverage, evidence and release gates.
- `art-director`: ship/level/UI visual consistency and asset pipeline.
- `sound-designer`: audio event specs, mix and implementation acceptance.

If subagents are unavailable, perform the same reviews sequentially and label each perspective. These role files are prompts, not independent running models.

## Project-specific verification
- Read `GROK_START_HERE.md` and relevant docs before large changes.
- Check current GitHub Actions, not only local assumptions.
- For scene/resource changes, validate actual dependencies by loading scenes with the pinned Godot version; `--import` alone is insufficient.
- For combat/flight changes, include deterministic tests for edge cases and regression behavior.
- For visuals, inspect PNG artifacts at native resolution and report renderer/settings.
- Keep screenshots as PNG; do not substitute gameplay video when screenshots are requested.
