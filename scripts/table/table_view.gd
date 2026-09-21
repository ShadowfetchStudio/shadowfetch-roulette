class_name TableView
extends Node3D


func _ready() -> void:
	_build()


func _build() -> void:
	var floor := MeshInstance3D.new()
	var floor_m := BoxMesh.new()
	floor_m.size = Vector3(18, 0.08, 14)
	floor.mesh = floor_m
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.045, 0.04, 0.038)
	floor_mat.metallic = 0.22
	floor_mat.roughness = 0.55
	floor.material_override = floor_mat
	floor.position = Vector3(0.2, -0.42, 1.2)
	add_child(floor)
	var felt := MeshInstance3D.new()
	var plane := BoxMesh.new()
	plane.size = Vector3(5.6, 0.06, 2.8)
	felt.mesh = plane
	felt.material_override = TableMaterials.felt()
	felt.position = Vector3(0.55, -0.16, 2.05)
	add_child(felt)
	var rail := MeshInstance3D.new()
	var rail_m := BoxMesh.new()
	rail_m.size = Vector3(5.95, 0.14, 3.15)
	rail.mesh = rail_m
	rail.material_override = TableMaterials.wood()
	rail.position = Vector3(0.55, -0.24, 2.05)
	add_child(rail)
	_gold_edge(Vector3(0.55, -0.11, 0.68), Vector3(5.7, 0.02, 0.04))
	_gold_edge(Vector3(0.55, -0.11, 3.42), Vector3(5.7, 0.02, 0.04))
	_gold_edge(Vector3(-2.22, -0.11, 2.05), Vector3(0.04, 0.02, 2.78))
	_gold_edge(Vector3(3.32, -0.11, 2.05), Vector3(0.04, 0.02, 2.78))
	var lamp := OmniLight3D.new()
	lamp.light_color = Color(1.0, 0.86, 0.62)
	lamp.light_energy = 3.1
	lamp.omni_range = 9.0
	lamp.position = Vector3(0.15, 2.8, 1.1)
	lamp.shadow_enabled = true
	add_child(lamp)
	_chip_tray()


func _gold_edge(pos: Vector3, size: Vector3) -> void:
	var edge := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	edge.mesh = mesh
	edge.material_override = TableMaterials.gold()
	edge.position = pos
	add_child(edge)


func _chip_tray() -> void:
	var colors := [
		Color(0.85, 0.85, 0.88),
		Color(0.20, 0.45, 0.85),
		Color(0.18, 0.55, 0.28),
		Color(0.15, 0.12, 0.14),
		Color(0.72, 0.16, 0.16),
	]
	for i in colors.size():
		var stack := Node3D.new()
		stack.position = Vector3(-2.15 + i * 0.28, -0.08, 3.25)
		add_child(stack)
		for k in 5:
			var chip := MeshInstance3D.new()
			var cyl := CylinderMesh.new()
			cyl.top_radius = 0.09
			cyl.bottom_radius = 0.09
			cyl.height = 0.018
			cyl.radial_segments = 20
			chip.mesh = cyl
			var mat := StandardMaterial3D.new()
			mat.albedo_color = colors[i]
			mat.roughness = 0.35
			mat.metallic = 0.15
			chip.material_override = mat
			chip.position.y = 0.02 + k * 0.019
			stack.add_child(chip)
