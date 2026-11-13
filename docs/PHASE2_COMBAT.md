# Phase 2 — Combat vertical slice

Status: implementation in progress; Godot runtime and interactive playtest are NOT RUN.

## Goal

Turn the flight prototype into the first combat encounter. The initial slice deliberately contains one player ship, one enemy fighter, one primary weapon, target lock, shields, hull damage, and a repeatable encounter. It is a systems prototype, not final art or a full arsenal.

## Player controls

| Action | Input | Purpose |
|---|---|---|
| Fire primary | Left mouse button | Fire the forward energy weapon |
| Acquire target | T | Lock the best target near the camera reticle |
| Clear target | Y | Clear the current lock |
| Existing flight controls | W/A/S/D, Space/Z, Q/E, I/K, J/L, Shift, X, C | Fly, rotate, boost, brake and change camera |

## Runtime architecture

- `Damageable` is a reusable child component named `Damageable`. It owns shield/hull values, shield regeneration delay, damage application and the destroyed signal.
- `TargetingSystem` is a child of the player ship. It searches the `combat_targets` group and selects the best candidate inside the active camera's forward acquisition cone and maximum range.
- `WeaponSystem` is a child of the player ship. It owns the primary-weapon cooldown and spawns `CombatProjectile` instances at its `Muzzle` marker.
- `CombatProjectile` moves in a straight line, ignores its source ship, detects physics bodies and calls `take_damage(amount)` on the first compatible damage receiver.
- `CombatHUD` displays the locked target, target shield/hull state, and player shield/hull state.

## Enemy integration contract

The enemy fighter scene must:
1. Add its root Node3D/CharacterBody3D to group `combat_targets`.
2. Contain a child node named `Damageable` using `res://scripts/combat/damageable.gd`.
3. Contain a collision shape on physics collision layer 1 so projectiles can detect it.
4. Expose its root as a Node3D and remain within the targeting system's configured range.
5. Use the shared projectile scene and call `configure(direction, source, speed, damage)` before adding each projectile to the active scene.
6. Never modify the player flight controller or the shared combat core files.

## Acceptance criteria

- Player can acquire a target in front of the active camera and clear the lock.
- Targets outside the acquisition cone or maximum range are rejected.
- Holding primary fire creates projectiles at the muzzle, respecting the fire-rate cooldown.
- Projectiles do not damage their source and apply damage to compatible targets on collision.
- Shield absorbs incoming damage before hull; overflow damages hull.
- Shields regenerate only after the configured delay; destroyed combatants do not regenerate.
- HUD reports target lock, target shield/hull, and player shield/hull.
- At least one enemy can approach, maneuver, fire, take damage, and be destroyed.
- The encounter can be restarted/repeated without restarting the application.

## Verification policy

Automated headless tests are not a substitute for combat playtesting. Report separately:
- static review;
- Godot parser/import and headless tests;
- combat scene headless startup;
- interactive Windows combat playtest.

Until the corresponding Godot CI run succeeds, all newly added combat tests and scenes remain NOT RUN. Until an interactive Windows session is played, aiming feel, projectile readability, combat pacing and visual feedback remain NOT RUN.
