# GALACTIC FRONTIER — Demo Guide

## The Silent Relay

The first playable vertical slice is designed for an approximately 10-minute session. Actual completion time depends on flight style and combat performance.

### Mission sequence

1. Depart the orbital carrier and follow the blue navigation beacon to the silent relay.
2. Enter the marked scan radius and press **F**.
3. Defeat three hostile waves protecting the relay.
4. Follow the amber marker to the wreck and press **F** to recover its data core.
5. Defeat three further hostile waves.
6. Follow the green marker back to the orbital carrier to complete the operation.

Enemy fighters use the same combat AI, projectile, shield and hull systems as the rest of the combat prototype. Destroyed ships produce impact and explosion effects.

## Controls

| Input | Action |
|---|---|
| W / S | Forward / reverse thrust |
| A / D | Strafe left / right |
| Space / Z | Vertical thrust up / down |
| Q / E | Yaw left / right |
| I / K | Pitch up / down |
| J / L | Roll left / right |
| Shift | Boost |
| X | Brake |
| Mouse | Aim / flight steering |
| Left mouse button | Fire primary weapons |
| T | Lock target |
| Y | Clear target |
| F | Scan relay or wreck when in range |
| C | Switch chase / cockpit camera |
| Esc | Pause |
| [ / ] | Decrease / increase mouse sensitivity |

## Build and runtime

- Target: Windows 64-bit desktop.
- Engine: Godot 4.7.2-stable.
- Renderer: Forward+.
- Extract the downloaded archive and keep GALACTIC-FRONTIER.exe and GALACTIC-FRONTIER.pck in the same folder.
- The game is single-player and does not require an account or an online connection after download.

## Validation status

The automated pipeline checks script parsing, combat tests, the complete mission progression, scene startup, Windows export and Windows executable startup. Interactive playtesting on a physical Windows PC remains a separate acceptance check.
