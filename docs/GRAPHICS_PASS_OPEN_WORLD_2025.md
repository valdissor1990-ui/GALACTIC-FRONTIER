# Graphics Pass — Open World 2020–2025 baseline

**Branch:** `grok/graphics-open-world-2025`  
**Author:** Grok  
**Status:** First implementation slice (procedural; no photogrammetry textures yet)

## What was wrong on main

- Flat `background_color` void (no starfield / nebula read)
- Single low-detail planet sphere
- Flat StandardMaterial hulls without rim / panel breakup
- No asteroid density for “open space” scale
- Glow / ACES / SSAO not used in the flight scene

## What this pass adds

| Piece | Path | Role |
|-------|------|------|
| Starfield sky shader | `assets/shaders/space_starfield_sky.gdshader` | Layered stars + nebula tint |
| Hull rim shader | `assets/shaders/hull_fresnel.gdshader` | Metallic panels + Fresnel silhouette |
| Backdrop builder | `scripts/environment/open_space_backdrop.gd` | Sky, key/fill lights, 2 planets, MultiMesh belt |
| Backdrop scene | `scenes/environment/open_space_backdrop.tscn` | Drop-in for any system scene |
| Flight wiring | `scenes/flight/test_flight.tscn` | Uses backdrop + hull materials |

## 2020–2025 target (honest scope)

**Achieved in this slice**
- Cinematic space read (stars, nebula, dual planets, belt)
- ACES tonemap + bloom for engines/emissive
- Mild SSAO
- MultiMesh asteroids (draw-call friendly)
- Rim-lit hulls without unique textures per part

**Not yet (next slices)**
- Real PBR texture sets (albedo/normal/ORM) on GLB ships from `assets/models/ships/`
- Station modules / docking bays
- Jump Gate / Silent Relay hero prop + pulse shader
- GPU particle thrusters tied to throttle
- Impostors / visibility ranges tuned after profiling
- Merge with ChatGPT `deep-space-detail-pass` / fleet mesh work if still divergent

## How to preview

Run `scenes/flight/test_flight.tscn` (or set as main temporarily).  
Godot 4.7 Forward+ recommended (already in `project.godot` on main).

## Performance notes

- Asteroids: one MultiMesh, ~220 instances, low-segment spheres
- Sky: procedural sky shader (no 8K HDRI dependency)
- Prefer sharing hull shader materials across enemies later

## Runtime

Visual quality **NOT RUN** in CI here until a gameplay capture job on this branch succeeds.
