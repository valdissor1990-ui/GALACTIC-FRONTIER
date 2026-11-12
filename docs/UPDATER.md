# Windows updater

## What the player sees

The main menu checks the public GitHub Releases endpoint when it opens. If a newer stable release is available, the update button changes to **DOWNLOAD UPDATE**. The player can continue playing offline if GitHub is unavailable; the check is not required to launch a mission.

The update process downloads two release assets:
- `GALACTIC-FRONTIER-windows-update.zip` — the Windows executable and matching PCK at the archive root.
- `update-manifest.json` — the release version and SHA-256 digest of the archive.

The client checks that the manifest version matches the release tag, downloads the archive, and verifies SHA-256 before starting the installer. A separate PowerShell process waits for the game to exit, replaces only the EXE and PCK, and restarts the game. It keeps the previous EXE/PCK under `%LOCALAPPDATA%/GALACTIC-FRONTIER/rollback`. The main menu exposes a confirmation-protected rollback action when that backup exists.

Save files are stored in Godot's `user://` data directory (per-user application data on Windows), not beside the executable. Updating or replacing the installation therefore does not delete player saves.

## Publishing a stable update

1. Change `config/version` in `project.godot` to the next three-part version, for example `0.1.1`.
2. Merge and verify the exact commit that should be released.
3. Create and push the matching tag, for example `v0.1.1`.
4. The **Release Windows Update Package** workflow imports and tests the project, exports Windows, creates the update ZIP and SHA-256 manifest, then publishes both as GitHub Release assets.
5. Verify that the release is stable (not a prerelease) and contains both exact asset names expected by `UpdateManager`.

Do not publish a tag until Godot CI, Windows export/smoke test, and visual QA pass on that commit.

## Recovery and trust

The installer keeps the immediately previous EXE/PCK pair and can restore it from the main menu. If file replacement itself fails, the helper restores the pre-install files before restarting the game. The helper writes diagnostics to `%LOCALAPPDATA%/GALACTIC-FRONTIER/update.log`.

SHA-256 detects incomplete or corrupted downloads. It is not a digital signature: it does not independently protect against a maliciously replaced GitHub release and its manifest. Before a public commercial release, add a separately trusted signing key (for example, signed manifests or Windows Authenticode) and verify it in the client. The current project remains offline-first: updates are optional and no account, telemetry, game server, or always-on connection is required.
