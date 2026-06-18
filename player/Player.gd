extends CharacterBody3D
## First-person crew member: movement + look + interaction. Body, camera, and a
## small HUD (crosshair + context prompt) are built in code so it works anywhere
## (lobby and aircraft) with no external wiring.

@export var walk_speed := 5.2
@export var sprint_speed := 8.6
@export var crouch_speed := 2.8
@export var jump_velocity := 5.2
@export var mouse_sensitivity := 0.0025
@export var ground_accel := 65.0
@export var air_accel := 16.0
@export var friction := 80.0
@export var sprint_fov_add := 8.0

const COYOTE_TIME := 0.12     # jump shortly after leaving a ledge
const JUMP_BUFFER := 0.12     # jump pressed shortly before landing
const STAND_HEIGHT := 1.65
const CROUCH_HEIGHT := 1.15
const EMOTES: Array[String] = ["o7", "GG!", "HELP!", "NICE!", "BRACE!"]

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
var _head: Node3D
var _camera: Camera3D
var _interact_ray: RayCast3D
var _prompt: Label
var _target: Node = null
var _emote_idx := 0

var _coyote := 0.0
var _jump_buf := 0.0
var _base_fov := 85.0
var _bob_t := 0.0
var _step_t := 0.0

func _ready() -> void:
	_build_body()
	_build_hud()
	if DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _build_body() -> void:
	var col := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.height = 1.8
	capsule.radius = 0.35
	col.shape = capsule
	col.position.y = 0.9
	add_child(col)

	_head = Node3D.new()
	_head.name = "Head"
	_head.position = Vector3(0, STAND_HEIGHT, 0)
	add_child(_head)

	_camera = Camera3D.new()
	_camera.current = true
	_camera.fov = _base_fov
	_head.add_child(_camera)

	_interact_ray = RayCast3D.new()
	_interact_ray.target_position = Vector3(0, 0, -3.0)
	_interact_ray.collide_with_areas = false
	_camera.add_child(_interact_ray)

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 2
	add_child(layer)

	var cross := Label.new()
	cross.text = "+"
	cross.add_theme_font_size_override("font_size", 22)
	cross.modulate = Color(1, 1, 1, 0.6)
	cross.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	layer.add_child(cross)

	_prompt = Label.new()
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 120)
	_prompt.modulate = Color(1, 0.95, 0.6)
	_prompt.visible = false
	layer.add_child(_prompt)

func _unhandled_input(event: InputEvent) -> void:
	var mm := event as InputEventMouseMotion
	if mm != null and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-mm.relative.x * mouse_sensitivity)
		_head.rotate_x(-mm.relative.y * mouse_sensitivity)
		_head.rotation.x = clampf(_head.rotation.x, -1.4, 1.4)
	if event.is_action_pressed("pause") and not get_tree().paused:
		var scene := get_tree().current_scene
		if scene != null:
			scene.add_child(preload("res://ui/PauseMenu.gd").new())
	if event.is_action_pressed("emote"):
		_emote()
	if event.is_action_pressed("interact") and _target != null and _target.has_method("interact"):
		_target.interact(self)

func _physics_process(delta: float) -> void:
	var grounded := is_on_floor()

	if grounded:
		_coyote = COYOTE_TIME
	else:
		velocity.y -= _gravity * delta
		_coyote -= delta

	if Input.is_action_just_pressed("jump"):
		_jump_buf = JUMP_BUFFER
	else:
		_jump_buf -= delta
	if _jump_buf > 0.0 and _coyote > 0.0:
		velocity.y = jump_velocity
		_jump_buf = 0.0
		_coyote = 0.0

	var crouching := Input.is_action_pressed("crouch")
	var sprinting := Input.is_action_pressed("sprint") and not crouching
	var speed := crouch_speed if crouching else (sprint_speed if sprinting else walk_speed)

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var wish := transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)
	wish.y = 0.0
	wish = wish.normalized() * speed

	var a := ground_accel if grounded else air_accel
	if input_dir.length() > 0.01:
		velocity.x = move_toward(velocity.x, wish.x, a * delta)
		velocity.z = move_toward(velocity.z, wish.z, a * delta)
	else:
		var f := friction if grounded else air_accel
		velocity.x = move_toward(velocity.x, 0.0, f * delta)
		velocity.z = move_toward(velocity.z, 0.0, f * delta)

	move_and_slide()
	_update_view(delta, sprinting, crouching)
	_update_interaction()

func _update_view(delta: float, sprinting: bool, crouching: bool) -> void:
	if _camera == null or _head == null:
		return
	var spd := Vector2(velocity.x, velocity.z).length()

	# crouch lowers the head
	var target_h := CROUCH_HEIGHT if crouching else STAND_HEIGHT
	_head.position.y = lerpf(_head.position.y, target_h, clampf(delta * 10.0, 0.0, 1.0))

	# sprint FOV kick
	var target_fov := _base_fov + (sprint_fov_add if sprinting and spd > 1.0 else 0.0)
	_camera.fov = lerpf(_camera.fov, target_fov, clampf(delta * 8.0, 0.0, 1.0))

	# head bob + footsteps
	if is_on_floor() and spd > 0.6:
		_bob_t += delta * spd * 1.6
		_camera.position.y = sin(_bob_t * 2.0) * 0.035
		_camera.position.x = sin(_bob_t) * 0.022
		_step_t -= delta * spd
		if _step_t <= 0.0:
			_step_t = 4.2
			Audio.play("step", -8.0, randf_range(0.9, 1.1))
	else:
		_camera.position.y = lerpf(_camera.position.y, 0.0, clampf(delta * 10.0, 0.0, 1.0))
		_camera.position.x = lerpf(_camera.position.x, 0.0, clampf(delta * 10.0, 0.0, 1.0))

func _update_interaction() -> void:
	if _interact_ray == null:
		return
	_interact_ray.force_raycast_update()
	var hit := _interact_ray.get_collider()
	if hit != null and hit.has_method("interact"):
		_target = hit
		var p: Variant = hit.get("prompt")
		_prompt.text = str(p) if p != null else "Use  [E]"
		_prompt.visible = true
	else:
		_target = null
		if _prompt != null:
			_prompt.visible = false

func _emote() -> void:
	var txt := EMOTES[_emote_idx % EMOTES.size()]
	_emote_idx += 1
	_show_bubble(txt)
	Audio.play("beep")
	var crew := get_parent()
	if crew is CrewManager:
		crew.send_emote(txt)

func _show_bubble(text: String) -> void:
	var b := Label3D.new()
	b.text = text
	b.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	b.no_depth_test = true
	b.font_size = 64
	b.pixel_size = 0.004
	b.position = Vector3(0, 2.1, 0)
	b.modulate = Color(1, 1, 0.5)
	b.outline_size = 12
	add_child(b)
	get_tree().create_timer(2.0).timeout.connect(b.queue_free)
