extends Node3D
## Dev-only: spawn one of each TaskStation type in a row + label, to verify each
## failure gets a distinct, well-scaled station model.

const TYPES := ["engine_fire", "gear_jam", "cabin_smoke", "hydraulics", "fuel_leak", "electrical", "decompression", "bird_strike"]

func _ready() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.5, 0.53, 0.58)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.58, 0.63)
	env.ambient_light_energy = 0.7
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-42, -35, 0)
	sun.light_energy = 1.5
	add_child(sun)
	var floor_mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(40, 12)
	floor_mi.mesh = pm
	floor_mi.material_override = Mats.flat(Color(0.4, 0.42, 0.46), 0.9, 0.0)
	add_child(floor_mi)

	for i in TYPES.size():
		var st := TaskStation.new()
		st.setup({"type": TYPES[i], "zone": "cabin", "severity": 2, "fuse": 0.0, "steps": ["a", "b"], "role": "engineer"})
		st.position = Vector3((i - 3.5) * 2.6, 0, 0)
		add_child(st)
		var lbl := Label3D.new()
		lbl.text = TYPES[i]
		lbl.font_size = 90
		lbl.pixel_size = 0.006
		lbl.position = Vector3((i - 3.5) * 2.6, 2.3, 0)
		lbl.modulate = Color(1, 0.9, 0.3)
		lbl.outline_size = 16
		lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		add_child(lbl)

	var cam := Camera3D.new()
	cam.position = Vector3(0, 2.4, 13.0)
	cam.look_at(Vector3(0, 0.9, 0), Vector3.UP)
	cam.current = true
	add_child(cam)
