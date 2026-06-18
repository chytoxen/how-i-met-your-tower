extends Node3D
## The hub: a greybox airport terminal you spawn into and walk around. Real
## models replace the boxes in Phase 2; for now it proves movement, lighting,
## shadows, the environment, and the photo-banner easter egg all work together.
## Outside the glass stands the control TOWER — the thing the whole game is
## about reaching.

func _ready() -> void:
	_build_environment()
	_build_terminal()
	_build_parkour()
	_build_tower_outside()
	_spawn_crew()
	_build_hud()
	var banners := BannerManager.new()
	add_child(banners)
	banners.populate(self, _banner_anchors())
	if Net.active:
		add_child(preload("res://ui/NetLobbyPanel.gd").new())
	else:
		_spawn_departures()
	if DisplayServer.get_name() != "headless":
		Audio.start_music("menu")

func _spawn_crew() -> void:
	var crew := CrewManager.new()
	crew.name = "CrewManager"
	add_child(crew)
	crew.build([Vector3(0, 0.2, 8), Vector3(-2, 0.2, 9), Vector3(2, 0.2, 9), Vector3(0, 0.2, 11)])

func _spawn_departures() -> void:
	var desk := DepartureDesk.new()
	desk.position = Vector3(0, 0, 2.0)
	add_child(desk)

func _build_parkour() -> void:
	# stacked crates near spawn
	_box(Vector3(1.2, 1.2, 1.2), Vector3(-8, 0.6, 6), Color(0.5, 0.4, 0.25))
	_box(Vector3(1.2, 1.2, 1.2), Vector3(-8, 1.8, 6), Color(0.5, 0.4, 0.25))
	_box(Vector3(1.2, 1.2, 1.2), Vector3(-9.2, 0.6, 6), Color(0.5, 0.4, 0.25))
	# ramp up to a mezzanine ledge on the right wall
	var ramp := _box(Vector3(3.0, 0.4, 6.0), Vector3(12, 1.2, 2), Color(0.4, 0.42, 0.46))
	ramp.rotation_degrees = Vector3(-18, 0, 0)
	_box(Vector3(6.0, 0.4, 10.0), Vector3(16.5, 2.6, -3), Color(0.45, 0.47, 0.5))
	# floating gap-jump platforms back toward the center
	_box(Vector3(1.8, 0.3, 1.8), Vector3(11, 2.2, -1), Color(0.3, 0.5, 0.6))
	_box(Vector3(1.8, 0.3, 1.8), Vector3(7, 2.6, 1), Color(0.3, 0.5, 0.6))
	_box(Vector3(1.8, 0.3, 1.8), Vector3(3, 3.0, 3), Color(0.3, 0.5, 0.6))

# --- environment & lighting --------------------------------------------------

func _build_environment() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_horizon_color = Color(0.55, 0.6, 0.7)
	sky_mat.ground_horizon_color = Color(0.3, 0.32, 0.36)
	sky.sky_material = sky_mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.4
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.ssao_enabled = true
	env.glow_enabled = true
	we.environment = env
	add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -125, 0)
	sun.light_energy = 1.2
	sun.shadow_enabled = Settings.video["shadow_quality"] > 0
	add_child(sun)

# --- terminal geometry -------------------------------------------------------

func _build_terminal() -> void:
	# Shell — real CC0 textures
	_textured(_box(Vector3(40, 0.5, 40), Vector3(0, -0.25, 0), Color.WHITE), Mats.textured("floor", 9.0))
	_textured(_box(Vector3(40, 0.4, 40), Vector3(0, 8.0, 0), Color.WHITE), Mats.flat(Color(0.10, 0.11, 0.14), 0.9))
	var wall_mat := Mats.textured("wall", 5.0, 0.0, Color(0.82, 0.84, 0.88))
	_textured(_box(Vector3(40, 8, 0.5), Vector3(0, 4, -20), Color.WHITE), wall_mat)
	_textured(_box(Vector3(0.5, 8, 40), Vector3(-20, 4, 0), Color.WHITE), wall_mat)
	_textured(_box(Vector3(0.5, 8, 40), Vector3(20, 4, 0), Color.WHITE), wall_mat)

	# Front glass facade (toward the apron/tower)
	var glass := _box(Vector3(40, 8, 0.3), Vector3(0, 4, 20), Color.WHITE)
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = Color(0.4, 0.6, 0.8, 0.14)
	gmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gmat.metallic = 0.6
	gmat.roughness = 0.05
	(glass.get_child(0) as MeshInstance3D).material_override = gmat

	# Pillars — brushed metal
	var pillar_mat := Mats.textured("metal", 2.0, 0.85, Color(0.58, 0.6, 0.66))
	for x in [-12, -4, 4, 12]:
		for z in [-12, 0, 12]:
			_textured(_box(Vector3(1, 8, 1), Vector3(x, 4, z), Color.WHITE), pillar_mat)

	# Gate-area carpet
	_textured(_box(Vector3(38, 0.06, 16), Vector3(0, 0.04, -4), Color.WHITE), Mats.textured("carpet", 6.0, 0.0, Color(0.55, 0.32, 0.36)))

	# Seating clusters
	var seat_mat := Mats.flat(Color(0.16, 0.2, 0.34), 0.5)
	for cx in [-10, 2, 12]:
		for row in range(3):
			_textured(_box(Vector3(4, 0.5, 0.8), Vector3(cx, 0.5, -6 + row * 2.0), Color.WHITE), seat_mat)
			_textured(_box(Vector3(4, 0.8, 0.2), Vector3(cx, 1.0, -6 + row * 2.0 - 0.4), Color.WHITE), seat_mat)

	# Check-in / gate desks — metal
	var desk_mat := Mats.textured("metal", 1.5, 0.7, Color(0.5, 0.52, 0.58))
	for dx in [-14, -7, 0, 7, 14]:
		_textured(_box(Vector3(3, 1.1, 1.2), Vector3(dx, 0.55, -17), Color.WHITE), desk_mat)

	# Flyable-plane pads
	for px in [-16, 16]:
		_textured(_box(Vector3(2, 0.1, 2), Vector3(px, 0.05, 16), Color.WHITE), Mats.flat(Color(0.9, 0.75, 0.1), 0.4))

	# Warm interior ceiling lights + glowing fixtures (the missing piece — was flat)
	for x in [-12, 0, 12]:
		for z in [-12, 0, 12]:
			var lamp := OmniLight3D.new()
			lamp.position = Vector3(x, 7.0, z)
			lamp.light_color = Color(1.0, 0.95, 0.86)
			lamp.light_energy = 2.0
			lamp.omni_range = 15.0
			add_child(lamp)
			var fix := _box(Vector3(2.4, 0.15, 2.4), Vector3(x, 7.75, z), Color.WHITE)
			var em := StandardMaterial3D.new()
			em.albedo_color = Color(1, 0.97, 0.9)
			em.emission_enabled = true
			em.emission = Color(1, 0.95, 0.85)
			em.emission_energy_multiplier = 2.5
			(fix.get_child(0) as MeshInstance3D).material_override = em

func _textured(body: StaticBody3D, mat: Material) -> StaticBody3D:
	(body.get_child(0) as MeshInstance3D).material_override = mat
	return body

func _build_tower_outside() -> void:
	# Ground apron beyond the glass
	_box(Vector3(120, 0.4, 80), Vector3(0, -0.2, 70), Color(0.22, 0.23, 0.25))
	# The control tower silhouette in the distance
	_box(Vector3(4, 26, 4), Vector3(28, 13, 80), Color(0.55, 0.57, 0.6))      # shaft
	_box(Vector3(8, 4, 8), Vector3(28, 27, 80), Color(0.3, 0.45, 0.6))        # cab (glass)
	var beacon := OmniLight3D.new()
	beacon.position = Vector3(28, 30, 80)
	beacon.light_color = Color(1.0, 0.4, 0.3)
	beacon.light_energy = 4.0
	beacon.omni_range = 40.0
	add_child(beacon)

func _box(size: Vector3, pos: Vector3, color: Color) -> StaticBody3D:
	var body := StaticBody3D.new()
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	mi.material_override = m
	body.add_child(mi)
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	body.add_child(cs)
	body.position = pos
	add_child(body)
	return body

# --- banner anchors (where the squad photos hang) ----------------------------

func _banner_anchors() -> Array:
	var a := []
	# back wall, facing +Z (into the room)
	for x in [-14, -7, 0, 7, 14]:
		a.append(Transform3D(Basis(), Vector3(x, 4.2, -19.6)))
	# left wall, facing +X
	var ry := Basis(Vector3.UP, deg_to_rad(90))
	for z in [-10, -2, 6]:
		a.append(Transform3D(ry, Vector3(-19.6, 4.2, z)))
	# right wall, facing -X
	var ryn := Basis(Vector3.UP, deg_to_rad(-90))
	for z in [-10, -2, 6]:
		a.append(Transform3D(ryn, Vector3(19.6, 4.2, z)))
	return a

# --- player + hud ------------------------------------------------------------

func _spawn_player_legacy() -> void:
	pass

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	var hint := Label.new()
	hint.text = "WASD move · Shift sprint · Space jump · Mouse look · [E] interact · Board the glowing DEPARTURES desk to fly · ESC cursor · F1 menu"
	hint.position = Vector2(16, 16)
	hint.modulate = Color(1, 1, 1, 0.7)
	layer.add_child(hint)
	add_child(layer)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F1:
		if Net.active:
			Net.leave()
		get_tree().paused = false
		GameState.goto_scene("res://ui/MainMenu.tscn")
