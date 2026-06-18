# How I Met Your Tower — Design

## Premise

A co-op aviation **emergency / disaster-rescue** game. 2–4 players crew a stricken
airliner. Systems are failing; the cabin is in chaos; the clock is running. The
crew must split between **cockpit** (fly + stabilize) and **cabin** (fight fires,
seal breaches, calm passengers), coordinate, and **reach the Tower** — Air Traffic
Control — to be talked down to a survivable landing.

**"The Tower" = ATC.** The title's whole meaning: the desperate scramble to reach
the people who can bring you home. The win condition is literally *meeting the
Tower* — establishing contact and landing alive.

Tone: tense, loud, heroic. Screaming passengers, blaring alarms, sparks and smoke —
but you are the ones trying to **save** the plane, not the opposite.

---

## Modes (both of the original asks, reframed)

1. **Mayday Co-op (primary).** 2–4 players, one crew, one aircraft. Survive the
   procedural emergency and land before the timer. Scales 1→4 players.
2. **Two-Ship Relay.** Two aircraft (2 players each), both racing their own
   emergency to land. **Walkie-talkie** links the crews; some steps require the
   *other* ship's help (e.g. they read you a checklist value only they can see) —
   the original "two teams must cooperate" obstacle.
3. **The Saboteur (asymmetric variant).** One crew member is secretly causing the
   failures (social-deduction). The others must land the plane *and* figure out
   who — covers the original "defenders vs intruder" asymmetric mode without a
   real-world atrocity framing. Non-lethal: the saboteur trips systems, doesn't
   murder passengers.

Spectators: a downed/ejected player spectates teammates and **hears** proximity
voice but cannot speak (per the original spec).

---

## Procedural variation (core pillar)

> *"Each time we start a new game, the map and the tasks need to be a bit
> different to keep it interesting."*

Implemented in `scenarios/ScenarioGenerator.gd`. A single integer **seed** (the
host broadcasts it; every client rebuilds the identical match) drives:

**Tasks differ** — a random subset of system failures is drawn from a pool
(engine fire, hydraulics, decompression, electrical, gear jam, fuel leak, cabin
smoke, bird strike). Each has:
- a **zone** (cockpit / cabin / wing / belly),
- a **severity** and a **fuse** (seconds until it goes critical; 0 = persistent),
- an ordered **multi-step fix chain** (e.g. engine fire → pull fire handle → cut
  fuel → arm bottle → discharge) deliberately too long to solo under pressure,
- a best-fit **crew role** (pilot / engineer / purser),
- a **staggered onset** so failures cascade instead of dumping at once.

**Map differs** — destination **airport** (5 layouts), **weather** (clear/storm/
fog/crosswind/icing — hard weather adds time + difficulty), and **cabin layout**
(row count, galley side, randomized item spawn locations for extinguishers/
toolkit/medkit/manual, a **jammed exit** that forces a co-op reroute, fire row).

**Difficulty** scales the number of simultaneous failures (1 + difficulty, capped
at 4) and the time limit.

Determinism is unit-tested (`scenarios/scenario_selftest.gd`): same seed →
identical scenario; different seeds → different scenarios; 6 seeds yield ≥4
distinct signatures. Run: `godot --headless --path . -s res://scenarios/scenario_selftest.gd`.

---

## Stealth vs. loud + suspicion (from the original)

Re-cast as **"calm cabin vs. panic"**. Crew actions either reassure or alarm the
passengers; a **panic meter** rises with visible fire/smoke, rough maneuvers, and
(in Saboteur mode) suspicious behavior. High panic = passengers block aisles,
won't follow brace instructions, jam exits — making the landing prep harder. Low
panic = orderly cabin, faster tasks. Same risk/consequence loop, no atrocity.

---

## Feature map (original request → plan)

| Original ask | Plan in this project |
|---|---|
| 4-player online, ≤2 per vehicle, self-hosted | Godot high-level multiplayer (ENet listen-server); any player hosts by IP/LAN (Phase 4) |
| First-person 3D, full models, physics | First-person now; CC0 models + authored scenes (Phase 2–3) |
| Steering the vehicle | Flight model for the airliner (Phase 3) |
| Proximity voice; spectators listen-only | Mic capture + positional mix over the net; spectators muted (Phase 5) |
| Walkie-talkies between crews | Dedicated radio channel, push-to-talk `B` (Phase 5) |
| Co-op gated obstacles | Cross-ship checklist steps + jammed-exit reroute (Phase 3–4) |
| Lobby = detailed airport, parkour, flyable planes | Airport hub greybox now; parkour + flyable trainer (Phase 2–3) |
| Character customization + gametag | Callsign + suit/trim color now; full cosmetics (Phase 2) |
| Asymmetric mode | The Saboteur (Phase 6) |
| Settings: audio/keybinds/graphics/screen | **Done** (live + persisted) |
| Clean UI, emotes | Menu/settings done; emote wheel (Phase 2) |
| Tension audio, screaming, music | CC0 SFX/music + dynamic panic audio (Phase 2, 5) |
| Side cutscene on landing | Scripted landing cam + outcome cutscene (Phase 7) |
| Easter eggs incl. squad photos as banners | **Photo banners done**; more eggs ongoing |
| Installer; anyone can host; auto-update | One-file `.exe` done; installer + version-manifest updater (Phase 8) |
| DLSS, optimize, Windows 11 | **FSR2** (see below) + LOD/occlusion (Phase 8) |
| Good lighting/shadows/textures | Forward+, shadows, SSAO, glow — **on** |
| Free/CC0 assets | Sourcing list below |

---

## Tech decisions

- **Engine: Godot 4.7** — free/MIT (matches the "free, no copyright" constraint),
  trivial Windows export, built-in high-level multiplayer, lightweight, and it
  cross-compiles to a single Windows `.exe` from the Pi (verified).
- **Renderer: Forward+** — best shadows/lighting/SSAO/glow (the "good lighting"
  ask). Fallback to Compatibility renderer if a friend's GPU lacks Vulkan.
- **Upscaling: FSR2, not DLSS.** DLSS is NVIDIA-proprietary and requires their SDK
  in Unreal/Unity — it can't ship in a free Godot project and would lock out
  AMD/Intel/older NVIDIA. **FSR 2.2 is built into Godot, free, open, and runs on
  all GPUs**, giving the same "render at lower res, upscale sharp" win. Wired to
  the Graphics → Render scale slider already.
- **Multiplayer: ENet listen-server** — one player hosts, others join by IP (LAN
  works out of the box; WAN needs a port-forward or we add a relay later). This is
  the "anyone can host from their computer" requirement.
- **Voice: Godot `AudioEffectCapture` + Opus over RPC**, positional mix for
  proximity, separate radio bus for walkie-talkies, spectators capture-disabled.

## Asset sourcing (all free / CC0 / commercial-OK)

- Models: **Kenney** (kenney.nl, CC0), **Quaternius** (CC0) — aircraft, props, gates.
- Textures/HDRIs: **Poly Haven** (CC0), **ambientCG** (CC0).
- Audio: **freesound.org** (filter CC0), **Kenney audio** (CC0); music: **Incompetech**/
  **FMA** CC-BY (credit) or CC0 tracks.
- Fonts: **Google Fonts** (OFL).

Drop into `assets/`. Keep a `CREDITS.md` for any CC-BY attribution.
