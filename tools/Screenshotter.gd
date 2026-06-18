extends Node
## Dev tool: render a scene offscreen and save a PNG, so visuals can be verified
## on a headless box (via xvfb + GL). Not shipped (tools/ is export-excluded if
## desired). Usage:
##   SHOT_SCENE=res://ui/MainMenu.tscn SHOT_OUT=/tmp/x.png \
##   xvfb-run -a godot --path . --rendering-method gl_compatibility res://tools/Screenshotter.tscn

func _ready() -> void:
	var scene_path := OS.get_environment("SHOT_SCENE")
	var out := OS.get_environment("SHOT_OUT")
	if scene_path == "" or out == "":
		get_tree().quit(1)
		return
	var ps: Variant = load(scene_path)
	if ps == null:
		push_error("Screenshotter: could not load " + scene_path)
		get_tree().quit(1)
		return
	add_child(ps.instantiate())
	var wait := float(OS.get_environment("SHOT_WAIT")) if OS.get_environment("SHOT_WAIT") != "" else 1.5
	await get_tree().create_timer(wait).timeout
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(out)
	print("SHOT_SAVED %s (%dx%d)" % [out, img.get_width(), img.get_height()])
	get_tree().quit(0)
