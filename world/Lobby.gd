extends Node3D
## The hub: a greybox airport terminal you spawn into and walk around. Real
## models replace the boxes in Phase 2; for now it proves movement, lighting,
## shadows, the environment, and the photo-banner easter egg all work together.
## Outside the glass stands the control TOWER — the thing the whole game is
## about reaching.

const ARMCHAIR := preload("res://assets/models/armchair/ArmChair_01_1k.gltf")
const PLANT := preload("res://assets/models/plant/potted_plant_04_1k.gltf")
const SUITCASE := preload("res://assets/models/suitcase/vintage_suitcase_1k.gltf")
const TRASHCAN := preload("res://assets/models/trashcan/metal_trash_can_1k.gltf")
const WETSIGN := preload("res://assets/models/wetsign/WetFloorSign_01_1k.gltf")
const EXTINGUISHER := preload("res://assets/models/extinguisher/korean_fire_extinguisher_01_1k.gltf")

# --- cohesive stylized palette (MUTED — see ART_DIRECTION.md; accents are not neon) ---
const C_FLOOR := Color(0.60, 0.60, 0.61)
const C_WALL := Color(0.84, 0.83, 0.80)   # warm off-white
const C_DARK := Color(0.13, 0.14, 0.16)
const C_TEAL := Color(0.30, 0.45, 0.46)   # muted teal-grey, used MATTE
const C_AMBER := Color(0.74, 0.56, 0.32)  # muted ochre
const C_METAL := Color(0.64, 0.65, 0.68)
const C_WOOD := Color(0.46, 0.34, 0.24)

func _ready() -> void:
	_build_environment()
	_build_terminal()
	_build_signage()
	_build_detail()
	_build_atmosphere()
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
	# In a networked lobby the cursor starts FREE so the CREW panel (READY UP /
	# START FLIGHT) is clickable; ESC toggles free/locked for walking around.
	crew.build([Vector3(0, 0.2, 8), Vector3(-2, 0.2, 9), Vector3(2, 0.2, 9), Vector3(0, 0.2, 11)], Net.active)

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
	sky_mat.sky_top_color = Color(0.30, 0.52, 0.85)
	sky_mat.sky_horizon_color = Color(0.72, 0.80, 0.88)
	sky_mat.ground_horizon_color = Color(0.42, 0.45, 0.50)
	sky.sky_material = sky_mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.38              # gentle cool fill (don't wash out the warm key)
	env.ambient_light_color = Color(0.66, 0.69, 0.76)
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.05
	env.tonemap_white = 6.0
	env.ssao_enabled = true
	env.ssao_radius = 1.6
	env.ssao_intensity = 2.6
	env.ssil_enabled = true
	env.ssr_enabled = true
	env.ssr_max_steps = 48
	# Subtle bloom — only genuinely bright lights bloom, not every surface (anti-neon).
	env.glow_enabled = true
	env.glow_intensity = 0.22
	env.glow_bloom = 0.08
	env.glow_hdr_threshold = 1.4
	# Light haze for soft god-rays + atmospheric depth (restrained, not milky).
	env.volumetric_fog_enabled = true
	env.volumetric_fog_density = 0.010
	env.volumetric_fog_albedo = Color(0.80, 0.84, 0.92)
	env.volumetric_fog_length = 90.0
	env.volumetric_fog_gi_inject = 0.5
	# Grade: DESATURATE slightly, natural contrast (the old +sat/+contrast read garish).
	env.adjustment_enabled = true
	env.adjustment_brightness = 1.0
	env.adjustment_contrast = 1.0
	env.adjustment_saturation = 0.98
	we.environment = env
	add_child(we)

	# Warm key sun raking in through the front glass wall (motivated light).
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-34, 152, 0)
	sun.light_energy = 2.1
	sun.light_color = Color(1.0, 0.94, 0.82)
	sun.light_angular_distance = 1.2   # soft, natural shadow edges
	sun.light_volumetric_fog_energy = 1.4
	sun.shadow_enabled = Settings.video["shadow_quality"] > 0
	add_child(sun)

# --- terminal geometry -------------------------------------------------------

func _build_terminal() -> void:
	# Polished stylized floor (low roughness -> SSR reflections = modern sheen)
	_mat_box(Vector3(40, 0.5, 40), Vector3(0, -0.25, 0), Mats.flat(C_FLOOR, 0.28, 0.0))
	# Clean warm matte walls
	var wall := Mats.flat(C_WALL, 0.95, 0.0)
	_mat_box(Vector3(40, 9, 0.5), Vector3(0, 4.5, -20), wall)
	_mat_box(Vector3(0.5, 9, 40), Vector3(-20, 4.5, 0), wall)
	_mat_box(Vector3(0.5, 9, 40), Vector3(20, 4.5, 0), wall)
	# Teal accent band running along the solid walls
	var accent := Mats.flat(C_TEAL, 0.5, 0.1)
	_trim(Vector3(40, 0.5, 0.12), Vector3(0, 6.2, -19.72), accent)
	_trim(Vector3(0.12, 0.5, 40), Vector3(-19.72, 6.2, 0), accent)
	_trim(Vector3(0.12, 0.5, 40), Vector3(19.72, 6.2, 0), accent)

	_build_ceiling()

	# Front glass curtain wall toward the apron/tower
	_mat_box(Vector3(40, 9, 0.3), Vector3(0, 4.5, 20), Mats.glass())

	# Columns with capitals/bases + a teal accent light strip
	for x in [-12, -4, 4, 12]:
		for z in [-12, 0, 12]:
			_column(Vector3(x, 0, z))

	# Gate-area carpet — cohesive teal-grey
	_mat_box(Vector3(38, 0.06, 16), Vector3(0, 0.04, -4), Mats.textured("carpet", 6.0, 0.0, Color(0.28, 0.40, 0.44)))

	# Lounge seating — armchairs in facing pairs
	for cx in [-15, -8, -1, 7, 13]:
		for i in range(2):
			_spawn_prop(ARMCHAIR, Vector3(cx + i * 1.25, 0, -6.5), 0.0)
			_spawn_prop(ARMCHAIR, Vector3(cx + i * 1.25, 0, -2.5), 180.0)

	# Greenery
	for pl in [Vector3(-18, 0, -10), Vector3(18, 0, -10), Vector3(-18, 0, 6), Vector3(18, 0, 6), Vector3(0, 0, -18)]:
		_spawn_prop(PLANT, pl, randf() * 360.0, Vector3(0.5, 1.2, 0.5))

	# Check-in desks — dark base, warm counter top, glowing monitor
	var base_mat := Mats.flat(C_DARK, 0.5, 0.2)
	var top_mat := Mats.flat(C_WOOD, 0.6, 0.0)
	for dx in [-14, -7, 0, 7, 14]:
		_mat_box(Vector3(3, 1.0, 1.2), Vector3(dx, 0.5, -17), base_mat)
		_trim(Vector3(3.2, 0.12, 1.4), Vector3(dx, 1.06, -17), top_mat)
		_trim(Vector3(0.9, 0.55, 0.06), Vector3(dx, 1.55, -16.6), Mats.emissive(Color(0.42, 0.55, 0.66), 0.7))

	# Flyable-plane pads — matte painted floor marker
	for px in [-16, 16]:
		_mat_box(Vector3(2, 0.1, 2), Vector3(px, 0.05, 16), Mats.flat(C_AMBER, 0.7, 0.0))

func _build_ceiling() -> void:
	# Dark coffered ceiling with recessed warm light strips between the beams.
	_mat_box(Vector3(40, 0.4, 40), Vector3(0, 9.0, 0), Mats.flat(Color(0.13, 0.14, 0.17), 0.8))
	var beam := Mats.flat(C_DARK, 0.6, 0.2)
	for x in [-16, -8, 0, 8, 16]:
		_trim(Vector3(0.5, 0.6, 40), Vector3(x, 8.6, 0), beam)      # beams along Z
	for z in [-16, -8, 0, 8, 16]:
		_trim(Vector3(40, 0.6, 0.5), Vector3(0, 8.6, z), beam)      # beams along X
	# recessed linear light strips (real fixtures: gentle emission) + WARM key fill lights
	# (warm pools vs the cool sky fill = the warm/cool contrast that makes it feel alive)
	var strip := Mats.emissive(Color(1.0, 0.95, 0.88), 1.4)
	for x in [-12, -4, 4, 12]:
		_trim(Vector3(1.2, 0.08, 34), Vector3(x, 8.55, 0), strip)
		for lz in [-11, 0, 11]:
			var lamp := OmniLight3D.new()
			lamp.position = Vector3(x, 8.2, lz)
			lamp.light_color = Color(1.0, 0.90, 0.78)
			lamp.light_energy = 3.0
			lamp.omni_range = 20.0
			add_child(lamp)

func _column(base: Vector3) -> void:
	# matte clean column (no glow — lit by the environment)
	_mat_box(Vector3(1.0, 8.4, 1.0), base + Vector3(0, 4.2, 0), Mats.flat(C_METAL, 0.55, 0.0))
	var cap := Mats.flat(C_DARK, 0.6, 0.0)
	_trim(Vector3(1.5, 0.45, 1.5), base + Vector3(0, 8.2, 0), cap)
	_trim(Vector3(1.5, 0.45, 1.5), base + Vector3(0, 0.22, 0), cap)
	# a single MATTE painted accent line (no emission)
	_trim(Vector3(0.16, 6.3, 0.16), base + Vector3(0, 4.0, -0.52), Mats.flat(C_TEAL, 0.6, 0.0))

# --- props + architectural trim (fills the box-room, breaks up flat surfaces) ---

func _build_detail() -> void:
	# real CC0 props (each gltf packs a believable pair)
	_spawn_prop(SUITCASE, Vector3(-7.6, 0, -3.6), 20.0, Vector3(1.3, 0.5, 0.6))
	_spawn_prop(SUITCASE, Vector3(6.4, 0, -3.4), -35.0, Vector3(1.3, 0.5, 0.6))
	_spawn_prop(SUITCASE, Vector3(13.4, 0, -5.8), 110.0, Vector3(1.3, 0.5, 0.6))
	_spawn_prop(TRASHCAN, Vector3(-11.2, 0, -10.9), 0.0, Vector3(1.3, 0.9, 0.7))
	_spawn_prop(TRASHCAN, Vector3(11.4, 0, 10.8), 25.0, Vector3(1.3, 0.9, 0.7))
	_spawn_prop(WETSIGN, Vector3(-2.2, 0, 4.5), 25.0, Vector3(0.6, 0.9, 0.6))
	_spawn_prop(WETSIGN, Vector3(9.0, 0, -8.5), -10.0, Vector3(0.6, 0.9, 0.6))
	# free-standing fire extinguishers against the walls
	for e in [[Vector3(-19.4, 0, -6.0), 90.0], [Vector3(19.4, 0, 2.0), -90.0], [Vector3(-8.0, 0, -19.4), 0.0]]:
		var n := EXTINGUISHER.instantiate()
		n.position = e[0]
		n.rotation_degrees = Vector3(0, e[1], 0)
		add_child(n)

	# baseboards along the 3 solid walls (columns get caps/bases in _column)
	var trim := Mats.flat(C_DARK, 0.6, 0.2)
	_trim(Vector3(40, 0.35, 0.18), Vector3(0, 0.18, -19.7), trim)
	_trim(Vector3(0.18, 0.35, 40), Vector3(-19.7, 0.18, 0), trim)
	_trim(Vector3(0.18, 0.35, 40), Vector3(19.7, 0.18, 0), trim)
	# window mullions + transom rails on the front glass facade (z=20, 9 tall)
	var frame := Mats.flat(C_DARK, 0.4, 0.5)
	for mx in range(-18, 19, 3):
		_trim(Vector3(0.22, 9, 0.45), Vector3(mx, 4.5, 20), frame)
	_trim(Vector3(40, 0.4, 0.5), Vector3(0, 0.3, 20), frame)
	_trim(Vector3(40, 0.4, 0.5), Vector3(0, 4.6, 20), frame)
	_trim(Vector3(40, 0.4, 0.5), Vector3(0, 8.7, 20), frame)

func _trim(size: Vector3, pos: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	add_child(mi)

func _textured(body: StaticBody3D, mat: Material) -> StaticBody3D:
	(body.get_child(0) as MeshInstance3D).material_override = mat
	return body

func _spawn_prop(scene: PackedScene, pos: Vector3, yaw_deg: float, col := Vector3(0.85, 0.9, 0.85)) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	body.rotation_degrees = Vector3(0, yaw_deg, 0)
	body.add_child(scene.instantiate())
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = col
	cs.shape = shape
	cs.position.y = col.y * 0.5
	body.add_child(cs)
	add_child(body)

func _build_tower_outside() -> void:
	# Apron beyond the glass + taxiway markings
	_mat_box(Vector3(120, 0.4, 80), Vector3(0, -0.2, 70), Mats.flat(Color(0.20, 0.21, 0.24), 0.95))
	for tx in range(-3, 4):
		_trim(Vector3(0.4, 0.02, 30), Vector3(tx * 6.0, 0.02, 45), Mats.flat(C_AMBER, 0.8))
	# The control tower in the distance — shaft + glass cab + a sweeping beacon
	_mat_box(Vector3(4.5, 28, 4.5), Vector3(28, 14, 80), Mats.flat(C_WALL, 0.7, 0.1))
	_mat_box(Vector3(9, 4.5, 9), Vector3(28, 29, 80), Mats.glass(Color(0.3, 0.45, 0.62, 0.2)))
	_trim(Vector3(9.6, 0.5, 9.6), Vector3(28, 31.4, 80), Mats.flat(C_DARK, 0.4, 0.3))
	var beacon := OmniLight3D.new()
	beacon.position = Vector3(28, 32, 80)
	beacon.light_color = Color(1.0, 0.4, 0.3)
	beacon.light_energy = 5.0
	beacon.omni_range = 45.0
	add_child(beacon)

func _mat_box(size: Vector3, pos: Vector3, mat: Material) -> StaticBody3D:
	var b := _box(size, pos, Color.WHITE)
	(b.get_child(0) as MeshInstance3D).material_override = mat
	return b

# --- signage + wayfinding (reads as a "designed" airport, not a box) ---------

func _build_signage() -> void:
	# Big illuminated DEPARTURES board on the back wall
	_trim(Vector3(11, 3.2, 0.2), Vector3(0, 5.6, -19.65), Mats.flat(C_DARK, 0.4, 0.2))
	var board := Label3D.new()
	board.text = "DEPARTURES"
	board.font_size = 130
	board.pixel_size = 0.011
	board.modulate = C_AMBER
	board.outline_size = 0
	board.position = Vector3(0, 6.4, -19.5)
	board.no_depth_test = false
	add_child(board)
	# split-flap style flight rows (emissive amber text)
	var rows := ["GATE 1   TEL AVIV      ON TIME", "GATE 2   THE TOWER     BOARDING", "GATE 3   RUNWAY 27     DELAYED"]
	for i in rows.size():
		var r := Label3D.new()
		r.text = rows[i]
		r.font_size = 56
		r.pixel_size = 0.0095
		r.modulate = Color(0.78, 0.66, 0.42)
		r.position = Vector3(0, 5.5 - i * 0.62, -19.5)
		add_child(r)

	# Hanging gate-direction signs from the ceiling
	_hang_sign(Vector3(-9, 6.4, -1), "← GATES 1-2", C_TEAL)
	_hang_sign(Vector3(9, 6.4, -1), "GATES 3-4 →", C_TEAL)
	_hang_sign(Vector3(0, 6.4, 11), "↓ DEPARTURES", C_AMBER)

	# Floor wayfinding stripe — MATTE painted line (not a glowing strip)
	var stripe := Mats.flat(C_TEAL, 0.7, 0.0)
	for z in range(-2, 13, 1):
		_trim(Vector3(0.5, 0.04, 0.7), Vector3(0, 0.06, float(z)), stripe)

func _hang_sign(pos: Vector3, text: String, col: Color) -> void:
	# drop rods
	for dx in [-1.6, 1.6]:
		_trim(Vector3(0.06, 1.4, 0.06), pos + Vector3(dx, 1.2, 0), Mats.flat(C_DARK, 0.4, 0.5))
	_trim(Vector3(3.6, 0.7, 0.18), pos, Mats.flat(C_DARK, 0.4, 0.2))
	var l := Label3D.new()
	l.text = text
	l.font_size = 52
	l.pixel_size = 0.009
	l.modulate = col
	l.position = pos + Vector3(0, 0, 0.12)
	add_child(l)
	var l2 := l.duplicate()
	l2.position = pos + Vector3(0, 0, -0.12)
	l2.rotation_degrees = Vector3(0, 180, 0)
	add_child(l2)

func _build_atmosphere() -> void:
	# Slow-floating dust motes catching the light — cheap, high-impact atmosphere.
	var p := GPUParticles3D.new()
	p.amount = 240
	p.lifetime = 14.0
	p.visibility_aabb = AABB(Vector3(-20, 0, -20), Vector3(40, 9, 40))
	p.position = Vector3(0, 4.5, 0)
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(19, 4.4, 19)
	pm.gravity = Vector3(0, -0.02, 0)
	pm.initial_velocity_min = 0.02
	pm.initial_velocity_max = 0.12
	pm.scale_min = 0.4
	pm.scale_max = 1.2
	p.process_material = pm
	var dot := QuadMesh.new()
	dot.size = Vector2(0.035, 0.035)
	var dm := StandardMaterial3D.new()
	dm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dm.albedo_color = Color(1.0, 0.97, 0.9, 0.5)
	dm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	dm.emission_enabled = true
	dm.emission = Color(1.0, 0.95, 0.85)
	dm.emission_energy_multiplier = 1.5
	dot.material = dm
	p.draw_pass_1 = dot
	add_child(p)

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
	if Net.active:
		hint.text = "Cursor is FREE — click READY UP, then the host clicks START FLIGHT · ESC: toggle cursor (free to click / locked to mouse-look) · WASD move · F1 menu"
	else:
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
