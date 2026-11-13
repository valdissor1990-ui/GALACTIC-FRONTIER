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

## International Space Station model

- File: `assets/models/environment/nasa_iss_station.glb`
- Source: [NASA 3D Resources — NASA-3D-Resources repository](https://github.com/nasa/NASA-3D-Resources)
- Original source path: `3D Models/International Space Station (ISS) (B)/International Space Station (ISS) (B).glb`
- License/usage: NASA describes its 3D Resources collection as free to download and use; follow the [NASA Images and Media Usage Guidelines](https://www.nasa.gov/nasa-brand-center/images-and-media/) for redistribution and commercial release.
- Intended use: distant, visual-only orbital station landmark in the space environment; no collision or gameplay dependency.
- Import: Godot 4.7.2 glTF/GLB importer.
