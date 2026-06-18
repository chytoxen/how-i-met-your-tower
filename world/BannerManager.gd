class_name BannerManager
extends Node
## Easter egg: hangs the squad's photos as framed, spotlit banners around the
## terminal. Bundled photos must be named banner1.jpg, banner2.jpg, ... (loaded by
## EXPLICIT path — res:// directory scanning does NOT work in exported builds, which
## is why the frames were empty in the shipped game). Players can also drop images
## into a `banners/` folder next to the .exe at runtime. Falls back to tinted
## placeholders so the walls are never empty.

const EXTS := ["png", "jpg", "jpeg", "webp"]
const MAX_BANNERS := 32

func populate(parent: Node3D, anchors: Array) -> void:
	var textures := _load_textures()
	if OS.get_environment("CREW_DEBUG") != "":
		print("[banners] loaded %d image(s)" % textures.size())
	for i in anchors.size():
		var tex: Texture2D
		if textures.size() > 0:
			tex = textures[i % textures.size()]
		else:
			tex = _placeholder(i)
		_hang(parent, anchors[i], tex)

func _load_textures() -> Array:
	var out := []
	# Bundled banners: load by explicit path so it works in exported builds.
	for i in range(1, MAX_BANNERS + 1):
		for ext in EXTS:
			var path := "res://assets/banners/banner%d.%s" % [i, ext]
			if ResourceLoader.exists(path):
				var r = load(path)
				if r is Texture2D:
					out.append(r)
				break
	# Runtime banners dropped next to the .exe (real filesystem; scanning is fine).
	var dir := DirAccess.open("user://banners")
	if dir != null:
		dir.list_dir_begin()
		var f := dir.get_next()
		while f != "":
			if not dir.current_is_dir() and f.get_extension().to_lower() in EXTS:
				var t := _load_image_texture("user://banners/" + f)
				if t != null:
					out.append(t)
			f = dir.get_next()
		dir.list_dir_end()
	return out

func _load_image_texture(path: String) -> Texture2D:
	# Imported res:// images load directly; runtime user:// images go via Image.
	if ResourceLoader.exists(path):
		var r = load(path)
		if r is Texture2D:
			return r
	var img := Image.new()
	if img.load(path) == OK:
		return ImageTexture.create_from_image(img)
	return null

func _hang(parent: Node3D, anchor: Transform3D, tex: Texture2D) -> void:
	var root := Node3D.new()
	root.transform = anchor
	parent.add_child(root)

	var frame := MeshInstance3D.new()
	var fmesh := BoxMesh.new()
	fmesh.size = Vector3(2.2, 1.4, 0.08)
	frame.mesh = fmesh
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color(0.05, 0.05, 0.06)
	frame.material_override = fm
	root.add_child(frame)

	var pic := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(2.0, 1.2)
	pic.mesh = quad
	pic.position = Vector3(0, 0, 0.05)
	var pm := StandardMaterial3D.new()
	pm.albedo_texture = tex
	pm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	pm.roughness = 0.6
	pic.material_override = pm
	root.add_child(pic)

	var lamp := SpotLight3D.new()
	lamp.position = Vector3(0, 1.3, 1.4)
	lamp.rotation_degrees = Vector3(-48, 0, 0)
	lamp.light_energy = 2.2
	lamp.spot_range = 7.0
	lamp.spot_angle = 35.0
	root.add_child(lamp)

func _placeholder(i: int) -> Texture2D:
	var img := Image.create(256, 160, false, Image.FORMAT_RGB8)
	img.fill(Color.from_hsv(fmod(0.13 * i, 1.0), 0.35, 0.45))
	return ImageTexture.create_from_image(img)
