# GALACTIC FRONTIER — Local Save and Pilot Profile

Status: **implemented and covered by automated regression tests**. Gameplay save/restore is integrated into The Silent Relay mission and the main-menu Continue flow.

## Storage and safety

- Offline-only storage under Godot's `user://saves` directory.
- No account, server, telemetry or external service is required for saving.
- Named slots accept only 1–24 ASCII letters, digits, hyphens and underscores.
- JSON envelope carries a schema version, Unix save timestamp and payload checksum.
- Payload is restricted to JSON-safe values; NaN, infinity, engine Objects and deeply nested data are rejected.
- A save is written to a temporary file, flushed, then atomically renamed into place.
- The previous committed save is retained as `.bak`; failed replacement attempts try to restore it.
- Loading validates file size, JSON structure, schema and checksum. A corrupt primary file falls back to the backup.
- Slot listing ignores corrupt and unsupported files.

## Autoloads

Project Settings registers these autoloads in order:

- `GameSave` → `scripts/save/save_manager.gd`
- `GameProfile` → `scripts/core/player_profile.gd`

The save-manager API is exposed through the `GameSave` autoload:

- `GameSave.save_slot(slot_id: String, payload: Dictionary) -> Dictionary`
- `GameSave.load_slot(slot_id: String) -> Dictionary`
- `GameSave.list_slots() -> Array[Dictionary]`
- `GameSave.delete_slot(slot_id: String) -> Dictionary`

Every operation returns a Dictionary with `ok`. Failed operations include an `error` string. A successful load returns `payload`, `saved_at_unix`, `schema_version` and `recovered_from_backup`.

## Active slots

### `silent_relay` — mission checkpoint

The mission director stores plain data:
- mission ID and stage;
- wave index, elapsed mission time and enemies destroyed;
- player world position, rotation and velocity;
- current hull and shield values.

F5 writes a manual checkpoint. F9 restores it. The main menu shows Continue only when a valid checkpoint for `silent_relay` exists.

Continue uses a one-shot `GameSave.pending_mission_payload` handoff. The menu sets it before changing scenes; the mission director consumes it only after the player, HUD and navigation beacon have initialized. This avoids losing the deferred restore when the menu scene is freed and prevents a fresh-start checkpoint from overwriting the saved one.

When restoring during a defence stage, enemy scene nodes are not serialized; the active wave is regenerated from the saved stage and wave index. Transient projectiles and UI state are intentionally not saved.

### `pilot_profile` — persistent player progression

The `GameProfile` autoload stores:
- selected ship ID;
- credits;
- unlocked ship IDs;
- completed mission IDs.

Current demo economy:
- starting balance: 2,500 CR;
- Raider Interceptor: 2,500 CR;
- Aegis Heavy Fighter: 5,000 CR;
- Bastion Bomber: 7,500 CR;
- first completion of The Silent Relay: +5,000 CR.

Mission rewards are idempotent: the same mission ID cannot grant the reward twice. The automated QA driver suppresses persistent rewards so visual/regression runs do not alter a user's pilot profile.

## Validation

Godot CI runs:
- save-manager regression tests;
- end-to-end Continue test (menu → mission → restored stage/player state);
- player ship purchase/profile test;
- one-time mission reward and insufficient-credit checks.

The latest verified CI run is linked from the [README](../README.md). Manual testing on a user's Windows PC remains a separate step.
