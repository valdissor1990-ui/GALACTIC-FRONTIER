# Phase 2 — Combat vertical slice

Status: implemented in the current Full HD development branch. Automated headless tests and Windows export are checked by Godot CI; interactive combat feel and final visual feedback still require playtesting.

## Goal

The first repeatable combat encounter: player ship, one enemy fighter, primary weapon, target lock, shields, hull damage and respawn.

## Runtime architecture

- Damageable owns shield/hull values, regeneration delay and destroyed signal.
- TargetingSystem searches combat_targets and selects a candidate in the active camera cone.
- WeaponSystem spawns shared CombatProjectile instances at the muzzle.
- EnemyCombatAI uses APPROACH / STRAFE / RETREAT / DISABLED.
- CombatEncounterController guards duplicate spawn, removes destroyed enemy and schedules respawn.
- CombatHUD displays target and player shield/hull state.
- HitFlashFx is attached to combat visuals for damage feedback.

## Verification

The CI suite runs combat-system tests, enemy AI/encounter lifecycle tests, flight-scene headless smoke tests and Windows export. A successful headless result does not verify aim feel, pacing, projectile readability or visual impact; those remain manual playtest tasks.
