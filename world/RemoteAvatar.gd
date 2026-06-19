class_name RemoteAvatar
extends Node3D
## A networked stand-in for another player: a blocky crew member with an actual
## FACE (eyes, smile, cap) and a code-driven WALK animation (arms + legs swing,
## body bob) that plays whenever the avatar is moving. Its transform is fed by
## CrewManager from the owner's RPCs and smoothed here; the walk is derived from
## how fast it's actually moving, so no extra network traffic is needed.

var _target_pos: Vector3
var _target_yaw: float
var _has_target := false

# limb pivots (rotated to animate the walk)
var _l_arm: Node3D
var _r_arm: Node3D
var _l_leg: Node3D
var _r_leg: Node3D
var _torso: Node3D
var _phase := 0.0
var _speed := 0.0
var _prev_pos := Vector3.ZERO
var _bob_base := 0.0

func setup(callsign: String, color: Color) -> void:
	var suit := _mat(color, 0.55)
	var suit_dark := _mat(color.darkened(0.35), 0.6)
	var skin := _mat(Color(0.86, 0.69, 0.56), 0.7)
	var dark := _mat(Color(0.12, 0.13, 0.16), 0.5)
	var white := _mat(Color(0.95, 0.96, 0.98), 0.4)
	var hi := _mat(Color(0.98, 0.86, 0.12), 0.5)
	hi.emission_enabled = true
	hi.emission = Color(0.55, 0.48, 0.1)

	# pelvis / torso (the torso pivot lets the whole upper body bob + lean)
	_torso = Node3D.new()
	_torso.position = Vector3(0, 0.92, 0)
	add_child(_torso)
	_bob_base = _torso.position.y

	_box(_torso, Vector3(0.5, 0.62, 0.3), Vector3(0, 0.32, 0), suit)        # chest
	_box(_torso, Vector3(0.54, 0.13, 0.34), Vector3(0, 0.06, 0), hi)        # hi-vis belt
	_box(_torso, Vector3(0.46, 0.18, 0.32), Vector3(0, 0.55, 0), suit_dark) # collar/shoulders

	# --- head with a real face (front = -Z, the way the body faces) ---
	var head := Node3D.new()
	head.position = Vector3(0, 0.74, 0)
	_torso.add_child(head)
	_box(head, Vector3(0.34, 0.34, 0.32), Vector3.ZERO, skin)               # head
	_box(head, Vector3(0.36, 0.12, 0.34), Vector3(0, 0.17, 0.01), suit)     # cap dome
	_box(head, Vector3(0.36, 0.05, 0.12), Vector3(0, 0.10, -0.20), suit_dark) # cap brim
	# eyes (white + dark pupil) on the -Z face
	for sx in [-0.08, 0.08]:
		_box(head, Vector3(0.09, 0.09, 0.02), Vector3(sx, 0.02, -0.17), white)
		_box(head, Vector3(0.04, 0.05, 0.02), Vector3(sx, 0.02, -0.185), dark)
	# smile
	_box(head, Vector3(0.16, 0.03, 0.02), Vector3(0, -0.10, -0.17), dark)

	# --- arms (pivot at the shoulder, limb hangs below) ---
	_l_arm = _limb(_torso, Vector3(-0.33, 0.5, 0), Vector3(0.13, 0.46, 0.14), suit, skin)
	_r_arm = _limb(_torso, Vector3(0.33, 0.5, 0), Vector3(0.13, 0.46, 0.14), suit, skin)

	# --- legs (pivot at the hip) ---
	_l_leg = _limb(self, Vector3(-0.13, 0.86, 0), Vector3(0.18, 0.52, 0.18), suit_dark, dark)
	_r_leg = _limb(self, Vector3(0.13, 0.86, 0), Vector3(0.18, 0.52, 0.18), suit_dark, dark)

	var tag := Label3D.new()
	tag.text = callsign
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.no_depth_test = true
	tag.font_size = 40
	tag.pixel_size = 0.003
	tag.position.y = 2.25
	tag.modulate = color.lightened(0.4)
	tag.outline_size = 8
	add_child(tag)

func _mat(c: Color, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	return m

func _box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)

## A limb = a pivot Node3D at the joint with the limb box hanging below it, so
## rotating the pivot on X swings the whole limb like a hinge.
func _limb(parent: Node3D, joint: Vector3, size: Vector3, mat: Material, end_mat: Material) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = joint
	parent.add_child(pivot)
	_box(pivot, size, Vector3(0, -size.y * 0.5, 0), mat)
	# hand / foot cap
	_box(pivot, Vector3(size.x * 1.05, size.x * 0.9, size.z * 1.05), Vector3(0, -size.y - size.x * 0.35, 0), end_mat)
	return pivot

func set_target(pos: Vector3, yaw: float) -> void:
	_target_pos = pos
	_target_yaw = yaw
	_has_target = true

func _process(delta: float) -> void:
	if not _has_target:
		return
	var t := clampf(delta * 12.0, 0.0, 1.0)
	global_position = global_position.lerp(_target_pos, t)
	rotation.y = lerp_angle(rotation.y, _target_yaw, t)
	_animate(delta)

func _animate(delta: float) -> void:
	# derive speed from how far we actually moved (horizontal only)
	var d := Vector2(global_position.x - _prev_pos.x, global_position.z - _prev_pos.z).length()
	_prev_pos = global_position
	var inst_speed: float = d / maxf(delta, 0.0001)
	_speed = lerpf(_speed, inst_speed, clampf(delta * 8.0, 0.0, 1.0))
	var moving: float = clampf(_speed / 3.5, 0.0, 1.0)

	if _l_arm == null:
		return
	_phase += delta * (4.0 + _speed * 1.6)
	var swing := sin(_phase) * 0.7 * moving       # leg/arm swing amplitude
	var idle := sin(_phase * 0.4) * 0.04 * (1.0 - moving)  # gentle idle breathing

	_l_leg.rotation.x = swing
	_r_leg.rotation.x = -swing
	_l_arm.rotation.x = -swing * 0.8
	_r_arm.rotation.x = swing * 0.8
	if _torso != null:
		_torso.position.y = _bob_base + absf(sin(_phase)) * 0.05 * moving + idle
		_torso.rotation.x = -0.06 * moving      # slight forward lean when walking

func show_emote(text: String) -> void:
	var b := Label3D.new()
	b.text = text
	b.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	b.no_depth_test = true
	b.font_size = 64
	b.pixel_size = 0.004
	b.position = Vector3(0, 2.5, 0)
	b.modulate = Color(1, 1, 0.5)
	b.outline_size = 12
	add_child(b)
	get_tree().create_timer(2.0).timeout.connect(b.queue_free)
