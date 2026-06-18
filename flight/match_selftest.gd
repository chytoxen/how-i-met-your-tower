extends SceneTree
## End-to-end match logic: a disciplined crew (fix the flight-critical failures,
## contact the Tower) must WIN; a passive crew (do nothing) must LOSE. Exercises
## the real ScenarioGenerator + MatchRules + FlightModel + AutoPilot.
## Run: godot --headless --path . -s res://flight/match_selftest.gd

func _sim(do_fixes: bool, do_contact: bool) -> Dictionary:
	var sc := ScenarioGenerator.generate(424242, 3)   # 4 failures, hard
	var fm := FlightModel.new()
	var ap := AutoPilot.new()
	var failures: Array = []
	for e in sc["events"]:
		failures.append({"type": e["type"], "fixed": false, "critical": false, "rem": float(e["fuse"])})
	var tower := false
	var t := 0.0
	var steps := 0
	while not fm.landed and not fm.crashed and steps < 12000:
		var dt := 0.05
		t += dt
		steps += 1
		if do_contact and t > 5.0:
			tower = true
		if do_fixes and t > 9.0:
			for f in failures:
				f["fixed"] = true   # a competent crew works every failure on the board
		for f in failures:
			if not f["fixed"] and f["rem"] > 0.0:
				f["rem"] -= dt
				if f["rem"] <= 0.0:
					f["critical"] = true
		var pen := MatchRules.aggregate(failures)
		var pitch_in := 0.0
		var roll_in := 0.0
		var throttle_in := 0.55
		if tower:
			var inp := ap.compute(fm)
			pitch_in = inp["pitch"]
			roll_in = inp["roll"]
			throttle_in = inp["throttle"]
		fm.update(dt, pitch_in, roll_in, throttle_in, pen)
	var gear_ok := true
	for f in failures:
		if f["type"] == "gear_jam" and not f["fixed"]:
			gear_ok = false
	var res := fm.result()
	return {"success": bool(res["success"]) and gear_ok and not fm.crashed, "grade": res["grade"], "crashed": fm.crashed}

func _init() -> void:
	var good := _sim(true, true)
	var bad := _sim(false, false)
	print("disciplined crew -> success=%s grade=%s crashed=%s" % [good["success"], good["grade"], good["crashed"]])
	print("passive crew     -> success=%s grade=%s crashed=%s" % [bad["success"], bad["grade"], bad["crashed"]])
	if good["success"] and not bad["success"]:
		print("MATCH SELF-TEST PASSED")
		quit(0)
	else:
		push_error("MATCH SELF-TEST FAILED")
		print("MATCH SELF-TEST FAILED")
		quit(1)
