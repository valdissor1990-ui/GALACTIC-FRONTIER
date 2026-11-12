# Visual overhaul — first playable art slice

## Included in this branch

- Generated original Player Fighter Mk.I GLB is included from the Blender asset build.
- The flight scene replaces the five primitive player-ship boxes with the generated 3D model.
- A deterministic space environment creates a starfield, a noise-painted planetary surface, a thin atmospheric shell and an asteroid field.
- The environment uses Godot's Compatibility renderer and built-in procedural generation; it does not download assets at runtime.

## Visual review

The first Blender preview was inspected. The model has a readable fighter silhouette, twin engine nacelles, swept wings and cockpit glazing. It is a useful first production asset, but still needs a second detailing pass: stronger surface breakup, more distinctive panel geometry, landing gear refinement, and a more dramatic engine treatment.

## Validation status

- Blender model generation: PASS in GitHub Actions run `43123808130`.
- `.blend`, `.glb`, and PNG preview artifact: generated and inspected.
- Godot import/parser and scene smoke test for this branch: PENDING.
- Interactive Windows playtest: NOT RUN.
- The scene scale/orientation of the imported GLB must be confirmed by Godot CI and then by a human visual review.


## Playable vertical-slice mission

- `scenes/demo/ten_minute_demo.tscn` launches the Silent Relay mission using the real flight and combat systems.
- Mission loop: fly to the relay, scan it with F, defeat three enemy waves, investigate and scan a wreck, defeat three further waves, then return to the orbital carrier.
- The mission director provides navigation, objective, radio and elapsed-time HUD elements. Enemy waves use the existing enemy AI, projectile, shield and hull systems.
- Default bootstrap now opens this mission. The standalone visual flight scene remains available for testing.
- Automated scene startup is checked in Godot CI; interactive Windows playtesting and visual quality review remain separate acceptance gates.
