# Blender Fleet Production Report

Generated on 2026-11-13 by the `ship-art-production` GitHub Actions workflow.

## Toolchain and result

- Blender: 4.5.16
- Godot: 4.7.2-stable
- Result: **PASS — 7/7 ship assets generated and validated**
- GLB payload total: approximately 17.53 MiB
- Each ship has an editable `.blend`, a Godot-ready `.glb` and a studio preview.
- Blender source files are stored in `art_source/ships/`, outside Godot's resource import path.
- Asset validation checked non-empty files, finite geometry and transforms, valid bounds, one `GF_*` root, mesh/polygon/material minimums, GLB re-import, source/export bounds consistency and non-blank previews.
- Godot import/parser validation and Windows export completed successfully on the production branch.

## Per-ship metrics

| Ship | Mesh objects | Blender polygons | GLB triangles | GLB materials | GLB size | Preview |
|---|---:|---:|---:|---:|---:|---:|
| Player Fighter Mk.I | 255 | 29,825 | 94,164 | 7 | 3.53 MiB | 1600×1100 |
| Raider Interceptor Mk.I | 217 | 9,859 | 57,672 | 6 | 3.69 MiB | 1800×1200 |
| Aegis Heavy Fighter | 84 | 2,866 | 15,208 | 6 | 0.79 MiB | 1500×1000 |
| Bastion Bomber | 200 | 7,110 | 37,368 | 6 | 1.99 MiB | 1500×1000 |
| Mule Cargo Hauler | 153 | 2,660 | 20,924 | 6 | 1.27 MiB | 1500×1000 |
| Vanguard Frigate | 218 | 7,054 | 37,956 | 5 | 2.07 MiB | 1500×1000 |
| Leviathan Cruiser | 428 | 14,650 | 77,900 | 6 | 4.19 MiB | 1500×1000 |

## Visual review notes

- Player Fighter and Raider have distinct fighter silhouettes and material palettes.
- Bastion Bomber and Mule Cargo Hauler read clearly as different roles.
- Aegis Heavy Fighter, Vanguard Frigate and Leviathan Cruiser are generated and import successfully, but need another art pass to make their silhouettes and scale more distinctive.
- Current previews are single three-quarter studio views. Final art acceptance still requires front, side, top, rear-three-quarter and in-game inspection.
- The current validator does **not** yet enforce UV-map presence, texture bake quality, LODs, collision proxies, animation rigs or draw-call budgets. These should be added as later quality gates rather than assumed complete.
- This is a validated procedural production pass, not a claim of final AAA art quality.
