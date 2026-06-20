extends Node
## Synthesized audio — every sound is generated in code at startup, so the game
## ships with ZERO external/copyright audio files (satisfies the "free from
## copyright" constraint better than even CC0). Autoloaded as "Audio".

const RATE := 22050

var _cache := {}
var _music_player: AudioStreamPlayer

func _ready() -> void:
	_cache["click"] = _blip(880.0, 0.05, 12.0)
	_cache["confirm"] = _arp([523.0, 659.0, 784.0], 0.18)
	_cache["deny"] = _blip(160.0, 0.18, 6.0, 0.4)
	_cache["beep"] = _blip(1200.0, 0.08, 10.0)
	_cache["success"] = _arp([523.0, 659.0, 784.0, 1046.0], 0.5)
	_cache["fail"] = _arp([392.0, 311.0, 233.0], 0.6)
	_cache["alarm"] = _alarm()
	_cache["wind"] = _noise(1.5, 0.25, true)
	_cache["engine"] = _engine()
	_cache["radio"] = _noise(0.4, 0.5, false)
	_cache["panic"] = _crowd(2.0)
	_cache["whoosh"] = _whoosh()
	_cache["explosion"] = _explosion()
	_cache["touchdown"] = _touchdown()
	_cache["step"] = _step()
	# Real CC0/ElevenLabs SFX override the synth versions when present.
	_load_sfx_override("alarm", true)
	_load_sfx_override("explosion", false)
	_load_sfx_override("confirm", false)   # ElevenLabs repair-success chime

# --- public API --------------------------------------------------------------

func play(sound: String, volume_db := 0.0, pitch := 1.0) -> void:
	if not _cache.has(sound):
		return
	var p := AudioStreamPlayer.new()
	p.stream = _cache[sound]
	p.bus = "SFX"
	p.volume_db = volume_db
	p.pitch_scale = pitch
	add_child(p)
	p.play()
	p.finished.connect(p.queue_free)

func play_loop(sound: String, volume_db := 0.0) -> AudioStreamPlayer:
	if not _cache.has(sound):
		return null
	var p := AudioStreamPlayer.new()
	p.stream = _cache[sound]
	p.bus = "SFX"
	p.volume_db = volume_db
	add_child(p)
	p.play()
	return p

func play_3d(sound: String, parent: Node3D, volume_db := 0.0) -> void:
	if not _cache.has(sound) or parent == null:
		return
	var p := AudioStreamPlayer3D.new()
	p.stream = _cache[sound]
	p.bus = "SFX"
	p.volume_db = volume_db
	p.unit_size = 6.0
	parent.add_child(p)
	p.play()
	p.finished.connect(p.queue_free)

func start_music(kind := "menu") -> void:
	stop_music()
	_music_player = AudioStreamPlayer.new()
	_music_player.stream = _music_stream(kind)
	_music_player.bus = "Music"
	add_child(_music_player)
	_music_player.play()

func stop_music() -> void:
	if _music_player != null and is_instance_valid(_music_player):
		_music_player.queue_free()
	_music_player = null

# --- synthesis ---------------------------------------------------------------

func _make_wav(samples: PackedFloat32Array, loop := false) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		bytes.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	wav.data = bytes
	if loop:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = samples.size()
	return wav

func _blip(freq: float, dur: float, decay: float, amp := 0.6) -> AudioStreamWAV:
	var n := int(dur * RATE)
	var a := PackedFloat32Array()
	a.resize(n)
	for i in n:
		var t := float(i) / RATE
		a[i] = sin(TAU * freq * t) * exp(-decay * t) * amp
	return _make_wav(a)

func _arp(freqs: Array, dur: float) -> AudioStreamWAV:
	var n := int(dur * RATE)
	var a := PackedFloat32Array()
	a.resize(n)
	var seg := n / freqs.size()
	for i in n:
		var t := float(i) / RATE
		var idx: int = clampi(i / seg, 0, freqs.size() - 1)
		var local_t := float(i - idx * seg) / RATE
		a[i] = sin(TAU * float(freqs[idx]) * t) * exp(-3.0 * local_t) * 0.5
	return _make_wav(a)

func _alarm() -> AudioStreamWAV:
	var dur := 1.0
	var n := int(dur * RATE)
	var a := PackedFloat32Array()
	a.resize(n)
	for i in n:
		var t := float(i) / RATE
		var f := 700.0 if fmod(t, 0.5) < 0.25 else 550.0
		a[i] = (1.0 if sin(TAU * f * t) > 0.0 else -1.0) * 0.35
	return _make_wav(a, true)

func _noise(dur: float, amp: float, loop: bool) -> AudioStreamWAV:
	var n := int(dur * RATE)
	var a := PackedFloat32Array()
	a.resize(n)
	var last := 0.0
	for i in n:
		var white := randf() * 2.0 - 1.0
		last = last * 0.92 + white * 0.08  # low-pass -> wind-ish
		a[i] = last * amp
	return _make_wav(a, loop)

func _engine() -> AudioStreamWAV:
	var dur := 1.0
	var n := int(dur * RATE)
	var a := PackedFloat32Array()
	a.resize(n)
	var last := 0.0
	for i in n:
		var t := float(i) / RATE
		var rumble := sin(TAU * 70.0 * t) * 0.4 + sin(TAU * 140.0 * t) * 0.2
		var white := randf() * 2.0 - 1.0
		last = last * 0.85 + white * 0.15
		a[i] = (rumble + last * 0.3) * 0.4
	return _make_wav(a, true)

func _crowd(dur: float) -> AudioStreamWAV:
	var n := int(dur * RATE)
	var a := PackedFloat32Array()
	a.resize(n)
	var last := 0.0
	for i in n:
		var t := float(i) / RATE
		var white := randf() * 2.0 - 1.0
		last = last * 0.9 + white * 0.1
		var wobble := 0.6 + 0.4 * sin(TAU * 6.0 * t)
		a[i] = last * wobble * 0.35
	return _make_wav(a, true)

func _whoosh() -> AudioStreamWAV:
	var dur := 0.7
	var n := int(dur * RATE)
	var a := PackedFloat32Array()
	a.resize(n)
	var last := 0.0
	for i in n:
		var env := sin(PI * float(i) / n)
		var white := randf() * 2.0 - 1.0
		last = last * 0.8 + white * 0.2
		a[i] = last * env * 0.6
	return _make_wav(a)

func _explosion() -> AudioStreamWAV:
	var dur := 1.4
	var n := int(dur * RATE)
	var a := PackedFloat32Array()
	a.resize(n)
	for i in n:
		var t := float(i) / RATE
		var env := exp(-3.0 * t)
		var white := randf() * 2.0 - 1.0
		var boom := sin(TAU * 50.0 * t)
		a[i] = (white * 0.7 + boom * 0.3) * env
	return _make_wav(a)

func _touchdown() -> AudioStreamWAV:
	var dur := 0.6
	var n := int(dur * RATE)
	var a := PackedFloat32Array()
	a.resize(n)
	for i in n:
		var t := float(i) / RATE
		var env := exp(-6.0 * t)
		var white := randf() * 2.0 - 1.0
		a[i] = (white * 0.5 + sin(TAU * 90.0 * t) * 0.5) * env
	return _make_wav(a)

func _step() -> AudioStreamWAV:
	var dur := 0.08
	var n := int(dur * RATE)
	var a := PackedFloat32Array()
	a.resize(n)
	var last := 0.0
	for i in n:
		var t := float(i) / RATE
		var env := exp(-28.0 * t)
		var white := randf() * 2.0 - 1.0
		last = last * 0.7 + white * 0.3
		a[i] = (last * 0.6 + sin(TAU * 110.0 * t) * 0.4) * env * 0.7
	return _make_wav(a)

## Play an ATC/voice line from assets/audio/voice/<name>.mp3 (ElevenLabs).
func play_voice(voice_name: String, volume_db := 1.0) -> void:
	var path := "res://assets/audio/voice/%s.mp3" % voice_name
	if not ResourceLoader.exists(path):
		return
	var s: Variant = load(path)
	if not (s is AudioStream):
		return
	var p := AudioStreamPlayer.new()
	p.stream = s
	p.bus = "SFX"
	p.volume_db = volume_db
	add_child(p)
	p.play()
	p.finished.connect(p.queue_free)

## Replace a synth SFX with a real file if one is bundled.
func _load_sfx_override(sfx_name: String, loop: bool) -> void:
	var path := "res://assets/audio/sfx/%s.mp3" % sfx_name
	if not ResourceLoader.exists(path):
		return
	var s: Variant = load(path)
	if s is AudioStreamMP3:
		s.loop = loop
	if s is AudioStream:
		_cache[sfx_name] = s

## Prefer a real CC0 track from assets/audio/music/<kind>.(mp3|ogg); fall back to
## the synthesized loop if none is bundled.
func _music_stream(kind: String) -> AudioStream:
	for ext in ["mp3", "ogg", "wav"]:
		var path := "res://assets/audio/music/%s.%s" % [kind, ext]
		if ResourceLoader.exists(path):
			var s: Variant = load(path)
			if s is AudioStreamMP3:
				s.loop = true
				return s
			if s is AudioStreamOggVorbis:
				s.loop = true
				return s
			if s is AudioStream:
				return s
	return _music(kind)

func _music(kind: String) -> AudioStreamWAV:
	# A slow, looping pad/arpeggio. Tense minor for the flight, calmer for menu.
	var prog: Array
	if kind == "flight":
		prog = [220.0, 277.0, 330.0, 247.0]  # A minor-ish tension
	else:
		prog = [261.0, 329.0, 392.0, 349.0]  # C major-ish calm
	var dur := 8.0
	var n := int(dur * RATE)
	var a := PackedFloat32Array()
	a.resize(n)
	var step := n / prog.size()
	for i in n:
		var t := float(i) / RATE
		var idx: int = clampi(i / step, 0, prog.size() - 1)
		var root: float = prog[idx]
		var pad := sin(TAU * root * t) * 0.18
		pad += sin(TAU * root * 1.5 * t) * 0.10
		pad += sin(TAU * root * 2.0 * t) * 0.06
		var arp_f: float = root * 2.0 * (1.0 + float((i / (RATE / 4)) % 3) * 0.25)
		var arp := sin(TAU * arp_f * t) * 0.05 * (0.5 + 0.5 * sin(TAU * 2.0 * t))
		a[i] = pad + arp
	return _make_wav(a, true)
