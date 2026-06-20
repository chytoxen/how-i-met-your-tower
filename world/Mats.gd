class_name Mats
extends RefCounted
## Shared PBR materials built from the CC0 ambientCG textures in assets/textures/.
## Cached so repeated walls/floors share one material.

static var _cache := {}

static func textured(tex: String, uv_scale := 1.0, metallic := 0.0, tint := Color.WHITE) -> StandardMaterial3D:
	var key := "%s|%.2f|%.2f|%s" % [tex, uv_scale, metallic, str(tint)]
	if _cache.has(key):
		return _cache[key]
	var m := StandardMaterial3D.new()
	var base := "res://assets/textures/" + tex
	if ResourceLoader.exists(base + "_color.jpg"):
		m.albedo_texture = load(base + "_color.jpg")
	if ResourceLoader.exists(base + "_rough.jpg"):
		m.roughness_texture = load(base + "_rough.jpg")
	if ResourceLoader.exists(base + "_normal.jpg"):
		m.normal_enabled = true
		m.normal_texture = load(base + "_normal.jpg")
		m.normal_scale = 0.45   # gentle — keep surfaces clean to match the flat Kenney models
	m.albedo_color = tint
	m.metallic = metallic
	m.metallic_specular = 0.5
	m.uv1_scale = Vector3(uv_scale, uv_scale, uv_scale)
	# Mipmaps + anisotropic filtering — kills the "smeared at grazing angles"
	# look on tiled floors/walls and the shimmer on distant surfaces.
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_cache[key] = m
	return m

static func flat(color: Color, rough := 0.7, metallic := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	m.metallic = metallic
	return m

## Emissive panel/strip (signage, light fixtures, accent glow).
static func emissive(color: Color, energy := 2.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = energy
	m.roughness = 0.4
	return m

## Tinted architectural glass for the curtain wall.
static func glass(tint := Color(0.55, 0.72, 0.85, 0.12)) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = tint
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.metallic = 0.8
	m.roughness = 0.03
	m.refraction_enabled = false
	return m
