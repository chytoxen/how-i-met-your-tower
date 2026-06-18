extends Node
## Global UI theme — applied to the root so every Control (menus, HUD, dialogs)
## picks it up with no per-scene wiring. Rajdhani for body, Orbitron for titles,
## styled buttons/panels/inputs in the game's blue palette. Autoloaded as "UI".

var theme: Theme
var title_font: FontFile
var body_font: FontFile
var bold_font: FontFile

const ACCENT := Color(0.45, 0.78, 1.0)
const PANEL_BG := Color(0.09, 0.12, 0.17, 0.96)

func _ready() -> void:
	body_font = load("res://assets/fonts/Rajdhani.ttf")
	bold_font = load("res://assets/fonts/RajdhaniBold.ttf")
	title_font = load("res://assets/fonts/Orbitron.ttf")

	theme = Theme.new()
	theme.default_font = body_font
	theme.default_font_size = 18

	# Buttons
	theme.set_stylebox("normal", "Button", _sb(Color(0.13, 0.17, 0.24), ACCENT.darkened(0.35), 1))
	theme.set_stylebox("hover", "Button", _sb(Color(0.18, 0.27, 0.37), ACCENT, 1))
	theme.set_stylebox("pressed", "Button", _sb(Color(0.10, 0.30, 0.45), ACCENT, 2))
	theme.set_stylebox("focus", "Button", _sb(Color(0, 0, 0, 0), ACCENT, 2))
	theme.set_stylebox("disabled", "Button", _sb(Color(0.10, 0.11, 0.13), Color(0.2, 0.2, 0.22), 1))
	theme.set_font("font", "Button", bold_font)
	theme.set_font_size("font_size", "Button", 18)
	theme.set_color("font_color", "Button", Color(0.85, 0.92, 1.0))
	theme.set_color("font_hover_color", "Button", Color(1, 1, 1))
	theme.set_color("font_pressed_color", "Button", Color(1, 1, 1))
	theme.set_color("font_disabled_color", "Button", Color(0.4, 0.4, 0.45))

	# Panels
	theme.set_stylebox("panel", "PanelContainer", _sb(PANEL_BG, ACCENT.darkened(0.45), 1))
	theme.set_stylebox("panel", "Panel", _sb(PANEL_BG, ACCENT.darkened(0.45), 1))

	# Text inputs
	theme.set_stylebox("normal", "LineEdit", _sb(Color(0.07, 0.09, 0.13), ACCENT.darkened(0.35), 1))
	theme.set_stylebox("focus", "LineEdit", _sb(Color(0.07, 0.09, 0.13), ACCENT, 2))
	theme.set_color("font_color", "LineEdit", Color(0.9, 0.95, 1.0))
	theme.set_color("caret_color", "LineEdit", ACCENT)

	# Labels + tabs
	theme.set_color("font_color", "Label", Color(0.88, 0.92, 0.97))
	theme.set_font("font", "TabContainer", bold_font)

	get_tree().root.theme = theme

## Apply the Orbitron title font + size to a label (used by menu headers).
func title(label: Label, size := 48) -> void:
	label.add_theme_font_override("font", title_font)
	label.add_theme_font_size_override("font_size", size)

func _sb(bg: Color, border: Color, bw: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(6)
	sb.set_border_width_all(bw)
	sb.border_color = border
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	return sb
