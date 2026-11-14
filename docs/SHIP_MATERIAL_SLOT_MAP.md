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
| `Raider | graphite recess` | `M_GF_Trim` |
| `Raider | obsidian ceramic` | `M_GF_Hull` |
| `Raider | plasma core` | `M_GF_Engine` |
| `Raider | polarized canopy` | `M_GF_Glass` |
| `Raider | titanium armor` | `M_GF_Hull` |
| `Raider | warning vermilion` | `M_GF_Trim` |

### Aegis Heavy Fighter

**Expected StaticMesh:** `/Game/GF/Ships/heavy_fighter.heavy_fighter`

| Source material name | Planned master |
|---|---|
| `Aegis Heavy Fighter | canopy glass` | `M_GF_Glass` |
| `Aegis Heavy Fighter | engine plasma` | `M_GF_Engine` |
| `Aegis Heavy Fighter | graphite` | `M_GF_Trim` |
| `Aegis Heavy Fighter | hull` | `M_GF_Hull` |
| `Aegis Heavy Fighter | identification` | `M_GF_Trim` |
| `Aegis Heavy Fighter | titanium armor` | `M_GF_Hull` |

### Bastion Bomber

**Expected StaticMesh:** `/Game/GF/Ships/bomber.bomber`

| Source material name | Planned master |
|---|---|
| `Bastion Bomber | canopy glass` | `M_GF_Glass` |
| `Bastion Bomber | engine plasma` | `M_GF_Engine` |
| `Bastion Bomber | graphite` | `M_GF_Trim` |
| `Bastion Bomber | hull` | `M_GF_Hull` |
| `Bastion Bomber | identification` | `M_GF_Trim` |
| `Bastion Bomber | titanium armor` | `M_GF_Hull` |

### Mule Cargo Hauler

**Expected StaticMesh:** `/Game/GF/Ships/cargo_hauler.cargo_hauler`

| Source material name | Planned master |
|---|---|
| `Mule Cargo Hauler | canopy glass` | `M_GF_Glass` |
| `Mule Cargo Hauler | engine plasma` | `M_GF_Engine` |
| `Mule Cargo Hauler | graphite` | `M_GF_Trim` |
| `Mule Cargo Hauler | hull` | `M_GF_Hull` |
| `Mule Cargo Hauler | identification` | `M_GF_Trim` |
| `Mule Cargo Hauler | titanium armor` | `M_GF_Hull` |

### Vanguard Frigate

**Expected StaticMesh:** `/Game/GF/Ships/frigate.frigate`

| Source material name | Planned master |
|---|---|
| `Vanguard Frigate | canopy glass` | `M_GF_Glass` |
| `Vanguard Frigate | engine plasma` | `M_GF_Engine` |
| `Vanguard Frigate | graphite` | `M_GF_Trim` |
| `Vanguard Frigate | hull` | `M_GF_Hull` |
| `Vanguard Frigate | titanium armor` | `M_GF_Hull` |

### Leviathan Cruiser

**Expected StaticMesh:** `/Game/GF/Ships/cruiser.cruiser`

| Source material name | Planned master |
|---|---|
| `Leviathan Cruiser | canopy glass` | `M_GF_Glass` |
| `Leviathan Cruiser | engine plasma` | `M_GF_Engine` |
| `Leviathan Cruiser | graphite` | `M_GF_Trim` |
| `Leviathan Cruiser | hull` | `M_GF_Hull` |
| `Leviathan Cruiser | identification` | `M_GF_Trim` |
| `Leviathan Cruiser | titanium armor` | `M_GF_Hull` |

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
