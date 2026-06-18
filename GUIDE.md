# How I Met Your Tower — Install · Play · Update

## For your friends — install & play (Windows 11)

1. **Download:** https://github.com/chytoxen/how-i-met-your-tower/releases/latest
   → under **Assets**, grab **HowIMetYourTower-v0.2.0.zip**.
2. **Unzip** anywhere, run **HowIMetYourTower.exe**.
   - Windows SmartScreen may warn "unknown publisher" → **More info → Run anyway**.
     (It's unsigned only because code-signing certificates cost money — the game is safe.)
3. **Play:**
   - **Solo:** `PLAY (SOLO)` → walk to the glowing **DEPARTURES** desk → press **E**.
   - **Co-op:** see below.

### Co-op (up to 4 players)
- **Host** (one person): `MULTIPLAYER → HOST A FLIGHT`, then share your IP.
  - **Same WiFi/LAN:** share your local IPv4 (run `ipconfig`, e.g. `192.168.1.23`).
  - **Over the internet:** forward **UDP port 24565** to your PC and share your public IP —
    or, much easier, everyone installs **ZeroTier** or **Hamachi** (free) and uses those IPs.
- **Everyone else:** `MULTIPLAYER → type the host's IP → JOIN`.
- In the lobby: **READY UP**. The host can switch **MODE** (Co-op / Saboteur) and hit **START FLIGHT**.

### Controls
`WASD` move · `Shift` sprint · `Ctrl` crouch · `Space` jump · mouse look ·
`E` interact · `C` emote · `V` push-to-talk · `B` walkie-talkie · `Esc` pause.
Everything is rebindable in **Settings → Controls**.

### The goal
Fix the failing systems (run to each console, press **E** to work its steps), **fix the
radio first** to reach the Tower (unlocks ATC guidance), then land before the timer or
the plane's hull runs out. In **Saboteur** mode one of you is secretly trying to crash it.

---

## Updates — how players get them
When you publish a new version, anyone who launches the game sees a green
**"Update vX available — Download"** banner on the main menu that opens the releases page.
They download the new zip and replace the old `.exe`. First-time players always get the
latest from the releases page, so they start current.

## Updates — how YOU publish one
1. Make your changes.
2. Bump the version in **two** files (keep them equal): `VERSION` and `CURRENT_VERSION`
   in `core/Updater.gd` (and `MyAppVersion` in `installer/setup.iss` if you ship the installer).
3. Run:
   ```bash
   ./publish_release.sh "what changed in this version"
   ```
   That rebuilds the Windows `.exe`, zips it, refreshes the update manifest, pushes, and
   creates the GitHub release. Players see the banner on their next launch.

## Optional: a real Windows installer
Instead of a zip, compile `installer/setup.iss` with [Inno Setup](https://jrsoftware.org/isdl.php)
(free, Windows) to produce `HowIMetYourTower-Setup.exe` with Start-menu/desktop shortcuts.

## Links
- **Game / source:** https://github.com/chytoxen/how-i-met-your-tower
- **Latest download:** https://github.com/chytoxen/how-i-met-your-tower/releases/latest
- **Update manifest:** https://raw.githubusercontent.com/chytoxen/how-i-met-your-tower/main/version.json
