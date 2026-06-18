class_name RemoteAvatar
extends Node3D
## A networked stand-in for another player: a colored body, a head, and a
## floating callsign. Its transform is fed by CrewManager from the owner's RPCs
## and smoothed here.

var _target_pos: Vector3
var _target_yaw: float
var _has_target := false

func setup(callsign: String, color: Color) -> void:
	var body := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.32
	cap.height = 1.7
	body.mesh = cap
	body.position.y = 0.9
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	body.material_override = m
	add_child(body)

	var head := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.18
	sm.height = 0.36
	head.mesh = sm
	head.position.y = 1.75
	var hm := StandardMaterial3D.new()
	hm.albedo_color = Color(0.8, 0.66, 0.55)
	head.material_override = hm
	add_child(head)

	var tag := Label3D.new()
	tag.text = callsign
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.no_depth_test = true
	tag.font_size = 40
	tag.pixel_size = 0.003
	tag.position.y = 2.15
	tag.modulate = color.lightened(0.4)
	tag.outline_size = 8
	add_child(tag)

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
