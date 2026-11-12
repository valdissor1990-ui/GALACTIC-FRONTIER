# Ship visual fallback

Engine baseline: Godot 4.7.2-stable.

The player fighter and Raider interceptor prefer their imported GLB models. The scene also contains a native Godot blockout mesh set so that the ship remains visible if a GLB cannot be imported on a target renderer or build machine.

`ShipVisualFallback` runs on the ship's `Visual` node:

1. It checks whether the optional imported model node exists and contains at least one `MeshInstance3D`.
2. If the imported model is valid, it hides the primitive blockout meshes to prevent duplicate geometry.
3. If the model is missing or has no renderable meshes, it keeps the blockout hull, then adds a cockpit canopy, armor panels, wing detailing, weapon pods and engine nozzles using built-in Godot meshes.
4. The player and raider use separate material palettes so silhouettes remain distinguishable in combat.

This is a resilience layer, not a replacement for final ship art. The GLB pipeline remains the preferred path. A release candidate must validate both paths: successful GLB import and the no-GLB fallback. The automated headless test covers visibility selection and generated detail nodes; gameplay screenshot capture checks the rendered result.
