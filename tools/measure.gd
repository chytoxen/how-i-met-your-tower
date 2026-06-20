extends SceneTree
func _init() -> void:
	var inst: Node = (load(OS.get_environment("MODEL")) as PackedScene).instantiate()
	var a: AABB = _a(inst, Transform3D.IDENTITY)
	print("AABB size=", a.size, " min_y=", a.position.y)
	quit()
func _a(n: Node, x: Transform3D) -> AABB:
	var t: Transform3D = x
	if n is Node3D:
		t = x * (n as Node3D).transform
	var out: AABB = AABB()
	var has := false
	if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
		out = t * (n as MeshInstance3D).mesh.get_aabb()
		has = true
	for c in n.get_children():
		var s: AABB = _a(c, t)
		if s.size != Vector3.ZERO:
			out = (out.merge(s) if has else s)
			has = true
	return out
