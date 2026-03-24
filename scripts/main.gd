extends Node3D

func _ready():
	GameManager.main_scene = self
	GameManager.coin_spawn_point = $Machine/CoinSpawnBox
	_prespawn_coins.call_deferred()

func _on_score(body: Node3D):
	if body.is_in_group("coins"):
		GameManager.add_score(1)
		body.queue_free()
	elif body.is_in_group("balls"):
		body.queue_free()
		GameManager.trigger_bonus_wheel()

func _prespawn_coins():
	# Grid-fill the entire platform with coins wall-to-wall
	# Platform x: ~-0.30 to 0.30, z: ~-0.67 to -0.20
	var coin_spacing = 0.032  # slightly larger than coin diameter (0.03)
	var x_start = -0.28
	var x_end = 0.28
	var z_start = -0.66
	var z_end = -0.21
	var z = z_start
	var row = 0
	while z <= z_end:
		var x_offset = 0.016 if row % 2 == 1 else 0.0  # stagger rows
		var x = x_start + x_offset
		while x <= x_end:
			var pos = Vector3(
				x + randf_range(-0.003, 0.003),
				0.91 + randf_range(0, 0.005),
				z + randf_range(-0.003, 0.003)
			)
			GameManager.spawn_coin(pos)
			x += coin_spacing
		z += coin_spacing * 0.87  # tighter row packing
		row += 1
