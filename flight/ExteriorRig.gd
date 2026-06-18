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
	# Ground
	_ground = MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(4000, 4000)
	_ground.mesh = pm
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.20, 0.30, 0.18)
	gm.roughness = 1.0
	_ground.material_override = gm
	add_child(_ground)

	# Runway ahead (down the -Z axis = out the windshield)
	_runway = Node3D.new()
	add_child(_runway)
	var strip := MeshInstance3D.new()
	var smesh := BoxMesh.new()
	smesh.size = Vector3(60, 1, 900)
	strip.mesh = smesh
	var sm := StandardMaterial3D.new()
	sm.albedo_color = Color(0.12, 0.12, 0.13)
	strip.material_override = sm
	strip.position.y = 0.5
	_runway.add_child(strip)
	for i in range(10):
		var dash := MeshInstance3D.new()
		var dm := BoxMesh.new()
		dm.size = Vector3(3, 1.1, 30)
		dash.mesh = dm
		var dmat := StandardMaterial3D.new()
		dmat.albedo_color = Color(0.9, 0.9, 0.9)
		dash.material_override = dmat
		dash.position = Vector3(0, 0.6, -400 + i * 90)
		_runway.add_child(dash)

	# City blocks beside the approach
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in range(60):
		var b := MeshInstance3D.new()
		var bm := BoxMesh.new()
		var h := rng.randf_range(10, 70)
		bm.size = Vector3(rng.randf_range(15, 40), h, rng.randf_range(15, 40))
		b.mesh = bm
		var bmat := StandardMaterial3D.new()
		var g := rng.randf_range(0.25, 0.5)
		bmat.albedo_color = Color(g, g, g + 0.05)
		b.material_override = bmat
		var side := -1.0 if rng.randf() < 0.5 else 1.0
		b.position = Vector3(side * rng.randf_range(90, 700), h * 0.5, rng.randf_range(-1200, 200))
		add_child(b)

	# Clouds
	for i in range(14):
		var c := MeshInstance3D.new()
		var cm := BoxMesh.new()
		cm.size = Vector3(rng.randf_range(30, 80), rng.randf_range(6, 14), rng.randf_range(30, 80))
		c.mesh = cm
		var cmat := StandardMaterial3D.new()
		cmat.albedo_color = Color(0.9, 0.92, 0.95, 0.5)
		cmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		c.material_override = cmat
		_reseed_cloud(c, rng, true)
		add_child(c)
		_clouds.append(c)

	# The other ship — a distant airliner off to port (two-ship flavor / easter egg)
	var ship := _toy_plane()
	ship.position = Vector3(-180, 40, -300)
	ship.scale = Vector3(3, 3, 3)
	add_child(ship)

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

static func _toy_plane() -> Node3D:
	var root := Node3D.new()
	var body := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 1.2
	cyl.bottom_radius = 1.2
	cyl.height = 16
	body.mesh = cyl
	body.rotation_degrees = Vector3(90, 0, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.85, 0.86, 0.9)
	body.material_override = mat
	root.add_child(body)
	var wing := MeshInstance3D.new()
	var wm := BoxMesh.new()
	wm.size = Vector3(22, 0.6, 3)
	wing.mesh = wm
	wing.material_override = mat
	root.add_child(wing)
	var tail := MeshInstance3D.new()
	var tm := BoxMesh.new()
	tm.size = Vector3(7, 0.5, 2)
	tail.mesh = tm
	tail.position = Vector3(0, 1.5, 7)
	tail.material_override = mat
	root.add_child(tail)
	var fin := MeshInstance3D.new()
	var fm := BoxMesh.new()
	fm.size = Vector3(0.5, 4, 3)
	fin.mesh = fm
	fin.position = Vector3(0, 2, 7)
	fin.material_override = mat
	root.add_child(fin)
	return root
