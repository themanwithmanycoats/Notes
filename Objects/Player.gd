extends CharacterBody3D

var speed
const WALK_SPEED = 5.0
const SPRINT_SPEED = 10.0
const JUMP_VELOCITY = 4.5
const SENSITIVITY = 0.003

# Bob variables
const BOB_FREQ = 2.0
const BOB_AMP = 0.08
var t_bob = 0.0

# FOV variables
const BASE_FOV = 75
const FOV_CHANGE = 1.5

# Slide variables
const SLIDE_SPEED_BOOST = 15.0  # Initial speed boost
const SLIDE_FOV_CHANGE = 10.0  # Extra FOV during slide
const SLIDE_DECELERATION = 3.0  # How fast slide loses speed (lower = longer slide)
const SLIDE_MIN_SPEED = 1.0  # When to exit slide
const SLIDE_CAMERA_LOWER = 0.5  # How much to lower camera during slide
var is_sliding = false
var slide_speed = 0.0
var slide_camera_offset = 0.0

var gravity = 9.8

@onready var head = $Head
@onready var camera = $Head/Camera3D

# Enemy indicator variables
var enemy_indicators = {}  # Track indicators by enemy reference

func _ready():
	print("=== PLAYER READY ===")
	print("Player node: ", self)
	print("Player position: ", global_position)
	
	# Add player to group for collision detection
	if not is_in_group("player"):
		add_to_group("player")
		print("✓ Added to 'player' group")
	else:
		print("✓ Already in 'player' group")
	
	# Lock and hide the mouse cursor
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	print("✓ Mouse captured")
	
	# Connect to tree_exiting signal to unlock mouse when destroyed
	tree_exiting.connect(_on_tree_exiting)
	print("✓ Tree exiting signal connected")
	print("=== PLAYER SETUP COMPLETE ===\n")

func _on_tree_exiting():
	# Unlock mouse when player is destroyed
	print("!!! PLAYER DESTROYED - Unlocking mouse !!!")
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _input(event: InputEvent) -> void:
	# Unlock mouse with Escape key (works even if player is destroyed)
	if event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Toggle mouse free with existing action
	if Input.is_action_just_pressed("mouse free"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-40), deg_to_rad(60))

func _physics_process(delta: float) -> void:
	# Add the gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	# Handle jump
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		if is_sliding:
			is_sliding = false
		velocity.y = JUMP_VELOCITY
	
	# Handle Slide
	if Input.is_action_just_pressed("Slide") and Input.is_action_pressed("Sprint") and is_on_floor() and !is_sliding:
		start_slide()
	
	# Break out of slide by pressing sprint again
	if is_sliding and Input.is_action_just_pressed("Sprint"):
		is_sliding = false
		speed = SPRINT_SPEED
		slide_camera_offset = 0.0
	
	# Update slide
	if is_sliding:
		update_slide(delta)
	else:
		# Handle Sprint
		if Input.is_action_pressed("Sprint"):
			speed = SPRINT_SPEED
		else:
			speed = WALK_SPEED
	
	# Get the input direction and handle the movement/deceleration
	var input_dir := Input.get_vector("Strafe Left", "Strafe Right", "Move Forward", "Move Backwards")
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if is_on_floor():
		if direction:
			if is_sliding:
				# During slide, move in slide direction
				velocity.x = direction.x * slide_speed
				velocity.z = direction.z * slide_speed
			else:
				velocity.x = direction.x * speed
				velocity.z = direction.z * speed
		else:
			if not is_sliding:
				velocity.x = 0
				velocity.z = 0
	else:
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 2.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 2.0)
	
	# Head bob (disable during slide)
	if not is_sliding:
		t_bob += delta * velocity.length() * float(is_on_floor())
		camera.transform.origin = _headbob(t_bob)
	else:
		# Lower camera during slide
		slide_camera_offset = lerp(slide_camera_offset, -SLIDE_CAMERA_LOWER, delta * 10.0)
		camera.transform.origin = Vector3(0, slide_camera_offset, 0)
	
	# FOV
	var velocity_clamped = clamp(velocity.length(), 0.5, SPRINT_SPEED * 2)
	var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	
	# Add extra FOV during slide
	if is_sliding:
		target_fov += SLIDE_FOV_CHANGE
	
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)
	
	move_and_slide()

func start_slide():
	is_sliding = true
	slide_speed = SLIDE_SPEED_BOOST

func update_slide(delta: float):
	# Decelerate slide speed
	slide_speed = lerp(slide_speed, 0.0, delta * SLIDE_DECELERATION)
	
	# Exit slide when speed is too low
	if slide_speed <= SLIDE_MIN_SPEED:
		is_sliding = false
		speed = WALK_SPEED
		# Return camera to normal height
		slide_camera_offset = 0.0

func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	return pos

# Called by enemy spawner to show directional indicator
func show_enemy_indicator(enemy: Node3D):
	# Create indicator UI
	var indicator = Control.new()
	indicator.set_anchors_preset(Control.PRESET_CENTER)
	indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	indicator.modulate.a = 0.0  # Start invisible for fade in
	
	# Create arrow label
	var label = Label.new()
	label.text = "⚠"
	label.add_theme_font_size_override("font_size", 48)
	label.add_theme_color_override("font_color", Color(1.0, 0.0, 0.0))
	indicator.add_child(label)
	
	# Add to camera's canvas layer (or create one)
	var canvas = get_or_create_canvas_layer()
	canvas.add_child(indicator)
	
	# Fade in animation (0.2 seconds), then fade out (0.7 seconds)
	var tween = create_tween()
	tween.tween_property(indicator, "modulate:a", 1.0, 0.2)
	tween.tween_property(indicator, "modulate:a", 0.0, 0.7)
	tween.tween_callback(indicator.queue_free)
	
	# Store reference (will auto-cleanup when indicator is freed)
	enemy_indicators[enemy] = {
		"indicator": indicator,
		"label": label,
		"fade_out_started": true  # Already handled by tween
	}

func _process(delta):
	# Update all enemy indicators
	for enemy in enemy_indicators.keys():
		if not is_instance_valid(enemy):
			# Clean up reference if enemy is destroyed
			enemy_indicators.erase(enemy)
			continue
		
		# Only update indicators that still exist
		if is_instance_valid(enemy_indicators[enemy].indicator):
			update_enemy_indicator(enemy, enemy_indicators[enemy])

func update_enemy_indicator(enemy: Node3D, indicator_data: Dictionary):
	var indicator = indicator_data.indicator
	var label = indicator_data.label
	
	# Get direction to enemy
	var to_enemy = (enemy.global_position - global_position).normalized()
	var forward = -head.global_transform.basis.z
	var right = head.global_transform.basis.x
	
	# Calculate angle
	var dot_forward = to_enemy.dot(forward)
	var dot_right = to_enemy.dot(right)
	
	# If enemy is behind or to the side, show indicator
	if dot_forward < 0.7:  # Not directly in front
		indicator.visible = true
		
		# Position indicator on edge of screen
		var viewport_size = get_viewport().get_visible_rect().size
		var angle = atan2(dot_right, dot_forward)
		
		# Map angle to screen edge position
		var screen_pos = Vector2.ZERO
		var margin = 100.0
		
		if abs(dot_right) > abs(dot_forward):
			# Enemy is more to the side
			screen_pos.x = viewport_size.x / 2 + sign(dot_right) * (viewport_size.x / 2 - margin)
			screen_pos.y = viewport_size.y / 2 - tan(angle) * (viewport_size.x / 2 - margin)
		else:
			# Enemy is more forward/backward
			screen_pos.y = viewport_size.y / 2 + sign(-dot_forward) * (viewport_size.y / 2 - margin)
			screen_pos.x = viewport_size.x / 2 + dot_right * (viewport_size.x / 2 - margin)
		
		screen_pos.y = clamp(screen_pos.y, margin, viewport_size.y - margin)
		screen_pos.x = clamp(screen_pos.x, margin, viewport_size.x - margin)
		
		indicator.position = screen_pos
		
		# Rotate arrow to point toward enemy
		label.rotation = angle + PI / 2
		
		# Fade based on distance
		var distance = global_position.distance_to(enemy.global_position)
		var alpha = clamp(1.0 - (distance / 50.0), 0.3, 1.0)
		label.modulate.a = alpha
	else:
		# Enemy is in front of player
		indicator.visible = false

func get_or_create_canvas_layer() -> CanvasLayer:
	# Check if canvas layer already exists
	for child in get_children():
		if child is CanvasLayer:
			return child
	
	# Create new canvas layer
	var canvas = CanvasLayer.new()
	canvas.name = "HUD"
	add_child(canvas)
	return canvas
