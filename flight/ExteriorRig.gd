class_name ExteriorRig
extends Node3D
## What you see out the windows. The cabin is static; THIS moves/tilts to sell the
## flight: ground rises as you descend, the world banks when you roll, the runway
## grows out the windshield as distance closes, clouds streak past for speed.
## Vertical scale is compressed (real metres would be invisible).

var _runway: Node3D
var _clouds: Array = []
var _ground: MeshInstance3D

func _ready() -> void:
	_build()

func _build() -> void:
	# Stylized ground — muted cohesive earth (cool, low-key so the lights read)
	_ground = MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(4000, 4000)
	_ground.mesh = pm
	_ground.material_override = Mats.flat(Color(0.15, 0.19, 0.18), 1.0, 0.0)
	add_child(_ground)

	# Runway down -Z (the near "approach" end is toward +Z, out the windshield).
	_runway = Node3D.new()
	add_child(_runway)
	_runway.add_child(_xbox(Vector3(60, 1, 940), Vector3(0, 0.5, 0), Mats.flat(Color(0.07, 0.07, 0.09), 0.65, 0.0)))
	var white := Mats.flat(Color(0.92, 0.93, 0.95), 0.5, 0.0)
	for i in range(16):                                  # centerline dashes
		_runway.add_child(_xbox(Vector3(2.4, 1.1, 24), Vector3(0, 0.6, -440 + i * 58), white))
	for k in range(8):                                   # threshold "piano keys"
		_runway.add_child(_xbox(Vector3(4.4, 1.1, 26), Vector3(-22.0 + k * 6.3, 0.6, 408), white))
	# emissive edge lights both sides (bloom makes them glow)
	var edge := Mats.emissive(Color(0.80, 0.88, 1.0), 6.0)
	for i in range(25):
		var z := -450.0 + i * 38.0
		_runway.add_child(_xbox(Vector3(1.5, 1.5, 1.5), Vector3(-31, 1.0, z), edge))
		_runway.add_child(_xbox(Vector3(1.5, 1.5, 1.5), Vector3(31, 1.0, z), edge))
	# green threshold bar / red far-end bar
	_runway.add_child(_xbox(Vector3(60, 1.4, 2.2), Vector3(0, 1.0, 422), Mats.emissive(Color(0.2, 1.0, 0.4), 6.0)))
	_runway.add_child(_xbox(Vector3(60, 1.4, 2.2), Vector3(0, 1.0, -470), Mats.emissive(Color(1.0, 0.2, 0.2), 6.0)))
	# PAPI glideslope lights (2 white + 2 red) left of the threshold
	for p in range(4):
		var col: Color = Color(1, 1, 1) if p < 2 else Color(1, 0.25, 0.2)
		_runway.add_child(_xbox(Vector3(2.2, 2.2, 2.2), Vector3(-40, 1.6, 405 - p * 4.5), Mats.emissive(col, 7.0)))
	# approach "rabbit" lights leading in beyond the threshold
	var appr := Mats.emissive(Color(1.0, 0.98, 0.92), 8.0)
	for i in range(12):
		_runway.add_child(_xbox(Vector3(6, 1.3, 1.6), Vector3(0, 1.0, 445 + i * 24), appr))

	# Dusk city beside the approach — cohesive cool palette, ~40% lit from within
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in range(56):
		var h := rng.randf_range(12, 95)
		var w := rng.randf_range(16, 42)
		var d := rng.randf_range(16, 42)
		var g := rng.randf_range(0.13, 0.26)
		var bmat := StandardMaterial3D.new()
		bmat.albedo_color = Color(g, g + 0.02, g + 0.07)
		bmat.roughness = 0.9
		if rng.randf() < 0.4:                            # lit building
			bmat.emission_enabled = true
			bmat.emission = Color(1.0, 0.82, 0.5)
			bmat.emission_energy_multiplier = 0.28
		var side := -1.0 if rng.randf() < 0.5 else 1.0
		var b := _xbox(Vector3(w, h, d),
			Vector3(side * rng.randf_range(95, 720), h * 0.5, rng.randf_range(-1200, 250)), bmat)
		add_child(b)

	# Soft, flat cloud layers (the chunky boxes read as "amateur")
	for i in range(16):
		var c := _xbox(Vector3(rng.randf_range(70, 170), rng.randf_range(3, 7), rng.randf_range(70, 170)),
			Vector3.ZERO, _cloud_mat())
		_reseed_cloud(c, rng, true)
		add_child(c)
		_clouds.append(c)

	# The other ship — a distant airliner off to port (two-ship flavor / easter egg)
	var ship := _toy_plane(Color(0.8, 0.3, 0.25))
	ship.position = Vector3(-180, 40, -300)
	ship.scale = Vector3(2, 2, 2)
	add_child(ship)

func _xbox(size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	return mi

func _cloud_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.92, 0.94, 0.98, 0.30)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m

func _reseed_cloud(c: Node3D, rng: RandomNumberGenerator, anywhere: bool) -> void:
	var z := rng.randf_range(-400, 20) if anywhere else rng.randf_range(-420, -360)
	c.position = Vector3(rng.randf_range(-200, 200), rng.randf_range(20, 120), z)

func update(delta: float, fm: FlightModel, _weather: String) -> void:
	var alt_v: float = clampf(fm.altitude * 0.045, 1.5, 70.0)
	position.y = -alt_v - 1.2
	rotation.z = deg_to_rad(-fm.roll)
	rotation.x = deg_to_rad(fm.pitch * 0.4)
	position.x = fm.heading * 1.5
	_runway.position.z = -clampf(fm.distance * 0.02, 0.0, 1500.0)

	var scroll: float = fm.airspeed * 0.06 * delta + 0.5
	var rng := RandomNumberGenerator.new()
	for c in _clouds:
		c.position.z += scroll
		if c.position.z > 30.0:
			rng.seed = int(Time.get_ticks_usec()) + c.get_instance_id()
			_reseed_cloud(c, rng, false)

## A proper airliner (nose = -Z): rounded fuselage, swept wings with dihedral,
## underwing engines, tailplane, a liveried fin, cockpit glass + lit cabin windows.
## Built from primitives so it ships with zero asset files and is easily restyled.
static func _toy_plane(livery := Color(0.16, 0.42, 0.82)) -> Node3D:
	var root := Node3D.new()
	var white := _plane_mat(Color(0.93, 0.94, 0.97), 0.35, 0.1)
	var accent := _plane_mat(livery, 0.4, 0.1)
	var metal := _plane_mat(Color(0.42, 0.44, 0.5), 0.45, 0.8)
	var glass := _plane_mat(Color(0.08, 0.12, 0.18), 0.05, 0.7)
	var win := _plane_mat(Color(0.75, 0.9, 1.0), 0.2, 0.0)
	win.emission_enabled = true
	win.emission = Color(0.6, 0.8, 1.0)
	win.emission_energy_multiplier = 1.4

	# Fuselage — a rounded tube down the Z axis (capsule = rounded nose + tail)
	var fus := CapsuleMesh.new()
	fus.radius = 1.5
	fus.height = 24.0
	_part2(root, fus, Vector3.ZERO, Vector3(90, 0, 0), white)

	# Cockpit windscreen — raked dark glass sitting on the upper-front surface
	_part2(root, _boxm(Vector3(1.9, 0.55, 1.7)), Vector3(0, 1.0, -8.2), Vector3(-26, 0, 0), glass)
	_part2(root, _boxm(Vector3(2.1, 0.5, 0.9)), Vector3(0, 0.55, -9.2), Vector3(-55, 0, 0), glass)

	# Cheatline + lit cabin windows down each side
	for sx in [-1.0, 1.0]:
		_part2(root, _boxm(Vector3(0.06, 0.4, 17.0)), Vector3(sx * 1.46, 0.15, 0.5), Vector3.ZERO, accent)
		for i in range(13):
			var z := -7.0 + i * 1.25
			_part2(root, _boxm(Vector3(0.05, 0.18, 0.18)), Vector3(sx * 1.5, 0.5, z), Vector3.ZERO, win)

	# Wings — pivot at the fuselage so they sweep back + rise (dihedral)
	_wing(root, -1.3, Vector3(0, 14, 5), white, metal)    # port
	_wing(root, 1.3, Vector3(0, -14, -5), white, metal)   # starboard

	# Tailplane (horizontal stabilisers) near the rear
	for s in [-1.0, 1.0]:
		_part2(root, _boxm(Vector3(5.0, 0.28, 1.7)), Vector3(s * 2.9, 1.4, 10.2), Vector3(0, s * 10, 0), white)

	# Vertical fin (liveried), leaning back
	_part2(root, _boxm(Vector3(0.35, 4.4, 3.4)), Vector3(0, 3.4, 10.4), Vector3(18, 0, 0), accent)
	return root

static func _wing(root: Node3D, side: float, sweep_dihedral: Vector3, mat: Material, engine_mat: Material) -> void:
	var pivot := Node3D.new()
	pivot.position = Vector3(side, -0.4, 1.5)
	pivot.rotation_degrees = sweep_dihedral
	root.add_child(pivot)
	var dir := signf(side)
	_part2(pivot, _boxm(Vector3(9.0, 0.32, 3.4)), Vector3(dir * 4.6, 0, 0), Vector3.ZERO, mat)
	# engine nacelle slung under the wing
	var nac := CapsuleMesh.new()
	nac.radius = 0.62
	nac.height = 3.2
	_part2(pivot, nac, Vector3(dir * 3.6, -1.0, -0.4), Vector3(90, 0, 0), engine_mat)

static func _plane_mat(c: Color, rough: float, metal: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	return m

static func _boxm(size: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = size
	return b

static func _part2(parent: Node3D, mesh: Mesh, pos: Vector3, rot_deg: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	mi.rotation_degrees = rot_deg
	mi.material_override = mat
	parent.add_child(mi)
