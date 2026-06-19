extends Node3D
## Dev-only: builds the ExteriorRig (runway/city) under a dusk environment so the
## emissive runway/approach lights + lit buildings bloom, for GPU photo-tour shots.
## No camera here — PhotoTour supplies the camera per shot.

func _ready() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(0.09, 0.12, 0.26)
	sm.sky_horizon_color = Color(0.55, 0.40, 0.38)
	sm.ground_horizon_color = Color(0.16, 0.17, 0.22)
	sky.sky_material = sm
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.35
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_white = 6.0
	env.glow_enabled = true
	env.glow_intensity = 0.9
	env.glow_bloom = 0.3
	env.glow_hdr_threshold = 0.85
	env.ssil_enabled = true
	env.volumetric_fog_enabled = true
	env.volumetric_fog_density = 0.005
	env.volumetric_fog_albedo = Color(0.5, 0.55, 0.72)
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.1
	env.adjustment_saturation = 1.15
	we.environment = env
	add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-11, 150, 0)
	sun.light_energy = 1.1
	sun.light_color = Color(1.0, 0.68, 0.48)
	sun.shadow_enabled = true
	add_child(sun)

	add_child(ExteriorRig.new())
