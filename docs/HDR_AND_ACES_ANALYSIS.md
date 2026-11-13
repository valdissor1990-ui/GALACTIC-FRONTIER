# HDR and ACES — engine analysis & project decisions

**Author:** Grok  
**Branch:** `grok/graphics-open-world-2025`

## 1. Two different “HDR”s

| Term | Meaning |
|------|--------|
| **HDR rendering** | Scene lit in high dynamic range (float buffers). Almost all modern engines do this. |
| **HDR display output** | Frame sent to monitor in HDR10/scRGB with >100 nits peak. Optional; needs OS/GPU path. |

GALACTIC FRONTIER today: **HDR rendering → SDR display** via tonemap + glow. True HDR output is a later option (Godot 4.7+ path).

## 2. Tonemapper cost (Godot Forward+)

Approximate cost from engine profiling (relative, 4K ref scene):

| Mode | ~ms | Notes |
|------|-----|-------|
| Linear | 0.82 | Clips brights |
| Reinhard | 0.93 | Soft, dull |
| **Filmic** | **1.00** | Good cheap film look |
| **ACES** | **1.07** | Slightly more contrast + desat |
| AgX (optimized) | ~1.05 | Better hue retention |
| AgX (exact) | higher | Avoid on low-end |

**Delta ACES − Filmic ≈ 0.07 ms** — small alone, free on Low when stacked with fewer glow mips and no color adjustment.

Official docs: ACES is *slightly slower than Filmic*; AgX is the slowest classic option unless approximated.

## 3. How engines handle HDR

### Godot 4
- Internal 3D is HDR.
- Tonemap: Linear / Reinhard / Filmic / ACES / AgX.
- Glow samples HDR before/around tonemap; Softlight blend.
- **ACES & Filmic** designed around SDR `white` — poor fit for true HDR display.
- **AgX** reworked for HDR output; Godot **4.7** adds display HDR.
- FSR1/2 scale 3D buffer; tonemap still full-res composite.

### Unreal Engine
- Long default: **ACES** (often criticized for hue shift / “that UE look”).
- Moving toward **ACES 2.0** and community **AgX** for grim/realistic looks.
- Full HDR display pipeline mature (nits, paper white).

### Unity (URP/HDRP)
- URP: ACES, Neutral, now **AgX** (6.7 beta).
- HDRP: richer HDR display + exposure metering.
- AgX sold on smooth highlight→white without ACES hue drift.

### Industry trend
- **ACES** = cinematic, contrasted, common default, hue shift on extreme brights.
- **AgX** = rising default (Blender, Unity, UE mods): preserves hue, rolls to white.
- For **emissive-heavy** games (space engines, lasers), AgX often needs less fighting in grade.

## 4. Project decisions (GALACTIC FRONTIER)

| Preset | Tonemap | Why |
|--------|---------|-----|
| **Low** | **Filmic** | ~same film family, cheaper; fewer glow mips; no adjustment pass |
| **Medium** | **ACES** | Target look for void + cyan plumes |
| **High** | **ACES** | Full glow mips + adjustment |

Additional Low savings:
- Glow levels 5–6 off (less blur bandwidth)
- `adjustment_enabled = false`
- Screen cinematic post off (already)
- Shadows off

**Not switching default Med/High to AgX yet** — ACES is locked art direction for open space; AgX remains a future A/B if display-HDR or hue issues appear on engines.

## 5. Practical rules

1. Author lights/emissions in **linear HDR** (energy > 1 is OK).
2. Use **tonemap white** as headroom, not as a brightness knob (prefer exposure).
3. Cap glow with **hdr_luminance_cap** so one projectile cannot bloom the frame.
4. Do not enable true HDR output without switching tonemap strategy (AgX / HDR-aware).
5. Measure: Debugger → Monitors; tonemap is rarely the #1 cost vs shadows/particles/resolution.

## 6. Code hooks

```gdscript
env.tonemap_mode = GraphicsQuality.tonemap_mode()  # Filmic or ACES
GraphicsQuality.apply_glow_levels(env)
env.adjustment_enabled = GraphicsQuality.adjustment_enabled()
```

See also: `docs/ACES_TONEMAP.md`, `docs/FSR1_AND_HDR.md`.
