extends Node3D
## THE MATCH. Builds the airliner interior, spawns the procedural failures as
## repair consoles, and runs the whole loop: fix failures (which restores control
## authority) -> CONTACT THE TOWER (unlocks ATC talk-down) -> get flown down the
## glide slope -> land inside the envelope before integrity or the clock runs out.
## The cabin is static; FlightModel is the truth, ExteriorRig shows it out the
## windows. Ends in a cutscene, then the results screen.

# Failure effects + flight-critical classification live in MatchRules (shared
# with the match self-test so the test runs the exact same math).

var scenario: Dictionary
var fm: FlightModel
var ap: AutoPilot
var exterior: ExteriorRig
var hud: MatchHUD
var stations: Array[TaskStation] = []
var tower_contacted := false
var time_left := 0.0
var panic := 0.0
var ended := false

var _crew: Node3D
var _engine_sfx: AudioStreamPlayer
var _panic_sfx: AudioStreamPlayer
var _zone_counter := {}
var _screamed := false
var _net_accum := 0.0
var _cabin_lights: Array = []
var _sabotage_cd := 0.0
var _approach_announced := false
var _brace_announced := false

func _ready() -> void:
	scenario = GameState.pending_scenario
	if scenario.is_empty():
		scenario = ScenarioGenerator.generate(randi(), 2)
	time_left = float(scenario["time_limit"])

	_build_environment()
	_build_fuselage()
	exterior = ExteriorRig.new()
	add_child(exterior)
	_spawn_stations()
	_spawn_crew()

	fm = FlightModel.new()
	ap = AutoPilot.new()

	hud = MatchHUD.new()
	add_child(hud)
	hud.setup(scenario)
	if GameState.match_mode == "saboteur" and GameState.is_saboteur:
		hud.flash("YOU ARE THE SABOTEUR — make it crash, don't get caught.")

	if DisplayServer.get_name() != "headless":
		Audio.start_music("flight")
		_engine_sfx = Audio.play_loop("engine", -8.0)
		_panic_sfx = Audio.play_loop("panic", -60.0)

# --- build -------------------------------------------------------------------

func _build_environment() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var mat := ProceduralSkyMaterial.new()
	var night: bool = String(scenario["weather"]).contains("night")
	var storm: bool = scenario["weather"] in ["storm", "fog", "icing"]
	mat.sky_top_color = Color(0.04, 0.05, 0.1) if night else (Color(0.35, 0.4, 0.46) if storm else Color(0.3, 0.55, 0.85))
	mat.sky_horizon_color = Color(0.1, 0.12, 0.18) if night else Color(0.6, 0.65, 0.7)
	sky.sky_material = mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.3 if night else 0.45
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.05
	env.tonemap_white = 6.0
	env.ssao_enabled = true
	env.ssao_intensity = 2.0
	env.ssil_enabled = true
	env.glow_enabled = true
	env.glow_intensity = 0.22
	env.glow_hdr_threshold = 1.4
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.0
	env.adjustment_saturation = 0.98
	if storm:
		env.fog_enabled = true
		env.fog_density = 0.012
		env.fog_light_color = Color(0.5, 0.52, 0.55)
	we.environment = env
	add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, -110, 0)
	sun.light_energy = 0.5 if night else 1.1
	sun.light_color = Color(0.7, 0.75, 1.0) if night else Color(1.0, 0.96, 0.9)
	sun.shadow_enabled = Settings.video["shadow_quality"] > 0
	add_child(sun)

func _build_fuselage() -> void:
	# Stylized clean cabin panels (cream) — cohesive with the terminal's look.
	var hull_mat := Mats.flat(Color(0.86, 0.85, 0.81), 0.72, 0.0)

	# floor (carpet aisle) + ceiling (panels)
	var fl := _solid_box(Vector3(5.0, 0.3, 34.0), Vector3(0, -0.15, 9.0), Color.WHITE)
	(fl.get_child(0) as MeshInstance3D).material_override = Mats.textured("carpet", 8.0, 0.0, Color(0.24, 0.30, 0.40))
	_mesh_box(Vector3(5.0, 0.2, 34.0), Vector3(0, 2.7, 9.0), Color.WHITE).material_override = hull_mat
	# warm LED cove strips along the ceiling edges + a center runner (soft, not neon)
	var cove := Mats.emissive(Color(1.0, 0.93, 0.84), 1.5)
	for sx in [-2.25, 2.25]:
		_mesh_box(Vector3(0.1, 0.08, 34.0), Vector3(sx, 2.52, 9.0), Color.WHITE).material_override = cove
	_mesh_box(Vector3(0.35, 0.06, 34.0), Vector3(0, 2.62, 9.0), Color.WHITE).material_override = cove
	# tail wall
	var tw := _solid_box(Vector3(5.0, 3.0, 0.3), Vector3(0, 1.4, 26.0), Color.WHITE)
	(tw.get_child(0) as MeshInstance3D).material_override = hull_mat
	# side collision walls (full height; visuals added separately with a window band)
	_collide_wall(Vector3(0.3, 3.0, 34.0), Vector3(-2.5, 1.4, 9.0))
	_collide_wall(Vector3(0.3, 3.0, 34.0), Vector3(2.5, 1.4, 9.0))
	for sx in [-2.45, 2.45]:
		_mesh_box(Vector3(0.15, 1.0, 34.0), Vector3(sx, 0.5, 9.0), Color.WHITE).material_override = hull_mat
		_mesh_box(Vector3(0.15, 0.9, 34.0), Vector3(sx, 2.25, 9.0), Color.WHITE).material_override = hull_mat
		_glass(Vector3(0.08, 0.7, 34.0), Vector3(sx, 1.45, 9.0))               # window strip

	# cockpit: instrument coaming + windshield up front (-Z nose)
	_mesh_box(Vector3(4.6, 0.9, 0.6), Vector3(0, 0.9, -6.0), Color(0.12, 0.13, 0.16))
	_glass(Vector3(4.4, 1.3, 0.1), Vector3(0, 1.9, -6.4))
	for seat_x in [-1.1, 1.1]:
		_seat(Vector3(seat_x, 0.0, -5.0))

	# cabin seats from procedural row count, split by aisle, galley on chosen side
	var rows: int = int(scenario["layout"]["rows"])
	for r in range(rows):
		var z := 2.0 + r * 0.95
		if z > 24.0:
			break
		for seat_x in [-1.7, -1.15, 1.15, 1.7]:
			_seat(Vector3(seat_x, 0.0, z), true)

	# overhead lights — warm cabin key
	for z in range(-4, 26, 5):
		var lamp := OmniLight3D.new()
		lamp.position = Vector3(0, 2.5, z)
		lamp.light_color = Color(1.0, 0.91, 0.80)
		lamp.light_energy = 1.3
		lamp.omni_range = 8.0
		add_child(lamp)
		_cabin_lights.append(lamp)

func _spawn_stations() -> void:
	# Reaching the Tower is itself a two-step task at the front radio panel.
	var contact := {"type": "contact_tower", "zone": "cockpit", "severity": 0, "fuse": 0.0,
		"steps": ["tune_radio", "declare_mayday"], "role": "pilot"}
	var events: Array = [contact]
	events.append_array(scenario["events"])

	for ev in events:
		var st := TaskStation.new()
		st.setup(ev)
		st.position = _zone_anchor(ev["zone"])
		add_child(st)
		stations.append(st)
		st.fixed_changed.connect(_on_station_fixed)
		st.net_handler = _on_station_interacted

func _zone_anchor(zone: String) -> Vector3:
	var slots := {
		"cockpit": [Vector3(0, 0, -5.4), Vector3(-1.6, 0, -4.2), Vector3(1.6, 0, -4.2)],
		"cabin": [Vector3(-1.9, 0, 5), Vector3(1.9, 0, 8), Vector3(-1.9, 0, 11), Vector3(1.9, 0, 14)],
		"wing": [Vector3(-2.0, 0, 9), Vector3(2.0, 0, 10)],
		"belly": [Vector3(0, 0, 13)],
	}
	var arr: Array = slots.get(zone, [Vector3(0, 0, 18)])
	var i: int = _zone_counter.get(zone, 0)
	_zone_counter[zone] = i + 1
	return arr[i % arr.size()]

func _spawn_crew() -> void:
	var crew := CrewManager.new()
	crew.name = "CrewManager"
	add_child(crew)
	crew.build([Vector3(0, 0.2, 1.0), Vector3(-1.6, 0.2, 2.0), Vector3(1.6, 0.2, 2.0), Vector3(0, 0.2, 3.0)])
	_crew = crew

# --- match loop --------------------------------------------------------------

func _process(delta: float) -> void:
	if ended or fm == null:
		return

	if _sabotage_cd > 0.0:
		_sabotage_cd -= delta

	# Clients don't run the sim; they render the host's broadcast state.
	if Net.active and not Net.is_host:
		exterior.update(delta, fm, scenario["weather"])
		hud.update(fm, time_left, panic, tower_contacted, stations)
		_emergency_lighting()
		_check_voice_cues()
		return

	time_left = maxf(0.0, time_left - delta)

	var penalties := _aggregate_penalties(delta)

	var pitch_in := 0.0
	var roll_in := 0.0
	var throttle_in := 0.55
	if tower_contacted:
		var inp := ap.compute(fm)
		pitch_in = inp["pitch"]
		roll_in = inp["roll"]
		throttle_in = inp["throttle"]

	fm.update(delta, pitch_in, roll_in, throttle_in, penalties)
	exterior.update(delta, fm, scenario["weather"])

	_update_panic(delta, penalties)
	hud.update(fm, time_left, panic, tower_contacted, stations)
	_emergency_lighting()
	_check_voice_cues()

	if Net.active and Net.is_host:
		_net_accum += delta
		if _net_accum >= 0.05:
			_net_accum = 0.0
			_net_state.rpc(_collect_state())

	if fm.crashed:
		_finish(false, "STRUCTURAL FAILURE")
	elif fm.landed:
		_resolve_landing()
	elif time_left <= 0.0:
		_finish(false, "OUT OF TIME — NEVER REACHED THE FIELD")

func _aggregate_penalties(delta: float) -> Dictionary:
	var failures: Array = []
	for st in stations:
		if st.failure_type == "contact_tower":
			continue
		if not st.fixed:
			st.tick_fuse(delta)
		failures.append({"type": st.failure_type, "fixed": st.fixed, "critical": st.critical})
	return MatchRules.aggregate(failures)

func _update_panic(delta: float, penalties: Dictionary) -> void:
	var drive: float = penalties["panic_drive"] + (1.0 - fm.integrity) * 0.3
	if fm.in_approach():
		drive += 0.3
	panic = clampf(panic + (drive - 0.2) * delta * 0.3, 0.0, 1.0)
	if _panic_sfx != null:
		_panic_sfx.volume_db = lerpf(-60.0, -6.0, panic)
	if fm.in_approach() and not _screamed and panic > 0.4:
		_screamed = true
		Audio.play("panic", -3.0)

func _emergency_lighting() -> void:
	var t := clampf(panic, 0.0, 1.0)
	var col := Color(1, 1, 1).lerp(Color(1.0, 0.35, 0.30), t)
	var energy := lerpf(0.8, 1.3, t)
	for l in _cabin_lights:
		l.light_color = col
		l.light_energy = energy

func _check_voice_cues() -> void:
	if tower_contacted and fm.in_approach() and not _approach_announced:
		_approach_announced = true
		Audio.play_voice("atc_approach")
	if fm.distance < 1800.0 and not _brace_announced:
		_brace_announced = true
		Audio.play_voice("atc_brace")

func _on_station_fixed(st: TaskStation) -> void:
	if st.failure_type == "contact_tower":
		tower_contacted = true
		Audio.play("radio", -4.0)
		Audio.play_voice("atc_contact")
		hud.flash("TOWER: \"Copy your mayday — we'll bring you home. Stand by.\"")

func _resolve_landing() -> void:
	var res := fm.result()
	var gear_ok := true
	for st in stations:
		if st.failure_type == "gear_jam" and not st.fixed:
			gear_ok = false
	if not gear_ok:
		_finish(false, "BELLY LANDING — GEAR NEVER CAME DOWN")
		return
	_finish(res["success"], res["grade"])

# --- end + cutscene ----------------------------------------------------------

func _finish(success: bool, headline: String) -> void:
	if ended:
		return
	if Net.active:
		if Net.is_host:
			_net_finish.rpc(success, headline)
	else:
		_do_finish(success, headline)

func _on_station_interacted(st: TaskStation) -> void:
	var idx := stations.find(st)
	# Saboteur re-breaks a FIXED station (not the radio) on a cooldown.
	if GameState.is_saboteur and st.fixed and st.failure_type != "contact_tower":
		if _sabotage_cd > 0.0:
			return
		_sabotage_cd = 12.0
		if not Net.active:
			st.rebreak_local()
		elif Net.is_host:
			_net_break.rpc(idx)
		else:
			_request_break.rpc_id(1, idx)
		return
	if not Net.active:
		st.advance_local()
	elif Net.is_host:
		_net_advance.rpc(idx)
	else:
		_request_advance.rpc_id(1, idx)

@rpc("any_peer", "reliable")
func _request_advance(idx: int) -> void:
	if Net.is_host:
		_net_advance.rpc(idx)

@rpc("authority", "reliable", "call_local")
func _net_advance(idx: int) -> void:
	if idx >= 0 and idx < stations.size():
		stations[idx].advance_local()

@rpc("any_peer", "reliable")
func _request_break(idx: int) -> void:
	if Net.is_host:
		_net_break.rpc(idx)

@rpc("authority", "reliable", "call_local")
func _net_break(idx: int) -> void:
	if idx >= 0 and idx < stations.size():
		stations[idx].rebreak_local()

func _collect_state() -> Dictionary:
	return {"alt": fm.altitude, "spd": fm.airspeed, "vs": fm.vspeed, "hdg": fm.heading,
		"roll": fm.roll, "pit": fm.pitch, "dist": fm.distance, "integ": fm.integrity,
		"land": fm.landed, "crash": fm.crashed, "t": time_left, "pan": panic, "tow": tower_contacted}

@rpc("authority", "unreliable")
func _net_state(s: Dictionary) -> void:
	if fm == null:
		return
	fm.altitude = s["alt"]
	fm.airspeed = s["spd"]
	fm.vspeed = s["vs"]
	fm.heading = s["hdg"]
	fm.roll = s["roll"]
	fm.pitch = s["pit"]
	fm.distance = s["dist"]
	fm.integrity = s["integ"]
	fm.landed = s["land"]
	fm.crashed = s["crash"]
	time_left = s["t"]
	panic = s["pan"]
	tower_contacted = s["tow"]

@rpc("authority", "reliable", "call_local")
func _net_finish(success: bool, headline: String) -> void:
	_do_finish(success, headline)

func _do_finish(success: bool, headline: String) -> void:
	if ended:
		return
	ended = true
	var fixed_count := 0
	var total := 0
	for st in stations:
		if st.failure_type == "contact_tower":
			continue
		total += 1
		if st.fixed:
			fixed_count += 1
	var sab_name := ""
	if GameState.match_mode == "saboteur" and Net.players.has(GameState.saboteur_id):
		sab_name = Net.players[GameState.saboteur_id].get("callsign", "")
	GameState.last_result = {
		"success": success,
		"headline": headline,
		"weather": scenario["weather"],
		"airport": scenario["airport"],
		"fixed": fixed_count,
		"total": total,
		"tower": tower_contacted,
		"integrity": int(fm.integrity * 100.0),
		"mode": GameState.match_mode,
		"saboteur": sab_name,
	}
	Audio.play_voice("atc_success" if success else "atc_lost")
	_play_cutscene(success)

func _play_cutscene(success: bool) -> void:
	if _crew != null:
		_crew.queue_free()
	if hud != null:
		hud.queue_free()
	if exterior != null:
		exterior.queue_free()
	if _engine_sfx != null:
		_engine_sfx.queue_free()

	var rig := Node3D.new()
	add_child(rig)
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(2000, 2000)
	ground.mesh = pm
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.2, 0.28, 0.18)
	ground.material_override = gm
	rig.add_child(ground)
	var runway := MeshInstance3D.new()
	var rmesh := BoxMesh.new()
	rmesh.size = Vector3(40, 0.5, 600)
	runway.mesh = rmesh
	var rmat := StandardMaterial3D.new()
	rmat.albedo_color = Color(0.12, 0.12, 0.13)
	runway.material_override = rmat
	runway.position = Vector3(0, 0.25, 0)
	rig.add_child(runway)

	var plane := ExteriorRig._toy_plane()
	plane.scale = Vector3(1.4, 1.4, 1.4)
	rig.add_child(plane)

	var cam := Camera3D.new()
	cam.position = Vector3(70, 25, 60)
	cam.look_at_from_position(Vector3(70, 25, 60), Vector3(0, 15, 0), Vector3.UP)
	cam.current = true
	rig.add_child(cam)

	Audio.stop_music()

	var start := Vector3(-220, 90, -220)
	plane.position = start
	var tween := create_tween()
	if success:
		tween.tween_property(plane, "position", Vector3(-30, 3, 30), 3.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tween.tween_callback(func() -> void: Audio.play("touchdown", 2.0))
		tween.tween_property(plane, "position", Vector3(120, 2, 120), 2.0).set_trans(Tween.TRANS_QUAD)
	else:
		tween.tween_property(plane, "position", Vector3(0, 1, 0), 2.2).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
		tween.tween_callback(func() -> void: _impact(rig, plane))

	await tween.finished
	await get_tree().create_timer(1.6).timeout
	GameState.goto_scene("res://ui/EndScreen.tscn")

func _impact(rig: Node3D, plane: Node3D) -> void:
	Audio.play("explosion", 4.0)
	var fire := CPUParticles3D.new()
	fire.emitting = true
	fire.one_shot = true
	fire.amount = 120
	fire.lifetime = 1.6
	fire.explosiveness = 0.9
	fire.position = plane.position + Vector3(0, 4, 0)
	fire.direction = Vector3(0, 1, 0)
	fire.spread = 80.0
	fire.initial_velocity_min = 8.0
	fire.initial_velocity_max = 26.0
	fire.scale_amount_min = 2.0
	fire.scale_amount_max = 5.0
	var fmat := StandardMaterial3D.new()
	fmat.emission_enabled = true
	fmat.emission = Color(1.0, 0.5, 0.1)
	fmat.albedo_color = Color(1.0, 0.4, 0.05)
	fire.material_override = fmat
	rig.add_child(fire)
	if plane != null and is_instance_valid(plane):
		plane.visible = false

# --- geometry helpers --------------------------------------------------------

func _mesh_box(size: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	mi.material_override = m
	mi.position = pos
	add_child(mi)
	return mi

func _solid_box(size: Vector3, pos: Vector3, color: Color) -> StaticBody3D:
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

func _collide_wall(size: Vector3, pos: Vector3) -> void:
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	body.add_child(cs)
	body.position = pos
	add_child(body)

func _glass(size: Vector3, pos: Vector3) -> void:
	var mi := _mesh_box(size, pos, Color(0.5, 0.7, 0.85, 0.16))
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.5, 0.7, 0.85, 0.16)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.metallic = 0.3
	m.roughness = 0.05
	mi.material_override = m

func _seat(pos: Vector3, passenger := false) -> void:
	var fab := Color(0.15, 0.19, 0.28)                                  # muted seat fabric
	_mesh_box(Vector3(0.46, 0.42, 0.46), pos + Vector3(0, 0.42, 0), fab)            # cushion
	_mesh_box(Vector3(0.46, 0.55, 0.12), pos + Vector3(0, 0.72, -0.2), fab)         # backrest
	_mesh_box(Vector3(0.06, 0.36, 0.40), pos + Vector3(-0.24, 0.55, 0), fab.darkened(0.15))  # armrests
	_mesh_box(Vector3(0.06, 0.36, 0.40), pos + Vector3(0.24, 0.55, 0), fab.darkened(0.15))
	if not passenger:
		return
	# A real seated NORMAL Kenney character (animated "sit"), varied per seat.
	var idx := int(absf(pos.x * 7.0 + pos.z * 13.0))
	var pax := Characters.make(Characters.normal_for(idx), "sit")
	pax.name = "pax"
	pax.rotation.y = PI
	pax.scale = Vector3(0.62, 0.62, 0.62)
	pax.position = pos + Vector3(0, 0.05, 0.12)
	add_child(pax)
