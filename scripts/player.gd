extends CharacterBody3D

## Orbit camera that works with both mouse drag and touch drag.
## Pivots around the coin pusher machine.

const ORBIT_SPEED = 0.005
const ZOOM_SPEED = 0.1
const MIN_DISTANCE = 0.8
const MAX_DISTANCE = 3.0
const MIN_PITCH = -0.3  # slight look-up
const MAX_PITCH = 1.2   # look down from above

var camera: Camera3D
var pivot_point := Vector3(0, 1.1, -0.5)  # center of the machine
var orbit_yaw := 0.0
var orbit_pitch := 0.6
var orbit_distance := 1.5

var _dragging := false
var _drag_touch_index := -1

func _ready():
	# No collision shape needed — we're just a camera holder
	camera = Camera3D.new()
	camera.current = true
	add_child(camera)
	_update_camera()

func _unhandled_input(event):
	# Mouse drag to orbit
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_dragging = event.pressed
		# Scroll to zoom
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			orbit_distance = max(MIN_DISTANCE, orbit_distance - ZOOM_SPEED)
			_update_camera()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			orbit_distance = min(MAX_DISTANCE, orbit_distance + ZOOM_SPEED)
			_update_camera()

	if event is InputEventMouseMotion and _dragging:
		orbit_yaw -= event.relative.x * ORBIT_SPEED
		orbit_pitch = clamp(orbit_pitch + event.relative.y * ORBIT_SPEED, MIN_PITCH, MAX_PITCH)
		_update_camera()

	# Touch drag to orbit
	if event is InputEventScreenTouch:
		if event.pressed and _drag_touch_index == -1:
			# Only start drag if not touching a UI button
			_drag_touch_index = event.index
			_dragging = true
		elif not event.pressed and event.index == _drag_touch_index:
			_drag_touch_index = -1
			_dragging = false

	if event is InputEventScreenDrag and event.index == _drag_touch_index:
		orbit_yaw -= event.relative.x * ORBIT_SPEED
		orbit_pitch = clamp(orbit_pitch + event.relative.y * ORBIT_SPEED, MIN_PITCH, MAX_PITCH)
		_update_camera()

func _update_camera():
	var offset = Vector3(
		sin(orbit_yaw) * cos(orbit_pitch),
		sin(orbit_pitch),
		cos(orbit_yaw) * cos(orbit_pitch)
	) * orbit_distance

	global_position = pivot_point + offset
	camera.global_position = global_position
	camera.look_at(pivot_point)

func _physics_process(_delta):
	# Override CharacterBody3D — no physics movement needed
	pass
