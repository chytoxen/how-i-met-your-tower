# Roadmap

Status as of **v0.11.0**.

## v0.11.0 — buildings + character customization
- [x] **Real city skyline**: the exterior boxes are now Kenney **City Kit** buildings (detail buildings +
      skyscrapers), tinted to a cohesive dusk palette with ~40% warm-lit from within.
- [x] **Curated characters**: passengers = "normal folks" pool; players = "funny" pool
      (mascot / robots / monster / geisha / caveman / ninja).
- [x] **Character customization**: a new CUSTOMIZE screen with a live rotating 3D preview — cycle your
      funny character + set your callsign. Choice is saved and sent to other players (shows on your avatar).

## v0.10.0 — real characters (cohesive CC0 art pass begins)
- [x] Crew + passengers are now **real animated Kenney "Blocky Characters"** (CC0) instead of my
      hand-built figures / egg-heads — faces, clothes, **idle/walk/sit animations**, 18 variants.
- [x] **Fetched autonomously from the Pi** (no PC needed): web tools find Kenney's direct CDN zip URL,
      curl + unzip → GLB. Same method now staged for the **City Kit** (buildings) + **Furniture Kit** (props).
- [ ] Next: standardize the whole game on the cohesive Kenney style — buildings/skyline, terminal
      furniture/props, then better music + textures (each GPU-verified against `ART_DIRECTION.md`).

## v0.9.0 — de-neon pass + art-direction standard
- [x] **Killed the "too neon" look** (see `ART_DIRECTION.md`): glowing architecture → matte (columns,
      wayfinding, signage, hi-vis); cut bloom + raised its threshold; removed the global saturation boost
      (now slightly desaturated); muted the teal/amber accents.
- [x] **Restored warmth** after the de-neon went too cold: a warm key light (ceiling/cove) vs a gentle
      cool fill = the warm/cool contrast the reference look depends on (lobby + cabin).
- [x] **Passengers** rebuilt from "egg-head on a block" into varied seated figures (muted clothes/hair).
- [x] **Photo-tour** now hides the HUD and renders offscreen (clean beauty shots, no window flashing).
- [x] `ART_DIRECTION.md` — a concrete checklist (matte, ~2-temperature palette, desaturate, value/depth,
      motivated light) derived from real reference, applied to every render going forward.

## v0.8.0 — stylized exterior + autonomous GPU previews
- [x] **Exterior/runway restyled** to match the terminal: a real runway (asphalt, centerline,
      threshold "piano keys") with **emissive edge / approach / PAPI / threshold lights**, a cohesive
      **dusk city skyline** with buildings lit from within, and soft cloud layers (the chunky cloud
      boxes are gone).
- [x] **Autonomous GPU render pipeline** (dev tooling): the game has a hidden photo-tour mode that
      renders chosen camera shots; the Pi cross-compiles, deploys to the Windows PC, and triggers an
      interactive scheduled task so previews render on the real RTX 3070 — no more software-render guessing.

## v0.7.0 — stylized environment art pass ("clean indie", not Scratch)
- [x] Committed to a cohesive **clean stylized indie** art direction for the world.
- [x] **Terminal rebuilt**: curated palette (cool concrete + warm white + teal & amber accents),
      coffered ceiling with recessed warm light strips, columns with teal accent glow + uplights,
      a glowing **DEPARTURES board**, hanging gate signs, floor **wayfinding** stripes, a proper
      glass curtain wall, and floating **dust-mote atmosphere** + volumetric god-rays.
- [x] **Cabin restyled**: clean cream panels + warm LED cove lighting (cohesive with the terminal).
- [x] Dropped the generic realistic-marble-on-boxes look that read as "amateur".

## v0.6.0 — voice fix + visual overhaul
- [x] **Voice chat no longer garbled** — the downsampler took every 4th mic sample with no filter,
      which aliased high frequencies into harsh noise. Now anti-aliased (averaged) at ~16 kHz.
- [x] **Proximity voice tuned** — clearly full volume up close, fading to silence by ~28 m, emitted
      from the speaker's head.
- [x] **Smeared textures FIXED** — textures were imported with no mipmaps (built scenes in code, so
      Godot's "detect 3D" never ran), and normal maps were treated as sRGB color. Both fixed +
      anisotropic filtering, so floors/walls stay crisp at distance and grazing angles.
- [x] **Less "old game" look** — MSAA 4×, ACES tonemap, SSIL + SSR + stronger SSAO, bloom, a subtle
      color grade and depth haze, softer sun shadows (lobby + cabin).
- [x] **Terminal no longer an empty box** — real CC0 props (luggage, trash cans, wet-floor signs,
      fire extinguishers) + architectural trim (pillar caps/bases, baseboards, window mullions).

## v0.5.0 — playable lobby + characters with faces + a real airliner
- [x] **FIXED (blocker): couldn't start a co-op match** — the cursor was locked to mouse-look so
      `READY UP` / `START FLIGHT` were unclickable. The networked lobby now starts with a **free cursor**
      (panel immediately clickable) and **ESC toggles** cursor free/locked for walking around. Verified
      with a 2-process lobby test.
- [x] **Crew characters now have a FACE** (eyes, smile, pilot cap, hi-vis) and proper proportions.
- [x] **Walk animation** — arms and legs swing, body bobs and leans whenever a crewmate is moving
      (code-driven from their actual speed, so it costs no extra network traffic).
- [x] **Real airliner** — the toy cylinder is gone; the plane is now a proper jet (rounded fuselage,
      swept wings + dihedral, underwing engines, tailplane, liveried swept fin, cockpit glass, lit
      cabin windows). Used by the landing/crash cutscene and the distant "other ship".

## v0.4.0 — the Tower speaks + real models
- [x] **ATC "Tower" voice** (ElevenLabs) — talks you down at contact / approach / brace / landing+crash.
- [x] Real **alarm + explosion SFX** (ElevenLabs) replacing the synth versions.
- [x] Real **CC0 3D models** (PolyHaven): armchairs replace the box lounge seating + potted plants for greenery.
- [x] Tooling: Godot/ElevenLabs MCPs (Pi) + Blender MCP (→ Windows over Tailscale) + a CC0 model pipeline + an offscreen screenshot rig for verifying visuals on the headless Pi.

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
- [ ] Optional: swap the procedural crew/plane for downloaded stylized CC0 models (Kenney/Quaternius/KayKit)
      via the PC + Blender pipeline if you want even more detail — the procedural ones look good and ship now
- [ ] First-person arms (your own hands) in the cockpit/cabin view
- [ ] Manual cockpit flying (yoke/throttle) for a pilot to beat the autopilot’s grade
- [ ] **Two-Ship Relay** mode (+ cross-ship walkie objectives)
- [ ] Self-replacing updater (vs. open-release-page), dedicated-server export
- [ ] Perf pass: LOD, occlusion culling, light baking

## Notes
- Greybox scenes are built in code for reliability; convert to authored `.tscn` when art lands.
- Add a Compatibility-renderer toggle for GPUs without Vulkan.
