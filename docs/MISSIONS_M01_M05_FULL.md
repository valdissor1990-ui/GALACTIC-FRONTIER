# M01–M05 Full Mission Package

**Canon:** `docs/CANON_STORY_UNIFIED.md`  
**Code:** `scripts/story/*`, `tests/story/test_m01_m05_story.gd`  
**Branch:** `grok/m01-m05-story-pack`

Runtime integration is present in CampaignManager, demo_mission_director and the bilingual dialogue overlay. M01 is exercised in the playable Silent Relay demo; M02–M05 remain data-driven campaign progression and are not yet full standalone playable missions.

---

## Flag table

| Flag | Set when | Meaning |
|------|----------|---------|
| `m01_done` | M01 success | Intro complete |
| `board_tier_0` | M01 | Aurelia contract board open |
| `vesper_access` | M02 | Vesper Salvage board |
| `m02_done` | M02 | |
| `m03_done` | M03 | |
| `shared_helix` | M03 choice | Sold trail to Helix |
| `shared_union` | M03 choice | Gave trail to Union |
| `kept_private` | M03 choice | Nyra-only path |
| `kestrel_access` | M04 | Kestrel Patrol board |
| `m04_done` | M04 | |
| `relay_contact_1` | M05 | Silent Relay answered |
| `m05_done` | M05 | |
| `act1_complete` | M05 | Act I gate for Act II |

---

## Decision consequences (M03)

| Choice | Flags | Relationship deltas |
|--------|-------|---------------------|
| Sell Helix | `shared_helix` | Voss+10, Helix+10, Free Colonies−5, Nyra−2 |
| Union | `shared_union` | Vorn+5, Union+10, Helix−5 |
| Private | `kept_private` | Nyra+10, Helix−3, Union−3 |

**Later hooks (design):**
- Helix → better salvage payouts, colder Free Colony docks, Helix team at M05 optional spawn.
- Union → softer Kestrel scan, Helix prices up.
- Private → slower funds, exclusive Nyra lines, Zero Limit less likely to pre-ambush (story).

---

## Save mapping

Compatible with existing payload contract (`docs/SAVE_SYSTEM.md`):

```json
{
  "mission_flags": { "m01_done": 1, "vesper_access": 1 },
  "completed_missions": ["m01", "m02"],
  "active_mission_id": "m03",
  "relationship": { "sera_quinn": 5, "jex_morra": 5 }
}
```

Use `StoryState.to_save_dict()` / `from_save_dict()` when building the gameplay snapshot. Do not persist Node references.

---

## Mission transitions

`m01 → m02 → m03 → m04 → m05 → (Act II)`  
`MissionCatalog.can_start` enforces order via `requires_missions`.

---

## Revisit lines

Nodes in `DialogueM01M05`: `revisit_quinn_after_m01`, `revisit_quinn_after_m03_helix`, `revisit_quinn_after_m03_private`, `revisit_jex_after_m02`.

Pick revisit node by flags when player talks again at Port Solace / Vesper drop.

---

## Test command

```bash
godot --headless --path . --script res://tests/story/test_m01_m05_story.gd
```

Regression tests run in Godot CI as part of the campaign integration workflow.

---

## Runtime integration status

- `Campaign` autoload owns `StoryState` and `CampaignManager`.
- Campaign objective progress is persisted through the versioned `GameSave` slot.
- Gameplay events are routed to objective types and target IDs; one event advances one matching objective.
- The playable Silent Relay demo starts M01, presents bilingual Quinn dialogue and reports flight/scan/docking milestones.
- M02–M05 definitions and dialogue are present; their dedicated world locations, NPC scenes and complete playable mission loops remain future content work.
- Do not modify SaveManager schema version without migration.

---

*Grok — GALACTIC FRONTIER parallel AI developer*
