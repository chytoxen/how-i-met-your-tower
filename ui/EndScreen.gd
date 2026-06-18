extends Control
## Post-flight results. Reads GameState.last_result.

func _ready() -> void:
	if DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_build()

func _build() -> void:
	var r: Dictionary = GameState.last_result
	var success: bool = r.get("success", false)

	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.09, 0.06) if success else Color(0.12, 0.05, 0.05)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 12)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(cc)
	cc.add_child(v)

	var sabotage: bool = r.get("mode", "coop") == "saboteur"
	var title := Label.new()
	if sabotage:
		title.text = "CREW SURVIVED" if success else "SABOTEUR WINS"
	else:
		title.text = "WHEELS DOWN" if success else "MAYDAY LOST"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.modulate = Color(0.5, 1, 0.6) if success else Color(1, 0.5, 0.45)
	UI.title(title, 56)
	v.add_child(title)

	var grade := Label.new()
	grade.text = str(r.get("headline", ""))
	grade.add_theme_font_size_override("font_size", 28)
	grade.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(grade)

	var summary := Label.new()
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary.modulate = Color(0.8, 0.85, 0.9)
	summary.text = "%s · %s\nFailures handled: %d / %d   ·   Hull integrity: %d%%   ·   Tower: %s" % [
		String(r.get("weather", "")).capitalize(), String(r.get("airport", "")).capitalize(),
		r.get("fixed", 0), r.get("total", 0), r.get("integrity", 0),
		"contacted" if r.get("tower", false) else "never reached"]
	v.add_child(summary)

	if sabotage and str(r.get("saboteur", "")) != "":
		var reveal := Label.new()
		reveal.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		reveal.modulate = Color(1, 0.6, 0.4)
		reveal.text = "The saboteur was: %s" % r.get("saboteur", "")
		v.add_child(reveal)

	v.add_child(_spacer(24))
	v.add_child(_button("FLY ANOTHER", func() -> void: Audio.play("click"); GameState.start_single_match()))
	v.add_child(_button("RETURN TO TERMINAL", func() -> void: Audio.play("click"); GameState.goto_scene("res://world/Lobby.tscn")))
	v.add_child(_button("QUIT", func() -> void: get_tree().quit()))

	Audio.start_music("menu")
	Audio.play("success" if success else "fail", 2.0)

func _button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(300, 44)
	b.pressed.connect(cb)
	return b

func _spacer(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c
