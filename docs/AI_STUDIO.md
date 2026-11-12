# AI Studio integration

## Selected upstream
This project adopts a **small, Godot-focused subset** of [bullish0x/GameStudio](https://github.com/bullish0x/GameStudio), rather than copying all 55 agents / 182 skills.

Audit performed against upstream `main` on 2026-11-12:
- Upstream advertises 55 agents, 182 skills, 13 hooks, 14 rules, and 41 templates.
- It contains a provider-neutral `.agents/` source and a Codex adapter under `.codex/`.
- Its README explicitly describes GameStudio as a project-local framework, not an automatically installed ChatGPT plugin or published Codex marketplace package.
- The upstream installer is manifest-tracked and designed not to overwrite user files, but a full install would add a very large, mostly irrelevant multi-engine framework.
- The source has an MIT license. The required notice is preserved in `THIRD_PARTY_NOTICES.md`.

## What this project includes
- Six focused Codex agent roles: producer, technical director, Godot GDScript specialist, QA lead, art director, sound designer.
- Three project-specific workflows: project audit, Godot scene validation, code review, plus visual evidence.
- A customized root `AGENTS.md` with the actual engine version, project constraints, autonomous-work authorization, verification rules, and agent routing.

## What was deliberately not copied
- Unity, Unreal, browser-game, and multiplayer/networking specialists.
- Generic hooks that run shell scripts automatically on session/commit/push.
- Installer scripts and broad template/document trees.
- Provider/model credentials, gateways, and launcher integrations.

Reason: this project is Godot-only; hooks can execute commands with side effects and should not be enabled without reviewing each one; and the existing repository already has its own CI, architecture, and workflow.

## Important runtime limitation
These files are repository instructions and Codex agent definitions. They do not start 6 independent model instances by themselves. A compatible Codex harness must load `.codex/agents/*.toml` and support subagents. In this ChatGPT conversation, I can use GitHub tools and perform specialist reviews sequentially, but cannot claim that the 6 roles are running as parallel agents.

## How to use in Codex
Open the repository in a current Codex desktop/CLI session. Codex reads `AGENTS.md` and can use project-scoped agent definitions from `.codex/agents/` when the active harness supports subagents. Ask it to audit the project or delegate a task to one of the roles. Keep routine implementation autonomous; reserve user approval for major vision/scope, licensing, spending, external account, and release decisions.
