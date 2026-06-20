extends Node3D
## Dev-only: load a character GLB (MODEL env), play its 'idle' anim, auto-frame by
## its bounding box, neutral lighting. For judging downloaded character models.

func _ready() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.50, 0.54, 0.60)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.58, 0.64)
	env.ambient_light_energy = 0.5
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-38, -42, 0)
	sun.light_energy = 1.6
	add_child(sun)
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(12, 12)
	ground.mesh = pm
	ground.material_override = Mats.flat(Color(0.4, 0.43, 0.48), 0.9, 0.0)
	add_child(ground)

	var path := OS.get_environment("MODEL")
	var inst: Node3D = (load(path) as PackedScene).instantiate()
	add_child(inst)
	var ap := _find_anim(inst)
	if ap != null:
		var want := OS.get_environment("ANIM")
		if want == "":
			want = "idle"
		if ap.has_animation(want):
			ap.play(want)
		ap.advance(0.4)

	var aabb := _aabb(inst, Transform3D.IDENTITY)
	var center := aabb.position + aabb.size * 0.5
	var s := maxf(aabb.size.y, maxf(aabb.size.x, 0.6))
	var cam := Camera3D.new()
	cam.position = center + Vector3(s * 0.8, s * 0.25, s * 1.7)
	cam.look_at(center, Vector3.UP)
	cam.current = true
	add_child(cam)

func _find_anim(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n
	for c in n.get_children():
		var r := _find_anim(c)
		if r != null:
			return r
	return null

func _aabb(n: Node, xform: Transform3D) -> AABB:
	var t := xform
	if n is Node3D:
		t = xform * (n as Node3D).transform
	var out := AABB()
	var has := false
	if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
		out = t * (n as MeshInstance3D).mesh.get_aabb()
		has = true
	for c in n.get_children():
		var sub := _aabb(c, t)
		if sub.size != Vector3.ZERO:
			out = out.merge(sub) if has else sub
			has = true
	return out
