extends Node3D
## Dev-only: mimics the first-person view of your own body — character at human
## scale, head hidden, camera at eye height (1.65) looking down, to verify the FP
## body reads right.

func _ready() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.35, 0.38, 0.42)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.6, 0.62, 0.66)
	env.ambient_light_energy = 0.8
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 20, 0)
	sun.light_energy = 1.4
	add_child(sun)
	var fl := MeshInstance3D.new()
	var pm := PlaneMesh.new(); pm.size = Vector2(8, 8)
	fl.mesh = pm
	fl.material_override = Mats.flat(Color(0.3, 0.33, 0.38), 0.9, 0.0)
	add_child(fl)

	var body := Characters.make(OS.get_environment("CHAR") if OS.get_environment("CHAR") != "" else "r", "idle")
	body.rotation.y = PI
	var s := Characters.HUMAN_SCALE
	body.scale = Vector3(s, s, s)
	Characters.hide_head(body)
	add_child(body)

	# camera where the player's eyes are, looking FORWARD (-Z) and down at your feet
	var cam := Camera3D.new()
	cam.position = Vector3(0, 1.65, 0.22)
	cam.rotation_degrees = Vector3(float(OS.get_environment("PITCH")) if OS.get_environment("PITCH") != "" else -55.0, 0, 0)
	cam.fov = 85
	cam.current = true
	add_child(cam)
