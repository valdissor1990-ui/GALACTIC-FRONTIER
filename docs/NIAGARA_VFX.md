# Niagara VFX — GALACTIC FRONTIER (UE 5.8)

## Runtime driver

`UGFShipVfxComponent` (on `AGFPlayerShipPawn`) owns continuous and one-shot FX:

| System soft path | Role | Driven by |
|------------------|------|-----------|
| `/Game/GF/VFX/NS_EngineThrust` | Left/right engine plume | speed + boost |
| `/Game/GF/VFX/NS_BoostTrail` | Boost streak | `IsBoostActive()` |
| `/Game/GF/VFX/NS_MuzzleFlash` | Weapon flash | `UGFWeaponComponent::FireOnce` |
| `/Game/GF/VFX/NS_SpaceDust` | Local parallax dust | speed norm |
| `/Game/GF/VFX/NS_ImpactSpark` | Hit sparks | `PlayImpact()` |

### User parameters (Niagara)

Add **User** exposed parameters (float):

- `User.Intensity` — 0..1+ thrust / effect strength  
- `User.Boost` — 0 or 1 while boosting  
- `User.Scale` — optional overall scale  

C++ sets them via `UNiagaraComponent::SetVariableFloat`.

## Authoring checklist (Editor)

1. Compile C++ (Niagara module linked in `GalacticFrontier.Build.cs`).  
2. Run `Content/Python/setup_galactic_frontier.py` — creates empty systems if missing.  
3. Open each `NS_*` and build emitters:
   - **EngineThrust**: GPU sprite/ribbon, additive cyan, spawn rate × Intensity, lifetime short, velocity −X (rear).  
   - **BoostTrail**: ribbon or stretched sprites, higher rate when Boost=1.  
   - **MuzzleFlash**: burst emitter, 0.08–0.15s, bright core.  
   - **SpaceDust**: large radius, slow particles, camera/ship relative.  
   - **ImpactSpark**: burst + short trails.  
4. Keep particle counts low; rely on `ApplyQualityScale` (Low≈0.35, Med≈0.7, High=1.0).

## Integration points

- Flight: `UGFShipFlightComponent::IsBoostActive()`, `GetVelocity()`, `MaxSpeed`  
- Weapon: muzzle at `MuzzleOffset`  
- Graphics: `UGFGraphicsSettings` preset at BeginPlay  

## Quality / performance

- Disable or hide `SpaceDust` on Low.  
- Prefer GPU emitters; avoid overdraw on thrusters (soft alpha, limited lifetime).  
- Pool one-shots (`ENCPoolMethod::AutoRelease`).  

## Status

- C++ driver: **implemented**  
- Asset graphs: **author in Editor** (placeholders only from Python)  
- Runtime playtest: **NOT RUN** in CI  

— Grok
