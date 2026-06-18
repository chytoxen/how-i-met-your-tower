class_name MatchHUD
extends CanvasLayer
## In-flight overlay: countdown, instruments, glide-slope cue, live objective list
## (the procedural failures), panic meter, tower status, and flash messages.

var _timer: Label
var _instr: Label
var _glide: Label
var _objectives: RichTextLabel
var _tower: Label
var _panic: ProgressBar
var _flash: Label

func setup(_scenario: Dictionary) -> void:
	_timer = _label(28, Control.PRESET_TOP_LEFT, Vector2(20, 16))
	_timer.modulate = Color(1, 0.9, 0.5)

	_instr = _label(18, Control.PRESET_TOP_RIGHT, Vector2(-230, 16))
	_instr.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	_glide = _label(22, Control.PRESET_CENTER_TOP, Vector2(0, 70))
	_glide.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	_objectives = RichTextLabel.new()
	_objectives.bbcode_enabled = true
	_objectives.fit_content = true
	_objectives.scroll_active = false
	_objectives.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT, Control.PRESET_MODE_MINSIZE, 20)
	_objectives.custom_minimum_size = Vector2(300, 220)
	_objectives.position.y -= 80
	add_child(_objectives)

	_tower = _label(18, Control.PRESET_BOTTOM_LEFT, Vector2(20, -70))
	_panic = ProgressBar.new()
	_panic.min_value = 0
	_panic.max_value = 1
	_panic.step = 0.01
	_panic.show_percentage = false
	_panic.custom_minimum_size = Vector2(240, 16)
	_panic.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, 20)
	_panic.position.y -= 40
	add_child(_panic)
	var pl := _label(14, Control.PRESET_BOTTOM_LEFT, Vector2(20, -58))
	pl.text = "CABIN PANIC"
	pl.modulate = Color(0.8, 0.8, 0.85)

	_flash = _label(24, Control.PRESET_CENTER_TOP, Vector2(0, 120))
	_flash.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_flash.modulate = Color(0.6, 0.9, 1.0, 0.0)

func update(fm: FlightModel, time_left: float, panic: float, tower: bool, stations: Array) -> void:
	_timer.text = "T-%02d:%02d" % [int(time_left) / 60, int(time_left) % 60]
	_instr.text = "ALT %4dm\nSPD %3dkt\nV/S %+0.1f\nDIST %4.1fkm\nHULL %3d%%" % [
		int(fm.altitude), int(fm.airspeed), fm.vspeed, fm.distance / 1000.0, int(fm.integrity * 100.0)]

	if not tower:
		_glide.text = "REACH THE TOWER — fix the radio up front"
		_glide.modulate = Color(1, 0.8, 0.3)
	elif fm.in_approach():
		var err := fm.altitude - fm.glide_target_alt()
		if err > 40.0:
			_glide.text = "ON APPROACH  ▲ TOO HIGH"
			_glide.modulate = Color(1, 0.6, 0.3)
		elif err < -40.0:
			_glide.text = "ON APPROACH  ▼ TOO LOW"
			_glide.modulate = Color(1, 0.6, 0.3)
		else:
			_glide.text = "ON APPROACH  ● ON GLIDE"
			_glide.modulate = Color(0.5, 1, 0.6)
	else:
		_glide.text = "ATC GUIDING YOU IN"
		_glide.modulate = Color(0.6, 0.9, 1.0)

	var lines := "[b]CHECKLIST[/b]\n"
	for st: TaskStation in stations:
		var obj_name := "MEET THE TOWER" if st.failure_type == "contact_tower" else st.pretty()
		var color := "#33ff55"
		var mark := "[x]"
		if not st.fixed:
			if st.critical:
				color = "#ff2222"
				mark = "[!]"
			elif st.step_index > 0:
				color = "#ffbb22"
				mark = "[~]"
			else:
				color = "#ff6644"
				mark = "[ ]"
		lines += "[color=%s]%s %s[/color]\n" % [color, mark, obj_name]
	_objectives.text = lines

	_tower.text = "TOWER: CONTACTED" if tower else "TOWER: NO CONTACT"
	_tower.modulate = Color(0.5, 1, 0.6) if tower else Color(1, 0.5, 0.4)
	_panic.value = panic
	_panic.modulate = Color(1, 0.4, 0.3) if panic > 0.6 else Color(0.9, 0.85, 0.4)

func flash(text: String) -> void:
	_flash.text = text
	_flash.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(2.5)
	tw.tween_property(_flash, "modulate:a", 0.0, 1.5)

func _label(font_size: int, preset: int, offset: Vector2) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", font_size)
	l.set_anchors_and_offsets_preset(preset, Control.PRESET_MODE_MINSIZE, 0)
	l.position += offset
	add_child(l)
	return l
