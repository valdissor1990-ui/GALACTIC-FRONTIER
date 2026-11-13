# AI collaboration protocol — GALACTIC FRONTIER

## Purpose

ChatGPT and Grok are two active contributors, not "developer plus auditor". They work in parallel on separate work packages, exchange commits and review each other's results. The owner approves product direction and scope; they are not expected to write code or install development tools.

## Roles

### ChatGPT — integration lead
- Owns the canonical project plan, architecture decisions, task decomposition and integration into `phase-1/flight-prototype`.
- Implements assigned work packages, maintains CI, resolves conflicts and reviews Grok's pull requests.
- Verifies the actual repository state and CI evidence before reporting completion.
- Does not silently overwrite Grok's work or claim that Grok has done work before a commit/PR exists.

### Grok — parallel implementation contributor
- Must implement concrete, bounded work packages, not stop at audits or recommendations.
- Works on a dedicated branch named `grok/<task-slug>`; never commits directly to `main` or `phase-1/flight-prototype`.
- Creates commits and opens a pull request targeting `phase-1/flight-prototype`.
- Supplies complete implementation, tests, exact commit SHA, changed-file list, test commands and honest PASS/FAIL/NOT RUN statuses.
- Performs a self-review before requesting ChatGPT integration.
- May independently review ChatGPT changes, but review must not replace its assigned implementation work.

## Parallel-work rules

1. Every task has one owner, a branch, an allowed file list, a deliverable and acceptance criteria.
2. ChatGPT and Grok must not edit the same files concurrently. If a task needs shared files, agree on ownership first.
3. Grok bases its task branch on the latest agreed Phase 1 HEAD and records that base SHA. If the base changes materially, rebase/refresh before opening a PR; never overwrite newer work.
4. Production changes go through PR review. No automatic merge. ChatGPT checks the diff, compatibility with Godot 4.7.2-stable, licensing, tests and CI.
5. Keep changes small and independently reviewable. No broad refactors, new dependencies, engine changes or Phase 2 systems without approval.
6. A test that was merely written is not a passing test. Report whether it was actually run by Godot CI.
7. Maintain one source of truth: the GitHub repository. Put task handoffs, design decisions and verification results in the repository, not only in chat.

## Current parallel assignment

**Grok owns:** Phase 1 deterministic tests for `FlightModel.integrate_velocity()`.

- Branch: `grok/phase1-flightmodel-tests`
- Base: `c16af851101f5e693fa13cca34c4a3fd7be81ff5`
- Allowed new files: `tests/flight/test_flight_model.gd` and `docs/PHASE1_TESTS.md` only.
- Do not edit production scripts, project settings, workflow files, roadmap or the main implementation notes.
- Cover acceleration along a normalized direction, speed limiting, exponential drag, no drag while acceleration input is present, and zero delta.
- Use a lightweight Godot 4.7.2-compatible headless test runner without third-party dependencies.
- Document the exact command to run the tests and the expected output/exit code.
- Open a PR to `phase-1/flight-prototype`; do not merge it.

**ChatGPT owns:** integration protocol, project size/content budget documentation, and review/integration of Grok's test PR. ChatGPT will separately extend CI to run the tests only after reviewing the submitted test runner.

## Handoff format

Every handoff must state:
- task and base SHA;
- branch and final commit SHA;
- files changed;
- implementation summary;
- exact test commands and actual results;
- known limitations and NOT RUN items;
- PR URL.

The integration lead must inspect the actual commit and diff; a textual claim or pasted code alone is not treated as a merged implementation.
