# SC detail slice (implemented)

**Branch:** `grok/graphics-open-world-2025`

## Done
1. **Dual-LOD asteroids** — near shell (higher segs, short range) + far shell (cheap mesh, begin fade).
2. **Hero hull** — `hull_fresnel`: panels, rivets, wear, window emissive strips.
3. **SectorDetailStreamer** — toggles nodes with `sector_poi` meta by player radius (Relay, GravityAnomaly marked).

## Files
- `assets/shaders/hull_fresnel.gdshader`
- `scripts/environment/open_space_backdrop.gd`
- `scripts/environment/sector_detail_streamer.gd`
- `scenes/flight/test_flight.tscn`

## NOT RUN
Fly belt (near rocks denser), orbit relay/anomaly (streamer), inspect hull in chase cam.
