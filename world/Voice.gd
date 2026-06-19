class_name Voice
extends Node
## Push-to-talk voice. Captures the mic while a talk key is held, downsamples to
## mono PCM, and streams it (host-relayed, unreliable) to the other players:
##   V  = proximity voice  (played at the speaker's avatar — quieter with distance)
##   B  = walkie-talkie     (played flat/2D — both ends hear it clearly)
##
## Robust by design: if there's no microphone / input is disabled / we're headless,
## it simply never captures (no crash, no error spam). Gated behind the keys so it
## adds zero overhead when nobody's talking.
##
## NOTE: this path needs a real two-machine + microphone test — it can't be
## validated headlessly. It's isolated behind PTT; if it misbehaves it won't
## affect the rest of the game.
##
## Added as a child named "Voice" under CrewManager so the RPC path matches.

var _capture: AudioEffectCapture
var _enabled := false
var _crew: Node
var _players := {}   # peer_id -> { "player": Node, "pb": AudioStreamGeneratorPlayback }
var _rate := 16000.0
var _step := 3       # mix-rate frames per output sample (anti-aliased average)

func setup(crew: Node) -> void:
	_crew = crew
	if DisplayServer.get_name() == "headless":
		return
	if not bool(ProjectSettings.get_setting("audio/driver/enable_input", false)):
		return
	# Target ~16 kHz voice regardless of the device mix rate (44.1/48 kHz).
	var mix := AudioServer.get_mix_rate()
	_step = maxi(1, int(round(mix / 16000.0)))
	_rate = mix / float(_step)
	_init_capture()

func _init_capture() -> void:
	var idx := AudioServer.get_bus_index("Mic")
	if idx == -1:
		idx = AudioServer.bus_count
		AudioServer.add_bus(idx)
		AudioServer.set_bus_name(idx, "Mic")
		AudioServer.set_bus_mute(idx, true)   # don't echo our own mic locally
		AudioServer.add_bus_effect(idx, AudioEffectCapture.new())
		idx = AudioServer.get_bus_index("Mic")
	var eff := AudioServer.get_bus_effect(idx, 0)
	if eff is AudioEffectCapture:
		_capture = eff
	var mic := AudioStreamPlayer.new()
	mic.stream = AudioStreamMicrophone.new()
	mic.bus = "Mic"
	add_child(mic)
	mic.play()
	_enabled = true

func _process(_delta: float) -> void:
	if not _enabled or not Net.active or _capture == null:
		return
	var walkie := Input.is_action_pressed("walkie_talkie")
	var talking := Input.is_action_pressed("push_to_talk") or walkie
	if not talking:
		_capture.clear_buffer()
		return
	var frames := _capture.get_frames_available()
	if frames <= 0:
		return
	var bytes := _pack(_capture.get_buffer(frames))
	if bytes.size() == 0:
		return
	if Net.is_host:
		_voice_play.rpc(Net.local_id(), bytes, 1 if walkie else 0)
	else:
		_voice_relay.rpc_id(1, bytes, 1 if walkie else 0)

@rpc("any_peer", "unreliable")
func _voice_relay(bytes: PackedByteArray, channel: int) -> void:
	if not Net.is_host:
		return
	_voice_play.rpc(multiplayer.get_remote_sender_id(), bytes, channel)

@rpc("authority", "unreliable", "call_local")
func _voice_play(id: int, bytes: PackedByteArray, channel: int) -> void:
	if id == Net.local_id():
		return
	_speak(id, bytes, channel)

func _pack(buf: PackedVector2Array) -> PackedByteArray:
	# Downsample mix-rate -> ~16 kHz. Average each group of _step frames (a cheap
	# low-pass) instead of dropping samples — naive decimation aliases high
	# frequencies into harsh noise, which is what made the voice sound terrible.
	var count := buf.size() / _step
	var out := PackedByteArray()
	out.resize(count * 2)
	for j in count:
		var acc := 0.0
		var base := j * _step
		for k in _step:
			var f := buf[base + k]
			acc += (f.x + f.y) * 0.5
		acc /= float(_step)
		out.encode_s16(j * 2, int(clampf(acc, -1.0, 1.0) * 32767.0))
	return out

func _speak(id: int, bytes: PackedByteArray, channel: int) -> void:
	if not _players.has(id):
		_players[id] = _make_player(id, channel)
	var pb = _players[id]["pb"]
	if pb == null:
		return
	var samples := bytes.size() / 2
	for i in samples:
		if pb.can_push_buffer(1):
			var s := float(bytes.decode_s16(i * 2)) / 32767.0
			pb.push_frame(Vector2(s, s))

func _make_player(id: int, channel: int) -> Dictionary:
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = _rate
	gen.buffer_length = 0.3
	var player: Node
	if channel == 0 and _crew != null and _crew.avatars.has(id):
		var p3 := AudioStreamPlayer3D.new()
		p3.stream = gen
		p3.bus = "SFX"
		# Proximity: clearly full volume up close, fading to nothing by ~28 m.
		p3.unit_size = 3.0
		p3.max_distance = 28.0
		p3.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
		p3.volume_db = 3.0
		p3.position.y = 1.6               # emit from the head, not the feet
		_crew.avatars[id].add_child(p3)   # proximity: follows the speaker
		player = p3
	else:
		var p2 := AudioStreamPlayer.new()
		p2.stream = gen
		p2.bus = "SFX"
		add_child(p2)
		player = p2
	player.play()
	return {"player": player, "pb": player.get_stream_playback()}
