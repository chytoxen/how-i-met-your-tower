class_name TaskStation
extends Interactable
## One failure's repair console. Multi-step on purpose: each [E] advances one step
## of the fix chain, so a single failure ties a player up for a few seconds and a
## stack of them forces the crew to split up. A console with a status light and a
## floating label; goes critical if its fuse expires before it's fixed.

signal fixed_changed(station: TaskStation)

const PRETTY := {
	"engine_fire": "ENGINE FIRE", "hydraulics": "HYDRAULICS", "decompression": "DECOMPRESSION",
	"electrical": "ELECTRICAL", "gear_jam": "GEAR JAM", "fuel_leak": "FUEL LEAK",
	"cabin_smoke": "CABIN SMOKE", "bird_strike": "BIRD STRIKE",
}

# Each failure type gets a DISTINCT, recognisable station (CC0 Kenney models).
# m=model, s=scale, y=mount height, base=needs a pedestal under it (props), else
# the model is the whole console.
const STATIONS := {
	"engine_fire":   {"m": "kenney_factory/machine-fortified",      "s": 0.95, "y": 0.0, "base": false},
	"gear_jam":      {"m": "kenney_factory/machine",                "s": 0.95, "y": 0.0, "base": false},
	"cabin_smoke":   {"m": "kenney_factory/machine-window",         "s": 0.95, "y": 0.0, "base": false},
	"hydraulics":    {"m": "kenney_factory/lever-double",           "s": 1.7,  "y": 0.95, "base": true},
	"fuel_leak":     {"m": "kenney_factory/pipe-large-valve",       "s": 1.0,  "y": 1.0,  "base": true},
	"electrical":    {"m": "kenney_factory/screen-panel-wide",      "s": 1.3,  "y": 1.05, "base": true},
	"decompression": {"m": "kenney_survival/barrel",                "s": 3.2,  "y": 0.9,  "base": true},
	"bird_strike":   {"m": "kenney_survival/metal-panel-screws",    "s": 1.6,  "y": 1.05, "base": true},
}

var failure_type := ""
var zone := ""
var severity := 1
var role := ""
var steps: Array = []
var step_index := 0
var fixed := false
var fuse_total := 0.0
var fuse_remaining := 0.0
var critical := false
var net_handler := Callable()   # set by the match so fixes replicate over the network

var _light: MeshInstance3D
var _label: Label3D
var _light_mat: StandardMaterial3D
var _pulse := 0.0

func setup(event: Dictionary) -> void:
	failure_type = event["type"]
	zone = event["zone"]
	severity = int(event["severity"])
	role = event["role"]
	steps = (event["steps"] as Array).duplicate()
	fuse_total = float(event["fuse"])
	fuse_remaining = fuse_total

func _ready() -> void:
	_build_visual()
	_refresh()

func _build_visual() -> void:
	var spec: Dictionary = STATIONS.get(failure_type, {"m": "kenney_factory/machine", "s": 0.95, "y": 0.0, "base": false})

	# pedestal under "prop" stations (lever/valve/barrel/panel) so they sit at a
	# usable height and read as a console; machine-type stations stand on their own.
	if spec.get("base", false):
		var ped := MeshInstance3D.new()
		var pm := BoxMesh.new()
		pm.size = Vector3(0.95, 0.9, 0.7)
		ped.mesh = pm
		var pmat := StandardMaterial3D.new()
		pmat.albedo_color = Color(0.16, 0.17, 0.21)
		pmat.metallic = 0.2
		pmat.roughness = 0.6
		ped.material_override = pmat
		ped.position.y = 0.45
		add_child(ped)

	var model_path := "res://assets/models/%s.glb" % spec["m"]
	if ResourceLoader.exists(model_path):
		var model: Node3D = (load(model_path) as PackedScene).instantiate()
		var s: float = spec["s"]
		model.scale = Vector3(s, s, s)
		model.position.y = spec["y"]
		add_child(model)

	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.1, 1.5, 0.8)
	cs.shape = shape
	cs.position.y = 0.75
	add_child(cs)

	_light = MeshInstance3D.new()
	var lmesh := SphereMesh.new()
	lmesh.radius = 0.1
	lmesh.height = 0.2
	_light.mesh = lmesh
	_light_mat = StandardMaterial3D.new()
	_light_mat.emission_enabled = true
	_light.material_override = _light_mat
	_light.position = Vector3(0.42, 1.55, 0.0)
	add_child(_light)

	_label = Label3D.new()
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.no_depth_test = true
	_label.font_size = 48
	_label.pixel_size = 0.003
	_label.position = Vector3(0, 1.7, 0)
	_label.outline_size = 8
	add_child(_label)

func interact(_by: Node) -> void:
	# Always route through the handler — it decides advance (crew) vs re-break
	# (saboteur) vs nothing, and replicates it. Falls back to a local advance if
	# no handler is set.
	if net_handler.is_valid():
		net_handler.call(self)
	elif not fixed:
		advance_local()

func advance_local() -> void:
	if fixed:
		return
	step_index += 1
	Audio.play("beep")
	if step_index >= steps.size():
		fixed = true
		critical = false
		Audio.play("confirm")
		fixed_changed.emit(self)
	_refresh()

func rebreak_local() -> void:
	# Saboteur un-does a completed repair.
	fixed = false
	step_index = 0
	critical = false
	fuse_remaining = fuse_total
	Audio.play("deny")
	_refresh()

func tick_fuse(delta: float) -> void:
	if fixed or fuse_total <= 0.0:
		return
	fuse_remaining = maxf(0.0, fuse_remaining - delta)
	if fuse_remaining <= 0.0 and not critical:
		critical = true
		Audio.play("alarm")
	_refresh()

func _process(delta: float) -> void:
	if critical and not fixed:
		_pulse += delta * 6.0
		var b := 0.5 + 0.5 * sin(_pulse)
		if _light_mat != null:
			_light_mat.emission = Color(1, 0.1, 0.1) * (0.4 + b)

func pretty() -> String:
	return PRETTY.get(failure_type, failure_type.capitalize())

func _refresh() -> void:
	if _light_mat == null:
		return
	var color: Color
	if fixed:
		color = Color(0.2, 1.0, 0.3)
	elif critical:
		color = Color(1.0, 0.1, 0.1)
	elif step_index > 0:
		color = Color(1.0, 0.7, 0.1)
	else:
		color = Color(1.0, 0.3, 0.2)
	_light_mat.emission = color
	_light_mat.albedo_color = color

	if fixed:
		_label.text = "%s\n[ FIXED ]" % pretty()
		_label.modulate = Color(0.5, 1.0, 0.6)
		prompt = "%s — fixed" % pretty()
	else:
		var next_step := String(steps[step_index]).capitalize() if step_index < steps.size() else "?"
		var fuse_txt := ""
		if fuse_total > 0.0:
			fuse_txt = "  (%ds)" % int(fuse_remaining) if not critical else "  CRITICAL"
		_label.text = "%s%s\n%d/%d" % [pretty(), fuse_txt, step_index, steps.size()]
		_label.modulate = Color(1, 0.3, 0.3) if critical else Color(1, 0.8, 0.4)
		prompt = "FIX %s: %s  [E]" % [pretty(), next_step]
