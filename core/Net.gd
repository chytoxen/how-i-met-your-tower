extends Node
## Multiplayer backbone (ENet). One player hosts (listen-server) on their machine,
## others join by IP — "anyone can host". Maintains the player roster, handles
## ready-up, and starts the match by broadcasting a seed so every client builds
## the identical procedural emergency. Autoloaded as "Net".

signal roster_changed
signal match_starting
signal connection_failed
signal server_left
signal connected

const DEFAULT_PORT := 24565
const MAX_PLAYERS := 4

var players := {}     # peer_id -> {callsign:String, color:Color, ready:bool}
var active := false
var is_host := false
var mode := "coop"    # "coop" | "saboteur"

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func host(port := DEFAULT_PORT) -> int:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(port, MAX_PLAYERS)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	is_host = true
	active = true
	players = {1: _self_info()}
	roster_changed.emit()
	return OK

func join(address := "127.0.0.1", port := DEFAULT_PORT) -> int:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(address, port)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	is_host = false
	active = true
	return OK

func leave() -> void:
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null
	players.clear()
	active = false
	is_host = false
	roster_changed.emit()

func local_id() -> int:
	if multiplayer.multiplayer_peer == null:
		return 1
	return multiplayer.get_unique_id()

func _self_info() -> Dictionary:
	return {"callsign": GameState.profile["callsign"], "color": GameState.profile["suit_color"],
		"character": GameState.profile.get("character", "r"), "ready": false}

# --- connection callbacks ----------------------------------------------------

func _on_peer_connected(_id: int) -> void:
	pass  # the joining client registers itself once it's connected

func _on_peer_disconnected(id: int) -> void:
	players.erase(id)
	if is_host:
		_push_roster.rpc(players)
	roster_changed.emit()

func _on_connected_to_server() -> void:
	_register.rpc_id(1, _self_info())
	connected.emit()

func _on_connection_failed() -> void:
	active = false
	connection_failed.emit()

func _on_server_disconnected() -> void:
	players.clear()
	active = false
	server_left.emit()

# --- roster sync (server authoritative) --------------------------------------

@rpc("any_peer", "reliable")
func _register(info: Dictionary) -> void:
	if not is_host:
		return
	var id := multiplayer.get_remote_sender_id()
	players[id] = info
	_push_roster.rpc(players)
	roster_changed.emit()

@rpc("authority", "reliable", "call_local")
func _push_roster(r: Dictionary) -> void:
	players = r
	roster_changed.emit()

func set_ready(v: bool) -> void:
	if is_host:
		if players.has(1):
			players[1]["ready"] = v
		_push_roster.rpc(players)
	else:
		_set_ready.rpc_id(1, v)

@rpc("any_peer", "reliable")
func _set_ready(v: bool) -> void:
	if not is_host:
		return
	var id := multiplayer.get_remote_sender_id()
	if players.has(id):
		players[id]["ready"] = v
	_push_roster.rpc(players)

func all_ready() -> bool:
	if players.is_empty():
		return false
	for id in players:
		if not players[id].get("ready", false):
			return false
	return true

func set_mode(m: String) -> void:
	if not is_host:
		return
	_sync_mode.rpc(m)

@rpc("authority", "reliable", "call_local")
func _sync_mode(m: String) -> void:
	mode = m
	roster_changed.emit()

# --- match start -------------------------------------------------------------

func start_match(difficulty := 2) -> void:
	if not is_host:
		return
	var sab_id := 0
	if mode == "saboteur" and players.size() >= 2:
		var ids := players.keys()
		sab_id = ids[randi() % ids.size()]
	_begin.rpc(randi(), difficulty, mode, sab_id)

@rpc("authority", "reliable", "call_local")
func _begin(seed_value: int, difficulty: int, match_mode: String, saboteur_id: int) -> void:
	GameState.pending_scenario = ScenarioGenerator.generate(seed_value, difficulty)
	GameState.match_mode = match_mode
	GameState.saboteur_id = saboteur_id
	GameState.is_saboteur = (saboteur_id == local_id())
	match_starting.emit()
	GameState.goto_scene("res://world/Aircraft.tscn")
