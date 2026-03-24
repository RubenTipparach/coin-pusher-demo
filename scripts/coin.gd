extends RigidBody3D

func _ready():
	mass = 0.005
	add_to_group("coins")
	continuous_cd = true
	# Prevent coins from sleeping in stuck positions
	can_sleep = false
	# Damping so coins settle but don't stick
	linear_damp = 0.5
	angular_damp = 1.0

	var phys = PhysicsMaterial.new()
	phys.friction = 0.5
	phys.bounce = 0.35
	physics_material_override = phys

	# Collision shape — thicker than visual to prevent embedding
	var col = CollisionShape3D.new()
	var shape = CylinderShape3D.new()
	shape.radius = 0.015
	shape.height = 0.008
	col.shape = shape
	add_child(col)

	# Visual mesh — thin coin look
	var mi = MeshInstance3D.new()
	var mesh = CylinderMesh.new()
	mesh.top_radius = 0.015
	mesh.bottom_radius = 0.015
	mesh.height = 0.004
	mesh.radial_segments = 16
	mi.mesh = mesh
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.84, 0.0)
	mat.metallic = 0.9
	mat.roughness = 0.2
	mi.material_override = mat
	add_child(mi)

func _physics_process(_delta):
	if global_position.y < -5:
		queue_free()
