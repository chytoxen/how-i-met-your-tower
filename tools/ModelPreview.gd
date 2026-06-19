extends Node3D
## Dev-only: load a model (env MODEL=res://...) and frame it for a screenshot.

func _ready() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.15, 0.16, 0.2)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.52, 0.6)
	env.ambient_light_energy = 1.0
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, -50, 0)
	sun.light_energy = 1.4
	add_child(sun)
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(8, 8)
	ground.mesh = pm
	add_child(ground)
	var path := OS.get_environment("MODEL")
	if path != "" and ResourceLoader.exists(path):
		add_child((load(path) as PackedScene).instantiate())
	var cam := Camera3D.new()
	cam.current = true
	add_child(cam)
	cam.position = Vector3(1.6, 1.3, 2.2)
	cam.look_at(Vector3(0, 0.5, 0), Vector3.UP)
