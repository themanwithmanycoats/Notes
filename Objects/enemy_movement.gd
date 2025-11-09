extends Node3D

@export var midi_player: MidiPlayer
@export var player: CharacterBody3D
@export var enemy_scene: PackedScene
@export var spawn_radius: float = 20.0
@export var min_angle: float = -180.0  # Degrees
@export var max_angle: float = 180.0   # Degrees

func _ready():
	if midi_player:
		midi_player.midi_event.connect(_on_midi_event)

func _on_midi_event(channel, event):
	# Check if this is a note on event
	if event is SMF.MIDIEventNoteOn and event.velocity > 0:
		spawn_enemy()

func spawn_enemy():
	if not player or not enemy_scene:
		return
	
	# Get random angle within specified range (in radians)
	var random_angle = deg_to_rad(randf_range(min_angle, max_angle))
	
	# Calculate spawn position in a ring around the player
	var player_pos = player.global_position
	var spawn_pos = Vector3(
		player_pos.x + spawn_radius * cos(random_angle),
		player_pos.y + 5,  # Use player's Y position instead of fixed -5.0
		player_pos.z + spawn_radius * sin(random_angle)
	)
	
	# Instantiate enemy
	var enemy = enemy_scene.instantiate()
	
	# Add to scene FIRST
	add_child(enemy)
	
	# Now set position and rotation (safe because enemy is in tree)
	enemy.global_position = spawn_pos
	
	# Make enemy face towards the player
	var direction_to_player = (player_pos - spawn_pos).normalized()
	enemy.look_at(spawn_pos + direction_to_player, Vector3.UP)
	
	
