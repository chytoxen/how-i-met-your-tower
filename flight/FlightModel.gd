class_name FlightModel
extends RefCounted
## Arcade flight simulation. The cabin interior is static; THIS is the "truth" of
## where the plane is — altitude, speed, descent, alignment, distance to the
## runway. The exterior rig and instruments visualize it. Unfixed failures feed
## in as penalties (less control authority, more wobble, drag, integrity loss),
## which is how cabin tasks affect the landing. Win = bring it down inside the
## envelope before integrity or the clock runs out.

const APPROACH_DISTANCE := 20000.0  # m: glide slope begins
const STALL_SPEED := 150.0          # kt
const VNE := 360.0                  # kt never-exceed
const GLIDE_TOP := 1100.0           # m: altitude at start of approach

var altitude := 1100.0   # m: start already near glide top so the slope is flyable
var airspeed := 280.0    # kt
var vspeed := 0.0        # m/s (+ = climb)
var heading := 0.0       # deg (0 = aligned)
var pitch := 2.0         # deg
var roll := 0.0          # deg
var throttle := 0.7      # 0..1
var distance := 30000.0  # m to threshold (~4.5 min flight at cruise)
var integrity := 1.0     # 0..1
var landed := false
var crashed := false

var _td := {}            # snapshot at touchdown

func update(delta: float, pitch_in: float, roll_in: float, throttle_in: float, penalties: Dictionary) -> void:
	if landed or crashed:
		return
	var authority: float = clampf(penalties.get("control", 1.0), 0.15, 1.0)
	var wobble: float = penalties.get("wobble", 0.0)
	var drag: float = penalties.get("drag", 0.0)
	var integ_rate: float = penalties.get("integrity_loss", 0.0)

	integrity = clampf(integrity - integ_rate * delta, 0.0, 1.0)
	if integrity <= 0.0:
		crashed = true
		return

	throttle = move_toward(throttle, clampf(throttle_in, 0.0, 1.0), delta * 0.6)
	var target_speed := 140.0 + throttle * 240.0 - drag * 70.0
	airspeed = move_toward(airspeed, target_speed, delta * 35.0)

	var noise := (randf() * 2.0 - 1.0) * wobble * 18.0
	var commanded_vs := pitch_in * authority * 14.0 + noise
	vspeed = move_toward(vspeed, commanded_vs, delta * 11.0)
	altitude = maxf(0.0, altitude + vspeed * delta)
	pitch = move_toward(pitch, pitch_in * 10.0, delta * 20.0)

	roll = move_toward(roll, roll_in * authority * 25.0 + noise, delta * 30.0)
	heading += roll * 0.04 * delta
	heading = clampf(heading, -45.0, 45.0)

	distance = maxf(0.0, distance - (airspeed * 0.514) * delta)  # kt -> m/s

	if airspeed < STALL_SPEED or airspeed > VNE:
		integrity = clampf(integrity - 0.03 * delta, 0.0, 1.0)

	if distance <= 0.0:
		landed = true
		_td = {"airspeed": airspeed, "vspeed": vspeed, "roll": roll, "heading": heading, "altitude": altitude}

func in_approach() -> bool:
	return distance <= APPROACH_DISTANCE

## Altitude the plane SHOULD be at right now to be on the glide slope.
func glide_target_alt() -> float:
	if distance > APPROACH_DISTANCE:
		return altitude
	return (distance / APPROACH_DISTANCE) * GLIDE_TOP

func result() -> Dictionary:
	if crashed:
		return {"success": false, "grade": "CRASH", "reasons": ["structural failure"]}
	if _td.is_empty():
		return {"success": false, "grade": "IN FLIGHT", "reasons": []}
	var reasons := []
	if _td["altitude"] > 60.0:
		reasons.append("overshot the runway")
	if _td["airspeed"] < 170.0 or _td["airspeed"] > 260.0:
		reasons.append("approach speed")
	if absf(_td["vspeed"]) > 6.0:
		reasons.append("descent rate")
	if absf(_td["roll"]) > 8.0:
		reasons.append("wings not level")
	if absf(_td["heading"]) > 6.0:
		reasons.append("runway alignment")
	var success: bool = reasons.is_empty() or (reasons.size() == 1 and absf(_td["vspeed"]) <= 9.0 and _td["altitude"] <= 60.0)
	var grade: String
	if reasons.is_empty():
		grade = "GREASED IT"
	elif success:
		grade = "HARD LANDING"
	else:
		grade = "OFF TARGET"
	return {"success": success, "grade": grade, "reasons": reasons}
