class_name RemoteAvatar
extends Node3D
## A networked stand-in for another player: a colored body, a head, and a
## floating callsign. Its transform is fed by CrewManager from the owner's RPCs
## and smoothed here.

var _target_pos: Vector3
var _target_yaw: float
var _has_target := false

func setup(callsign: String, color: Color) -> void:
	var suit := StandardMaterial3D.new()
	suit.albedo_color = color
	suit.roughness = 0.55
	var skin := StandardMaterial3D.new()
	skin.albedo_color = Color(0.8, 0.65, 0.54)
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.14, 0.15, 0.19)
	var hi := StandardMaterial3D.new()
	hi.albedo_color = Color(0.95, 0.85, 0.2)
	hi.emission_enabled = true
	hi.emission = Color(0.55, 0.48, 0.1)

	_part(Vector3(0.52, 0.64, 0.32), Vector3(0, 1.15, 0), suit)       # torso
	_part(Vector3(0.54, 0.12, 0.34), Vector3(0, 0.92, 0), hi)         # hi-vis belt
	_part(Vector3(0.36, 0.36, 0.36), Vector3(0, 1.64, 0), skin)       # head
	_part(Vector3(0.14, 0.52, 0.14), Vector3(-0.34, 1.12, 0), suit)   # left arm
	_part(Vector3(0.14, 0.52, 0.14), Vector3(0.34, 1.12, 0), suit)    # right arm
	_part(Vector3(0.19, 0.58, 0.19), Vector3(-0.13, 0.5, 0), dark)    # left leg
	_part(Vector3(0.19, 0.58, 0.19), Vector3(0.13, 0.5, 0), dark)     # right leg

	var tag := Label3D.new()
	tag.text = callsign
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.no_depth_test = true
	tag.font_size = 40
	tag.pixel_size = 0.003
	tag.position.y = 2.2
	tag.modulate = color.lightened(0.4)
	tag.outline_size = 8
	add_child(tag)

func _part(size: Vector3, pos: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	add_child(mi)

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
