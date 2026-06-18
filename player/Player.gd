extends CharacterBody3D
## First-person crew member: movement + look + interaction. Body, camera, and a
## small HUD (crosshair + context prompt) are built in code so it works anywhere
## (lobby and aircraft) with no external wiring.

@export var walk_speed := 4.5
@export var sprint_speed := 7.5
@export var crouch_speed := 2.5
@export var jump_velocity := 5.0
@export var mouse_sensitivity := 0.0025
@export var accel := 60.0

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
var _head: Node3D
var _camera: Camera3D
var _interact_ray: RayCast3D
var _prompt: Label
var _target: Node = null

const EMOTES: Array[String] = ["o7", "GG!", "HELP!", "NICE!", "BRACE!"]
var _emote_idx := 0

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
	_head.position = Vector3(0, 1.65, 0)
	add_child(_head)

	_camera = Camera3D.new()
	_camera.current = true
	_camera.fov = 85.0
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
	if not is_on_floor():
		velocity.y -= _gravity * delta
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	var speed := walk_speed
	if Input.is_action_pressed("crouch"):
		speed = crouch_speed
	elif Input.is_action_pressed("sprint"):
		speed = sprint_speed

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var dir := (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	var target := dir * speed
	velocity.x = move_toward(velocity.x, target.x, accel * delta)
	velocity.z = move_toward(velocity.z, target.z, accel * delta)
	move_and_slide()

	_update_interaction()

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
