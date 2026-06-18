class_name CrewManager
extends Node3D
## Spawns the crew and replicates their movement. In single-player it just spawns
## the local Player. In multiplayer it spawns the local Player plus a RemoteAvatar
## per other peer, and syncs transforms over RPC (~20 Hz). Used by both the lobby
## and the aircraft so the spawn/replication logic lives in one place.
##
## Must be added with name "CrewManager" so the RPC node path matches on all peers.

signal local_spawned(player: Node3D)

var avatars := {}        # peer_id -> RemoteAvatar
var local_player: Node3D
var _spawn_points: Array = [Vector3.ZERO]
var _send_accum := 0.0

func build(points: Array) -> void:
	if points.size() > 0:
		_spawn_points = points
	if not Net.active:
		_spawn_local(_point(0))
		return
	Net.roster_changed.connect(_on_roster)
	var ids := Net.players.keys()
	ids.sort()
	for i in ids.size():
		var id: int = ids[i]
		if id == Net.local_id():
			_spawn_local(_point(i))
		else:
			_spawn_remote(id, _point(i))

	var voice := Voice.new()
	voice.name = "Voice"
	add_child(voice)
	voice.setup(self)

func _point(i: int) -> Vector3:
	return _spawn_points[i % _spawn_points.size()]

func _spawn_local(pos: Vector3) -> void:
	local_player = preload("res://player/Player.tscn").instantiate()
	local_player.position = pos
	add_child(local_player)
	local_spawned.emit(local_player)

func _spawn_remote(id: int, pos: Vector3) -> void:
	var av := RemoteAvatar.new()
	av.position = pos
	add_child(av)
	var info: Dictionary = Net.players.get(id, {})
	av.setup(info.get("callsign", "Crew"), info.get("color", Color.WHITE))
	avatars[id] = av

func _on_roster() -> void:
	# lobby late join / leave
	for id in Net.players.keys():
		if id != Net.local_id() and not avatars.has(id):
			_spawn_remote(id, _point(avatars.size() + 1))
	for id in avatars.keys():
		if not Net.players.has(id):
			avatars[id].queue_free()
			avatars.erase(id)

func _process(delta: float) -> void:
	if not Net.active or local_player == null:
		return
	_send_accum += delta
	if _send_accum >= 0.05:
		_send_accum = 0.0
		# Client RPCs only reach the server, so the host relays everyone's
		# transforms to all clients. Host broadcasts its own directly.
		if Net.is_host:
			_apply_xform.rpc(Net.local_id(), local_player.global_position, local_player.rotation.y)
		else:
			_report_xform.rpc_id(1, local_player.global_position, local_player.rotation.y)

@rpc("any_peer", "unreliable")
func _report_xform(pos: Vector3, yaw: float) -> void:
	if not Net.is_host:
		return
	_apply_xform.rpc(multiplayer.get_remote_sender_id(), pos, yaw)

@rpc("authority", "unreliable", "call_local")
func _apply_xform(id: int, pos: Vector3, yaw: float) -> void:
	if id == Net.local_id():
		return
	if avatars.has(id):
		avatars[id].set_target(pos, yaw)

func send_emote(text: String) -> void:
	if not Net.active:
		return
	if Net.is_host:
		_apply_emote.rpc(Net.local_id(), text)
	else:
		_report_emote.rpc_id(1, text)

@rpc("any_peer", "reliable")
func _report_emote(text: String) -> void:
	if not Net.is_host:
		return
	_apply_emote.rpc(multiplayer.get_remote_sender_id(), text)

@rpc("authority", "reliable", "call_local")
func _apply_emote(id: int, text: String) -> void:
	if id == Net.local_id():
		return
	if avatars.has(id):
		avatars[id].show_emote(text)
