class_name AutoPilot
extends RefCounted
## Shared "talk-you-down" controller. Once the crew has CONTACTED THE TOWER, ATC
## guidance flies the glide slope using this. Its inputs are still subject to the
## aircraft's control authority (degraded by unfixed cockpit failures) inside
## FlightModel.update — so a damaged plane wobbles even with perfect guidance.
## A human pilot at the yoke can override/assist. PD + small integral kills the
## steady-state droop so a healthy approach lands clean.

var i_term := 0.0

func compute(fm: FlightModel) -> Dictionary:
	var alt_err := fm.glide_target_alt() - fm.altitude
	i_term = clampf(i_term + alt_err * 0.00006, -0.5, 0.5)
	var pitch_in := clampf(alt_err * 0.022 + i_term - fm.vspeed * 0.03, -1.0, 1.0)
	var roll_in := clampf(-fm.heading * 0.30 - fm.roll * 0.05, -1.0, 1.0)
	var throttle_in := clampf(fm.throttle + (215.0 - fm.airspeed) * 0.01, 0.0, 1.0)
	return {"pitch": pitch_in, "roll": roll_in, "throttle": throttle_in}
