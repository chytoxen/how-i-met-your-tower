extends Node
## Player profile (callsign + appearance), scene routing, and match handoff.
## Autoloaded as "GameState".

signal profile_changed

const PROFILE_PATH := "user://profile.cfg"

var profile := {
	"callsign": "Maverick",                 # gamertag shown to other players
	"suit_color": Color(0.85, 0.2, 0.2),    # crew jumpsuit primary
	"trim_color": Color(0.95, 0.85, 0.2),   # hi-vis trim
	"skin_tone": 2,                         # index into a palette (Phase 2)
	"hat": 0,                               # 0 none, 1 cap, 2 headset (Phase 2)
}

var session_seed := 0          # reshuffled each launch
var pending_scenario := {}     # host fills this before starting a match
var last_result := {}          # set by the match, read by the results screen
var match_mode := "coop"       # "coop" | "saboteur"
var is_saboteur := false        # is THIS player the secret saboteur this match?
var saboteur_id := 0            # peer id of the saboteur (0 = none)

func _ready() -> void:
	randomize()
	session_seed = randi()
	load_profile()

func goto_scene(path: String) -> void:
	get_tree().change_scene_to_file(path)

## Generate a fresh procedural emergency and drop into the aircraft (single
## player / host). Multiplayer host broadcasts the same seed (Phase 4).
func start_single_match(difficulty := 2) -> void:
	pending_scenario = ScenarioGenerator.generate(randi(), difficulty)
	match_mode = "coop"
	is_saboteur = false
	saboteur_id = 0
	goto_scene("res://world/Aircraft.tscn")

func set_callsign(value: String) -> void:
	var c := value.strip_edges()
	if c.length() > 16:
		c = c.substr(0, 16)
	if c == "":
		c = "Rookie"
	profile.callsign = c
	profile_changed.emit()
	save_profile()

func save_profile() -> void:
	var cfg := ConfigFile.new()
	for k in profile:
		cfg.set_value("profile", k, profile[k])
	cfg.save(PROFILE_PATH)

func load_profile() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PROFILE_PATH) != OK:
		return
	for k in profile.keys():
		profile[k] = cfg.get_value("profile", k, profile[k])
