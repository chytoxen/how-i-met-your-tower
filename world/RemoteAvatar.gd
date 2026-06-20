class_name RemoteAvatar
extends Node3D
## A networked stand-in for another player: a real animated Kenney "Blocky
## Character" (CC0). Plays idle/walk driven by its actual movement speed, with a
## floating callsign. Transform is fed by CrewManager from the owner's RPCs and
## smoothed here. (18 character variants → crew + passengers look varied.)

const SCALE := 0.78

var _target_pos: Vector3
var _target_yaw: float
var _has_target := false
var _ap: AnimationPlayer
var _prev_pos := Vector3.ZERO
var _speed := 0.0

func setup(callsign: String, color: Color, character := "") -> void:
	if character == "":
		character = Characters.funny_for(hash(callsign))
	var model := Characters.make(character, "idle")
	model.rotation.y = PI                        # Kenney chars face +Z; turn to game forward (-Z)
	model.scale = Vector3(SCALE, SCALE, SCALE)
	add_child(model)
	_ap = Characters.find_anim(model)

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
	# drive idle/walk from actual horizontal speed (no extra net traffic)
	var d := Vector2(global_position.x - _prev_pos.x, global_position.z - _prev_pos.z).length()
	_prev_pos = global_position
	_speed = lerpf(_speed, d / maxf(delta, 0.0001), clampf(delta * 8.0, 0.0, 1.0))
	if _ap != null:
		var want := "walk" if _speed > 0.6 else "idle"
		if _ap.current_animation != want and _ap.has_animation(want):
			_ap.play(want, 0.2)

func show_emote(text: String) -> void:
	var b := Label3D.new()
	b.text = text
	b.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	b.no_depth_test = true
	b.font_size = 64
	b.pixel_size = 0.004
	b.position = Vector3(0, 2.4, 0)
	b.modulate = Color(1, 1, 0.5)
	b.outline_size = 12
	add_child(b)
	get_tree().create_timer(2.0).timeout.connect(b.queue_free)
