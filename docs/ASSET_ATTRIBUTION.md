# Third-party space assets

## 1999 RQ36 asteroid model

- File: `assets/models/environment/1999_rq36_asteroid.glb`
- Source: NASA 3D Resources, [NASA-3D-Resources repository](https://github.com/nasa/NASA-3D-Resources)
- Original source path: `3D Models/1999 RQ36 asteroid/1999 RQ36 asteroid.glb`
- License/usage: NASA describes the collection as free to download and use; review the [NASA Images and Media Usage Guidelines](https://www.nasa.gov/nasa-brand-center/images-and-media/) before commercial distribution. The model is credited to the NASA 3D Resources collection.
- Intended use: instanced asteroid geometry in the Aurelia relay debris field.
- Import: Godot 4.7.2 glTF/GLB importer.

The model is used as source geometry for MultiMesh instances. The game retains a procedural fallback if the asset cannot be imported.

## Gas giant texture map

- File: `assets/textures/space/jupiter_2k.jpg`
- Source: [Sanghel/solar-system-3d](https://github.com/Sanghel/solar-system-3d), sourced from Solar System Scope.
- License: Creative Commons Attribution 4.0 International (CC BY 4.0); attribution required. See the upstream `public/textures/README.md` and [Solar System Scope textures](https://www.solarsystemscope.com/textures/).
- Intended use: 2K equirectangular base-color map for the Nacreon gas giant; the procedural shader remains as an offline fallback.
- Credit: Solar System Scope.


## Additional vetted free sources (catalogue; not yet imported)

The following sources were checked while expanding the asset pool. They are recorded separately from assets already present in the repository; listing a source does not mean its files have been imported or approved for the final art direction.

### 3D models and environment props

- [Kenney Space Kit mirror](https://github.com/Hidencod/tge-assets/tree/main/packs/space-kit): 153 self-contained GLB models in the Space Kit; the upstream asset pack is CC0. Useful for modular station interiors, hangar props, cargo and background traffic. Style is deliberately low-poly, so use selectively rather than replacing the game's hero ships.
- [NASA 3D Resources](https://github.com/nasa/NASA-3D-Resources): extensive spacecraft, telescope, satellite, lander, station and small-body models. NASA describes the collection as free to download and use; review NASA media usage guidance for each release.
- [Polyy.AI — 35 Spaceships](https://polyyai.itch.io/3d-spaceships-pack): 35 GLB ships with PBR maps, CC0. The pack is AI-assisted and low-poly; inspect silhouettes and material quality before adopting any ship as a hero asset.
- [Poly Haven](https://polyhaven.com/): CC0 photogrammetry models, HDRIs and PBR materials; commercial use allowed. Best candidate for high-quality metal, rock, ice and surface materials.

### Space backgrounds and sky

- [Toolbench Deep-Space Skybox](https://toolbenchdev.com/gamedev/cc0-game-assets/deep-space-skybox/): CC0, 4096×2048 equirectangular HDR/PNG, including separate stars, galaxy, nebula and sun layers. The publisher documents Godot 4 PanoramaSkyMaterial setup but notes that this release has not been tested in Godot; validate import, exposure and visual fit before integration.
- [NASA Blue Marble](https://science.nasa.gov/earth/earth-observatory/blue-marble-next-generation/base-map/): public-domain Earth imagery suitable for planetary maps, subject to NASA media usage guidance.
- [Solar System Scope textures](https://www.solarsystemscope.com/textures/): planetary maps under CC BY 4.0; retain the required credit and licence notice.

### Sound effects and music

- [Kenney Sci-Fi Sounds on OpenGameArt](https://opengameart.org/content/sci-fi-sounds): 70 normalized OGG effects for engines, explosions and lasers; CC0. Optional credit: Kenney.nl.
- [Space Flight Sound Effects](https://opengameart.org/content/space-flight-sound-effects): CC0 ambience and ship-flight effects.
- [Dark Sci-Fi Audio Pack](https://opengameart.org/content/dark-sci-fi-audio-pack): CC0 pack with five ambient music tracks and three UI/system sounds.
- [Anamnesis](https://efilheim.itch.io/anamnesis): CC0 ambient/sci-fi music pack; OGG archive is 68 MB, so import only selected tracks after listening and checking in-game loop points.

### Selection policy

Prefer CC0/public-domain sources for assets intended for direct integration. For NASA and CC BY sources, preserve the relevant usage guidance and attribution. Do not import a resource solely because it is free: check visual consistency with the approved Freelancer-inspired art direction, file size, texture resolution, PBR channel conventions, mesh scale/orientation, and Godot 4.7.2 import results first.

## Kenney Space Kit — distant traffic

- Files:
  - `assets/models/environment/kenney_craft_cargo_a.glb`
  - `assets/models/environment/kenney_craft_miner.glb`
  - `assets/models/environment/kenney_craft_racer.glb`
  - Additional staged models: `kenney_craft_cargo_b.glb`, `kenney_meteor_detailed.glb`, `kenney_turret_double.glb`
- Source: [Kenney Space Kit](https://kenney-assets.itch.io/space-kit), mirrored in [Hidencod/tge-assets](https://github.com/Hidencod/tge-assets/tree/main/packs/space-kit).
- License: CC0 1.0 Universal. Kenney states that the assets may be used in commercial projects without permission or required attribution.
- Intended use: three low-poly civilian traffic silhouettes, kept distant from the camera; not used to replace player/enemy hero ships.
- Import: original GLB files, imported by Godot 4.7.2 glTF importer without conversion.

The cargo-B model is staged for future traffic variation. The detailed meteor is instanced as a second asteroid silhouette, and the double turret is mounted on the derelict wreck.

## Kenney Sci-Fi Sounds

- Files: `assets/audio/sfx/kenney_laser_small.ogg`, `kenney_laser_large.ogg`, `kenney_explosion_crunch.ogg`, `kenney_impact_metal.ogg`, `kenney_force_field.ogg`.
- Source: [Kenney Sci-Fi Sounds](https://kenney.nl/assets/sci-fi-sounds), mirrored in [danvanderboom/Aetherium](https://github.com/danvanderboom/Aetherium/tree/main/samples/unity/Aphelion/Assets/ThirdParty/Kenney/SciFiSounds).
- License: CC0 1.0 Universal; source `License.txt` is included as `assets/audio/sfx/KENNEY_SCI_FI_SOUNDS_LICENSE.txt`.
- Integration: AudioManager loads authored OGG weapon, explosion, metal-impact and shield sounds. The procedural engine loop and synthesized fallback sounds remain available if an imported OGG is missing.
