extends Area3D  # Or whatever type your root is

func _ready():
	print("=== Enemy Ready ===")
	print("Enemy name: ", name)
	print("Enemy type: ", get_class())
	
	# Check collision shape
	var collision_shape = find_child("CollisionShape3D", true, false)
	if collision_shape:
		print("✓ CollisionShape found")
		print("  Shape: ", collision_shape.shape)
	else:
		print("✗ NO CollisionShape found!")
	
	# Check collision layers
	print("Collision Layer: ", collision_layer)
	print("Collision Mask: ", collision_mask)
	
	# Connect signals
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	print("✓ Signals connected")

func _on_body_entered(body):
	print("!!! BODY ENTERED: ", body.name, " (", body.get_class(), ")")
	if body.is_in_group("player"):
		print("💥 IT'S THE PLAYER!")
	else:
		print("Not player. Groups: ", body.get_groups())

func _on_area_entered(area):
	print("!!! AREA ENTERED: ", area.name)
