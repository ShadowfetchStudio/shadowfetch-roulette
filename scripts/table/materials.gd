class_name TableMaterials
extends RefCounted


static func gold() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.78, 0.62, 0.28)
	m.metallic = 0.92
	m.roughness = 0.28
	m.clearcoat_enabled = true
	m.clearcoat = 0.35
	m.rim_enabled = true
	m.rim = 0.16
	return m


static func brass() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.62, 0.48, 0.22)
	m.metallic = 0.86
	m.roughness = 0.38
	return m


static func wood() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.16, 0.10, 0.07)
	m.metallic = 0.04
	m.roughness = 0.62
	return m


static func felt() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.05, 0.20, 0.14)
	m.roughness = 0.92
	m.metallic = 0.0
	return m


static func ivory() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.93, 0.90, 0.84)
	m.metallic = 0.12
	m.roughness = 0.28
	m.clearcoat_enabled = true
	m.clearcoat = 0.4
	return m


static func pocket(color: int) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	match color:
		RouletteTypes.COLOR_GREEN:
			m.albedo_color = Color(0.08, 0.38, 0.22)
		RouletteTypes.COLOR_RED:
			m.albedo_color = Color(0.62, 0.10, 0.12)
		_:
			m.albedo_color = Color(0.07, 0.075, 0.085)
	m.roughness = 0.45
	m.metallic = 0.08
	return m


static func chrome() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.82, 0.84, 0.86)
	m.metallic = 1.0
	m.roughness = 0.18
	return m


static func dark_metal() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.12, 0.13, 0.15)
	m.metallic = 0.78
	m.roughness = 0.4
	return m
