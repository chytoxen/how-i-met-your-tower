class_name ScenarioGenerator
extends RefCounted
## Procedurally builds a unique emergency per match from a single seed.
##
## Design goal (per the brief): every game the MAP and the TASKS differ.
##   - TASKS differ: a different set of system failures is drawn, each with a
##     multi-step fix chain that forces cockpit + cabin to split the work.
##   - MAP differs: cabin layout (row count, galley side, item spawns, a jammed
##     exit) + destination airport + weather are reshuffled.
##
## Fully DETERMINISTIC from the seed, so a host can broadcast one int and every
## client builds the identical match. Same seed -> identical scenario.

## Each failure: where it lives, how dangerous, how long until it goes critical
## (fuse 0.0 = persistent/no countdown), its ordered fix steps, and the crew
## role best suited to it. Steps are intentionally multi-stage so one player
## can't solo it under pressure.
const FAILURES := {
	"engine_fire":   {"zone": "wing",    "severity": 3, "fuse": 120.0, "steps": ["pull_fire_handle", "cut_fuel_to_engine", "arm_bottle", "discharge_bottle"], "role": "engineer"},
	"hydraulics":    {"zone": "cockpit", "severity": 3, "fuse": 0.0,   "steps": ["switch_to_backup_pump", "manual_trim", "stabilize_yoke"], "role": "pilot"},
	"decompression": {"zone": "cabin",   "severity": 2, "fuse": 60.0,  "steps": ["deploy_masks", "seal_breach", "descend_to_10k"], "role": "purser"},
	"electrical":    {"zone": "cockpit", "severity": 2, "fuse": 0.0,   "steps": ["shed_load", "reset_breakers", "switch_to_battery"], "role": "engineer"},
	"gear_jam":      {"zone": "belly",   "severity": 2, "fuse": 0.0,   "steps": ["pull_manual_release", "crank_gear_down", "confirm_three_green"], "role": "engineer"},
	"fuel_leak":     {"zone": "wing",    "severity": 3, "fuse": 180.0, "steps": ["isolate_tank", "crossfeed_balance", "calc_remaining_range"], "role": "pilot"},
	"cabin_smoke":   {"zone": "cabin",   "severity": 1, "fuse": 90.0,  "steps": ["find_source", "extinguish", "ventilate"], "role": "purser"},
	"bird_strike":   {"zone": "wing",    "severity": 2, "fuse": 0.0,   "steps": ["assess_damage", "reduce_airspeed", "feather_prop"], "role": "pilot"},
}

const WEATHERS := ["clear_day", "clear_night", "storm", "fog", "crosswind", "icing"]
const HARD_WEATHER := ["storm", "fog", "icing"]
const AIRPORTS := ["coastal_short", "mountain_valley", "city_river", "desert_long", "island_strip"]
const ITEMS := ["extinguisher_fwd", "extinguisher_aft", "toolkit", "medkit", "ops_manual"]

## Build a complete, deterministic match descriptor.
static func generate(seed_value: int, difficulty: int = 1) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value

	# --- tasks: draw N failures, stagger their onset so they cascade ---
	var pool := _shuffled(FAILURES.keys(), rng)
	var count: int = clampi(1 + difficulty, 1, 4)
	var events := []
	var t := 0.0
	for f in pool.slice(0, count):
		var info: Dictionary = FAILURES[f]
		t += rng.randf_range(0.0, 25.0)
		events.append({
			"type": f,
			"zone": info["zone"],
			"severity": info["severity"],
			"onset": roundi(t),
			"fuse": info["fuse"],
			"steps": (info["steps"] as Array).duplicate(),
			"role": info["role"],
		})

	# --- map: weather, destination, cabin layout ---
	var weather: String = WEATHERS[rng.randi() % WEATHERS.size()]
	var airport: String = AIRPORTS[rng.randi() % AIRPORTS.size()]

	var severity_total := 0
	for e in events:
		severity_total += int(e["severity"])

	var time_limit := 300.0 + 90.0 * count
	if weather in HARD_WEATHER:
		time_limit += 120.0

	var layout := {
		"rows": rng.randi_range(12, 24),
		"galley_side": ("left" if rng.randf() < 0.5 else "right"),
		"item_spawns": _shuffled(ITEMS, rng),
		"blocked_exit": rng.randi_range(0, 3),   # which exit is jammed (co-op reroute)
		"aisle_fire_row": rng.randi_range(3, 18),
	}

	return {
		"seed": seed_value,
		"difficulty": difficulty,
		"events": events,
		"weather": weather,
		"airport": airport,
		"time_limit": roundi(time_limit),
		"severity_total": severity_total,
		"layout": layout,
		"objective": "Stabilize the aircraft, reach the Tower, and land before the timer runs out.",
	}

## Deterministic Fisher-Yates using the supplied RNG (Array.shuffle() would use
## the GLOBAL rng and break seed determinism, so we roll our own).
static func _shuffled(arr: Array, rng: RandomNumberGenerator) -> Array:
	var a := arr.duplicate()
	for i in range(a.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = a[i]
		a[i] = a[j]
		a[j] = tmp
	return a
