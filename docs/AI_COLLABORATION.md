# AI collaboration protocol — GALACTIC FRONTIER

## Purpose

ChatGPT and Grok contribute in parallel on separate work packages. ChatGPT is the integration lead; Grok currently owns narrative development. The owner approves product direction and scope and is not expected to write code or install development tools.

## Current repository baseline

- Repository: `valdissor1990-ui/GALACTIC-FRONTIER`
- Canonical integration branch: `chatgpt/ten-minute-vertical-slice`
- Current verified project version: `0.1.0`
- Engine: Godot 4.7.2-stable, GDScript.
- The Silent Relay is a playable mission with combat waves, local checkpoint saves, a persistent pilot profile, ship purchases and a 7-ship hangar.
- Four small fighter-class ships are pilotable; Mule Cargo Hauler, Vanguard Frigate and Leviathan Cruiser are display-only.
- See README.md and docs/ROADMAP.md before starting. Do not rely on old Phase 1 task descriptions or stale branch names.

## Roles

### ChatGPT — integration lead
- Owns architecture, task decomposition, code implementation, CI, reviews and merges.
- Verifies the actual repository state and CI evidence before reporting completion.
- Does not claim Grok has completed work before a commit/PR exists.
- Avoids editing the same files concurrently with Grok.

### Grok — narrative and content contributor
- Current assignment: develop original story, characters, mission concepts and dialogue for the next campaign steps after The Silent Relay.
- Do not copy Freelancer plot, characters, names, dialogue or protected designs. Use only broad space-RPG genre conventions.
- Produce practical, implementation-ready content: mission goals, mission stages, objectives, branching choices, radio dialogue, character voice and rewards.
- Keep the first expansion within the existing Godot mission framework; do not invent large systems that are not yet implemented.
- Do not edit production code, project settings, ship assets, save/profile code or CI unless ChatGPT explicitly assigns a separate implementation task.

## Current narrative work package

Create a new branch named `grok/narrative-phase-2` from the latest `chatgpt/ten-minute-vertical-slice` head.

Create only new files under `docs/story/`:
- `next_missions.md` — 2–3 follow-up missions after The Silent Relay, with clear objectives and gameplay stages.
- `characters.md` — 3–5 original characters, their roles, motivations and distinct voices.
- `dialogue_the_silent_relay.md` — polished radio dialogue for the existing mission, grouped by mission stage and combat wave.

Acceptance criteria:
1. Story is original and consistent with the existing premise of isolated colonies and a damaged ancient gate network.
2. Each mission can be built from existing flight, scan, combat-wave and return-to-carrier mechanics. Mark any proposed new mechanic as a future dependency.
3. Dialogue is concise enough for radio delivery and has distinct speaker identities.
4. Include mission objective, success/failure conditions, estimated playtime, rewards and transition to the next mission.
5. No changes to GDScript or existing production files.
6. Open a PR to `chatgpt/ten-minute-vertical-slice`; do not merge it.

## Parallel-work rules

1. Every task has one owner, a branch, an allowed file list, a deliverable and acceptance criteria.
2. ChatGPT and Grok must not edit the same files concurrently.
3. Base work on the latest agreed branch head and record the exact base SHA. If the base changes materially, refresh the branch before opening a PR.
4. Production changes go through PR review. ChatGPT checks the diff, compatibility with Godot 4.7.2-stable, licensing, tests and CI.
5. Keep changes small and independently reviewable. No broad refactors, new dependencies or engine changes without approval.
6. A test that was merely written is not a passing test. Report whether it was actually run by Godot CI.
7. Keep the GitHub repository as the source of truth; record task handoffs and design decisions in the repository.

## Handoff format

Every handoff must state:
- task and base SHA;
- branch and final commit SHA;
- files changed;
- implementation/content summary;
- exact test commands and actual results, or state NOT RUN;
- known limitations;
- PR URL.

ChatGPT inspects the actual commit and diff before integration. A textual claim or pasted code alone is not treated as merged work.
