extends Node
## Launch-time update check. On startup it fetches a small JSON manifest you
## publish; if it advertises a newer version than this build, the main menu shows
## a banner with a one-click download. Fails silently with no network / no URL.
## Autoloaded as "Updater".
##
## Publish flow (see UPDATING.md): host a manifest like
##   { "version": "0.3.0", "url": "https://github.com/you/.../releases/latest",
##     "notes": "What changed" }
## and set MANIFEST_URL below (or it stays disabled).

signal update_available(version: String, url: String, notes: String)

const CURRENT_VERSION := "0.10.0"
const MANIFEST_URL := "https://raw.githubusercontent.com/chytoxen/how-i-met-your-tower/main/version.json"

var has_update := false
var update_version := ""
var update_url := ""
var update_notes := ""

func _ready() -> void:
	if MANIFEST_URL == "":
		return
	check()

func check(url := MANIFEST_URL) -> void:
	if url == "":
		return
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_done.bind(http))
	if http.request(url) != OK:
		http.queue_free()

func _on_done(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray, http: HTTPRequest) -> void:
	http.queue_free()
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		return
	var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var ver: String = parsed.get("version", "")
	if _is_newer(ver, CURRENT_VERSION):
		has_update = true
		update_version = ver
		update_url = parsed.get("url", "")
		update_notes = parsed.get("notes", "")
		update_available.emit(update_version, update_url, update_notes)

func _is_newer(a: String, b: String) -> bool:
	var x := _semver(a)
	var y := _semver(b)
	for i in 3:
		if x[i] != y[i]:
			return x[i] > y[i]
	return false

func _semver(v: String) -> Array:
	var out: Array = []
	for p in v.split("."):
		out.append(int(p))
	while out.size() < 3:
		out.append(0)
	return out
