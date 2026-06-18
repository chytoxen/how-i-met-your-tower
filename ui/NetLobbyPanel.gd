extends CanvasLayer
## Shown in the lobby during a networked session: live roster, ready toggle, and
## (host only) the START button. Walk the airport while you wait; ready up to fly.

var _roster: RichTextLabel
var _mode_btn: Button
var _ready_btn: Button
var _start_btn: Button
var _is_ready := false

func _ready() -> void:
	var panel := PanelContainer.new()
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.offset_left = -300
	panel.offset_top = 16
	panel.offset_right = -16
	panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	panel.grow_vertical = Control.GROW_DIRECTION_END
	add_child(panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	v.custom_minimum_size = Vector2(260, 0)
	panel.add_child(v)

	var title := Label.new()
	title.text = "CREW"
	title.add_theme_font_size_override("font_size", 22)
	v.add_child(title)

	_roster = RichTextLabel.new()
	_roster.bbcode_enabled = true
	_roster.fit_content = true
	_roster.custom_minimum_size = Vector2(240, 110)
	v.add_child(_roster)

	_mode_btn = Button.new()
	_mode_btn.pressed.connect(func() -> void:
		Audio.play("click")
		Net.set_mode("saboteur" if Net.mode == "coop" else "coop"))
	v.add_child(_mode_btn)

	_ready_btn = Button.new()
	_ready_btn.text = "READY UP"
	_ready_btn.pressed.connect(_toggle_ready)
	v.add_child(_ready_btn)

	_start_btn = Button.new()
	_start_btn.text = "START FLIGHT"
	_start_btn.pressed.connect(func() -> void:
		Audio.play("confirm")
		Net.start_match(2))
	v.add_child(_start_btn)

	var leave := Button.new()
	leave.text = "LEAVE"
	leave.pressed.connect(func() -> void:
		Net.leave()
		GameState.goto_scene("res://ui/MainMenu.tscn"))
	v.add_child(leave)

	Net.roster_changed.connect(_refresh)
	Net.server_left.connect(func() -> void:
		Net.leave()
		GameState.goto_scene("res://ui/MainMenu.tscn"))
	_refresh()

func _toggle_ready() -> void:
	Audio.play("click")
	_is_ready = not _is_ready
	_ready_btn.text = "UNREADY" if _is_ready else "READY UP"
	Net.set_ready(_is_ready)

func _refresh() -> void:
	if _roster == null:
		return
	var txt := ""
	for id in Net.players:
		var info: Dictionary = Net.players[id]
		var mark := "[color=#33ff55]READY[/color]" if info.get("ready", false) else "[color=#ffaa44]…[/color]"
		var me := "  (you)" if id == Net.local_id() else ""
		txt += "%s%s  %s\n" % [info.get("callsign", "Crew"), me, mark]
	_roster.text = txt
	_mode_btn.text = "MODE: %s" % ("SABOTEUR" if Net.mode == "saboteur" else "CO-OP")
	_mode_btn.disabled = not Net.is_host
	_start_btn.visible = Net.is_host
	_start_btn.disabled = not Net.all_ready()
