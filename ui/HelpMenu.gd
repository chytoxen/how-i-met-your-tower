extends Control
## Detailed, scrollable in-game help: objective, controls (live from the current
## keybinds), how to play solo / co-op, and tips. Replaces the on-screen control
## hint labels. Reached from the main menu (and the pause menu).

func _ready() -> void:
	if DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_build()

func _key(action: String) -> String:
	return OS.get_keycode_string(Settings.binds.get(action, Settings.DEFAULT_BINDS.get(action, 0)))

func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.07, 0.11)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 30)
	root.add_theme_constant_override("separation", 12)
	add_child(root)

	var title := Label.new()
	title.text = "HOW TO PLAY"
	UI.title(title, 36)
	title.modulate = UI.ACCENT.lightened(0.2)
	root.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 6)
	scroll.add_child(col)

	_h(col, "THE MISSION")
	_p(col, "You are the flight crew of an airliner that's falling apart. Stabilise the failing systems, REACH THE TOWER (Air Traffic Control), and get talked down to a safe landing before the timer — or the hull — runs out. Every flight is different.")

	_h(col, "MOVEMENT")
	_kv(col, "Move", "%s / %s / %s / %s" % [_key("move_forward"), _key("move_left"), _key("move_back"), _key("move_right")])
	_kv(col, "Sprint", _key("sprint"))
	_kv(col, "Crouch", _key("crouch"))
	_kv(col, "Jump", _key("jump"))
	_kv(col, "Look", "Mouse")
	_kv(col, "Free cursor (lobby)", "%s — toggle look / click menus" % _key("pause"))

	_h(col, "ACTIONS")
	_kv(col, "Interact / work a task", "%s — look at a console and press to work each step" % _key("interact"))
	_kv(col, "Emote", _key("emote"))
	_kv(col, "Pause / cursor", _key("pause"))
	_kv(col, "Menu (in a flight)", "F1")

	_h(col, "VOICE CHAT")
	_kv(col, "Push-to-talk", "Hold %s (proximity — louder up close)" % _key("push_to_talk"))
	_kv(col, "Walkie-talkie", "Hold %s (whole crew hears you clearly)" % _key("walkie_talkie"))
	_p(col, "In Settings > Audio you can switch between PUSH-TO-TALK and OPEN MIC (voice-activated). Rebind any key in Settings > Controls.")

	_h(col, "SOLO")
	_p(col, "Main menu > PLAY (SOLO). Walk to the glowing DEPARTURES desk and interact to board a flight.")

	_h(col, "CO-OP (up to 4)")
	_p(col, "One player: MULTIPLAYER > HOST A FLIGHT, and share your IP. Same Wi-Fi works out of the box; over the internet the host forwards UDP port 24565 (or use Hamachi / ZeroTier). Everyone else: MULTIPLAYER > type the host's IP > JOIN. In the lobby, walk around, then READY UP — the host hits START FLIGHT.")

	_h(col, "THE FLIGHT")
	_p(col, "A checklist of failures appears (top-left). Run to each station and work its steps. SPLIT UP — you can't be everywhere at once.")
	_p(col, "FIX THE RADIO FIRST (\"MEET THE TOWER\") — that unlocks ATC guiding you down. Unfixed failures wreck your controls, add drag, and eat hull integrity; fires and decompression will bring you down if ignored.")
	_p(col, "Land inside the envelope (speed / descent rate / wings level / aligned with the runway) before the clock hits zero.")

	_h(col, "TIPS")
	_p(col, "• Each station type looks different — learn them: a valve is a fuel leak, an orange tank is decompression, levers are hydraulics, a panel is electrical.")
	_p(col, "• Customize your character in the main menu (CUSTOMIZE).")
	_p(col, "• Watch the timer and the hull bar — triage the most dangerous failures first.")

	var back := Button.new()
	back.text = "BACK"
	back.custom_minimum_size = Vector2(180, 42)
	back.pressed.connect(func() -> void:
		Audio.play("click")
		GameState.goto_scene("res://ui/MainMenu.tscn"))
	root.add_child(back)

func _h(parent: VBoxContainer, text: String) -> void:
	var s := Control.new(); s.custom_minimum_size = Vector2(0, 10); parent.add_child(s)
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 22)
	l.modulate = Color(1.0, 0.78, 0.35)
	parent.add_child(l)

func _p(parent: VBoxContainer, text: String) -> void:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(820, 0)
	l.modulate = Color(0.85, 0.88, 0.92)
	parent.add_child(l)

func _kv(parent: VBoxContainer, k: String, val: String) -> void:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	var lk := Label.new()
	lk.text = k
	lk.custom_minimum_size = Vector2(220, 0)
	lk.modulate = Color(0.7, 0.85, 1.0)
	h.add_child(lk)
	var lv := Label.new()
	lv.text = val
	lv.modulate = Color(0.92, 0.92, 0.92)
	h.add_child(lv)
	parent.add_child(h)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		GameState.goto_scene("res://ui/MainMenu.tscn")
