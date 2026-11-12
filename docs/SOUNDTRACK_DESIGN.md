# GALACTIC FRONTIER — Soundtrack Design

Status: design only. No audio assets in repo yet.
Goal: background score for a long single-player frontier space RPG.
Tone: dry, vast, slightly melancholic; rare warmth; never cartoonish.

---

## 1. Overall palette

**Core colors**
- Low analog synth pads (cold blue)
- Soft granular noise (hull / radio dust)
- Sparse piano or electric piano (human moments)
- Distant choir-like pads only for Thread / ancient nodes
- Light percussion: soft ticks, not military drums (except Ring Guard scenes)

**Avoid**
- Constant heroic brass
- Busy modern trailer percussion under exploration
- Cartoon stingers on every UI click

**Dynamic layers (ideal implementation)**
1. Space bed (always)
2. Tension layer (pirates / debt pressure)
3. Combat pulse
4. Thread anomaly shimmer
Mute/unmute by gameplay state in Godot (`AudioServer` buses + interactive music).

---

## 2. Track list (background + key moments)

| ID | Name | Where | BPM | Feel |
|----|------|-------|-----|------|
| BGM-01 | Dry Dock Hum | Hangars, Mara, debt UI | 70 | Mechanical warmth, low drones, occasional wrench-like ticks |
| BGM-02 | Wedge Drift | Open flight in Ysera border systems | 80 | Wide pad, slow pulse, lonely |
| BGM-03 | Anchor Nights | Stations, bars, Nex | 90 | Noir bass, muted keys, light beat |
| BGM-04 | Vector Smile | Corporate offices / Tarek | 100 | Clean, polished, slightly threatening gloss |
| BGM-05 | Ring Statute | Guard beacons, inspections | 95 | Cold ostinato, snare ghost notes, rigid |
| BGM-06 | Ash Frequency | Cult, Ilsa, sermons | 60 | Drones, reversed tones, whispered texture (no clear vocals needed) |
| BGM-07 | Grid Silence | Recon beacons, empty space | 66 | Near-silence, long reverb, rare piano |
| BGM-08 | Caravan Nerve | Escorts | 110 | Rolling low rhythm, rising when enemies near |
| BGM-09 | Node Contact | Thread activation | 50→72 | Choir-pad swell, metallic harmonics |
| BGM-10 | Korvax Horizon | Second galaxy exploration | 78 | New interval color (more minor 2nds), thinner air |
| BGM-11 | Debt Red | Low hull / high heat / red chip | 120 | Heartbeat pulse, narrow filters |
| BGM-12 | Pathfinders Home | Company growth, safe return | 84 | Modest hopeful theme, still restrained |
| STG-01 | Jump Gate | Hyperspace transition sting | — | 12–20s whoosh + harmonic resolve |
| STG-02 | Destroyed | Ship loss / key death | — | Short truncated pad, no big orchestral boom |

---

## 3. Main motif (Pathfinders theme)

Simple interval idea (for composer):

- Motif A: rising minor 3rd, then down a whole step (questioning, not triumphant).
- Motif B: two long notes a perfect 5th apart (map / route).
- Combine A+B only in BGM-12 and rare story peaks.

Exploration versions use fragments of A only, buried in pads.

---

## 4. State mapping (runtime)

| Game state | Primary | Layer add |
|------------|---------|-----------|
| Docked safe | BGM-01 or BGM-03 | none |
| Free flight | BGM-02 / BGM-10 | optional faint ticks |
| Mission escort | BGM-08 | tension if enemy spawn |
| Combat | BGM-08 combat layer or dedicated combat bed | percussion up |
| Dialogue story | lower bed −6 dB | none |
| Thread node | BGM-09 | anomaly shimmer |
| Wanted / debt crisis | BGM-11 | replace free flight |

Crossfade 2–4 seconds; never hard cut except STG stingers.

---

## 5. Production specs

- Format target: OGG Vorbis or WAV stems for Godot import.
- Loop points: seamless on all BGM-*; mark loop start/end in filename or `.import` notes.
- Loudness: exploratory beds quieter than combat; leave headroom for SFX.
- Length: 2–4 min loops for beds; stingers under 20s.
- License: original only; no copyrighted samples without clearance. Prefer CC0 / self-made / commissioned.

---

## 6. First playable package (minimum)

If only 4 tracks can be made first:

1. `bgm_wedge_drift` — default space
2. `bgm_dry_dock_hum` — stations
3. `bgm_caravan_nerve` — tension/combat capable
4. `stg_jump_gate` — transition

---

## 7. Prompt pack (for generative music tools)

**Wedge Drift**
> Ambient space game soundtrack, slow 80 BPM, cold analog pads, soft granular noise, sparse notes, lonely frontier, no drums, cinematic but quiet, seamless loop

**Dry Dock Hum**
> Industrial ambient, hangar atmosphere, low drones, distant metallic ticks, warm but tired, 70 BPM, subtle rhythm, space station interior, loopable

**Caravan Nerve**
> Tense space escort theme, 110 BPM, deep bass pulse, restrained electronic percussion, building pressure, dark sci-fi, not overly heroic

**Node Contact**
> Mysterious ancient technology reveal, evolving drone, ethereal pad choir, metallic harmonics, slow swell, awe without fantasy magic

**Korvax Horizon**
> Alien outer-galaxy ambient, thinner textures, minor-second dissonance, vast silence between notes, exploratory, cold beauty

---

## 8. Implementation note

Audio files are not committed here. When assets exist, place under `assets/audio/music/` and list licenses in `docs/THIRD_PARTY_NOTICES.md` if any third-party content is used.
