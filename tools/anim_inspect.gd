extends SceneTree
## Dev-only: load a model and print its AnimationPlayer animations. Run:
##   godot --headless --path . -s res://tools/anim_inspect.gd
func _init() -> void:
	var path := OS.get_environment("MODEL")
	if path == "":
		path = "res://assets/models/crew/CesiumMan.glb"
	if not ResourceLoader.exists(path):
		print("MISSING: ", path); quit(2); return
	var inst := (load(path) as PackedScene).instantiate()
	var aps: Array = []
	_find(inst, aps)
	if aps.is_empty():
		print("NO AnimationPlayer in ", path); quit(3); return
	for ap: AnimationPlayer in aps:
		print("AnimationPlayer @ ", ap.get_path())
		for a in ap.get_animation_list():
			print("  anim: '", a, "'  len=", ap.get_animation(a).length)
	quit(0)

func _find(n: Node, out: Array) -> void:
	if n is AnimationPlayer:
		out.append(n)
	for c in n.get_children():
		_find(c, out)
