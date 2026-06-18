extends Control
## Main menu. Built in code for reliability; restyled with real fonts/art in
## Phase 2. Title intentionally kept: "the Tower" is Air Traffic Control.

var _update_shown := false

func _ready() -> void:
	if DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		Audio.start_music("menu")
	_build_ui()
	_check_update()

func _check_update() -> void:
	if Updater.has_update:
		_show_update(Updater.update_version, Updater.update_url, "")
	Updater.update_available.connect(_show_update)

func _show_update(version: String, url: String, _notes: String) -> void:
	if _update_shown:
		return
	_update_shown = true
	var b := Button.new()
	b.text = "● Update v%s available — Download" % version
	b.modulate = Color(0.6, 1.0, 0.7)
	b.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE, Control.PRESET_MODE_MINSIZE, 8)
	b.pressed.connect(func() -> void:
		if url != "":
			OS.shell_open(url))
	add_child(b)

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.07, 0.11)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := VBoxContainer.new()
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_theme_constant_override("separation", 12)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(cc)
	cc.add_child(center)

	var title := Label.new()
	title.text = "HOW I MET YOUR TOWER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.modulate = UI.ACCENT.lightened(0.2)
	UI.title(title, 44)
	center.add_child(title)

	var sub := Label.new()
	sub.text = "Co-op aviation emergency  ·  Reach the Tower  ·  Land alive"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.modulate = Color(0.7, 0.8, 0.9)
	center.add_child(sub)

	center.add_child(_spacer(24))
	center.add_child(_menu_button("PLAY (SOLO)", _on_play))
	center.add_child(_menu_button("MULTIPLAYER", _on_multiplayer))
	center.add_child(_menu_button("CUSTOMIZE", _on_customize))
	center.add_child(_menu_button("SETTINGS", _on_settings))
	center.add_child(_menu_button("QUIT", _on_quit))

	var ver := Label.new()
	ver.text = "v%s" % Updater.CURRENT_VERSION
	ver.modulate = Color(0.5, 0.5, 0.6)
	ver.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, 12)
	add_child(ver)

func _menu_button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(280, 44)
	b.pressed.connect(func() -> void:
		Audio.play("click")
		cb.call())
	return b

func _spacer(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c

# --- actions -----------------------------------------------------------------

func _on_play() -> void:
	GameState.goto_scene("res://world/Lobby.tscn")

func _on_multiplayer() -> void:
	GameState.goto_scene("res://ui/MultiplayerMenu.tscn")

func _on_settings() -> void:
	GameState.goto_scene("res://ui/SettingsMenu.tscn")

func _on_quit() -> void:
	get_tree().quit()

func _on_customize() -> void:
	var dlg := AcceptDialog.new()
	dlg.title = "Customize Crew Member"

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)

	var name_edit := LineEdit.new()
	name_edit.text = GameState.profile["callsign"]
	name_edit.placeholder_text = "Callsign / gamertag"
	name_edit.max_length = 16
	vb.add_child(_labeled("Callsign", name_edit))

	var suit := ColorPickerButton.new()
	suit.color = GameState.profile["suit_color"]
	suit.custom_minimum_size = Vector2(120, 32)
	vb.add_child(_labeled("Suit color", suit))

	var trim := ColorPickerButton.new()
	trim.color = GameState.profile["trim_color"]
	trim.custom_minimum_size = Vector2(120, 32)
	vb.add_child(_labeled("Trim color", trim))

	dlg.add_child(vb)
	dlg.confirmed.connect(func() -> void:
		GameState.set_callsign(name_edit.text)
		GameState.profile["suit_color"] = suit.color
		GameState.profile["trim_color"] = trim.color
		GameState.save_profile())
	add_child(dlg)
	dlg.popup_centered(Vector2i(380, 240))

func _labeled(text: String, control: Control) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	var l := Label.new()
	l.text = text
	l.custom_minimum_size = Vector2(110, 0)
	h.add_child(l)
	h.add_child(control)
	return h

func _play_menu_music() -> void:
	var path := _first_audio("res://assets/audio/music")
	if path == "":
		return
	var stream = load(path)
	if stream == null:
		return
	var pl := AudioStreamPlayer.new()
	pl.stream = stream
	pl.bus = "Music"
	pl.autoplay = true
	add_child(pl)

func _first_audio(dir_path: String) -> String:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return ""
	dir.list_dir_begin()
	var f := dir.get_next()
	while f != "":
		if not dir.current_is_dir() and f.get_extension().to_lower() in ["ogg", "mp3", "wav"]:
			dir.list_dir_end()
			return dir_path + "/" + f
		f = dir.get_next()
	dir.list_dir_end()
	return ""
