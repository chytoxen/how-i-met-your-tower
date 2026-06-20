extends Node3D
## Dev-only: shows a crew avatar so the character can be eyeballed via Screenshotter.

func _ready() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.12, 0.14, 0.18)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.52, 0.6)
	env.ambient_light_energy = 1.0
	we.environment = env
	add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, -45, 0)
	sun.light_energy = 1.3
	add_child(sun)

	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(12, 12)
	ground.mesh = pm
	add_child(ground)

	var av := RemoteAvatar.new()
	add_child(av)
	av.setup("MAVERICK", Color(0.85, 0.2, 0.2))
	av.rotation.y = PI    # turn the character toward the +Z camera
	av.set_process(false) # freeze movement-driven anim switching; idle keeps playing

	var cam := Camera3D.new()
	cam.position = Vector3(1.4, 1.5, 3.0)
	cam.look_at(Vector3(0, 1.0, 0), Vector3.UP)
	cam.current = true
	add_child(cam)
