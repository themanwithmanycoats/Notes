extends Node3D

@export var midi_player: MidiPlayer
@export var player: CharacterBody3D
@export var enemy_scene: PackedScene
@export var spawn_radius: float = 20.0
@export var min_angle: float = -180.0  # Degrees
@export var max_angle: float = 180.0   # Degrees
@export var max_speed: float = 5.0     # Maximum movement speed
@export var acceleration: float = 2.0  # How quickly they speed up
@export var track_player_distance: float = 10.0  # Distance to track player before resuming
@export var track_duration: float = 2.0  # How long to track player (seconds)

var enemies: Array = []  # Array to track spawned enemies

func _ready():
	if midi_player:
		midi_player.midi_event.connect(_on_midi_event)

func _on_midi_event(channel, event):
	# Check if this is a note on event
	if event is SMF.MIDIEventNoteOn and event.velocity > 0:
		spawn_enemy()

func _process(delta):
	# Update all enemies movement
	for enemy_data in enemies:
		if is_instance_valid(enemy_data.enemy):
			move_enemy(enemy_data, delta)

func spawn_enemy():
	if not player or not enemy_scene:
		return
	
	# Get random angle within specified range (in radians)
	var random_angle = deg_to_rad(randf_range(min_angle, max_angle))
	
	# Calculate spawn position in a ring around the player
	var player_pos = player.global_position
	var spawn_pos = Vector3(
		player_pos.x + spawn_radius * cos(random_angle),
		player_pos.y + 5,  # Same height as player
		player_pos.z + spawn_radius * sin(random_angle)
	)
	
	# Calculate target position (opposite side of the ring)
	var target_pos = Vector3(
		player_pos.x + spawn_radius * cos(random_angle + PI),
		player_pos.y + 1,
		player_pos.z + spawn_radius * sin(random_angle + PI)
	)
	
	# Instantiate enemy
	var enemy = enemy_scene.instantiate()
	
	# Add to scene FIRST
	add_child(enemy)
	
	# Now set position at spawn point
	enemy.global_position = spawn_pos
	
	# Make enemy face towards the target position initially
	var direction_to_target = (target_pos - spawn_pos).normalized()
	enemy.look_at(spawn_pos + direction_to_target, Vector3.UP)
	
	# Store enemy with its current speed data and target position
	var enemy_data = {
		"enemy": enemy,
		"current_speed": 0.0 + 30,
		"target_reached": false,
		"target_position": target_pos,
		"spawn_position": spawn_pos,
		"is_tracking_player": true,  # Start by tracking player
		"track_timer": 0.0,  # Timer for tracking duration
		"initial_direction": direction_to_target  # Store initial movement direction
	}
	enemies.append(enemy_data)

func move_enemy(enemy_data: Dictionary, delta: float):
	var enemy = enemy_data.enemy
	var enemy_pos = enemy.global_position
	
	if enemy_data.is_tracking_player and is_instance_valid(player):
		# Track player mode
		var player_pos = player.global_position
		var direction_to_player = (player_pos - enemy_pos).normalized()
		
		# Update tracking timer
		enemy_data.track_timer += delta
		
		# Gradually increase speed
		enemy_data.current_speed = lerp(enemy_data.current_speed, max_speed, acceleration * delta)
		
		# Move towards player
		var movement = direction_to_player * enemy_data.current_speed * delta
		enemy.global_position += movement
		
		# Face the player
		if direction_to_player.length() > 0:
			enemy.look_at(enemy_pos + direction_to_player, Vector3.UP)
		
		# Check if we should stop tracking (either by distance or time)
		var distance_to_player = enemy_pos.distance_to(player_pos)
		if distance_to_player < track_player_distance or enemy_data.track_timer >= track_duration:
			enemy_data.is_tracking_player = false
			
	else:
		# Resume normal movement to target position
		var target_pos = enemy_data.target_position
		var direction_to_target = (target_pos - enemy_pos).normalized()
		
		# Gradually increase speed
		enemy_data.current_speed = lerp(enemy_data.current_speed, max_speed, acceleration * delta)
		
		# Move towards target position
		var movement = direction_to_target * enemy_data.current_speed * delta
		enemy.global_position += movement
		
		# Face the movement direction
		if direction_to_target.length() > 0:
			enemy.look_at(enemy_pos + direction_to_target, Vector3.UP)
		
		# Remove enemy if it reaches its target position
		if enemy_pos.distance_to(target_pos) < 0.5:
			enemy_data.target_reached = true

# Clean up destroyed enemies
func _physics_process(delta):
	for i in range(enemies.size() - 1, -1, -1):
		var enemy_data = enemies[i]
		if not is_instance_valid(enemy_data.enemy) or enemy_data.target_reached:
			if is_instance_valid(enemy_data.enemy):
				enemy_data.enemy.queue_free()
			enemies.remove_at(i)
