class_name WheelView
extends Node3D

const POCKETS := 37
const RADIUS := 1.35

var rotor: Node3D
var ball: MeshInstance3D
var _spinning := false
var _wheel_speed := 0.0
var _ball_angle := 0.0
var _ball_speed := 0.0
var _ball_radius := 1.22
var _target := 0
var _phase := 0
var _time := 0.0
var _duration := 4.2
var _finished := false


func _ready() -> void:
	_build()


func _build() -> void:
	var base := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 1.48
	cyl.bottom_radius = 1.52
	cyl.height = 0.18
	cyl.radial_segments = 48
	base.mesh = cyl
	base.material_override = TableMaterials.wood()
	add_child(base)
	var rim := MeshInstance3D.new()
	var rim_m := TorusMesh.new()
	rim_m.inner_radius = 1.30
	rim_m.outer_radius = 1.46
	rim_m.rings = 48
	rim_m.ring_segments = 16
	rim.mesh = rim_m
	rim.position.y = 0.12
	rim.material_override = TableMaterials.gold()
	add_child(rim)
	rotor = Node3D.new()
	rotor.name = "Rotor"
	add_child(rotor)
	var cone := MeshInstance3D.new()
	var cone_m := CylinderMesh.new()
	cone_m.top_radius = 0.18
	cone_m.bottom_radius = 0.72
	cone_m.height = 0.16
	cone_m.radial_segments = 36
	cone.mesh = cone_m
	cone.position.y = 0.12
	cone.material_override = TableMaterials.brass()
	rotor.add_child(cone)
	var hub := MeshInstance3D.new()
	var hub_m := CylinderMesh.new()
	hub_m.top_radius = 0.16
	hub_m.bottom_radius = 0.16
	hub_m.height = 0.22
	hub.mesh = hub_m
	hub.position.y = 0.22
	hub.material_override = TableMaterials.chrome()
	rotor.add_child(hub)
	for i in POCKETS:
		var n: int = RouletteTypes.WHEEL_ORDER[i]
		var ang := -float(i) * TAU / float(POCKETS)
		var pocket := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.20, 0.05, 0.34)
		pocket.mesh = box
		pocket.material_override = TableMaterials.pocket(RouletteTypes.pocket_color(n))
		pocket.position = Vector3(sin(ang) * 1.02, 0.10, cos(ang) * 1.02)
		pocket.rotation.y = ang
		rotor.add_child(pocket)
		var divider := MeshInstance3D.new()
		var dbox := BoxMesh.new()
		dbox.size = Vector3(0.018, 0.08, 0.36)
		divider.mesh = dbox
		divider.material_override = TableMaterials.gold()
		var dang := ang - TAU / float(POCKETS) * 0.5
		divider.position = Vector3(sin(dang) * 1.02, 0.12, cos(dang) * 1.02)
		divider.rotation.y = dang
		rotor.add_child(divider)
		var lab := Label3D.new()
		lab.text = str(n)
		lab.font_size = 28
		lab.modulate = Color(0.95, 0.92, 0.82)
		lab.position = Vector3(sin(ang) * 1.18, 0.16, cos(ang) * 1.18)
		lab.rotation.y = ang + PI
		rotor.add_child(lab)
	ball = MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.055
	sm.height = 0.11
	ball.mesh = sm
	ball.material_override = TableMaterials.ivory()
	ball.position = Vector3(1.22, 0.22, 0)
	add_child(ball)
	_place_ball_rest(0)


func pocket_angle(pocket: int) -> float:
	var idx := RouletteTypes.WHEEL_ORDER.find(pocket)
	if idx < 0:
		idx = 0
	return -float(idx) * TAU / float(POCKETS)


func _place_ball_rest(pocket: int) -> void:
	var local := pocket_angle(pocket)
	var world := rotor.rotation.y + local
	ball.position = Vector3(sin(world) * 1.02, 0.16, cos(world) * 1.02)
	_ball_angle = world
	_ball_radius = 1.02


func start_spin(pocket: int, duration: float) -> void:
	_target = pocket
	_duration = duration
	_time = 0.0
	_phase = 0
	_finished = false
	_spinning = true
	_wheel_speed = 7.4
	_ball_speed = -16.5
	_ball_radius = 1.24
	_ball_angle = randf() * TAU


func is_busy() -> bool:
	return _spinning and not _finished


func _process(delta: float) -> void:
	if not _spinning:
		rotor.rotate_y(delta * 0.12)
		return
	_time += delta
	var u := clampf(_time / _duration, 0.0, 1.0)
	_wheel_speed = lerpf(7.4, 1.8, u)
	rotor.rotate_y(_wheel_speed * delta)
	if u < 0.62:
		_ball_speed = lerpf(-16.5, -3.0, u / 0.62)
		_ball_radius = 1.24
		_ball_angle += _ball_speed * delta
		ball.position = Vector3(sin(_ball_angle) * _ball_radius, 0.22, cos(_ball_angle) * _ball_radius)
	else:
		var t := (u - 0.62) / 0.38
		var target_world := rotor.rotation.y + pocket_angle(_target)
		_ball_angle = lerp_angle(_ball_angle, target_world, clampf(t * 3.2, 0.0, 1.0))
		_ball_radius = lerpf(1.24, 1.02, t)
		var y := lerpf(0.22, 0.16, t)
		ball.position = Vector3(sin(_ball_angle) * _ball_radius, y, cos(_ball_angle) * _ball_radius)
		if u >= 1.0:
			_place_ball_rest(_target)
			_spinning = false
			_finished = true
