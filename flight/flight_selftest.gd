extends SceneTree
## Proves the emergency is winnable: a simple stabilizing controller flying the
## glide slope must land cleanly with no failures, and must struggle (crash or
## bad grade) under heavy unfixed-failure penalties.
## Run: godot --headless --path . -s res://flight/flight_selftest.gd
## Always quits (never hangs) so buffered output flushes.

func _fly(penalties: Dictionary) -> Dictionary:
	var fm := FlightModel.new()
	var ap := AutoPilot.new()
	var steps := 0
	while not fm.landed and not fm.crashed and steps < 12000:
		var dt := 0.05
		var inp := ap.compute(fm)
		fm.update(dt, inp["pitch"], inp["roll"], inp["throttle"], penalties)
		steps += 1
	var r := fm.result()
	r["steps"] = steps
	r["alt"] = fm.altitude
	return r

func _init() -> void:
	var clean := _fly({})
	print("clean   -> success=%s grade=%s steps=%d touchdown_alt=%.0f reasons=%s" % [
		clean["success"], clean["grade"], clean["steps"], clean["alt"], clean["reasons"]])
	var wrecked := _fly({"control": 0.2, "wobble": 0.9, "drag": 0.6, "integrity_loss": 0.02})
	print("wrecked -> success=%s grade=%s steps=%d reasons=%s" % [
		wrecked["success"], wrecked["grade"], wrecked["steps"], wrecked["reasons"]])

	var ok := bool(clean["success"]) and not bool(wrecked["success"])
	if ok:
		print("ALL FLIGHT SELF-TESTS PASSED")
		quit(0)
	else:
		push_error("FLIGHT SELF-TEST FAILED (clean must land, wrecked must not)")
		print("FLIGHT SELF-TEST FAILED")
		quit(1)
