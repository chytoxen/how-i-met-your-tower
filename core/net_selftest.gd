extends Node
## Headless 2-instance networking test (run as a scene so the Net autoload
## resolves). Each instance must end up seeing both players in the roster.
##   NET_ROLE=server godot --headless res://core/NetTest.tscn
##   NET_ROLE=client godot --headless res://core/NetTest.tscn

var role := "server"

func _ready() -> void:
	role = OS.get_environment("NET_ROLE")
	if role == "":
		role = "server"
	Net.roster_changed.connect(_on_roster)
	Net.connection_failed.connect(func() -> void:
		print(role, " CONNECTION FAILED")
		get_tree().quit(1))
	if role == "server":
		print("[server] host err=", Net.host(24599))
	else:
		print("[client] join err=", Net.join("127.0.0.1", 24599))
	get_tree().create_timer(12.0).timeout.connect(func() -> void:
		print("%s TIMEOUT roster=%d" % [role, Net.players.size()])
		get_tree().quit(2))

func _on_roster() -> void:
	print("[%s] roster=%d ids=%s" % [role, Net.players.size(), str(Net.players.keys())])
	if Net.players.size() >= 2:
		print("%s NET OK" % role)
		get_tree().quit(0)
