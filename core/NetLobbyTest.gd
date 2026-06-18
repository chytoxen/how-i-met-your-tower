extends Node
## Headless 2-instance LOBBY test: host + client both enter the networked lobby.
## Verifies the client spawns its OWN player (the black-screen bug regression).
## Run with CREW_DEBUG=1 so CrewManager prints when it spawns the local player.
##   NET_ROLE=server CREW_DEBUG=1 godot --headless res://core/NetLobbyTest.tscn
##   NET_ROLE=client CREW_DEBUG=1 godot --headless res://core/NetLobbyTest.tscn

func _ready() -> void:
	var role := OS.get_environment("NET_ROLE")
	if role == "":
		role = "server"
	if role == "server":
		Net.host(24601)
		get_tree().create_timer(0.6).timeout.connect(func() -> void:
			GameState.goto_scene("res://world/Lobby.tscn"))
	else:
		Net.connected.connect(func() -> void:
			GameState.goto_scene("res://world/Lobby.tscn"))
		Net.join("127.0.0.1", 24601)
