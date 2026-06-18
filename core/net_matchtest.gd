extends Node
## Headless 2-instance MATCH test: host + client connect, host starts the match,
## both load the aircraft and the host broadcasts flight state to the client.
## We just watch both process logs for script/RPC errors during a live match.
##   NET_ROLE=server godot --headless res://core/NetMatchTest.tscn
##   NET_ROLE=client godot --headless res://core/NetMatchTest.tscn

var role := "server"
var _started := false

func _ready() -> void:
	role = OS.get_environment("NET_ROLE")
	if role == "":
		role = "server"
	print("[%s] start" % role)
	if role == "server":
		Net.host(24600)
		Net.roster_changed.connect(_check)
	else:
		Net.join("127.0.0.1", 24600)

func _check() -> void:
	if Net.players.size() >= 2 and not _started:
		_started = true
		print("[server] both joined -> starting match")
		get_tree().create_timer(1.0).timeout.connect(func() -> void: Net.start_match(2))
