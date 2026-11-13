# Graphics Pass — Open World 2020–2025 baseline

**Branch:** `grok/graphics-open-world-2025`  
**Author:** Grok  
**Status:** Slice 2 — thrusters, relay landmark, combat bolt

## Slice 1
- Starfield + nebula sky shader
- Hull Fresnel / panel shader
- OpenSpaceBackdrop (ACES, glow, SSAO, dual planets, MultiMesh belt)
- Wired into `test_flight.tscn`

## Slice 2 (this update)

| Piece | Path |
|-------|------|
| Engine plume shader | `assets/shaders/engine_plume.gdshader` |
| Relay pulse shader | `assets/shaders/relay_pulse.gdshader` |
| Thrust FX controller | `scripts/vfx/engine_thrust_fx.gd` |
| Silent Relay beacon | `scenes/environment/silent_relay_beacon.tscn` |
| Emissive projectile | `scenes/combat/projectile.tscn` |
| Backdrop spawns relay | `scripts/environment/open_space_backdrop.gd` |
| Ship plumes + sparks | `scenes/flight/test_flight.tscn` |

Thrust intensity follows speed + boost (visual only, no physics change).

## Still next
- PBR maps on GLB `player_fighter` / fleet
- Enemy fighter material parity
- Hit / explosion one-shots
- Profile MultiMesh + particles on target hardware
- Merge with ChatGPT deep-space / fleet branches when stable

## Preview
`scenes/flight/test_flight.tscn` — Godot 4.7 Forward+.  
Runtime **NOT RUN** in this agent environment.
