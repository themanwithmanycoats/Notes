extends Node3D

func _ready():
	# Use the exact path you copied
	var anim_player = get_node("Enemy idle/AnimationPlayer")
	# Or if it's a direct child:
	# var anim_player = $AnimationPlayer
	
	if anim_player:
		print("✓ AnimationPlayer found!")
		anim_player.play("MoveUp")
	else:
		print("✗ Not found at this path")
