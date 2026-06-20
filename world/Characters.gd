class_name Characters
extends RefCounted
## Curated Kenney "Blocky Characters" pools + a loader. Passengers draw from
## NORMAL (everyday folks); players pick from FUNNY (silly variants). Categorised
## by eye from a rendered contact sheet (tools/CharSheet).

# Everyday people — casual, business, a pilot/officer, a doctor.
const NORMAL := ["a", "b", "c", "e", "f", "i", "j", "k", "m", "p", "q"]
# Silly options for players: mascot, two robots, green monster, geisha, caveman, ninja.
const FUNNY := ["d", "g", "h", "l", "n", "o", "r"]
const FUNNY_NAMES := {
	"d": "The Mascot", "g": "Robo-Red", "h": "Robo-Blue", "l": "Swamp Thing",
	"n": "Geisha", "o": "Caveman", "r": "Ninja",
}

## Load a character GLB (matte, animated) and start `anim` looping. `id` is a
## letter a..r; unknown ids fall back to the first funny option.
static func make(id: String, anim := "idle") -> Node3D:
	if not _valid(id):
		id = FUNNY[0]
	var model: Node3D = (load("res://assets/models/kenney_chars/character-%s.glb" % id) as PackedScene).instantiate()
	var ap := find_anim(model)
	if ap != null and ap.has_animation(anim):
		ap.get_animation(anim).loop_mode = Animation.LOOP_LINEAR
		ap.play(anim)
	return model

static func _valid(id: String) -> bool:
	return id.length() == 1 and id >= "a" and id <= "r"

static func normal_for(seed_val: int) -> String:
	return NORMAL[absi(seed_val) % NORMAL.size()]

static func funny_for(seed_val: int) -> String:
	return FUNNY[absi(seed_val) % FUNNY.size()]

static func find_anim(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n
	for c in n.get_children():
		var r := find_anim(c)
		if r != null:
			return r
	return null
