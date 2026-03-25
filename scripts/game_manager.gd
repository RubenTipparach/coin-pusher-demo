extends Node

var score: int = 0
var dollars: int = 10
var score_label: Label
var dollars_label: Label
var debug_label: Label
var score_3d: Label3D
var coins_3d: Label3D
var interact_prompt: Label
var main_scene: Node
var coin_spawn_point: Node3D
var coin_scene = preload("res://scenes/coin.tscn")
var ball_script = preload("res://scripts/ball.gd")
const MAX_COINS = 500

var next_ball_at: int = 50
var balls_pending: int = 0
var coins_loaded: int = 0
var canvas: CanvasLayer
var ui_root: Control

func _ready():
	canvas = CanvasLayer.new()
	add_child(canvas)

	ui_root = Control.new()
	ui_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(ui_root)

	# Score panel
	var panel = PanelContainer.new()
	panel.anchor_left = 0.0
	panel.anchor_right = 1.0
	panel.anchor_top = 0.0
	panel.anchor_bottom = 0.0
	panel.offset_bottom = 60
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.6)
	panel.add_theme_stylebox_override("panel", style)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(panel)

	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(hbox)

	score_label = Label.new()
	score_label.text = "SCORE: 0"
	score_label.add_theme_font_size_override("font_size", 36)
	score_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	score_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	score_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(score_label)

	dollars_label = Label.new()
	dollars_label.text = "$10"
	dollars_label.add_theme_font_size_override("font_size", 36)
	dollars_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
	dollars_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dollars_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dollars_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dollars_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(dollars_label)

	var is_touch = DisplayServer.is_touchscreen_available()

	if is_touch:
		# Drop Coin button (touch mode)
		var btn_container = CenterContainer.new()
		btn_container.anchor_left = 0.5
		btn_container.anchor_right = 0.5
		btn_container.anchor_top = 1.0
		btn_container.anchor_bottom = 1.0
		btn_container.offset_left = -100
		btn_container.offset_right = 100
		btn_container.offset_top = -140
		btn_container.offset_bottom = -20
		btn_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ui_root.add_child(btn_container)

		var coin_btn = Button.new()
		coin_btn.text = "DROP COIN"
		coin_btn.custom_minimum_size = Vector2(180, 80)
		coin_btn.add_theme_font_size_override("font_size", 28)
		var btn_style = StyleBoxFlat.new()
		btn_style.bg_color = Color(0.9, 0.7, 0.1)
		btn_style.corner_radius_top_left = 16
		btn_style.corner_radius_top_right = 16
		btn_style.corner_radius_bottom_left = 16
		btn_style.corner_radius_bottom_right = 16
		btn_style.content_margin_left = 20
		btn_style.content_margin_right = 20
		btn_style.content_margin_top = 10
		btn_style.content_margin_bottom = 10
		coin_btn.add_theme_stylebox_override("normal", btn_style)
		var btn_hover = btn_style.duplicate()
		btn_hover.bg_color = Color(1.0, 0.84, 0.2)
		coin_btn.add_theme_stylebox_override("hover", btn_hover)
		var btn_pressed = btn_style.duplicate()
		btn_pressed.bg_color = Color(0.7, 0.55, 0.05)
		coin_btn.add_theme_stylebox_override("pressed", btn_pressed)
		coin_btn.add_theme_color_override("font_color", Color(0.1, 0.05, 0))
		coin_btn.pressed.connect(_on_coin_btn_pressed)
		btn_container.add_child(coin_btn)
	else:
		# Crosshair (desktop FPS mode)
		var crosshair = Label.new()
		crosshair.text = "+"
		crosshair.add_theme_font_size_override("font_size", 28)
		crosshair.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
		crosshair.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		crosshair.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		crosshair.anchor_left = 0.5
		crosshair.anchor_right = 0.5
		crosshair.anchor_top = 0.5
		crosshair.anchor_bottom = 0.5
		crosshair.offset_left = -15
		crosshair.offset_right = 15
		crosshair.offset_top = -15
		crosshair.offset_bottom = 15
		crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ui_root.add_child(crosshair)

	# Instructions
	var instructions = Label.new()
	if is_touch:
		instructions.text = "Drag to rotate camera\nTap DROP COIN to launch!\nEvery 50 points earns a BALL DROP"
	else:
		instructions.text = "Press E at coin slot to insert $1 for 10 coins!\nEvery 50 points earns a BALL DROP.\nBall in pit = $10!  ESC to toggle mouse"
	instructions.add_theme_font_size_override("font_size", 18)
	instructions.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
	instructions.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instructions.anchor_left = 0.0
	instructions.anchor_right = 1.0
	instructions.anchor_top = 1.0
	instructions.anchor_bottom = 1.0
	if is_touch:
		instructions.offset_top = -200
		instructions.offset_bottom = -150
	else:
		instructions.offset_top = -80
		instructions.offset_bottom = -20
	instructions.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(instructions)

	var tween = create_tween()
	tween.tween_interval(8.0)
	tween.tween_property(instructions, "modulate:a", 0.0, 2.0)

	# Debug label (top-right)
	debug_label = Label.new()
	debug_label.text = "$ 10 | Coins: 0"
	debug_label.add_theme_font_size_override("font_size", 20)
	debug_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	debug_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	debug_label.anchor_left = 1.0
	debug_label.anchor_right = 1.0
	debug_label.anchor_top = 0.0
	debug_label.anchor_bottom = 0.0
	debug_label.offset_left = -250
	debug_label.offset_right = -10
	debug_label.offset_top = 65
	debug_label.offset_bottom = 90
	debug_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(debug_label)

	# Interact prompt (centered, below crosshair)
	interact_prompt = Label.new()
	interact_prompt.text = ""
	interact_prompt.add_theme_font_size_override("font_size", 22)
	interact_prompt.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
	interact_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interact_prompt.anchor_left = 0.0
	interact_prompt.anchor_right = 1.0
	interact_prompt.anchor_top = 0.5
	interact_prompt.anchor_bottom = 0.5
	interact_prompt.offset_top = 25
	interact_prompt.offset_bottom = 55
	interact_prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	interact_prompt.visible = false
	ui_root.add_child(interact_prompt)

func _update_debug_label():
	var coin_count = get_tree().get_nodes_in_group("coins").size()
	debug_label.text = "$" + str(dollars) + " | Loaded: " + str(coins_loaded) + " | Coins: " + str(coin_count)

func _process(_delta):
	_update_debug_label()

func _update_dollars_label():
	dollars_label.text = "$" + str(dollars)

func add_score(amount: int = 1):
	score += amount
	score_label.text = "SCORE: " + str(score)
	if score_3d:
		score_3d.text = "Score: " + str(score)
	while score >= next_ball_at:
		balls_pending += 1
		next_ball_at += 50
		_show_notification("BALL DROP!")
	if balls_pending > 0:
		drop_next_ball()

func add_dollars(amount: int):
	dollars += amount
	_update_dollars_label()
	if amount > 0:
		_show_notification("+$" + str(amount) + "!")

func try_insert_dollar() -> bool:
	if dollars <= 0:
		_show_notification("No money!")
		return false
	dollars -= 1
	coins_loaded += 10
	_update_dollars_label()
	_update_coins_3d()
	_show_notification("Loaded 10 coins!")
	return true

func try_shoot_coin() -> bool:
	if coins_loaded <= 0:
		_show_notification("Out of coins!")
		return false
	coins_loaded -= 1
	_update_coins_3d()
	return true

func _update_coins_3d():
	if coins_3d:
		coins_3d.text = "Coins: " + str(coins_loaded)

func drop_next_ball():
	if balls_pending <= 0 or not main_scene:
		return
	balls_pending -= 1
	var ball = RigidBody3D.new()
	ball.set_script(ball_script)
	ball.position = Vector3(randf_range(-0.08, 0.08), 1.7, randf_range(-0.65, -0.45))
	main_scene.add_child(ball)

func _show_notification(text: String):
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 48)
	label.add_theme_color_override("font_color", Color(1, 0.15, 0.15))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.anchor_left = 0.0
	label.anchor_right = 1.0
	label.anchor_top = 0.3
	label.anchor_bottom = 0.3
	label.offset_top = -30
	label.offset_bottom = 30
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(label)
	var tw = create_tween()
	tw.tween_interval(1.5)
	tw.tween_callback(label.queue_free)

func _on_coin_btn_pressed():
	if not coin_spawn_point:
		return
	var pos = coin_spawn_point.global_position
	pos += Vector3(randf_range(-0.02, 0.02), randf_range(-0.01, 0.01), 0)
	var impulse = Vector3(randf_range(-0.004, 0.004), randf_range(-0.002, 0.002), -0.015)
	spawn_coin(pos, impulse)

func spawn_coin(pos: Vector3, impulse: Vector3 = Vector3.ZERO):
	if not main_scene:
		return
	var coins = get_tree().get_nodes_in_group("coins")
	if coins.size() >= MAX_COINS:
		coins[0].queue_free()
	var coin = coin_scene.instantiate()
	coin.position = pos
	main_scene.add_child(coin)
	if impulse != Vector3.ZERO:
		coin.apply_central_impulse(impulse)
