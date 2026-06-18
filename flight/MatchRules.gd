class_name MatchRules
extends RefCounted
## Shared rules: how each unfixed failure degrades the aircraft. Lives here (not
## in Aircraft) so the match self-test exercises the EXACT same math the game runs.

const PEN := {
	"hydraulics": {"control": 0.45, "wobble": 0.40},
	"electrical": {"control": 0.25, "wobble": 0.20},
	"engine_fire": {"drag": 0.35, "integrity": 0.012},
	"fuel_leak": {"drag": 0.18, "integrity": 0.006},
	"bird_strike": {"drag": 0.22, "wobble": 0.15},
	"decompression": {"panic": 0.50, "integrity": 0.005},
	"cabin_smoke": {"panic": 0.35},
	"gear_jam": {},
}
const CRIT_INTEGRITY := 0.03

## failures: Array of {"type":String, "fixed":bool, "critical":bool}.
## Returns the penalty dict FlightModel.update expects.
static func aggregate(failures: Array) -> Dictionary:
	var control_loss := 0.0
	var wobble := 0.0
	var drag := 0.0
	var integ := 0.0
	var panic_drive := 0.0
	for f in failures:
		if f.get("fixed", false) or f.get("type", "") == "contact_tower":
			continue
		var p: Dictionary = PEN.get(f["type"], {})
		control_loss += p.get("control", 0.0)
		wobble += p.get("wobble", 0.0)
		drag += p.get("drag", 0.0)
		integ += p.get("integrity", 0.0)
		panic_drive += p.get("panic", 0.0)
		if f.get("critical", false):
			integ += CRIT_INTEGRITY
			panic_drive += 0.2
	return {
		"control": clampf(1.0 - control_loss, 0.15, 1.0),
		"wobble": wobble,
		"drag": drag,
		"integrity_loss": integ,
		"panic_drive": panic_drive,
	}

## A failure that affects flying (vs. one that only affects the cabin/panic).
static func is_flight_critical(failure_type: String) -> bool:
	return failure_type in ["hydraulics", "electrical", "engine_fire", "fuel_leak", "bird_strike", "gear_jam"]
