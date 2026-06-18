extends Node
## Temporary main scene used only to verify banner loading inside a PACKED export
## (the bug that shipped empty frames). Loads banners the same way the lobby does
## and reports the count, then quits.

func _ready() -> void:
	var bm := BannerManager.new()
	add_child(bm)
	var n: int = bm._load_textures().size()
	print("BANNER_EXPORT_TEST loaded=%d" % n)
	get_tree().quit(0 if n >= 5 else 1)
