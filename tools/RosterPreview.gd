extends Node
## Dev-only: shows the lobby roster panel so its on-screen position can be verified.

func _ready() -> void:
	var cl := CanvasLayer.new()
	add_child(cl)
	var bg := ColorRect.new()
	bg.color = Color(0.1, 0.12, 0.16)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	cl.add_child(bg)
	add_child(preload("res://ui/NetLobbyPanel.gd").new())
