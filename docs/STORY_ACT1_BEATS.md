# GALACTIC FRONTIER — Story Act I Beats

Detailed mission list for Prologue + Act I. Source: `docs/NARRATIVE_BIBLE.md`.
Runtime mission resources are not created in this commit.

---

## P0 — Prologue: License and Clamp

**Location:** Dry Dock 9 hangar → beacon Grid-12 → return.

**Objectives:**
1. Accept debt terms from Mara Kell.
2. Launch and reach Grid-12.
3. Scan beacon / retrieve log.
4. Survive light pirate pressure (optional fail → log damaged, less debt relief).
5. Return to Dock 9.

**Key dialogue:** Mara debt chip; Arcadis note “Do not give this to Vector.”

**Rewards:** first debt layer reduced; Thread fragment flag `thread_fragment_grid12`.

---

## A1M1 — Silence on the Grid

**Type:** recon / light combat.
**Objectives:** full log recovery; optional secondary scan of debris.
**NPCs:** Nex (radio after).
**Outcomes:**
- Success: fragment quality high; Nex tip about two interested parties.
- Partial: corrupted log; Tarek still contacts later with worse offer.

---

## A1M2 — Caravan to Anchor

**Type:** escort.
**Objectives:** keep freighter alive to Anchor-4.
**Branches:**
- Fight off raiders.
- Pay partial cargo to buy passage.
- Abandon caravan.

**Outcomes:** house rep++ / money++ with rep−− / unlock bar phrase “bread at the old price”.

---

## A1M3 — Tarek’s Man

**Type:** dialogue + optional ambush.
**Objectives:** meet Yun Tarek; decide on fragment.
**Branches:**
- Sell exclusive → debt−−, fuel priority, Guard suspicion later.
- Copy only → medium pay, Vector heat.
- Refuse → tariff pressure event within 1–2 play hours.

**Flags:** `vector_deal_sold` / `vector_deal_copy` / `vector_deal_refused`.

---

## A1M4 — Grey Box

**Type:** delivery with mid-flight complication.
**Objectives:** move sealed container; container heats and signals.
**Branches:** deliver sealed / open (Arcadis voice + Cashier hint) / divert to Guard.

**Risk:** scan heat if opened in public space.

---

## A1M5 — Cashier Node

**Type:** exploration + defense.
**Objectives:** reach Thread node; survive drones; activate once.
**Results:** map unlock 1–2 systems; Rinn broadcast to report in.

**Flags:** `thread_node_cashier_open`.

---

## A1M6 — Talk on the Beacon

**Type:** dialogue (Ring Guard).
**Objectives:** respond to Commander Seva Rinn.
**Branches:** cooperate / defy / lie.

**Outcomes:** temporary civilian collaborator status / wanted light / lie check later in Act I.

---

## A1M7 — Vector Errand

**Type:** combat or intimidation contract.
**Objectives:** “remove” a competitor courier.
**Branches:** complete / warn target / fake proof.

**Rep:** Vector+ may mean local houses−.

---

## A1M8 — House Defense

**Type:** defend station approach.
**Objectives:** hold lane while civilians evacuate or dock finishes transfer.
**Link:** harder if A1M7 completed for Vector.

---

## A1M9 — Ash Scan

**Type:** scan-only at a node.
**Objectives:** Ilsa asks scan-and-leave; staying triggers optional combat/dialogue.
**Branch:** pure scan / linger / report to Rinn.

---

## A1M10 — Dock Under Lien

**Type:** climax Act I.
**Setup:** Vector pressure or pirate leverage on Dry Dock 9 (depends on prior flags).
**Objectives:** defend dock / win auction / refinance through a faction.

**Mara success line:** Chip still red, but not on my neck anymore.
**Mara failure line:** Hangar sealed. You may fly. Do not come home.

**Act I clear flags:** `act1_complete`, `dock9_status` = open|seized|vector_lien|pathfinder_shared.

---

## Suggested Act I production order

1. P0 playable tutorial slice.
2. A1M1–A1M3 (debt + Vector contact).
3. A1M4–A1M6 (Thread introduction + Guard).
4. A1M7–A1M9 (faction pressure triangle).
5. A1M10 (resolve dock).

Combat, navigation, and save systems must exist before A1M10 is marked production-ready.
