# GALACTIC FRONTIER — Campaign Story (Integration Spec)

Status: **design for implementation** (not runtime data yet).
Does not modify GDScript, scenes, or CI.

---

## 0. Existing vs new

### Treated as existing framework (do not reinvent)

From project docs / stated game systems:

| ID | Role in campaign |
|----|------------------|
| **Aurelia Reach** | Settled start region: stations, law, contracts, tutorial space |
| **Vesper Belt** | Hazardous belt: salvage, debris, scavengers |
| **Kestrel Expanse** | Frontier patrol space: military pressure, escorts, interdiction |
| **Silent Relay** | Anomalous relay/gate-signal zone; main mystery hook |
| **Vesper Salvage** | Contract type / activity loop in Vesper Belt |
| **Kestrel Patrol** | Contract type / activity loop in Kestrel Expanse |
| Flight + camera + combat prototype | Player ship control, targeting, damage, enemies |
| Master-plan factions (working names) | Terran Union, Free Colonies, Helix Dynamics, Outer Rim Confederation, Order of Zero Limit |
| Gate network mystery | Ancient spatial Gates; cascade failure; colonies isolated |

### New in this document

- Protagonist identity and motivation
- Political conflict graph tied to the named regions
- Full campaign spine (4 acts) with branches
- Mission sheets: start/end conditions, objectives, dialogues, triggers, rewards, choice consequences
- Side content wired to Vesper Salvage / Kestrel Patrol
- Programmer integration checklist (data only; no code written here)

---

## 1. Universe summary

Human expansion used an ancient **Gate Network**. A cascade collapse isolated colonies. Generations later, power is regional, not galactic.

**Aurelia Reach** rebuilt docks, tariffs, and “respectable” law.  
**Vesper Belt** feeds industry with salvage and ore — and hides unmarked wrecks.  
**Kestrel Expanse** is where patrols and free captains argue over who owns a corridor.  
**Silent Relay** should be a dead nav beacon cluster. It is not dead. It answers on frequencies no colony registry owns.

Themes: control of infrastructure, price of restoration, freedom vs order, responsibility for waking old systems.

---

## 2. Protagonist

**Name (default):** Captain **Riven Hale** (player-renameable).  
**Role:** Independent pilot under a thin commercial license issued in Aurelia Reach.  
**Start condition:** Ship is operational; credits are low; a co-signed dock fee is due at **Port Solace** (Aurelia).

**Motivation ladder (revealed in play):**
1. Clear the dock lien and keep the ship.
2. Find why a personal distress tag from a missing contact pings near Silent Relay.
3. Decide who may control a reawakening Gate spine — Union, Helix, Free Colonies, Zero Limit, or no one.

**Not** a pre-chosen messiah. Power comes from routes, reputation, and keys — not prophecy.

### Allies

| Character | Location bias | Function |
|-----------|---------------|----------|
| **Dockmaster Sera Quinn** | Port Solace (Aurelia) | Early quest giver; debt/practical mentor |
| **Jex Morra** | Vesper Belt | Salvage broker; Vesper Salvage board |
| **Lt. Kade Vorn** | Kestrel Expanse | Patrol contact; law vs pragmatism |
| **Dr. Nyra Sol** | Mobile / Silent Relay research | Scientist; translates Relay signals |
| **Cap. Orlen Fisk** | Free captain | Rival/ally on contracts |

### Opponents / pressure actors

| Character | Faction lean | Function |
|-----------|--------------|----------|
| **Director Helene Voss** | Helix Dynamics | Corporate acquisition of Relay data |
| **Commodore Rusk** | Terran Union / Kestrel command | Order, interdiction, “safety corridors” |
| **Ash-Speaker Ila** | Order of Zero Limit | Wants Relay sealed or destroyed |
| **Wreck-Boss Tarn** | Belt scavenger clan | Violence over salvage rights |

---

## 3. Faction stakes by region

| Region | Who wants what |
|--------|----------------|
| Aurelia Reach | Union legitimacy + Free Colony trade rights; Helix lobbyists |
| Vesper Belt | Helix resource claims; scavengers; Free Colony independents |
| Kestrel Expanse | Union patrol doctrine vs free corridor captains |
| Silent Relay | All major powers; Zero Limit obstruction; scientific open access |

Reputation with factions must gate contracts and alter patrol aggression (designer intent; implement when faction system exists).

---

## 4. Campaign structure

### Act I — Aurelia Reach: License and Lien
Teach flight/combat lightly through story. Establish debt, first choices, rumor of Silent Relay.

### Act II — Vesper Belt: What the wrecks remember
Vesper Salvage jobs become plot carriers. Discover Relay-related wreck data. Helix and scavengers collide.

### Act III — Kestrel Expanse: Who owns the corridor
Kestrel Patrol missions and interdiction. Union pressure. Player forced into public stance.

### Act IV — Silent Relay: Open, sell, or bury
Multi-path finale. Consequences for all three other regions.

**Estimated story mission count:** 28–36 main beats + regional side boards.

---

## 5. Mission sheet format (for programmers)

Each mission resource should eventually support fields:

```
id, act, region
start_conditions[]
end_success[], end_fail[]
objectives[] { id, type, target, count, optional }
dialogue_nodes[]
triggers[] { event, action }
rewards { credits, rep{}, items[], unlocks[] }
choice_flags[]
on_complete_world_events[]
```

Objective types (suggested): `goto`, `scan`, `destroy`, `protect`, `dock`, `deliver`, `survive_timer`, `talk`.

---

## 6. First missions — ready scenarios

### MISSION M01 — Port Solace Launch
**Region:** Aurelia Reach  
**Act:** I  

**Start conditions:**
- New game / campaign flag `campaign_started == false`
- Player ship intact

**Objectives:**
1. `talk` — Sera Quinn (dock office)
2. `dock` exit / undock complete
3. `goto` — nav buoy Aurelia-A3
4. `scan` — buoy
5. `dock` — return Port Solace

**Failure:** none critical (can retry buoy scan).

**Dialogue (short):**

- **Quinn:** Lien is live. Fly the buoy check, bring me a clean scan, and I file your first work stamp.
- **Player:** How deep is the debt? / Just give the coordinates. / What if I refuse?
- **Quinn:** Refuse and the clamps stay. Coordinates on your board. Welcome to Aurelia.

**Rewards:** credits small; unlock contract board tier 0; flag `m01_done`.

**Programmer:** wire as first mission after hangar spawn; no combat required.

---

### MISSION M02 — Belt Taste (Vesper Salvage intro)
**Region:** Aurelia → Vesper Belt edge  
**Start:** `m01_done`

**Objectives:**
1. `goto` — Vesper marker VB-01
2. `scan` — debris field (3 nodes)
3. Optional `destroy` — 0–2 scavenger hostiles if aggro
4. `deliver` — salvage package to Jex Morra drop relay

**Triggers:**
- On first debris scan → radio from Jex (Vesper Salvage license pitch)
- If player fires first on neutral salvage ship → rep scavengers −

**Rewards:** credits; unlock **Vesper Salvage** board; flag `vesper_access`.

**Programmer:** reuse combat only if hostiles exist; salvage can be scan+pickup volumes.

---

### MISSION M03 — Name on a Tag
**Region:** Aurelia / data  
**Start:** `vesper_access`

**Story:** Personal tag of missing contact **Ellis Hale** (sibling/partner — configurable) embedded in salvage metadata.

**Objectives:**
1. `talk` — Quinn with the tag data
2. `talk` — Nyra Sol (holo or station visit)
3. Choice:
   - Share data with Helix contact (Voss)
   - Share with Union desk
   - Keep private (Nyra only)

**Flags:** `shared_helix` / `shared_union` / `kept_private`

**Consequences:**
- Helix: more credits later, less trust from Free Colonies
- Union: patrol friendliness in Kestrel, Helix prices up
- Private: slower funding, exclusive Nyra path into Silent Relay

**Programmer:** choice must persist in save (`SAVE_SYSTEM` story flags).

---

### MISSION M04 — Kestrel Escort (Kestrel Patrol intro)
**Region:** Kestrel Expanse  
**Start:** `m03_done`

**Objectives:**
1. `goto` — convoy gather point
2. `protect` — freighter (timer or distance)
3. `destroy` or `survive` — interdictors
4. `dock` or `goto` — handoff beacon

**Dialogue:**
- **Vorn:** Kestrel Patrol does not pay for elegance. Keep the freighter alive.
- **Player:** Who is hitting convoys? / Copy. / This is Union politics.

**Rewards:** unlock **Kestrel Patrol** contracts; flag `kestrel_access`; rep Union slight + if success.

**Programmer:** protect AI ally ship; fail if freighter destroyed.

---

### MISSION M05 — Static on the Relay
**Region:** approach Silent Relay (restricted edge)  
**Start:** `kestrel_access` AND any of m03 flags

**Objectives:**
1. `goto` — outer relay marker (no full instance yet if not built — use anomaly zone)
2. `scan` — Silent Relay pulse (survive interference timer)
3. Optional combat: Zero Limit skirmishers OR Helix “retrieval” team depending on m03 choice
4. Escape to safe nav

**Twist:** Relay returns a coordinate set inside Vesper deep wreck — not a gate open yet.

**Rewards:** flag `relay_contact_1`; unlock Act II mission gate; Nyra commentary.

**Programmer:** scripted pulse event; region transition safety (clamp speed/hazards).

---

## 7. Act spines (condensed mission IDs)

**Act I:** M01–M05 + side boards in Aurelia  
**Act II (Vesper):** M06 Salvage War, M07 Wreck of the *Cassiter*, M08 Helix Claim Jump, M09 Tarn’s Due, M10 Deep Manifest  
**Act III (Kestrel):** M11 Corridor Tax, M12 Vorn’s Order, M13 Free Captain Compact, M14 Interdiction Net, M15 Public Frequency  
**Act IV (Relay):** M16–M22 path missions (Open / Sell Helix / Cede Union / Seal Zero Limit hybrid)

Each path needs unique end flags and regional economic/patrol aftermath notes in world state.

---

## 8. Side content mapping

| Board | Region | Examples |
|-------|--------|----------|
| General contracts | Aurelia | delivery, bounty, data |
| **Vesper Salvage** | Vesper Belt | mark wreck, extract cargo, clear claim jumpers |
| **Kestrel Patrol** | Kestrel Expanse | escort, sweep, assist interdiction, rescue pod |
| Story sides | any | Quinn debt arc, Fisk rivalry, Nyra research samples |

Side missions must not hard-block Act progress except optional power/credits.

---

## 9. Gradual revelation

1. **Debt & work** — Aurelia only
2. **Salvage economy** — Vesper is profitable and dirty
3. **Personal stake** — Ellis tag
4. **State power** — Kestrel patrol reality
5. **Relay is alive** — Silent Relay responds
6. **Gate spine politics** — who may reconnect worlds
7. **Finale identity** — player as kingmaker or saboteur

---

## 10. Programmer implementation order (no code here)

1. Story flag store in save (string/bool map).
2. Mission state machine: locked → available → active → success/fail.
3. Region travel hooks: Aurelia / Vesper / Kestrel / SilentRelay ids.
4. Contract boards: filter by `vesper_access` / `kestrel_access`.
5. Implement M01–M05 as data + triggers before writing Act II text into code.
6. Dialogue: simple node graph or sequential lines with choice indices.
7. Do **not** alter flight/combat systems for story; only call into them (spawn enemies, goto marks).

---

## 11. Relation to older narrative docs

`docs/NARRATIVE_BIBLE.md` (Orion Pathfinders / Ysera-Korvax draft) is a **parallel draft**.  
**This file is the integration-facing campaign** using Aurelia Reach, Vesper Belt, Kestrel Expanse, Silent Relay, Vesper Salvage, and Kestrel Patrol.

If both remain, pick one continuity before implementing dialogue assets. Recommendation: **prefer this document** for systems alignment; migrate any preferred character lines from the older bible manually.

---

## 12. Acceptance criteria for “story foundation done”

- [x] Regions named in design with roles
- [x] Protagonist, allies, opponents
- [x] 4-act structure
- [x] First five missions with start/end, objectives, dialogue seeds, rewards, flags
- [x] Side boards mapped to Vesper Salvage / Kestrel Patrol
- [x] Programmer checklist
- [ ] Runtime mission resources (not in this commit)
- [ ] Full dialogue scripts for M06+ (follow-up doc)
