extends SceneTree
## Headless self-test for the procedural generator.
## Run: godot --headless --path . -s res://scenarios/scenario_selftest.gd
## Proves: (1) determinism (same seed -> identical), (2) variety across seeds.

func _init() -> void:
	var a := ScenarioGenerator.generate(12345, 2)
	var b := ScenarioGenerator.generate(12345, 2)
	var c := ScenarioGenerator.generate(99999, 2)

	assert(a.hash() == b.hash(), "FAIL: same seed must be deterministic")
	assert(a.hash() != c.hash(), "FAIL: different seeds should differ")
	print("[ok] determinism: same seed identical, different seeds differ")

	var signatures := {}
	for s in [101, 202, 303, 404, 505, 606]:
		var sc := ScenarioGenerator.generate(s, 2)
		var types := PackedStringArray()
		for e in sc["events"]:
			types.append(e["type"])
		signatures[", ".join(types) + "|" + sc["weather"] + "|" + sc["airport"]] = true
		print("seed %4d | wx=%-11s | apt=%-14s | %4ds | rows=%2d | tasks: %s" % [
			s, sc["weather"], sc["airport"], sc["time_limit"], sc["layout"]["rows"], ", ".join(types)])

	assert(signatures.size() >= 4, "FAIL: not enough variety across seeds")
	print("[ok] variety: %d distinct scenario signatures from 6 seeds" % signatures.size())
	print("ALL SELF-TESTS PASSED")
	quit(0)
