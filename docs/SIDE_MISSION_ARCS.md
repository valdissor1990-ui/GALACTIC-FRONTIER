# GALACTIC FRONTIER — Side Mission Arcs

Unique multi-step side chains. Each arc is 4–8 missions unless noted.
Procedural station contracts are separate (generator: type × threat × modifier × faction).

Linked to: `docs/NARRATIVE_BIBLE.md`.

---

## Design rules

- Local NPC or crisis first; personal stake second; world consequence third.
- At least one meaningful branch per arc.
- Reward mix: credits, reputation, access, lore, ship/company progress — not only money.
- Failure states allowed (NPC dies, station closes, rival claims prize).

---

## Arc list (30)

### 1. Shipyard Debt (Mara)
Steps: partial payments → sabotage rival claim → auction pressure → clear or refinance.
Branch: pay clean / grey money / let Vector buy the note.

### 2. Cap Orsa Rivalry
Race the same contracts → sabotage rumors → forced wingman on a deadly escort → respect or permanent feud.

### 3. Rhea’s Past
Hire Rhea → Ring inquiry → sealed file → hide her / trade her / help clear her name.

### 4. Nex Under Glass
Informant sells one secret too many → hit team → safehouse → Nex leaves system or stays as permanent intel source.

### 5. Anchor Quarantine
Plague scare → blockade → medicine run → truth: corporate cover-up or real pathogen.

### 6. Black Box Flight 77
Old war debris → encrypted box → veterans vs official history → publish, sell, or bury.

### 7. Mechanic’s Family
Dock tech’s child missing in Korvax → trail of shelters → rescue or confirm death → dock discounts / story flag.

### 8. The Cartographer
Buys/sells charts → one chart is lethal lie → confrontation → rare true Thread annotation as reward.

### 9. Wedge Arena
Illegal ship duels → ranking → championship purse → Guard raid mid-event.

### 10. Mirror Contraband
Cargo that blanks witness logs → buyer / moral refuse / reverse sting.

### 11. Vector Intern
Young agent breaks under pressure → help defect / return to Tarek / use as double source.

### 12. Ring Deserter
Hide deserter → Rinn pressure → extract or surrender → reputation swing.

### 13. Ash Preacher
Peaceful station leans cult → protect speech / expose cell / negotiate exit corridor.

### 14. Bounty on You
Contract on player head → find broker → reverse hunt → clear or fake death.

### 15. Station Without a Name
Radio-silent community → their rule is silence → help survive Scan-sweep → access to quiet dock.

### 16. Debt Collector
Note sold to worse creditor → intimidation missions → buyback or violent end.

### 17. Ore Rush
Limited asteroid → three captains → share, steal, or destroy claim beacon.

### 18. Ghost Channel
Someone copies player callsign → reputation damage → unmask impostor.

### 19. Museum of Hulks
Curator wants “rare piece” → piece is Thread component → donate, sell, install.

### 20. Captains’ Court
Tried for Act I incident → bribe / evidence / trial by combat proxy.

### 21. Station Wedding
Escort VIP → house feud erupts → keep peace or pick a side.

### 22. Docker Strike
Vector pressure on labor → mediate / break strike / protect picket.

### 23. Children’s Transport
Escort sensitive passengers → ambush → no cynical punchline; heavy tone.

### 24. Arcadis’s Old Friend
Drunk truth-teller → reveals Voln tried to seal Thread → points to Act II gate.

### 25. Beacon Blackout
Series of systems lose nav → find jammer → corporate test or cult rite.

### 26. False Pathfinder
Scammer uses company name → legal claim / public exposure / violent shutdown.

### 27. Contract for Silence
Pay to keep a story buried → blackmail escalates → end the lever.

### 28. Korvax Library
Data access for sealed sector permit → fetch archive under fire → map unlock.

### 29. Last Caravan
“Retirement escort” → everything goes wrong → legacy payout / bitter failure.

### 30. House on the Edge
Acquire tiny outpost as Orion branch → defend → upgrade → permanent company hub.

---

## Procedural contract modifiers (station board)

**Types:** escort, delivery, recon, clear, rescue, hunt, data race.

**Modifiers:** storm corridor, betrayal mid-job, timer, do-not-scan cargo, night route, Orsa competition, silent running, live hostages.

**Outputs:** credits, rep delta, heat, optional unique item seed.

---

## Tracking suggestion (future data)

`side_arc_id`, `step_index`, `branch_flags`, `completed`, `failed`, `reputation_delta`, `world_flags[]`.

Do not implement save schema in this doc commit.
