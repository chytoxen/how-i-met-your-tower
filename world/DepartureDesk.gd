class_name DepartureDesk
extends Interactable
## The glowing "DEPARTURES" desk in the lobby. Interacting boards a flight, which
## generates a fresh procedural emergency and drops you into the aircraft.

func _ready() -> void:
	prompt = "BOARD FLIGHT  [E]"
	var desk := MeshInstance3D.new()
	var dm := BoxMesh.new()
	dm.size = Vector3(2.4, 1.1, 1.0)
	desk.mesh = dm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.18, 0.30, 0.40)
	m.emission_enabled = true
	m.emission = Color(0.10, 0.22, 0.34)
	m.emission_energy_multiplier = 0.55
	desk.material_override = m
	desk.position.y = 0.55
	add_child(desk)

	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.4, 1.1, 1.0)
	cs.shape = shape
	cs.position.y = 0.55
	add_child(cs)

	var sign := Label3D.new()
	sign.text = "DEPARTURES\n— BOARD FLIGHT —"
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign.font_size = 44
	sign.pixel_size = 0.004
	sign.position = Vector3(0, 1.9, 0)
	sign.modulate = Color(0.72, 0.82, 0.90)
	sign.outline_size = 10
	add_child(sign)

	var beacon := OmniLight3D.new()
	beacon.position = Vector3(0, 2.2, 0)
	beacon.light_color = Color(0.5, 0.66, 0.82)
	beacon.light_energy = 1.4
	beacon.omni_range = 7.0
	add_child(beacon)

func interact(_by: Node) -> void:
	Audio.play("confirm")
	GameState.start_single_match(2)
