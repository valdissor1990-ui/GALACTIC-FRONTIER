# GROK TASK — GALACTIC FRONTIER Unreal migration audit

You are the independent audit and migration-planning agent for GALACTIC FRONTIER.

## Decision already made
The project is migrating fully to Unreal Engine 5.8.4 stable for Windows PC, single-player, personal/non-commercial use. The Godot project must remain intact as a reference until the Unreal version is accepted. Do not debate the engine choice or propose a second engine.

## Your exclusive scope
Perform a deep, evidence-based audit of the existing Godot integration branch and produce a migration specification. Do not edit implementation files. Your only permitted repository change is:
`docs/UNREAL_GROK_AUDIT.md`

Implementation ownership belongs to ChatGPT. Do not modify:
- `Unreal/`
- `Source/`
- `.uproject` or Unreal config
- existing Blender generators
- existing GLB/BLEND/texture/audio assets
- Godot files
- README, master plan or shared docs

## Audit tasks

1. Enumerate every playable system, subsystem, scene, autoload, resource, input action, test and workflow.
2. Trace actual call/dependency relationships. Do not rely on names or README claims alone.
3. Create a migration matrix with columns:
   - System / feature
   - Existing Godot source paths
   - Current behavior and state/data
   - Dependencies and event flow
   - Unreal destination (C++ / Blueprint / Data Asset / UMG / Niagara / Enhanced Input / SaveGame etc.)
   - Migration risk
   - Acceptance test
   - Status (not started / scaffold / ported / verified)
4. Audit flight behavior in detail: acceleration, inertia/drag, braking, boost depletion/recharge, angular inertia, mouse look, camera switching, destroyed-state behavior and input focus/pause.
5. Audit combat: target acquisition/clear, weapons, cooldowns, projectile movement/collision, damage, shields, enemy AI, waves and encounter lifecycle.
6. Audit player profile/save: schema, versioning, selected ship, credits, unlocks, modules, contract state, mission completion, story flags, checkpoint/retry and backward-compatible migration.
7. Audit mission/story canon and flag dependencies. Resolve authoritative sources and identify conflicts/unfinished branches.
8. Inventory every ship and environment asset. Reuse existing `.blend` and `.glb` files; no replacement ship. Record materials/textures, UV concerns, scale, forward axis, pivot, collision and LOD readiness.
9. Audit UI, audio, VFX, environment, settings, update manager and offline/no-network requirements.
10. Audit current tests and CI; map each to an Unreal automation/editor/functional test or manual acceptance test.
11. Identify hidden dependencies, dead code, duplicate systems, incomplete features and risks likely to cause regressions.
12. Recommend an implementation order that respects dependencies and keeps Player Fighter as the first visual/gameplay vertical slice.

## Quality requirements
- Every factual claim must point to exact file paths and, where possible, function/class names.
- Separate implemented, partially implemented, planned and merely documented behavior.
- Do not mark something implemented just because a document describes it.
- Do not claim a test passed unless you can cite its actual run/result.
- No generic advice; findings must be specific to this repository.
- Do not invent engine APIs. UE mapping may be conceptual if not verified against UE 5.8.4 docs.

## Deliverable
Write `docs/UNREAL_GROK_AUDIT.md` with:
1. Executive summary.
2. Complete system inventory.
3. Migration matrix.
4. Asset readiness inventory.
5. Data/save compatibility plan.
6. Test and CI replacement plan.
7. Critical risks and missing requirements.
8. Recommended phased sequence.
9. Explicit evidence references.

Do not create code or assets. Do not touch `main`. Work only on the assigned branch if you have repository access. If you cannot edit the repository, return the complete report and clearly say it has not been committed.
