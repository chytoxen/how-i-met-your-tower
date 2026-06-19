extends Node
## GPU photo-tour for faithful previews on real hardware. Activated when a
## photo.json sits next to the executable (see MainMenu). Renders each requested
## camera shot through the MAIN window viewport on the GPU (the proven capture
## path), saves PNGs (+ a log naming the GPU) to out_dir, then quits. Mutes audio.
## Never runs in the shipped game (no photo.json there).

var _exe_dir: String

func _ready() -> void:
	_exe_dir = OS.get_executable_path().get_base_dir()
	print("[tour] start  exe_dir=", _exe_dir, "  device=", RenderingServer.get_video_adapter_name())
	DirAccess.make_dir_recursive_absolute(_exe_dir.path_join("shots"))
	_write(_exe_dir.path_join("shots/_started.txt"), "entered photo tour\n")
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), -80.0)
	var w := get_window()
	if w != null:
		w.size = Vector2i(1600, 900)
		# park the window offscreen so it doesn't flash on Noam's monitor
		DisplayServer.window_set_position(Vector2i(-2200, 80))
	_run.call_deferred()

func _process(_d: float) -> void:
	# instanced Lobby/Player grabs the mouse in _ready; keep it free during the tour
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _run() -> void:
	var cfg := _load_config()
	var out_dir: String = cfg.get("out_dir", _exe_dir.path_join("shots"))
	DirAccess.make_dir_recursive_absolute(out_dir)
	var lines: Array = ["DEVICE=" + RenderingServer.get_video_adapter_name()]
	for shot in cfg.get("shots", []):
		var nm := str(shot.get("name", "shot"))
		var ok := await _capture(shot, out_dir)
		print("[tour] ", nm, " -> ", ok)
		lines.append(nm + " -> " + ("ok" if ok else "FAIL"))
	_write(out_dir.path_join("_tour.log"), "\n".join(lines) + "\n")
	print("[tour] done")
	await get_tree().create_timer(0.2).timeout
	get_tree().quit()

func _capture(shot: Dictionary, out_dir: String) -> bool:
	var sp: String = shot.get("scene", "")
	if not ResourceLoader.exists(sp):
		return false
	var inst := (load(sp) as PackedScene).instantiate()
	add_child(inst)
	await get_tree().create_timer(0.7).timeout            # let the scene build + settle
	_hide_huds(inst)                                       # clean beauty shot, no UI overlay
	var cam := Camera3D.new()
	cam.fov = float(shot.get("fov", 70.0))
	var p: Array = shot.get("pos", [0, 2, 8])
	var l: Array = shot.get("look", [0, 1, 0])
	cam.position = Vector3(p[0], p[1], p[2])
	add_child(cam)
	cam.look_at(Vector3(l[0], l[1], l[2]), Vector3.UP)
	cam.current = true                                    # added last -> wins over the scene's camera
	await get_tree().create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	var ok := false
	var img := get_viewport().get_texture().get_image()
	if img != null:
		ok = img.save_png(out_dir.path_join(str(shot.get("name", "shot")) + ".png")) == OK
	inst.queue_free()
	cam.queue_free()
	await get_tree().process_frame
	return ok

func _hide_huds(n: Node) -> void:
	if n is CanvasLayer or n is Control:
		n.visible = false
	for c in n.get_children():
		_hide_huds(c)

func _load_config() -> Dictionary:
	var p := _exe_dir.path_join("photo.json")
	if FileAccess.file_exists(p):
		var j: Variant = JSON.parse_string(FileAccess.get_file_as_string(p))
		if typeof(j) == TYPE_DICTIONARY:
			return j
	return {"shots": [{"scene": "res://world/Lobby.tscn", "name": "lobby",
		"pos": [0, 1.7, 9], "look": [0, 4.5, -19]}]}

func _write(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f != null:
		f.store_string(text)
		f.close()
