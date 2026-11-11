# Blender asset pipeline

## First production model: Player Fighter Mk.I

The first art asset is the original player-controlled fighter. It follows the approved project direction: realistic science-fiction hardware, layered metal/ceramic armor, a panoramic cockpit, swept wings, twin ion engines, visible service panels, weapon hardpoints and restrained cyan emissive details.

The model is generated procedurally in Blender so the source remains editable and reproducible.

### Source

- `scripts/blender/build_player_fighter.py` — complete Blender Python scene generator.
- Coordinate convention: nose points toward Blender local -Y; Blender's glTF exporter performs axis conversion for the exported model.
- No external models, textures, add-ons or paid assets are required.

### Generated outputs

The GitHub Actions workflow produces:

- `assets/models/ships/player_fighter.blend` — editable Blender project.
- `assets/models/ships/player_fighter.glb` — glTF binary for Godot import.
- `assets/previews/player_fighter_preview.png` — studio render preview.

### Build

The workflow `.github/workflows/blender-assets.yml` installs Blender on a GitHub-hosted Ubuntu runner, runs the generator, validates that all outputs exist, commits generated files to the asset branch, and uploads a downloadable workflow artifact.

The model is not integrated into the playable Godot scene until its generated GLB is inspected and its scale/orientation/materials are checked. Current interactive runtime status: NOT RUN.

## Asset production order

1. Player fighter — first controllable ship.
2. Enemy fighter — visually distinct opponent using the same art direction.
3. Space station — first large navigable landmark.
4. Planet surface/orbit assets and star.
5. Asteroid field and environmental props.

The original concept sketches remain the visual reference. Any sketch-specific silhouette details should be preserved when the reference image is available during final art review.
