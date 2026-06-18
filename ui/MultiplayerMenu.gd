extends Control
## Host a server or join one by IP. Host = your machine becomes the listen-server
## ("anyone can host"). On a successful connection we drop into the networked lobby.

var _ip: LineEdit
var _port: LineEdit
var _status: Label

func _ready() -> void:
	if DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_build()
	Net.connected.connect(_on_connected)
	Net.connection_failed.connect(func() -> void: _set_status("Could not reach that host."))

func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.07, 0.11)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_CENTER)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 12)
	add_child(v)

	var title := Label.new()
	title.text = "MULTIPLAYER"
	title.add_theme_font_size_override("font_size", 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)

	v.add_child(_button("HOST A FLIGHT", _on_host))

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	_ip = LineEdit.new()
	_ip.text = "127.0.0.1"
	_ip.placeholder_text = "host IP"
	_ip.custom_minimum_size = Vector2(180, 40)
	row.add_child(_ip)
	_port = LineEdit.new()
	_port.text = str(Net.DEFAULT_PORT)
	_port.custom_minimum_size = Vector2(90, 40)
	row.add_child(_port)
	v.add_child(row)
	v.add_child(_button("JOIN", _on_join))

	_status = Label.new()
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.modulate = Color(1, 0.8, 0.5)
	v.add_child(_status)

	v.add_child(_spacer(16))
	v.add_child(_button("BACK", func() -> void: GameState.goto_scene("res://ui/MainMenu.tscn")))

func _on_host() -> void:
	Audio.play("click")
	var err := Net.host(_port_value())
	if err == OK:
		GameState.goto_scene("res://world/Lobby.tscn")
	else:
		_set_status("Host failed (port in use?) — code %d" % err)

func _on_join() -> void:
	Audio.play("click")
	_set_status("Connecting…")
	var err := Net.join(_ip.text.strip_edges(), _port_value())
	if err != OK:
		_set_status("Join failed — code %d" % err)

func _on_connected() -> void:
	GameState.goto_scene("res://world/Lobby.tscn")

func _port_value() -> int:
	var p := int(_port.text)
	return p if p > 0 else Net.DEFAULT_PORT

func _set_status(t: String) -> void:
	if _status != null:
		_status.text = t

func _button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(300, 42)
	b.pressed.connect(cb)
	return b

func _spacer(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c
