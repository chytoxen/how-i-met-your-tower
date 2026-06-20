extends Node3D
## Dev-only: everything at its CURRENT in-game scale, lined up against a 1.8 m
## player-height reference pole, to audit for consistent/reasonable scale.

func _ready() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.55, 0.58, 0.62)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.58, 0.63)
	env.ambient_light_energy = 0.7
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, -30, 0)
	sun.light_energy = 1.5
	add_child(sun)
	var fl := MeshInstance3D.new()
	var pm := PlaneMesh.new(); pm.size = Vector2(30, 12)
	fl.mesh = pm
	fl.material_override = Mats.flat(Color(0.42, 0.45, 0.49), 0.9, 0.0)
	add_child(fl)

	# 1.8 m reference pole (player height) with a 1.0 m band
	_pole(Vector3(0, 0, 0))

	var x := 1.6
	_label("player\n(0.66)", x)
	_char("character-r", x, 0.66)
	x += 1.6
	_label("passenger\n(0.66)", x)
	_char("character-a", x, 0.66)
	x += 2.0
	_label("sofa 1.9", x)
	_furn("kenney_furniture/loungeSofa", x, 1.9)
	x += 1.8
	_label("chair 1.9", x)
	_furn("kenney_furniture/loungeChair", x, 1.9)
	x += 1.6
	_label("lamp 2.0", x)
	_furn("kenney_furniture/lampSquareFloor", x, 2.0)
	x += 2.2
	_label("station", x)
	var st := TaskStation.new()
	st.setup({"type": "hydraulics", "zone": "cabin", "severity": 2, "fuse": 0.0, "steps": ["a"], "role": "pilot"})
	st.position = Vector3(x, 0, 0)
	add_child(st)

	var cam := Camera3D.new()
	cam.position = Vector3(5.2, 1.7, 9.5)
	cam.look_at(Vector3(5.2, 1.0, 0), Vector3.UP)
	cam.fov = 55
	cam.current = true
	add_child(cam)

func _pole(p: Vector3) -> void:
	var pole := MeshInstance3D.new()
	var bm := BoxMesh.new(); bm.size = Vector3(0.12, 1.8, 0.12)
	pole.mesh = bm
	pole.material_override = Mats.flat(Color(0.9, 0.3, 0.2), 0.6, 0.0)
	pole.position = p + Vector3(0, 0.9, 0)
	add_child(pole)
	var band := MeshInstance3D.new()
	var bb := BoxMesh.new(); bb.size = Vector3(0.16, 0.04, 0.16)
	band.mesh = bb
	band.material_override = Mats.flat(Color(1, 1, 1), 0.6, 0.0)
	band.position = p + Vector3(0, 1.0, 0)
	add_child(band)
	_label("1.8m", p.x - 0.6)

func _label(t: String, x: float) -> void:
	var l := Label3D.new()
	l.text = t
	l.font_size = 60
	l.pixel_size = 0.004
	l.position = Vector3(x, 2.4, 0)
	l.modulate = Color(1, 0.9, 0.3)
	l.outline_size = 12
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(l)

func _char(id: String, x: float, scl: float) -> void:
	var m := Characters.make(id.replace("character-", ""), "idle")
	m.scale = Vector3(scl, scl, scl)
	m.position = Vector3(x, 0, 0)
	add_child(m)

func _furn(path: String, x: float, scl: float) -> void:
	var m: Node3D = (load("res://assets/models/%s.glb" % path) as PackedScene).instantiate()
	m.scale = Vector3(scl, scl, scl)
	m.position = Vector3(x, 0, 0)
	add_child(m)
