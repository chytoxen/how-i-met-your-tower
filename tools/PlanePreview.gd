extends Node3D
## Dev-only: frames ExteriorRig._toy_plane() for a screenshot. CAM env picks angle.

func _ready() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.55, 0.68, 0.85)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.6, 0.65, 0.75)
	env.ambient_light_energy = 1.0
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	we.environment = env
	add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-42, -55, 0)
	sun.light_energy = 1.5
	add_child(sun)

	var plane := ExteriorRig._toy_plane()
	add_child(plane)

	var cam := Camera3D.new()
	cam.current = true
	add_child(cam)
	match OS.get_environment("CAM"):
		"front":
			cam.position = Vector3(7, 4, -20)
			cam.look_at(Vector3(0, 0, -2), Vector3.UP)
		"top":
			cam.position = Vector3(0.1, 26, 1)
			cam.look_at(Vector3(0, 0, 1), Vector3.UP)
		_:
			cam.position = Vector3(16, 7, -14)
			cam.look_at(Vector3(0, 0.5, 1), Vector3.UP)
