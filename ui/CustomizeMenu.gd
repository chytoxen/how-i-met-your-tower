extends Control
## Character customization: pick your (funny) crew character with a live rotating
## 3D preview, set your callsign + accent color. Saved to the profile and sent to
## other players over the network. Reached from the main menu.

var _idx := 0
var _holder: Node3D
var _name_lbl: Label
var _viewport: SubViewport

func _ready() -> void:
	if DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_idx = maxi(0, Characters.FUNNY.find(GameState.profile.get("character", "r")))
	_build()

func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.07, 0.11)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := VBoxContainer.new()
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_theme_constant_override("separation", 10)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(cc)
	cc.add_child(center)

	var title := Label.new()
	title.text = "CUSTOMIZE YOUR CREW MEMBER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.title(title, 32)
	title.modulate = UI.ACCENT.lightened(0.2)
	center.add_child(title)

	# --- live 3D preview in a SubViewport ---
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(360, 380)
	_viewport.transparent_bg = true
	_viewport.own_world_3d = true
	_viewport.msaa_3d = Viewport.MSAA_4X
	var world := Node3D.new()
	_viewport.add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, -40, 0)
	sun.light_energy = 1.6
	world.add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-10, 150, 0)
	fill.light_energy = 0.5
	fill.light_color = Color(0.7, 0.8, 1.0)
	world.add_child(fill)
	_holder = Node3D.new()
	world.add_child(_holder)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 1.35, 4.4)
	cam.look_at(Vector3(0, 1.05, 0), Vector3.UP)
	cam.fov = 40.0
	cam.current = true
	world.add_child(cam)

	var svc := SubViewportContainer.new()
	svc.stretch = true
	svc.custom_minimum_size = Vector2(360, 380)
	svc.add_child(_viewport)

	# arrows on either side of the preview
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	row.add_child(_arrow("◀", -1))
	row.add_child(svc)
	row.add_child(_arrow("▶", 1))
	center.add_child(row)

	_name_lbl = Label.new()
	_name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_lbl.modulate = Color(1.0, 0.85, 0.4)
	UI.title(_name_lbl, 24)
	center.add_child(_name_lbl)

	center.add_child(_spacer(8))
	var name_edit := LineEdit.new()
	name_edit.name = "CallsignEdit"
	name_edit.text = GameState.profile["callsign"]
	name_edit.placeholder_text = "Callsign / gamertag"
	name_edit.max_length = 16
	name_edit.custom_minimum_size = Vector2(260, 36)
	name_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(name_edit)

	center.add_child(_spacer(12))
	var save := Button.new()
	save.text = "SAVE & BACK"
	save.custom_minimum_size = Vector2(260, 44)
	save.pressed.connect(func() -> void:
		Audio.play("confirm")
		GameState.set_character(Characters.FUNNY[_idx])
		GameState.set_callsign(name_edit.text)
		GameState.goto_scene("res://ui/MainMenu.tscn"))
	center.add_child(save)

	_refresh()

func _arrow(glyph: String, dir: int) -> Control:
	var wrap := CenterContainer.new()
	wrap.custom_minimum_size = Vector2(64, 380)
	var b := Button.new()
	b.text = glyph
	b.custom_minimum_size = Vector2(56, 72)
	b.add_theme_font_size_override("font_size", 28)
	b.pressed.connect(func() -> void:
		Audio.play("click")
		_idx = wrapi(_idx + dir, 0, Characters.FUNNY.size())
		_refresh())
	wrap.add_child(b)
	return wrap

func _refresh() -> void:
	for c in _holder.get_children():
		c.queue_free()
	var id: String = Characters.FUNNY[_idx]
	var model := Characters.make(id, "idle")
	_holder.add_child(model)
	_name_lbl.text = "%s   (%d/%d)" % [Characters.FUNNY_NAMES.get(id, id), _idx + 1, Characters.FUNNY.size()]

func _process(delta: float) -> void:
	if _holder != null:
		_holder.rotation.y += delta * 0.8   # slow turntable

func _spacer(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		GameState.goto_scene("res://ui/MainMenu.tscn")
