extends Node3D
func _ready() -> void:
	add_child(preload("res://world/Lobby.tscn").instantiate())
	await get_tree().create_timer(0.6).timeout
	var cam := Camera3D.new()
	add_child(cam)
	if OS.get_environment("FLOOR") != "":
		cam.global_position = Vector3(0, 0.5, 16)          # low, grazing down the floor
		cam.look_at(Vector3(0, 0.0, -18), Vector3.UP)
	else:
		cam.global_position = Vector3(2.0, 2.8, 6.0)
		cam.look_at(Vector3(-3, 0.6, -4), Vector3.UP)
	cam.current = true
