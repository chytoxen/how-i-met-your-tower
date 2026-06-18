extends Node
## Temporary main scene used only to verify SHIPPED assets load inside a PACKED
## export (banners, CC0 textures, real music) — the things that fail in packs but
## work in the editor. Reports counts/flags, then quits.

func _ready() -> void:
	var bm := BannerManager.new()
	add_child(bm)
	var banners: int = bm._load_textures().size()
	var tex_ok := ResourceLoader.exists("res://assets/textures/floor_color.jpg")
	var music_ok := ResourceLoader.exists("res://assets/audio/music/menu.mp3") \
		or ResourceLoader.exists("res://assets/audio/music/flight.mp3")
	print("PACKED_ASSET_TEST banners=%d texture=%s music=%s" % [banners, tex_ok, music_ok])
	get_tree().quit(0 if (banners >= 5 and tex_ok and music_ok) else 1)
