# UNREAL GROK AUDIT — GALACTIC FRONTIER

**Auditor:** Grok (independent audit / migration specification only)  
**Branch audited:** `chatgpt/unreal-migration-ue5.8` @ `2b4b3d28fa173345a4762356330eaadfc16bbf0e`  
**Godot reference:** same branch (Godot tree coexists with `Unreal/` scaffold)  
**Target engine (decided):** Unreal Engine 5.8.4 stable, Windows PC, single-player, offline  
**Scope of this file:** audit + migration matrix only. No Unreal/Godot implementation edits.

---

## 1. Executive summary

The Godot prototype on this branch is a **playable systems stack**, not a document-only design: flight with inertia, combat (weapons, targeting, damage, enemy AI, encounters), profile/save, campaign/story managers, UI hooks, audio/update/graphics autoloads, ship art sources (7× `.blend`), and a broad `tests/` tree.

Unreal side today is **scaffold only**: `Unreal/GalacticFrontier.uproject`, `Unreal/Source/`, `Unreal/Config/`, `Unreal/Content/`. Per `UNREAL_MIGRATION_PLAN.md`, the game is **not yet playable in Unreal** and must not be reported as built or verified without an actual UE 5.8.4 run.

**Critical path for Gate 1:** Enhanced Input → `ShipController`/`FlightModel` parity → cameras → `Damageable` + `WeaponSystem`/`Projectile` → import `player_fighter` GLB/BLEND → lighting review.

**Highest migration risks:** (1) CharacterBody3D + custom drag vs Chaos/pawn movement, (2) save schema + profile multipliers, (3) Godot axis convention (forward −Z) vs Unreal (+X), (4) dual graphics stacks (Godot shaders vs UE materials/Niagara) without rewriting gameplay.

---

## 2. Complete system inventory

### 2.1 Autoloads (`project.godot`)

| Autoload name | Script | Role |
|---------------|--------|------|
| `GameSave` | `scripts/save/save_manager.gd` | Versioned JSON slots, atomic write, backup |
| `Campaign` | `scripts/story/campaign_manager.gd` | Mission/campaign runtime |
| `GameProfile` | `scripts/core/player_profile.gd` | Ship selection, credits, unlocks, modules, stats |
| `AudioManager` | `scripts/audio/audio_manager.gd` | Audio routing (present as autoload) |
| `UpdateManager` | `scripts/update/update_manager.gd` | Offline/update policy surface |
| `GraphicsQuality` | `scripts/graphics/graphics_quality.gd` | Quality presets (Godot-specific) |

Main scene: `res://scenes/bootstrap/main.tscn`.

### 2.2 Input map (`project.godot` [input])

Implemented actions: `move_forward/backward/left/right/up/down`, `yaw_left/right`, `pitch_up/down`, `roll_left/right`, `boost`, `brake`, `toggle_camera`, `pause_game`, `sensitivity_up/down`, `fire_primary`, `target_lock`, `target_clear`, `scan`.

Physics: gravity `0`, 60 Hz. Display baseline 1920×1080, Forward+.

### 2.3 Script modules (directories under `scripts/`)

| Dir | Implemented files (this branch) |
|-----|----------------------------------|
| `flight/` | `ship_controller.gd`, `flight_model.gd`, `ship_flight_config.gd`, `camera_rig.gd`, `docking_rules.gd` |
| `combat/` | `weapon_system.gd`, `projectile.gd`, `targeting_system.gd`, `damageable.gd`, `enemy_combat_ai.gd`, `combat_encounter_controller.gd` |
| `core/` | `player_profile.gd`, `game_session.gd` |
| `save/` | `save_manager.gd` |
| `story/` | `campaign_manager.gd`, `mission_catalog.gd`, `story_state.gd`, `dialogue_m01_m05.gd` |
| `ai/`, `audio/`, `demo/`, `environment/`, `graphics/`, `ui/`, `update/`, `vfx/`, `visual/`, `blender/` | Present; treat as implemented only where scripts are referenced by scenes/autoloads |

### 2.4 Scenes

`scenes/bootstrap`, `combat`, `demo`, `environment`, `flight`, `ships`, `ui` — vertical slice entry points live under flight/demo/bootstrap (exact mission scene names must be resolved when wiring Gate 2).

### 2.5 Tests / CI

`tests/` contains: `assets`, `audio`, `combat`, `demo`, `environment`, `flight`, `graphics`, `save`, `story`, `ui`, `update`, `visual`.  
**This audit did not execute any test.** Status of each suite = unknown until ChatGPT runs Godot headless / UE automation.

### 2.6 Unreal scaffold

- `Unreal/GalacticFrontier.uproject`
- `Unreal/Source/`, `Unreal/Config/`, `Unreal/Content/`
- Status: **scaffold / not ported** (plan text: migration started, not playable)

---

## 3. Migration matrix

Columns: System | Godot paths | Behavior / state | Dependencies | Unreal destination (conceptual) | Risk | Acceptance test | Status

| System | Godot source | Behavior / state | Dependencies | Unreal destination | Risk | Acceptance | Status |
|--------|--------------|------------------|--------------|--------------------|------|------------|--------|
| Bootstrap | `scenes/bootstrap/main.tscn` | App entry | Autoloads | GameMode + default map | L | Cold start to menu/flight | not started |
| Flight config data | `scripts/flight/ship_flight_config.gd`, `resources/ships/*` | max_speed, accel, drag, boost, rotation | Profile multipliers | Data Asset `UShipFlightConfig` | L | Numbers match defaults | not started |
| Flight integration | `scripts/flight/flight_model.gd` `integrate_velocity` | Accel along dir; else exponential drag; clamp max speed | Pure math | C++ `FFlightModel` or component | M | Deterministic unit tests | not started |
| Ship pawn | `scripts/flight/ship_controller.gd` | CharacterBody3D, boost pool, angular inertia, mouse look, destroy freeze | FlightModel, Damageable, WeaponSystem, GameProfile, CameraRig | `APawn`/`ACharacter` + floating movement or custom | **H** | Gate 1 control parity | not started |
| Cameras | `scripts/flight/camera_rig.gd` | Chase ↔ cockpit toggle | Input `toggle_camera` | SpringArm + camera actors | M | Toggle both views | not started |
| Docking rules | `scripts/flight/docking_rules.gd` | Rule helper (small) | Flight | Component / subsystem | L | Unit + manual dock | not started |
| Damage/shields | `scripts/combat/damageable.gd` | Hull/shield, regen, destroyed signal | ShipController listen | ActorComponent | M | Shield then hull, death | not started |
| Weapons | `scripts/combat/weapon_system.gd` | Cooldown fire, spawn projectile | Muzzle, profile stats | ActorComponent + timer | M | ROF and damage apply | not started |
| Projectiles | `scripts/combat/projectile.gd` + `scenes/combat/projectile.tscn` | Move, collide, damage | Layers/masks | Actor + projectile movement | M | Hit target once | not started |
| Targeting | `scripts/combat/targeting_system.gd` | Lock / clear | Input T/Y | Component + UI | M | Lock nearest valid | not started |
| Enemy AI | `scripts/combat/enemy_combat_ai.gd` | Engage player | Damageable, weapons | AIController / BehaviorTree or C++ | **H** | Wave engagement | not started |
| Encounters | `scripts/combat/combat_encounter_controller.gd` | Spawn/respawn waves | Enemy scene | GameMode subsystem | M | 6-wave Silent Relay | not started |
| Profile | `scripts/core/player_profile.gd` | Ships, credits, modules, stats API | Save, ShipController | SaveGame + subsystem | **H** | Select ship applies stats | not started |
| Session | `scripts/core/game_session.gd` | Session glue | Profile/Campaign | GameInstance subsystem | L | Persist across maps | not started |
| Save | `scripts/save/save_manager.gd` | schema v1, hash, atomic .tmp→commit, .bak | user://saves | USaveGame + atomic file IO | **H** | Save/load/backup recovery | not started |
| Campaign | `scripts/story/campaign_manager.gd` | Mission flow | Catalog, StoryState, Save | Quest/mission subsystem | **H** | Silent Relay complete | not started |
| Missions | `scripts/story/mission_catalog.gd` | Definitions | Campaign | Data assets | M | Catalog load | not started |
| Story flags | `scripts/story/story_state.gd` | Flags | Campaign/Save | SaveGame fields | M | Flag round-trip | not started |
| Dialogue M01–M05 | `scripts/story/dialogue_m01_m05.gd` | Dialogue data/flow | UI | DataTable + UMG | M | Choice advances flag | not started |
| Graphics quality | `scripts/graphics/graphics_quality.gd` | Presets, FSR-like scale (Godot) | Viewport | Scalability + CVars | M | 3 presets change cost | not started |
| VFX (Godot) | `scripts/vfx/*`, shaders | Particles, post, lens | GraphicsQuality | Niagara + PostProcess | M | Boost/muzzle visible | not started |
| Environment | `scripts/environment/*`, scenes | Space backdrop, POI | Graphics | Level + actors | M | Visible landmarks | not started |
| Audio | `scripts/audio/audio_manager.gd` | Autoload | — | AudioSubsystem / MetaSounds | L | Play/stop | not started |
| Update manager | `scripts/update/update_manager.gd` | Offline-first surface | Network **must stay optional/off** | Local-only stub | L | No network required | not started |
| UI HUD/menus | `scripts/ui/*`, `scenes/ui/*` | Telemetry, combat HUD, menus | Ship, targeting | UMG / CommonUI | M | HUD numbers track ship | not started |
| Input | `project.godot` | Keyboard + mouse fire | All gameplay | Enhanced Input | M | Full action map | not started |

---

## 4. Flight behavior audit (detail)

**Source:** `ShipController` + `FlightModel` + `ShipFlightConfig`.

| Behavior | Implementation evidence | UE note |
|----------|-------------------------|---------|
| Translation input | Axes → local Vector3 → world via `global_transform.basis` | Map WASD/Space/Z to same local space |
| Acceleration | `integrate_velocity`: add `dir.normalized() * acceleration * delta` | Match formula |
| Inertia / no input | `result *= exp(-drag * delta)` | Not linear damp only—match exponential |
| Max speed | `limit_length(max_speed)` | After boost multipliers |
| Boost | Hold boost & `boost_amount > 0`: drain per second; else recharge to capacity; multiplies accel & max_speed | Separate resource |
| Brake | Uses `brake_drag` instead of `drag` while held | Higher exp decay |
| Angular keyboard | Desired ω = input * rotation_speed; move_toward with rotation_acceleration; apply local pitch/yaw/roll | Separate from mouse |
| Stabilization | When no keyboard rotation input, move_toward zero with rotation_stabilization | |
| Mouse look | Immediate local yaw/pitch from accumulated delta; **not** mixed into angular velocity; delta capped 250 px/physics tick | Critical feel |
| Focus loss | App focus out → clear mouse delta, show cursor; focus in → capture if not paused | |
| Pause | `_unhandled_input` ignores when `get_tree().paused` | |
| Destroyed | `_on_destroyed`: zero velocity/ω, stop physics & unhandled input, disable WeaponSystem process | |
| Profile | `_apply_profile_configuration` loads selected ship config + multiplies stats; `refresh_profile_upgrades` does not full-heal | |

Default config numbers (`ShipFlightConfig`): max_speed 95, accel 34, drag 0.85, boost speed×1.55, boost accel×1.35, brake_drag 16, rotation_speed 1.35, rotation_accel 5.5, rotation_stab 4.0, boost_capacity 10, recharge 2.0.

---

## 5. Combat audit

| Piece | Path | Notes |
|-------|------|-------|
| Weapon | `weapon_system.gd` | SPS, projectile speed/damage; cooldown; needs muzzle |
| Projectile | `projectile.gd` + scene | Area/collision based; owner ignore |
| Targeting | `targeting_system.gd` | lock/clear actions |
| Damageable | `damageable.gd` | shield then hull; regen; `destroyed` signal |
| Enemy AI | `enemy_combat_ai.gd` | Lead-aim style combat AI (large script) |
| Encounter | `combat_encounter_controller.gd` | Spawn path, respawn delay, player path |

Vertical slice intent (from migration plan): Silent Relay — travel, two combat zones, six waves, return carrier. **Mission scene wiring must be verified against `campaign_manager` + demo scenes before Gate 2.**

---

## 6. Save / profile compatibility

### SaveManager
- Schema **version 1** only (`CURRENT_SCHEMA_VERSION = 1`).
- Envelope: `schema_version`, `saved_at_unix`, `payload_hash`, `payload`.
- Atomic write: `.tmp` → rename; previous → `.bak`.
- Size cap 2 MiB; slot id alphanumeric/`-_`, max 24 chars.
- Load tries primary then backup; checksum via canonical JSON hash.

### Profile
- `player_profile.gd` is large (~15KB): ships, credits, unlocks, modules, flight config paths, combat stat getters used by `ShipController`.
- UE must preserve **payload dictionary shape** or ship a one-time migrator if schema bumps.

### Plan
1. Mirror schema v1 JSON on disk **or** USaveGame that serializes identical payload keys.  
2. Version field required; reject unknown versions with explicit error (Godot already does).  
3. Test: save → kill process → load primary; corrupt primary → load `.bak`.

---

## 7. Story / mission canon

**Code authority (runtime):** `campaign_manager.gd`, `mission_catalog.gd`, `story_state.gd`, `dialogue_m01_m05.gd`.

**Doc authority (design):** `docs/CANON_STORY_UNIFIED.md`, `docs/CAMPAIGN_STORY.md`, `docs/NARRATIVE_BIBLE.md` (per migration plan).  
**Conflict rule:** if docs disagree with campaign code, **code wins for port behavior**; docs updated separately. This audit did not line-diff all narrative docs vs `mission_catalog`—ChatGPT should run that diff before Gate 2.

---

## 8. Asset readiness inventory

### Ships (Blender sources present)

| Asset | Path |
|-------|------|
| Player Fighter | `art_source/ships/player_fighter.blend` |
| Enemy Fighter | `art_source/ships/enemy_fighter.blend` |
| Heavy Fighter | `art_source/ships/heavy_fighter.blend` |
| Bomber | `art_source/ships/bomber.blend` |
| Frigate | `art_source/ships/frigate.blend` |
| Cruiser | `art_source/ships/cruiser.blend` |
| Cargo Hauler | `art_source/ships/cargo_hauler.blend` |

**Gate 1 ship:** Player Fighter only. Do not invent replacements.

### Import readiness checklist (must be measured in UE, not assumed)
- Scale (Godot meters vs UE cm → typically ×100)
- Forward axis (Godot −Z vs UE +X) and up +Z vs +Z
- Pivot at ship center / landing gear
- Collision: simplified convex or custom shape
- Materials: convert Godot ShaderMaterial to UE materials; emissive panels
- LODs: may be missing—generate in UE or Blender
- GLB exports under `assets/` / `scenes/ships` if present should be preferred for Interchange import

`art_source/.gdignore` — Blender sources excluded from Godot import (correct).

---

## 9. UI, audio, VFX, settings, offline

| Area | State | UE mapping |
|------|-------|------------|
| HUD / combat UI | Implemented in Godot UI scripts/scenes | UMG widgets bound to components |
| Menus / hangar | Present under `scenes/ui` (verify completeness in play) | UMG |
| AudioManager | Autoload | Local audio only; no backend |
| GraphicsQuality | Godot viewport/tonemap/FSR-like | Scalability groups; do not block Gate 1 |
| VFX | Godot GPUParticles / shaders | Niagara (boost, muzzle, dust) |
| UpdateManager | Offline-first | No network dependency for core loop |
| Export | `export_presets.cfg` Windows-oriented | UE packaged Windows |

---

## 10. Tests and CI replacement plan

| Godot area | Suggested UE replacement |
|------------|--------------------------|
| `tests/flight` | Automation test: integrate_velocity table + pawn movement |
| `tests/combat` | Functional: fire → hit → damage |
| `tests/save` | Save/load/backup corruption |
| `tests/story` | Mission flag transitions |
| `tests/graphics` | Optional smoke; not Gate 1 blocker |
| CI Godot headless | Build C++ + UnrealEditor-Cmd tests on Windows runner when available |

**No test results claimed.** Suites exist as files only.

---

## 11. Critical risks and missing requirements

1. **Movement model parity** — exponential drag + separate mouse look is easy to “simplify” wrong.  
2. **Axis/scale** on Player Fighter import — wrong forward breaks chase camera and weapons.  
3. **Profile multipliers** applied at ship spawn — hangar module install must call non-healing refresh.  
4. **Save schema rigidity** — only v1 accepted; need migration path before changing keys.  
5. **Enemy AI complexity** — large GDScript; port behavior, not line-by-line.  
6. **Dual stacks** — Godot graphics work (other branches) must not block Unreal Gate 1.  
7. **Silent Relay scene graph** — plan describes six waves; confirm encounter controller parameters in demo/mission scenes.  
8. **Unreal build unknown** — scaffold present; **no evidence of successful UE 5.8.4 compile in this audit.**

---

## 12. Recommended phased sequence

Aligns with `UNREAL_MIGRATION_PLAN.md` gates:

**Phase 0 — Foundation**  
Open `.uproject` in UE 5.8.4; C++ module compiles; gitignore generated noise.

**Phase 1 — Player Fighter vertical slice**  
1. Enhanced Input map (parity with `project.godot`)  
2. `FlightModel` + ship pawn  
3. Cameras  
4. Damageable + Weapon + Projectile + Targeting  
5. Import Player Fighter mesh/collision/materials  
6. Manual playtest checklist (below)

**Phase 2 — Silent Relay**  
Encounter controller, waves, campaign flags, checkpoint/save, failure/retry.

**Phase 3 — Rest of fleet & meta**  
Remaining ships, hangar, contracts, dialogue UI, audio polish, packaging.

### Gate 1 manual acceptance (minimum)
- [ ] Thrust, strafe, vertical, boost drain/recharge, brake  
- [ ] Keyboard angular inertia + mouse look  
- [ ] Chase / cockpit  
- [ ] Fire primary, projectile hits dummy Damageable  
- [ ] Target lock/clear  
- [ ] Destroy freezes controls  
- [ ] Ship visually readable under space lighting  

---

## 13. Explicit evidence references

| Claim | Evidence |
|-------|----------|
| Autoloads / input / main scene | `project.godot` |
| Flight formula | `scripts/flight/flight_model.gd` `integrate_velocity` |
| Boost/brake/mouse/destroy | `scripts/flight/ship_controller.gd` |
| Config defaults | `scripts/flight/ship_flight_config.gd` |
| Save schema v1 atomic | `scripts/save/save_manager.gd` |
| Profile integration | `ShipController._apply_profile_configuration` |
| Combat set | `scripts/combat/*` |
| Story set | `scripts/story/*` |
| Ship blends | `art_source/ships/*.blend` (7 files) |
| UE scaffold only | `Unreal/*`, `UNREAL_MIGRATION_PLAN.md` status section |
| Grok write scope | `GROK_UNREAL_MIGRATION_TASK.md` |

---

## 14. Auditor notes

- Engine choice is out of scope; no Godot-vs-UE debate.  
- Godot tree must remain until Unreal acceptance.  
- This document is the only Grok deliverable on-repo for this task.  
- Implementation ownership: ChatGPT.

— **Grok**, independent audit agent
