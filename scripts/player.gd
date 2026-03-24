extends CharacterBody3D

## Dual-mode camera: FPS on desktop, orbit on touch/mobile.
## Uses DisplayServer.is_touchscreen_available() to detect mode.

# FPS settings
const SPEED = 5.0
const JUMP_VEL = 4.5
const MOUSE_SENS = 0.002

# Orbit settings
const ORBIT_SPEED = 0.005
const ZOOM_SPEED = 0.1
const MIN_DISTANCE = 0.8
const MAX_DISTANCE = 3.0
const MIN_PITCH = -0.3
const MAX_PITCH = 1.2

var camera: Camera3D
var is_touch: bool = false
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

# Orbit state
var pivot_point := Vector3(0, 1.1, -0.5)
var orbit_yaw := 0.0
var orbit_pitch := 0.6
var orbit_distance := 1.5
var _dragging := false
var _drag_touch_index := -1

func _ready():
	is_touch = DisplayServer.is_touchscreen_available()

	if is_touch:
		camera = Camera3D.new()
		camera.current = true
		add_child(camera)
		_update_orbit_camera()
	else:
		_setup_fps()

func _setup_fps():
	var col = CollisionShape3D.new()
	var capsule = CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = 1.8
	col.shape = capsule
	add_child(col)

	camera = Camera3D.new()
	camera.position.y = 0.65
	camera.current = true
	add_child(camera)

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	var keys = {
		"move_forward": KEY_W,
		"move_backward": KEY_S,
		"move_left": KEY_A,
		"move_right": KEY_D,
		"jump": KEY_SPACE,
	}
	for action in keys:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			var ev = InputEventKey.new()
			ev.physical_keycode = keys[action]
			InputMap.action_add_event(action, ev)

func _unhandled_input(event):
	if is_touch:
		_handle_touch_input(event)
	else:
		_handle_fps_input(event)

# --- FPS input ---
func _handle_fps_input(event):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENS)
		camera.rotate_x(-event.relative.y * MOUSE_SENS)
		camera.rotation.x = clamp(camera.rotation.x, -1.4, 1.4)

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			_try_insert_coin()
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

# --- Touch/orbit input ---
func _handle_touch_input(event):
	if event is InputEventScreenTouch:
		if event.pressed and _drag_touch_index == -1:
			_drag_touch_index = event.index
			_dragging = true
		elif not event.pressed and event.index == _drag_touch_index:
			_drag_touch_index = -1
			_dragging = false

	if event is InputEventScreenDrag and event.index == _drag_touch_index:
		orbit_yaw -= event.relative.x * ORBIT_SPEED
		orbit_pitch = clamp(orbit_pitch + event.relative.y * ORBIT_SPEED, MIN_PITCH, MAX_PITCH)
		_update_orbit_camera()

	# Also support mouse drag for orbit (desktop testing)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_dragging = event.pressed
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			orbit_distance = max(MIN_DISTANCE, orbit_distance - ZOOM_SPEED)
			_update_orbit_camera()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			orbit_distance = min(MAX_DISTANCE, orbit_distance + ZOOM_SPEED)
			_update_orbit_camera()

	if event is InputEventMouseMotion and _dragging:
		orbit_yaw -= event.relative.x * ORBIT_SPEED
		orbit_pitch = clamp(orbit_pitch + event.relative.y * ORBIT_SPEED, MIN_PITCH, MAX_PITCH)
		_update_orbit_camera()

func _update_orbit_camera():
	var offset = Vector3(
		sin(orbit_yaw) * cos(orbit_pitch),
		sin(orbit_pitch),
		cos(orbit_yaw) * cos(orbit_pitch)
	) * orbit_distance

	global_position = pivot_point + offset
	camera.global_position = global_position
	camera.look_at(pivot_point)

func _physics_process(delta):
	if is_touch:
		return

	# FPS physics
	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VEL

	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var dir = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if dir:
		velocity.x = dir.x * SPEED
		velocity.z = dir.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

func _try_insert_coin():
	if not GameManager.coin_spawn_point:
		return
	var pos = GameManager.coin_spawn_point.global_position
	pos += Vector3(randf_range(-0.02, 0.02), randf_range(-0.01, 0.01), 0)
	var impulse = Vector3(randf_range(-0.004, 0.004), randf_range(-0.002, 0.002), -0.015)
	GameManager.spawn_coin(pos, impulse)
