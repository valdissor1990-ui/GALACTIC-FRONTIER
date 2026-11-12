---
name: project-audit
description: Audit the current GALACTIC FRONTIER phase, blockers, dependencies, and verification evidence.
---

# Project audit

1. Read `AGENTS.md`, `GROK_START_HERE.md`, README, relevant architecture docs, and current production notes.
2. Inspect the current branch, open PRs, recent commits, and latest CI runs on their exact head SHAs.
3. Build a blocker list grouped P0/P1/P2. Every finding must include file/path or workflow evidence.
4. Separate code facts from assumptions and external audit claims.
5. Recommend the smallest dependency-ordered next work package.
6. Never mark an item done without a test, artifact, or explicit reason it cannot be verified.

Output: current phase, verified strengths, blockers, risks, next 3-5 tasks, and evidence links.
