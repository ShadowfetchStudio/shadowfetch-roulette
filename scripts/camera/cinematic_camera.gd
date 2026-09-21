class_name CinematicCamera
extends Node3D

var camera: Camera3D
var _yaw := -0.35
var _pitch := -0.55
var _dist := 5.4
var _target := Vector3(0.15, 0.15, 0.85)
var _orbiting := false
var _look: Vector3 = Vector3(0.15, 0.15, 0.85)


func _ready() -> void:
	camera = Camera3D.new()
	camera.fov = 38
	add_child(camera)
	_apply()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("reset_camera"):
		reset()
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_RIGHT:
			_orbiting = mb.pressed
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			_dist = maxf(_dist - 0.25, 3.2)
			_apply()
		if mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_dist = minf(_dist + 0.25, 8.5)
			_apply()
	if event is InputEventMouseMotion and _orbiting:
		var mm := event as InputEventMouseMotion
		var s := SettingsStore.camera_sensitivity
		_yaw -= mm.relative.x * 0.005 * s
		_pitch = clampf(_pitch - mm.relative.y * 0.004 * s, -1.15, -0.22)
		_apply()


func reset() -> void:
	_yaw = -0.35
	_pitch = -0.55
	_dist = 5.4
	_target = Vector3(0.15, 0.15, 0.85)
	_apply()


func look_wheel() -> void:
	_target = Vector3(0.0, 0.2, 0.1)
	_dist = 4.4
	_pitch = -0.72
	_yaw = 0.15
	_apply()


func look_table() -> void:
	reset()


func _apply() -> void:
	var off := Vector3(
		sin(_yaw) * cos(_pitch),
		-sin(_pitch),
		cos(_yaw) * cos(_pitch)
	) * _dist
	camera.position = _target + off
	camera.look_at(_target)


func _process(delta: float) -> void:
	_look = _look.lerp(_target, clampf(delta * 8.0, 0.0, 1.0))
