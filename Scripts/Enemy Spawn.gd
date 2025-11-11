extends Node3D

@export var midi_player: MidiPlayer
@export var player: CharacterBody3D
@export var enemy_scene: PackedScene
@export var spawn_distance: float = 30.0  # Distance from player
@export var spawn_height_above_player: float = 10.0  # How high above player
@export var min_angle: float = -180.0  # Degrees
@export var max_angle: float = 180.0   # Degrees
@export var fast_speed: float = 15.0  # Speed when moving to correct Z
@export var slow_speed: float = 5.0   # Speed after reaching correct Z
@export var y_threshold: float = 2.0  # How close to Y (height) before slowing down

var enemies: Array = []  # Array to track spawned enemies

func _ready():
	print("=== ENEMY SPAWNER READY ===")
	print("Player assigned: ", player != null)
	print("Enemy scene assigned: ", enemy_scene != null)
	print("MIDI player assigned: ", midi_player != null)
	
	if midi_player:
		midi_player.midi_event.connect(_on_midi_event)
		print("MIDI event connected!")
	else:
		print("WARNING: No MIDI player assigned!")

func _on_midi_event(channel, event):
	print("MIDI Event received - Channel: ", channel, " Event type: ", event)
	# Check if this is a note on event
	if event is SMF.MIDIEventNoteOn and event.velocity > 0:
		print("✓ Note On detected! Spawning enemy...")
		spawn_enemy()
	else:
		print("✗ Not a Note On event or velocity is 0")

func _process(delta):
	# Update all enemies movement and check collisions
	for enemy_data in enemies:
		if is_instance_valid(enemy_data.enemy):
			move_enemy(enemy_data, delta)
			check_enemy_collision(enemy_data)
		else:
			print("WARNING: Invalid enemy detected in array")

func spawn_enemy():
	print("\n=== SPAWN ENEMY CALLED ===")
	
	if not player:
		print("ERROR: Player is null!")
		return
	if not enemy_scene:
		print("ERROR: Enemy scene is null!")
		return
	
	print("✓ Player found at position: ", player.global_position)
	print("✓ Enemy scene ready")
	
	# Get random angle within specified range (in radians)
	var random_angle = deg_to_rad(randf_range(min_angle, max_angle))
	print("Random angle: ", rad_to_deg(random_angle), " degrees")
	
	# Calculate spawn position at similar distance and higher than player
	var player_pos = player.global_position
	var spawn_pos = Vector3(
		player_pos.x + spawn_distance * cos(random_angle),
		player_pos.y + spawn_height_above_player,  # Higher than player
		player_pos.z + spawn_distance * sin(random_angle)
	)
	print("Spawn position calculated: ", spawn_pos)
	
	# Instantiate enemy
	var enemy = enemy_scene.instantiate()
	print("Enemy instantiated: ", enemy)
	
	# Add to scene
	add_child(enemy)
	print("Enemy added to scene tree")
	
	# Set position at spawn point
	enemy.global_position = spawn_pos
	print("Enemy position set to: ", enemy.global_position)
	
	# ========== RED FLARE WITH MESH ==========
	create_spawn_flare(spawn_pos)
	print("Spawn flare created")
	# =========================================
	
	# Show enemy indicator on player HUD
	if player.has_method("show_enemy_indicator"):
		player.show_enemy_indicator(enemy)
		print("Enemy indicator shown on player HUD")
	else:
		print("WARNING: Player doesn't have show_enemy_indicator method")
	
	# Make enemy face towards the player initially
	var direction_to_target = (player_pos - spawn_pos).normalized()
	enemy.look_at(spawn_pos + direction_to_target, Vector3.UP)
	print("Enemy facing player")
	
	# Play animation
	var anim_player = enemy.find_child("AnimationPlayer", true, false)
	if anim_player:
		anim_player.play("MoveUp")
		print("Animation 'MoveUp' started")
	else:
		print("WARNING: No AnimationPlayer found on enemy")
	
	# Store enemy with its current speed data
	var enemy_data = {
		"enemy": enemy,
		"reached_y": false,  # Has it reached the correct Y axis (height)?
		"current_speed": fast_speed
	}
	enemies.append(enemy_data)
	print("Enemy added to tracking array. Total enemies: ", enemies.size())
	print("=== SPAWN COMPLETE ===\n")

func create_spawn_flare(position: Vector3):
	# Create a glowing sphere
	var flare_mesh = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	flare_mesh.mesh = sphere
	
	# Create emissive red material
	var material = StandardMaterial3D.new()
	material.shading_mode = 0  # Unlit mode
	material.emission_enabled = true
	material.emission = Color(1.0, 0.0, 0.0)  # Red
	material.emission_energy_multiplier = 8.0  # Very bright for bloom
	material.transparency = 1  # Alpha transparency
	material.albedo_color = Color(1.0, 0.0, 0.0, 0.8)
	
	flare_mesh.material_override = material
	flare_mesh.global_position = position
	
	# Add red light
	var light = OmniLight3D.new()
	light.light_color = Color(1.0, 0.0, 0.0)
	light.light_energy = 15.0
	light.omni_range = 20.0
	flare_mesh.add_child(light)
	
	add_child(flare_mesh)
	
	# Animate scale up then fade out
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(flare_mesh, "scale", Vector3(2, 2, 2), 0.2)
	tween.tween_property(light, "light_energy", 0.0, 0.5)
	tween.tween_property(material, "albedo_color:a", 0.0, 0.5)
	tween.chain().tween_callback(flare_mesh.queue_free)

func check_enemy_collision(enemy_data: Dictionary):
	var enemy = enemy_data.enemy
	
	if not enemy is Area3D:
		return
	
	# Check for overlapping bodies
	var overlapping = enemy.get_overlapping_bodies()
	
	for body in overlapping:
		if body.is_in_group("player"):
			# Destroy the player
			body.queue_free()
			return

func move_enemy(enemy_data: Dictionary, delta: float):
	if not player:
		return
		
	var enemy = enemy_data.enemy
	var enemy_pos = enemy.global_position
	var player_pos = player.global_position  # Get current player position every frame
	
	# Calculate distance to player's current Y (height)
	var y_distance = abs(enemy_pos.y - player_pos.y)
	
	# Check if we've reached the correct Y axis (height)
	if not enemy_data.reached_y:
		if y_distance < y_threshold:
			enemy_data.reached_y = true
			enemy_data.current_speed = slow_speed
	
	# Priority movement: Y (height) first, then X and Z
	var movement_direction = Vector3.ZERO
	
	if not enemy_data.reached_y:
		# Move primarily towards correct Y/height (fast) - fall down
		movement_direction = Vector3(0, sign(player_pos.y - enemy_pos.y), 0)
		enemy_data.current_speed = fast_speed
	else:
		# Once Y is correct, move towards player's current position (slower)
		var direction_to_player = (player_pos - enemy_pos).normalized()
		movement_direction = direction_to_player
	
	# Move the enemy
	var movement = movement_direction * enemy_data.current_speed * delta
	enemy.global_position += movement
	
	# Face the movement direction
	if movement_direction.length() > 0:
		enemy.look_at(enemy_pos + movement_direction, Vector3.UP)
	
	# Remove enemy if it reaches player
	if enemy_pos.distance_to(player_pos) < 1.0:
		enemy.queue_free()
		enemies.erase(enemy_data)

# Clean up destroyed enemies
func _physics_process(delta):
	for i in range(enemies.size() - 1, -1, -1):
		var enemy_data = enemies[i]
		if not is_instance_valid(enemy_data.enemy):
			enemies.remove_at(i)
