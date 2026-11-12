# GALACTIC FRONTIER — Local Save System

Status: foundation implemented; gameplay capture/restore integration remains a separate task.

## Design guarantees

- Offline-only storage under Godot's `user://saves` directory.
- Named slots accept only 1–24 ASCII letters, digits, hyphens and underscores.
- JSON envelope carries a schema version, Unix save timestamp and payload checksum.
- Payload is restricted to JSON-safe values; NaN, infinity, engine Objects and deeply nested data are rejected.
- A save is written to a temporary file, flushed, then atomically renamed into place.
- The previous committed save is retained as `.bak`; failed replacement attempts try to restore it.
- Loading validates file size, JSON structure, schema and checksum. A corrupt primary file falls back to the backup.
- Slot listing ignores corrupt and unsupported files.
- No network calls, telemetry, account identifiers or external services are involved.

## API

Add `scripts/save/save_manager.gd` as an Autoload named `SaveManager` in Project Settings → Autoload.

- `SaveSlots.save_slot(slot_id: String, payload: Dictionary) -> Dictionary`
- `SaveSlots.load_slot(slot_id: String) -> Dictionary`
- `SaveSlots.list_slots() -> Array[Dictionary]`
- `SaveSlots.delete_slot(slot_id: String) -> Dictionary`

Every operation returns a Dictionary with `ok`. Failed operations include an `error` string. A successful load returns `payload`, `saved_at_unix`, `schema_version` and `recovered_from_backup`.

## Initial payload contract

The manager deliberately does not serialize live scene nodes or Resources. The game layer must construct a plain-data snapshot, for example:

```gdscript
{
    "player": {
        "ship_id": "player_fighter",
        "position": [0.0, 0.0, 0.0],
        "rotation": [0.0, 0.0, 0.0],
        "velocity": [0.0, 0.0, 0.0],
        "hull": 100.0,
        "shield": 60.0,
        "boost": 10.0
    },
    "credits": 0,
    "current_system": "sol_frontier",
    "completed_missions": [],
    "mission_flags": {}
}
```

Vectors must be converted to three-number arrays and reconstructed by the gameplay layer. Do not persist NodePaths, Object references, active projectiles, enemy nodes or transient UI state.

## Validation

Run the regression suite with:

```sh
godot --headless --path . --script res://tests/save/test_save_manager.gd
```

The Silent Relay mission currently uses the `quick` slot: F5 saves player flight state and mission checkpoint; F9 restores it. During a defence wave, loading recreates that wave rather than persisting individual enemy transforms and health. The save foundation must pass the suite before further persistence scope is added. Schema changes require an explicit migration path; never silently reinterpret an unknown future version.
