extends Node
## Global settings: audio, video, controls. Persists to user://settings.cfg.
## Autoloaded as "Settings" (first autoload, so input actions exist before any
## scene needs them). Headless-safe: guards DisplayServer calls.

const SETTINGS_PATH := "user://settings.cfg"

const BUSES := ["Master", "Music", "SFX"]

## Default key bindings. Stored as PHYSICAL keycodes so they map by position and
## work on non-QWERTY layouts. Re-bindable from the Controls tab at runtime.
const DEFAULT_BINDS := {
	"move_forward": KEY_W,
	"move_back": KEY_S,
	"move_left": KEY_A,
	"move_right": KEY_D,
	"jump": KEY_SPACE,
	"sprint": KEY_SHIFT,
	"crouch": KEY_CTRL,
	"interact": KEY_E,
	"emote": KEY_C,
	"push_to_talk": KEY_V,    # proximity voice (Phase 5)
	"walkie_talkie": KEY_B,   # cross-crew radio (Phase 5)
	"pause": KEY_ESCAPE,
}

var audio_volumes := {"Master": 1.0, "Music": 0.8, "SFX": 1.0}
var video := {
	"fullscreen": false,
	"vsync": true,
	"msaa": 2,            # 0=off 1=2x 2=4x 3=8x
	"render_scale": 1.0,  # 0.5..1.0 ; below 1.0 enables FSR2 upscaling
	"shadow_quality": 2,  # 0=off 1=low 2=medium 3=high
}
var binds := {}          # action -> physical keycode
## Voice chat: "ptt" (hold the talk key) or "open" (open mic, voice-activated).
## sensitivity = RMS gate for open mic (lower = picks up quieter speech).
var voice := {"mode": "ptt", "sensitivity": 0.04}

func _ready() -> void:
	_ensure_buses()
	binds = DEFAULT_BINDS.duplicate()
	load_settings()
	apply_all()

func _ensure_buses() -> void:
	for bus_name in BUSES:
		if AudioServer.get_bus_index(bus_name) == -1:
			var idx := AudioServer.bus_count
			AudioServer.add_bus(idx)
			AudioServer.set_bus_name(idx, bus_name)
			AudioServer.set_bus_send(idx, "Master")

# --- apply -------------------------------------------------------------------

func apply_all() -> void:
	apply_audio()
	apply_video()
	apply_binds()

func apply_audio() -> void:
	for bus_name in audio_volumes:
		var idx := AudioServer.get_bus_index(bus_name)
		if idx != -1:
			var v: float = clampf(audio_volumes[bus_name], 0.0, 1.0)
			AudioServer.set_bus_volume_db(idx, linear_to_db(v) if v > 0.0 else -80.0)

func apply_video() -> void:
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_FULLSCREEN if video.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_vsync_mode(
			DisplayServer.VSYNC_ENABLED if video.vsync else DisplayServer.VSYNC_DISABLED)
	var vp := get_viewport()
	if vp:
		vp.scaling_3d_scale = clampf(video.render_scale, 0.5, 1.0)
		vp.scaling_3d_mode = (Viewport.SCALING_3D_MODE_FSR2 if video.render_scale < 0.999
			else Viewport.SCALING_3D_MODE_BILINEAR)
		vp.msaa_3d = video.msaa

func apply_binds() -> void:
	for action in DEFAULT_BINDS.keys():
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		InputMap.action_erase_events(action)
		var ev := InputEventKey.new()
		ev.physical_keycode = binds.get(action, DEFAULT_BINDS[action])
		InputMap.action_add_event(action, ev)

# --- mutators (used by the Settings menu) ------------------------------------

func set_volume(bus_name: String, v: float) -> void:
	audio_volumes[bus_name] = clampf(v, 0.0, 1.0)
	apply_audio()
	save_settings()

func set_video(key: String, value) -> void:
	video[key] = value
	apply_video()
	save_settings()

func set_bind(action: String, keycode: int) -> void:
	binds[action] = keycode
	apply_binds()
	save_settings()

func set_voice(key: String, value) -> void:
	voice[key] = value
	save_settings()

# --- persistence -------------------------------------------------------------

func save_settings() -> void:
	var cfg := ConfigFile.new()
	for k in audio_volumes:
		cfg.set_value("audio", k, audio_volumes[k])
	for k in video:
		cfg.set_value("video", k, video[k])
	for a in binds:
		cfg.set_value("binds", a, binds[a])
	for k in voice:
		cfg.set_value("voice", k, voice[k])
	cfg.save(SETTINGS_PATH)

func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	for k in audio_volumes.keys():
		audio_volumes[k] = cfg.get_value("audio", k, audio_volumes[k])
	for k in video.keys():
		video[k] = cfg.get_value("video", k, video[k])
	for a in DEFAULT_BINDS.keys():
		binds[a] = cfg.get_value("binds", a, DEFAULT_BINDS[a])
	for k in voice.keys():
		voice[k] = cfg.get_value("voice", k, voice[k])
