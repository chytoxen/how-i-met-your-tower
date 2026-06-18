extends Node
## Headless end-to-end test of the auto-updater: point it at a manifest URL
## advertising a newer version and confirm it detects the update.
##   UPD_URL=http://127.0.0.1:8099/version.json godot --headless res://core/UpdaterTest.tscn

func _ready() -> void:
	var url := OS.get_environment("UPD_URL")
	Updater.update_available.connect(func(v: String, _u: String, _n: String) -> void:
		print("UPDATE DETECTED version=%s" % v)
		get_tree().quit(0))
	Updater.check(url)
	get_tree().create_timer(8.0).timeout.connect(func() -> void:
		print("NO UPDATE DETECTED has_update=%s" % Updater.has_update)
		get_tree().quit(1))
