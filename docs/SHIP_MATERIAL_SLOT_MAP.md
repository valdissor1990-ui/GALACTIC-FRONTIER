# Ship Material Slot Map — GALACTIC FRONTIER

**Status: PRE-IMPORT REFERENCE — NEEDS_UE_EDITOR**  
**Source of names:** `assets/models/ships/single-mesh-report.json`  
**Export contract:** seven GLBs, one exported mesh and one mesh node per ship.

This document records the material names emitted by the Blender single-mesh export and proposes semantic master-material assignments. It is **not** evidence that Unreal Interchange preserved the names, slot order, blend mode, texture links or material parameters. Do not create or assign final Unreal material assets until the UE 5.8.4 import report and StaticMesh material panels have been inspected.

## Proposed master material families

| Proposed master | Intended surface | Planned setup after import |
|---|---|---|
| `M_GF_Hull` | Main armor, hull plating, titanium/ceramic armor | Opaque PBR; base color, metallic, roughness, normal; restrained edge wear |
| `M_GF_Glass` | Cockpit canopy / polarized glazing | Transparent or masked only after checking imported opacity; controlled specular and reflection; avoid opaque plastic |
| `M_GF_Engine` | Engine plasma, ion emission, plasma core | Emissive surface with exposure-safe intensity; bloom supplied by post process |
| `M_GF_Trim` | Graphite recesses, identification markings, accent and warning colors | Opaque PBR; lower metallic or painted finish; preserve authored color variation |

## Per-ship source material names and planned assignments

The names below are reproduced from the source report. The final Unreal slot index is intentionally **not** stated: the report does not expose the material-slot index mapping. Record the actual imported slot index from the StaticMesh Editor during Phase B.

### Player Fighter Mk.I

**Expected StaticMesh:** `/Game/GF/Ships/player_fighter.player_fighter`

| Source material name | Planned master |
|---|---|
| `Brushed gunmetal armor` | `M_GF_Hull` |
| `Ceramic titanium — midnight blue` | `M_GF_Hull` |
| `Cockpit polarized glass` | `M_GF_Glass` |
| `Graphite recesses` | `M_GF_Trim` |
| `Identification ceramic` | `M_GF_Trim` |
| `Ion cyan accent` | `M_GF_Trim` |
| `Ion engine emission` | `M_GF_Engine` |

### Raider Interceptor

**Source GLB:** `enemy_fighter.glb`  
**Expected StaticMesh:** `/Game/GF/Ships/enemy_fighter.enemy_fighter`

| Source material name | Planned master |
|---|---|
| `Raider &#124; graphite recess` | `M_GF_Trim` |
| `Raider &#124; obsidian ceramic` | `M_GF_Hull` |
| `Raider &#124; plasma core` | `M_GF_Engine` |
| `Raider &#124; polarized canopy` | `M_GF_Glass` |
| `Raider &#124; titanium armor` | `M_GF_Hull` |
| `Raider &#124; warning vermilion` | `M_GF_Trim` |

### Aegis Heavy Fighter

**Expected StaticMesh:** `/Game/GF/Ships/heavy_fighter.heavy_fighter`

| Source material name | Planned master |
|---|---|
| `Aegis Heavy Fighter &#124; canopy glass` | `M_GF_Glass` |
| `Aegis Heavy Fighter &#124; engine plasma` | `M_GF_Engine` |
| `Aegis Heavy Fighter &#124; graphite` | `M_GF_Trim` |
| `Aegis Heavy Fighter &#124; hull` | `M_GF_Hull` |
| `Aegis Heavy Fighter &#124; identification` | `M_GF_Trim` |
| `Aegis Heavy Fighter &#124; titanium armor` | `M_GF_Hull` |

### Bastion Bomber

**Expected StaticMesh:** `/Game/GF/Ships/bomber.bomber`

| Source material name | Planned master |
|---|---|
| `Bastion Bomber &#124; canopy glass` | `M_GF_Glass` |
| `Bastion Bomber &#124; engine plasma` | `M_GF_Engine` |
| `Bastion Bomber &#124; graphite` | `M_GF_Trim` |
| `Bastion Bomber &#124; hull` | `M_GF_Hull` |
| `Bastion Bomber &#124; identification` | `M_GF_Trim` |
| `Bastion Bomber &#124; titanium armor` | `M_GF_Hull` |

### Mule Cargo Hauler

**Expected StaticMesh:** `/Game/GF/Ships/cargo_hauler.cargo_hauler`

| Source material name | Planned master |
|---|---|
| `Mule Cargo Hauler &#124; canopy glass` | `M_GF_Glass` |
| `Mule Cargo Hauler &#124; engine plasma` | `M_GF_Engine` |
| `Mule Cargo Hauler &#124; graphite` | `M_GF_Trim` |
| `Mule Cargo Hauler &#124; hull` | `M_GF_Hull` |
| `Mule Cargo Hauler &#124; identification` | `M_GF_Trim` |
| `Mule Cargo Hauler &#124; titanium armor` | `M_GF_Hull` |

### Vanguard Frigate

**Expected StaticMesh:** `/Game/GF/Ships/frigate.frigate`

| Source material name | Planned master |
|---|---|
| `Vanguard Frigate &#124; canopy glass` | `M_GF_Glass` |
| `Vanguard Frigate &#124; engine plasma` | `M_GF_Engine` |
| `Vanguard Frigate &#124; graphite` | `M_GF_Trim` |
| `Vanguard Frigate &#124; hull` | `M_GF_Hull` |
| `Vanguard Frigate &#124; titanium armor` | `M_GF_Hull` |

### Leviathan Cruiser

**Expected StaticMesh:** `/Game/GF/Ships/cruiser.cruiser`

| Source material name | Planned master |
|---|---|
| `Leviathan Cruiser &#124; canopy glass` | `M_GF_Glass` |
| `Leviathan Cruiser &#124; engine plasma` | `M_GF_Engine` |
| `Leviathan Cruiser &#124; graphite` | `M_GF_Trim` |
| `Leviathan Cruiser &#124; hull` | `M_GF_Hull` |
| `Leviathan Cruiser &#124; identification` | `M_GF_Trim` |
| `Leviathan Cruiser &#124; titanium armor` | `M_GF_Hull` |

## UE Editor reconciliation checklist

For each of the seven StaticMeshes:

- [ ] Confirm the imported object path matches the expected path above.
- [ ] Record the actual Material Slot index and imported material asset name.
- [ ] Confirm the material is not a default grey or missing/pink material.
- [ ] Confirm Base Color, Metallic, Roughness and Normal texture connections.
- [ ] Inspect canopy opacity and sort/translucency behavior before selecting the Glass master blend mode.
- [ ] Confirm emissive engine material is actually assigned to nozzle/plasma geometry.
- [ ] Compare the slot list against this map; add any unlisted slot rather than silently mapping it to Hull.
- [ ] Only after reconciliation, create `M_GF_Hull`, `M_GF_Glass`, `M_GF_Engine`, `M_GF_Trim` and per-ship material instances.

## Important limitation

The single-mesh report proves that the source GLBs contain the listed named materials and one mesh node each. It does not prove Unreal's imported slot ordering or material fidelity. Final assignments and visual quality remain **NEEDS_UE_EDITOR** until the owner runs the import and inspects the assets in UE 5.8.4.
