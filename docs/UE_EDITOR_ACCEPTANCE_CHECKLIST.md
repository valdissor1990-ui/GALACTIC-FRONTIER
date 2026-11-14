# Unreal Editor Acceptance Checklist — GALACTIC FRONTIER

**Status: NEEDS_UE_EDITOR**  
**Required version:** Unreal Engine 5.8.4  
**Project:** `Unreal/GalacticFrontier.uproject`  
**Branch:** `chatgpt/unreal-migration-ue5.8`  
**Do not merge PR #99 until this checklist has been completed.**

This checklist is the human acceptance gate for the existing Blender/GLB assets and the Unreal runtime. Source-level CI cannot replace these checks.

## 1. Open and compile

- [ ] Open `Unreal/GalacticFrontier.uproject` with Unreal Engine **5.8.4**.
- [ ] If prompted to rebuild the C++ project, choose **Yes**.
- [ ] Wait for the editor to finish compiling and loading.
- [ ] Confirm the Compile toolbar reports success and the Output Log contains no C++/UHT errors.
- [ ] If compilation fails, save the complete first error and the surrounding 30–50 log lines. Do not continue to import until compile errors are fixed.

## 2. Run the asset import pipeline

In the Unreal Editor:

1. Open **Tools → Execute Python Script**.
2. Select `Unreal/Content/Python/setup_galactic_frontier.py` from the repository.
3. Wait until the script logs `PIPELINE REPORT` and completes.
4. Open the generated report at:
   `Unreal/Saved/GFAssetManifests/asset_pipeline_report.json`

Acceptance:

- [ ] `overall_status` is `passed`.
- [ ] `ships`, `environment`, `space`, and `planets` stages are all `validated`.
- [ ] Seven catalog ship entries are present and validated as `StaticMesh`.
- [ ] No ship has `failed`, `missing_source`, `failed_target_exists`, or a rename error.
- [ ] Each ship source GLB has exactly one mesh node and imports as exactly one StaticMesh.
- [ ] The imported object path matches the exact expected path below.

### Seven catalog ship paths

| Ship ID | Expected StaticMesh object path |
|---|---|
| `player_fighter` | `/Game/GF/Ships/player_fighter.player_fighter` |
| `cargo_hauler` | `/Game/GF/Ships/cargo_hauler.cargo_hauler` |
| `raider_interceptor` | `/Game/GF/Ships/enemy_fighter.enemy_fighter` |
| `aegis_heavy_fighter` | `/Game/GF/Ships/heavy_fighter.heavy_fighter` |
| `bastion_bomber` | `/Game/GF/Ships/bomber.bomber` |
| `frigate` | `/Game/GF/Ships/frigate.frigate` |
| `cruiser` | `/Game/GF/Ships/cruiser.cruiser` |

## 3. Inspect every ship in Content Browser and viewport

Open `Content/GF/Ships`. Repeat this section for all seven imported StaticMeshes.

- [ ] Asset exists at the exact path in the table above.
- [ ] Asset name equals the source GLB basename.
- [ ] StaticMesh opens without import warnings or missing dependencies.
- [ ] Hull materials render with their intended base colour and metallic/roughness response; no pink, default grey, or checkerboard surfaces.
- [ ] Base Color, Metallic/Roughness and Normal texture inputs are present where the GLB provides them.
- [ ] Canopy/glass reads as a transparent or visibly glazed surface, not an opaque plastic block.
- [ ] Engine/nozzle material has a restrained emissive response where authored.
- [ ] The nose points along Unreal **+X** (the direction of forward flight).
- [ ] Pivot is near the intended ship centre and the model is not offset far from its origin.
- [ ] Dimensions and configured `VisualScale` produce a sensible in-game size.
- [ ] Collision is present and useful; it is not a zero-sized shape or a single oversized spherical approximation.
- [ ] No obvious holes, flipped normals, detached geometry, or missing material slots.

Record any failed ship by ID and attach a screenshot of the StaticMesh viewport plus its material slots.

## 4. Inspect environment and lighting

- [ ] `/Game/GF/Space/space_backdrop.space_backdrop` loads and displays stars without a visible sphere edge.
- [ ] All four planet StaticMeshes load with non-grey albedo and visible surface shading.
- [ ] Planet roughness and normal maps affect the surface under the key light.
- [ ] Planet scale and placement keep every planet clearly separated from the player spawn and from the starfield backdrop.
- [ ] No z-fighting, sudden clipping, or a planet positioned immediately in front of the ship.
- [ ] The post-process volume is unbound and active.
- [ ] Exposure is stable; the space background remains dark while lit ship surfaces retain detail.
- [ ] Bloom is restrained; engine highlights do not wash out the hull.
- [ ] Contact shadows and reflections do not create excessive noise or flicker.

## 5. Play the flight test

Open and play `/Game/GF/Maps/L_FlightTest`.

- [ ] Player spawns in the Player Fighter Mk.I with a visible complete mesh.
- [ ] Chase camera frames the full ship and does not clip through the hull.
- [ ] Cockpit camera is inside the forward cockpit area and looks along +X.
- [ ] Camera toggle works repeatedly.
- [ ] Forward, strafe, vertical movement, pitch, yaw and roll respond.
- [ ] Boost increases speed and engine glow; release returns to normal thrust.
- [ ] Brake slows the ship.
- [ ] Weapon fire produces projectiles and a visible muzzle effect if the Niagara graph is authored.
- [ ] Target lock and target clear work.
- [ ] At least one full enemy wave appears with complete imported ship meshes.
- [ ] Enemy variants follow the intended wave composition: interceptors first, heavy escort in wave 2, bomber-lite in wave 3.
- [ ] Enemies move, aim, fire, take damage and are removed after destruction.
- [ ] Pressing **F** within range starts the relay scan; leaving range resets progress.
- [ ] Complete the relay defence, wreck scan/defence, return-to-carrier and contract completion.
- [ ] No crash, freeze, missing-asset fallback primitive, or repeated error spam occurs.

## 6. Capture evidence and report

Please provide:

1. The complete `asset_pipeline_report.json` (or its contents).
2. The first compile result (success or the first full error).
3. One screenshot per ship if any ship fails the viewport checks; otherwise one fleet overview plus a representative material view.
4. A short flight-test recording or screenshots covering chase camera, cockpit, boost, firing and one enemy wave.
5. Whether Silent Relay completed and whether credits/story flag were saved.

**Do not mark the Editor gate as passed from source inspection alone.** Until the above checks are actually run in UE 5.8.4, status remains `NEEDS_UE_EDITOR`.
