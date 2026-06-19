extends Node3D
func _ready() -> void:
	add_child(preload("res://world/Lobby.tscn").instantiate())
	await get_tree().create_timer(0.6).timeout
	var cam := Camera3D.new()
	add_child(cam)
	match OS.get_environment("CAM"):
		"floor":
			cam.global_position = Vector3(0, 0.5, 16)
			cam.look_at(Vector3(0, 0.0, -18), Vector3.UP)
		"windows":   # eye level looking at the glass wall (god rays)
			cam.global_position = Vector3(-6, 1.7, -6)
			cam.look_at(Vector3(4, 3.5, 20), Vector3.UP)
		"concourse": # eye level looking at the DEPARTURES board
			cam.global_position = Vector3(0, 1.7, 9)
			cam.look_at(Vector3(0, 4.5, -19), Vector3.UP)
		_:
			cam.global_position = Vector3(2.0, 2.8, 6.0)
			cam.look_at(Vector3(-3, 0.6, -4), Vector3.UP)
	cam.current = true
