extends Control
## Functional settings: Audio / Graphics / Controls. Every control writes through
## the Settings autoload, which applies live and persists to user://settings.cfg.

var _rebinding_action := ""
var _rebind_button: Button = null

func _ready() -> void:
	if DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_build()

func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.07, 0.11)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 28)
	root.add_theme_constant_override("separation", 14)
	add_child(root)

	var title := Label.new()
	title.text = "SETTINGS"
	title.add_theme_font_size_override("font_size", 36)
	root.add_child(title)

	var tabs := TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(tabs)
	tabs.add_child(_audio_tab())
	tabs.add_child(_graphics_tab())
	tabs.add_child(_controls_tab())

	var back := Button.new()
	back.text = "BACK"
	back.custom_minimum_size = Vector2(160, 40)
	back.pressed.connect(func() -> void: GameState.goto_scene("res://ui/MainMenu.tscn"))
	root.add_child(back)

func _audio_tab() -> Control:
	var v := VBoxContainer.new()
	v.name = "Audio"
	v.add_theme_constant_override("separation", 12)
	for bus in Settings.BUSES:
		var s := HSlider.new()
		s.min_value = 0.0
		s.max_value = 1.0
		s.step = 0.01
		s.value = Settings.audio_volumes[bus]
		s.custom_minimum_size = Vector2(260, 0)
		s.value_changed.connect(func(val: float) -> void: Settings.set_volume(bus, val))
		v.add_child(_row(bus, s))
	return v

func _graphics_tab() -> Control:
	var v := VBoxContainer.new()
	v.name = "Graphics"
	v.add_theme_constant_override("separation", 12)

	var fs := CheckBox.new()
	fs.text = "Fullscreen"
	fs.button_pressed = Settings.video["fullscreen"]
	fs.toggled.connect(func(p: bool) -> void: Settings.set_video("fullscreen", p))
	v.add_child(fs)

	var vs := CheckBox.new()
	vs.text = "VSync"
	vs.button_pressed = Settings.video["vsync"]
	vs.toggled.connect(func(p: bool) -> void: Settings.set_video("vsync", p))
	v.add_child(vs)

	var msaa := OptionButton.new()
	for t in ["Off", "2x", "4x", "8x"]:
		msaa.add_item(t)
	msaa.selected = Settings.video["msaa"]
	msaa.item_selected.connect(func(i: int) -> void: Settings.set_video("msaa", i))
	v.add_child(_row("Anti-aliasing (MSAA)", msaa))

	var rs := HSlider.new()
	rs.min_value = 0.5
	rs.max_value = 1.0
	rs.step = 0.05
	rs.value = Settings.video["render_scale"]
	rs.custom_minimum_size = Vector2(260, 0)
	rs.value_changed.connect(func(val: float) -> void: Settings.set_video("render_scale", val))
	v.add_child(_row("Render scale (FSR2 below 1.0)", rs))

	var sh := OptionButton.new()
	for t in ["Off", "Low", "Medium", "High"]:
		sh.add_item(t)
	sh.selected = Settings.video["shadow_quality"]
	sh.item_selected.connect(func(i: int) -> void: Settings.set_video("shadow_quality", i))
	v.add_child(_row("Shadow quality", sh))

	return v

func _controls_tab() -> Control:
	var v := VBoxContainer.new()
	v.name = "Controls"
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var inner := VBoxContainer.new()
	inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.add_theme_constant_override("separation", 6)
	sc.add_child(inner)
	v.add_child(sc)
	for action in Settings.DEFAULT_BINDS.keys():
		var b := Button.new()
		b.custom_minimum_size = Vector2(180, 0)
		b.text = OS.get_keycode_string(Settings.binds.get(action, Settings.DEFAULT_BINDS[action]))
		b.pressed.connect(func() -> void: _start_rebind(action, b))
		inner.add_child(_row(String(action).capitalize(), b))
	return v

func _start_rebind(action: String, button: Button) -> void:
	_rebinding_action = action
	_rebind_button = button
	button.text = "press a key..."

func _input(event: InputEvent) -> void:
	if _rebinding_action == "":
		return
	var key_event := event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return
	var kc := key_event.physical_keycode
	Settings.set_bind(_rebinding_action, kc)
	if _rebind_button != null:
		_rebind_button.text = OS.get_keycode_string(kc)
	_rebinding_action = ""
	_rebind_button = null
	get_viewport().set_input_as_handled()

func _row(text: String, control: Control) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	var l := Label.new()
	l.text = text
	l.custom_minimum_size = Vector2(220, 0)
	h.add_child(l)
	h.add_child(control)
	return h
