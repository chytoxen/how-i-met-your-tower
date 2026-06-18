# How I Met Your Tower

A co-op, first-person **aviation emergency** game. You and up to 3 friends are the
flight crew of a failing airliner. Fix the failing systems, **reach the Tower**
(Air Traffic Control), and get talked down to a landing before the clock — or the
plane — runs out. Every flight is procedurally different.

> Engine: **Godot 4.7** · Target: **Windows 11** (x86-64) · Dev host: Raspberry Pi 5 (cross-compiled)

---

## Status — v0.2.0 (complete, playable solo + co-op)

**Verified** (compiles clean, every scene boots, logic self-tests pass, networking
proven across two processes, Windows `.exe` builds):

- Main menu · multiplayer menu · functional **Settings** (audio / graphics incl. FSR2 / live key rebinding) · crew **customization** · **pause menu**
- First-person movement + interaction · **emotes**
- Airport **lobby** hub: control Tower, **parkour**, and the **squad-photo banner easter egg**
- **Procedural emergencies** — failures, tasks, weather, destination, cabin layout differ every match (deterministic from a seed so all players get the same one)
- The full **flight loop**: repair consoles (multi-step, fused) → reach the Tower → ATC talks you down the glide slope → land or crash → **cinematic cutscene** → results → fly again
- Panic/screams, hull integrity, the countdown
- **Co-op multiplayer**: host/join by IP, networked lobby with ready-up, replicated crew, host-authoritative match, synced fixes + flight + emotes

**Needs your real-hardware test** (can't be validated headless): **proximity voice +
walkie-talkie** (built, push-to-talk, gated + graceful with no mic) and live
multiplayer *feel* across separate machines.

See `ROADMAP.md` for what's done vs. remaining, `DESIGN.md` for the full vision.

---

## Play it

**Prebuilt (hand to friends):** `builds/HowIMetYourTower-v0.2.0.zip` — unzip and run
`HowIMetYourTower.exe` (self-contained, Windows 11). Or build the installer from
`installer/setup.iss` with [Inno Setup](https://jrsoftware.org/isdl.php).

**From source:** install Godot 4.7, open `project.godot`, press **F5**.

**Rebuild / repackage the Windows build (from the Pi or any machine with Godot):**
```bash
./build_windows.sh     # -> builds/HowIMetYourTower.exe
./package.sh           # -> builds/HowIMetYourTower-vX.Y.Z.zip
```

### Solo
Main menu → **PLAY (SOLO)** → walk to the glowing **DEPARTURES** desk → press **E**.

### With friends (up to 4)
One hosts: **MULTIPLAYER → HOST**. Others: **MULTIPLAYER → type host IP → JOIN**.
In the lobby, **READY UP**; host hits **START FLIGHT**. (LAN works out of the box;
over the internet forward UDP **24565** or use ZeroTier/Hamachi.)

### Controls
`WASD` move · `Shift` sprint · `Ctrl` crouch · `Space` jump · mouse look ·
`E` interact · `C` emote · `V` push-to-talk · `B` walkie · `Esc` pause. All rebindable.

---

## Add your squad's photos (easter egg)

Drop `.png` / `.jpg` files into **`assets/banners/`** — they auto-hang as framed,
spotlit banners around the terminal (11 slots, cycled). No code changes needed.

---

## Project layout

```
core/        autoloads: Settings, Audio (synth), GameState, Net, Updater
player/      first-person controller (+ interaction, emotes)
world/       Lobby, Aircraft (the match), TaskStation, CrewManager, RemoteAvatar, Voice, BannerManager
flight/      FlightModel, AutoPilot, ExteriorRig, MatchRules (+ self-tests)
scenarios/   ScenarioGenerator (+ self-test)
ui/          MainMenu, MultiplayerMenu, SettingsMenu, MatchHUD, NetLobbyPanel, PauseMenu, EndScreen
installer/   Inno Setup script        assets/  banners / audio / fonts / textures / models
```

Updating the game for players who already have it: see `UPDATING.md`.
