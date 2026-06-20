extends SceneTree
func _init() -> void:
	var inst: Node = (load(OS.get_environment("MODEL")) as PackedScene).instantiate()
	_p(inst, 0)
	quit()
func _p(n: Node, d: int) -> void:
	var mesh := ""
	if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
		mesh = " [MESH surfaces=%d]" % (n as MeshInstance3D).mesh.get_surface_count()
	print("  ".repeat(d), n.name, " (", n.get_class(), ")", mesh)
	for c in n.get_children(): _p(c, d + 1)
