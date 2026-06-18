extends CanvasLayer
## Pause overlay (Resume / Quit to Menu). Runs while the tree is paused, so it
## sets itself to ALWAYS. Opened by the player pressing the pause key in gameplay.

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 10
	get_tree().paused = true
	if DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_build()

func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 12)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(cc)
	cc.add_child(v)

	var title := Label.new()
	title.text = "PAUSED"
	title.add_theme_font_size_override("font_size", 44)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)

	v.add_child(_button("RESUME", _resume))
	v.add_child(_button("QUIT TO MENU", _quit_to_menu))

func _button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(280, 44)
	b.pressed.connect(cb)
	return b

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_resume()

func _resume() -> void:
	get_tree().paused = false
	if DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	queue_free()

func _quit_to_menu() -> void:
	get_tree().paused = false
	if Net.active:
		Net.leave()
	GameState.goto_scene("res://ui/MainMenu.tscn")
