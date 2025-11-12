extends Node3D

func _ready():
	await get_tree().process_frame
	await get_tree().process_frame
	
	var video_player = $VideoStreamPlayer
	var sphere = $"sky box"
	
	# Try to get the material
	var material = sphere.material_override
	
	if material == null:
		material = sphere.get_active_material(0)
	
	if material == null:
		push_error("No material found on sky box!")
		return
	
	print("Material found: ", material)
	material.set_shader_parameter("video_texture", video_player.get_video_texture())
	
	print("Video texture connected to skybox!")
