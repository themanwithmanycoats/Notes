extends Node3D

var update_count = 0

func _ready():
	# Wait for everything to load
	await get_tree().create_timer(1.0).timeout
	
	var video_player = $VideoStreamPlayer
	var sphere = $"sky box"
	
	print("\n=== DETAILED SKYBOX DEBUG ===")
	print("Video Player Node: ", video_player)
	print("Sphere Node: ", sphere)
	
	# Check video
	if video_player:
		print("\nVIDEO STATUS:")
		print("  Stream loaded: ", video_player.stream != null)
		if video_player.stream:
			print("  Stream path: ", video_player.stream.resource_path)
		print("  Is playing: ", video_player.is_playing())
		print("  Paused: ", video_player.paused)
		print("  Autoplay: ", video_player.autoplay)
		print("  Loop: ", video_player.loop)
		
		var vt = video_player.get_video_texture()
		print("  Video texture: ", vt)
		if vt:
			print("  Texture valid: ", vt.get_rid().is_valid())
	
	# Check material
	if sphere:
		print("\nMATERIAL STATUS:")
		var mat = sphere.material_override
		if mat == null:
			mat = sphere.get_active_material(0)
			print("  Using surface material (not override)")
		else:
			print("  Using material_override")
		
		if mat:
			print("  Material type: ", mat.get_class())
			
			if mat is ShaderMaterial:
				print("  Shader assigned: ", mat.shader != null)
				if mat.shader:
					print("  Shader path: ", mat.shader.resource_path)
				
				print("\nSHADER PARAMETERS:")
				var texture_param = mat.get_shader_parameter("video_texture")
				print("  video_texture param: ", texture_param)
				print("  base_brightness: ", mat.get_shader_parameter("base_brightness"))
				print("  glow_intensity: ", mat.get_shader_parameter("glow_intensity"))
				
				# Try setting texture
				var vt = video_player.get_video_texture()
				if vt:
					mat.set_shader_parameter("video_texture", vt)
					print("  ✓ Texture set to material!")
					
					# Verify it was set
					await get_tree().process_frame
					var check = mat.get_shader_parameter("video_texture")
					print("  Verification - texture is now: ", check)
				else:
					print("  ✗ No video texture available!")
			else:
				print("  ✗ Material is NOT ShaderMaterial, it's: ", mat.get_class())
		else:
			print("  ✗ NO MATERIAL FOUND!")
	
	print("=============================\n")

func _process(delta):
	update_count += 1
	
	# Update texture continuously
	if update_count % 5 == 0:  # Every ~5 frames
		var video_player = $VideoStreamPlayer
		var sphere = $"sky box"
		
		if sphere and video_player:
			var mat = sphere.material_override
			if mat == null:
				mat = sphere.get_active_material(0)
			
			if mat is ShaderMaterial:
				var vt = video_player.get_video_texture()
				if vt:
					mat.set_shader_parameter("video_texture", vt)
