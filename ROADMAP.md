# Roadmap

Status as of **v0.3.0**.

## v0.3.0 — bug fixes + visual/audio overhaul
- [x] **FIXED: client black screen / can't move in co-op** — clients now always spawn
      their own player (was depending on the roster, which hadn't synced yet). Verified with a 2-process lobby test.
- [x] **FIXED: empty photo banners** — load by explicit path (res:// dir scanning fails in
      exported builds). Verified inside a real packed build (5 photos load).
- [x] **FIXED: F1 in a server now leaves cleanly** (disconnects + returns to menu).
- [x] **FIXED: menus centered** (CenterContainer) and **roster panel back on-screen** (explicit anchors).
- [x] **Movement overhaul**: acceleration/friction, air control, coyote-time + jump-buffer, head-bob, sprint FOV, footsteps.
- [x] **Real CC0 textures** (ambientCG): tiled floor, carpet, concrete walls, metal — + warm interior lighting.
- [x] **Blocky crew characters** (suit/hi-vis/skin) replacing the capsules.
- [x] **Real CC0 music** (OpenGameArt) for menu + flight, with synth fallback.

## ✅ Done

**Foundation & systems**
- [x] Godot 4.7 project, autoloads (Settings / Audio / GameState / Net / Updater), git
- [x] Functional settings: audio, graphics (MSAA, **FSR2** render-scale, shadows), live key rebinding — persisted
- [x] First-person controller (walk/sprint/crouch/jump/look + interaction)
- [x] Fully **synthesized audio** (alarms, engine, beeps, music, explosion… zero copyright files)

**Single-player game (complete loop)**
- [x] Airport lobby hub + control Tower + **parkour** + **photo-banner easter egg**
- [x] Departures desk → board → match
- [x] **Procedural scenario generator** (failures/tasks/weather/airport/cabin layout differ every match; deterministic from seed)
- [x] Airliner interior (cockpit + cabin + window strips), passengers
- [x] **Flight model + ATC autopilot** — fix systems, reach the Tower, get talked down; *self-test proves it's winnable*
- [x] Multi-step **repair consoles** wired to the procedural failures (fuses, criticals)
- [x] Panic system + approach screams, timer, win/lose, hull integrity
- [x] Landing/crash **cinematic cutscene** + results screen + Fly Again
- [x] *Match self-test: disciplined crew wins, passive crew crashes*

**Multiplayer (co-op)**
- [x] ENet host/join by IP (“anyone can host”) — *2-process connection test passes*
- [x] Networked lobby: roster, ready-up, host START
- [x] Replicated players (RemoteAvatars) + host-authoritative match — *2-process match test runs clean*
- [x] Replicated task fixes, synced flight state, synced end
- [x] **Emotes** (synced) · **Pause menu**
- [x] **The Saboteur** asymmetric mode (host toggle · secret role · re-break sabotage · end-screen reveal)

**Art & content pass**
- [x] Global UI **theme + fonts** (Orbitron / Rajdhani, OFL) applied everywhere
- [x] Emergency cabin lighting (reddens with panic)
- [x] Squad **photos** wired into the lobby banners

**Identity, polish, distribution**
- [x] Crew customization (callsign, suit/trim color)
- [x] Clean menu/settings UI, multiplayer menu, in-game HUD
- [x] **Launch-time auto-updater** (notify + one-click download)
- [x] **Windows installer** (Inno Setup script) + one-file `.exe` + `package.sh` zip
- [x] Cross-compiled Windows build verified from the Pi

## ⚠️ Built but needs YOUR real-hardware test
- [ ] **Proximity voice + walkie-talkie** — implemented (push-to-talk, host-relayed PCM, positional playback), but can't be validated without mics on two machines. Isolated behind PTT; degrades gracefully with no mic.
- [ ] Live multiplayer *feel* across separate machines (latency, NAT/port-forward) — code path proven, but only a real session confirms it.

## ⬜ Remaining (content & polish)
- [ ] Replace greybox with CC0 **3D models** (Kenney/Quaternius) — UI theme/fonts + lighting are done; the model swap is the big remaining art task
- [ ] First-person arms + character model with the chosen colors
- [ ] Manual cockpit flying (yoke/throttle) for a pilot to beat the autopilot’s grade
- [ ] **Two-Ship Relay** mode (+ cross-ship walkie objectives)
- [ ] Self-replacing updater (vs. open-release-page), dedicated-server export
- [ ] Perf pass: LOD, occlusion culling, light baking

## Notes
- Greybox scenes are built in code for reliability; convert to authored `.tscn` when art lands.
- Add a Compatibility-renderer toggle for GPUs without Vulkan.
