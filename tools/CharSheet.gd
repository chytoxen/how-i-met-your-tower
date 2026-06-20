extends Node3D
## Dev-only: lay out all 18 Kenney characters in a grid + label each, for picking
## "normal" vs "funny" variants. Renders via Screenshotter.

const CHARS := "abcdefghijklmnopqr"

func _ready() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.55, 0.58, 0.63)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.6, 0.62, 0.66)
	env.ambient_light_energy = 0.7
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, -30, 0)
	sun.light_energy = 1.5
	add_child(sun)

	# BATCH env: 0 = a..i, 1 = j..r (single straight-on row of 9)
	var batch := int(OS.get_environment("BATCH"))
	for n in 9:
		var i := batch * 9 + n
		var which := CHARS[i]
		var model: Node3D = (load("res://assets/models/kenney_chars/character-%s.glb" % which) as PackedScene).instantiate()
		model.position = Vector3(n * 1.5, 0, 0)
		add_child(model)   # face +Z = toward the camera
		var lbl := Label3D.new()
		lbl.text = which
		lbl.font_size = 200
		lbl.pixel_size = 0.005
		lbl.position = Vector3(n * 1.5, 2.5, 0.2)
		lbl.modulate = Color(1, 0.9, 0.2)
		lbl.outline_size = 30
		lbl.no_depth_test = true
		lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		add_child(lbl)

	var cam := Camera3D.new()
	cam.position = Vector3(6.0, 1.4, 11.5)   # straight-on, eye level
	cam.look_at(Vector3(6.0, 1.1, 0), Vector3.UP)
	cam.current = true
	add_child(cam)
