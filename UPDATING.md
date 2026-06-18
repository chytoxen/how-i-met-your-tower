# Pushing updates

The game checks for updates on launch. When you publish a newer version, players
see a **"Update vX.Y.Z available — Download"** banner on the main menu that opens
your release page. First-time installers just grab the latest release, so they
start current.

## Release a new version

1. Bump the version in **two** places (keep them equal):
   - `VERSION`
   - `CURRENT_VERSION` in `core/Updater.gd`
   - (and `MyAppVersion` in `installer/setup.iss` if you ship the installer)
2. Build + package:
   ```bash
   ./package.sh          # -> builds/HowIMetYourTower-vX.Y.Z.zip
   ```
   For a real installer, compile `installer/setup.iss` with Inno Setup on Windows
   (free, https://jrsoftware.org/isdl.php) → `HowIMetYourTower-Setup.exe`.
3. Publish the zip (or installer) — easiest is a **GitHub Release**.
4. Publish/refresh a **manifest** JSON somewhere with a stable URL, e.g. commit a
   `version.json` to the repo and use its raw URL:
   ```json
   { "version": "0.3.0",
     "url": "https://github.com/<you>/<repo>/releases/latest",
     "notes": "Two-ship mode, voice fixes" }
   ```
5. Point the updater at that manifest **once**: set `MANIFEST_URL` in
   `core/Updater.gd` to the raw `version.json` URL, then ship that build. From
   then on, every launch compares `version` to the running build and shows the
   banner when yours is newer.

## Notes
- The updater fails silently with no network or an unset URL — it never blocks play.
- It opens the release page rather than self-replacing the running .exe (Windows
  can't overwrite a running binary). Players download + run the new installer/zip.
- Versions are compared as semver (`major.minor.patch`).
