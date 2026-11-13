# GALACTIC FRONTIER — Unified Canon Story

**Authority:** This document supersedes conflicting bits of `NARRATIVE_BIBLE.md` and `CAMPAIGN_STORY.md` where they disagree.
**Status:** Design canon for ChatGPT integration. No runtime code.
**Author:** Grok (parallel AI developer)

---

## 0. Merge rules

| Source | What we keep |
|--------|----------------|
| Master plan | Gate Network collapse; colony isolation; offline single-player; original IP (no Freelancer copies) |
| Old bible (`NARRATIVE_BIBLE`) | Company fantasy *Orion Pathfinders*; debt-to-dock opening; three-way struggle over infrastructure; character *types* (dock manager, corporate liaison, patrol commander, cult voice, informant, rival captain); Thread = living nav infrastructure |
| Regional campaign (`CAMPAIGN_STORY`) | **Aurelia Reach**, **Vesper Belt**, **Kestrel Expanse**, **Silent Relay**; activities **Vesper Salvage**, **Kestrel Patrol**; mission-sheet format; flags/save; M01–M05 structure |
| Master-plan faction list | Terran Union, Free Colonies, Helix Dynamics, Outer Rim Confederation, Order of Zero Limit — **canonical faction names** |

**Dropped as separate geographies:** Ysera / Korvax as primary galaxy names (optional later as distant labels only).  
**Dropped as faction brand names:** Vector, Ring Guard, Star Ash — mapped onto Helix / Union–Kestrel / Zero Limit.

---

## 1. One-sentence pitch

An independent pilot of the failing contract house **Orion Pathfinders** works Aurelia’s docks, Vesper’s wrecks, and Kestrel’s corridors until the **Silent Relay** answers — and every power wants the Gate spine it can wake.

---

## 2. World (unified)

Human expansion rode an ancient **Gate Network**. A cascade failure shattered reliable travel. Regions lived alone long enough to grow different laws.

| Region | Function |
|--------|----------|
| **Aurelia Reach** | Settled start: Port Solace, licenses, liens, “respectable” contracts |
| **Vesper Belt** | Debris economy; **Vesper Salvage** board; scavenger clans; Helix claims |
| **Kestrel Expanse** | Frontier corridors; **Kestrel Patrol** board; Union interdiction vs free captains |
| **Silent Relay** | Should-be-dead relay cluster that answers on non-registry frequencies; key to Gate spine |

**The Thread:** In-universe name for the deeper Gate navigation layer under charts. Silent Relay is a visible wound in that layer. Control of Thread/Gates = tariffs, blockades, and who eats.

---

## 3. Factions (unified names)

| Faction | Agenda | Regional face |
|---------|--------|----------------|
| **Terran Union** | Restore order and controlled corridors | Kestrel command, Commodore Rusk; Lt. Kade Vorn as conflicted field contact |
| **Free Colonies** | Local autonomy, trade without Union tolls | Aurelia independents, Outer captains |
| **Helix Dynamics** | Own salvage rights and Relay data | Director Helene Voss (absorbs old “Tarek/Vector” role) |
| **Outer Rim Confederation** | Border houses, mercenaries, grey routes | Dock politics, escort markets |
| **Order of Zero Limit** | Gate/Relay are existential threat — seal or break | Ash-Speaker Ila (absorbs old cult voice) |

---

## 4. Player and company

**Company:** Orion Pathfinders — recon, escort, retrieval; nearly broke.  
**Pilot default name:** Riven Hale (renameable).  
**Opening pressure:** Lien at **Port Solace** under dockmaster **Sera Quinn** (Mara Kell role merged here).  
**Missing founder:** Arcadis Voln — logs only; tried to *limit* Thread use, not sell it.  
**Personal hook:** Distress/metadata tag tied to **Ellis Hale** (missing contact) surfaces in Vesper salvage data.

### Core cast (merged)

| Canon name | Role | Old draft echo |
|------------|------|----------------|
| Sera Quinn | Dock / debt / early mentor | Mara Kell |
| Jex Morra | Vesper Salvage broker | — |
| Lt. Kade Vorn | Kestrel Patrol human face | Seva Rinn (softer entry) |
| Commodore Rusk | Hard Union pressure | Rinn at full authority |
| Dr. Nyra Sol | Relay science | — |
| Director Helene Voss | Helix | Yun Tarek |
| Ash-Speaker Ila | Zero Limit | Ilsa “Ash” |
| Cap. Orlen Fisk | Rival free captain | Cap Orsa |
| Nex | Informant, Port Solace / Anchor bars | Nex |
| Boatswain Rhea | Optional hire, ex-patrol tech | Rhea |

---

## 5. Campaign spine (4 acts)

### Act I — Aurelia Reach: License and Lien
Debt, first scans, unlock boards, first moral sale of data.

### Act II — Vesper Belt: What the wrecks remember
Vesper Salvage drives plot; Ellis tag; Helix vs scavengers; path to Relay coordinates.

### Act III — Kestrel Expanse: Who owns the corridor
Kestrel Patrol, interdiction, public stance vs Union/Free captains.

### Act IV — Silent Relay: Open, sell, seal, or hold
Finale branches; Arcadis’s warning resolved by player action.

**Endings (high level):**
1. **Helix charter** — efficiency, private tariffs, Pathfinders paid, colonies dependent.
2. **Union spine** — patrol safety, hard control, grey captains squeezed.
3. **Zero seal** — Relay buried; less catastrophe risk; slower recovery.
4. **Pathfinders custody** — company becomes route-keeper; permanent pressure from all sides.
5. **Break nodes** — no single owner; chaos and freedom mixed.

---

## 6. Mission spine (integration IDs)

Keep M01–M05 from campaign doc; rename flavor only where needed:

| ID | Title | Region | Unlocks |
|----|-------|--------|---------|
| M01 | Port Solace Launch | Aurelia | Board tier 0 |
| M02 | Belt Taste | Vesper edge | **Vesper Salvage** |
| M03 | Name on a Tag | Aurelia/data | Choice flags Helix/Union/Private |
| M04 | Kestrel Escort | Kestrel | **Kestrel Patrol** |
| M05 | Static on the Relay | Silent Relay edge | Act II gate |

Act II+ IDs: M06–M22 as in `CAMPAIGN_STORY.md`, written against unified faction names only.

---

## 7. Choice flags (save)

Minimum set:

`m01_done`, `vesper_access`, `kestrel_access`, `relay_contact_1`,  
`shared_helix`, `shared_union`, `kept_private`,  
`act1_complete` … `act4_path_helix|union|seal|custody|break`,  
`dock_lien_status`, `rheya_hired`, `fisk_rivalry_stage`

---

## 8. Side content

- **Vesper Salvage** board — procedural + arcs (Tarn, claims, deep wrecks).
- **Kestrel Patrol** board — escort, sweep, assist, rescue.
- **Aurelia general** — delivery, bounty, data.
- Long arcs from `SIDE_MISSION_ARCS.md` retargeted to canon names (Quinn debt, Fisk rivalry, Rhea past, Nex under glass, etc.).

---

## 9. Tone and dialogue rules

Unchanged: short NPC lines; 2–4 player replies; consequences delayed 10–30 minutes; no lore lectures; no Freelancer-protected elements.

---

## 10. Deprecation notice

- `NARRATIVE_BIBLE.md` — historical draft; use only for extra dialogue flavor.
- `CAMPAIGN_STORY.md` — regional/mission structure still valid; faction labels must follow **this** file.
- `STORY_ACT1_BEATS.md` / `SIDE_MISSION_ARCS.md` — remap names on implementation.

---

*Grok — GALACTIC FRONTIER parallel AI developer*
