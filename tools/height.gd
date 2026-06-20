extends SceneTree
func _init() -> void:
	root_setup()
func root_setup() -> void:
	var inst: Node3D = (load(OS.get_environment("MODEL")) as PackedScene).instantiate()
	get_root().add_child(inst)
	var ap: AnimationPlayer = inst.find_child("AnimationPlayer", true, false)
	if ap and ap.has_animation("idle"):
		ap.play("idle"); ap.advance(0.5)
	await process_frame
	# combined global AABB of all mesh parts
	var out := AABB()
	var has := false
	for m in _meshes(inst):
		var a: AABB = m.get_aabb()                # local
		a = m.global_transform * a                 # to world
		out = out.merge(a) if has else a
		has = true
	print("HEIGHT at scale 1 = ", out.size.y, "  (min_y=", out.position.y, ")")
	quit()
func _meshes(n: Node) -> Array:
	var r: Array = []
	if n is MeshInstance3D and (n as MeshInstance3D).mesh != null: r.append(n)
	for c in n.get_children(): r += _meshes(c)
	return r
