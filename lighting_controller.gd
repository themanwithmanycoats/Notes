extends Node
## Global lighting controller that reacts to MIDI events.
##
## This script dynamically adjusts WorldEnvironment settings to create
## aggressive, Thumper-style visual effects synchronized to music.
## It pulses glow, exposure, contrast, saturation, and colors on each beat.
##
## Color modes (priority order):
## 1. Color Rotator - Automatic red-to-blue cycling
## 2. MIDI Channel Colors - Per-channel predefined colors
## 3. Note Pitch Colors - Color based on note pitch
## 4. Fallback White - If all above are disabled

## Reference to the WorldEnvironment node that contains all visual settings
@export var world_environment: WorldEnvironment

## Reference to the MIDI player that triggers visual pulses
@export var midi_player: MidiPlayer

@export_group("Glow")
## Base glow intensity when no beat is playing (Thumper default: 2.5)
@export var base_glow_intensity: float = 4.65
## Peak glow intensity on beat hits (Thumper default: 5.0)
@export var pulse_glow_intensity: float = 4.7
## Base bloom amount - how much glow spreads (0.0-1.0)
@export var base_glow_bloom: float = 0.011
## Peak bloom amount on beats - maximum glow spread
@export var pulse_glow_bloom: float = 0.015
## Base glow strength multiplier
@export var base_glow_strength: float = 0.3
## Peak glow strength on beats
@export var pulse_glow_strength: float = 1.0
## Base HDR threshold - lower = more things glow (0.0-1.0)
@export var base_glow_hdr_threshold: float = 0.835
## Peak HDR threshold on beats - lower = even more glow
@export var pulse_glow_hdr_threshold: float = 0.835
## Base HDR scale - intensity multiplier for HDR colors
@export var base_glow_hdr_scale: float = 2.415
## Peak HDR scale on beats - maximum HDR intensity
@export var pulse_glow_hdr_scale: float = 4.0

@export_group("Tonemap")
## Base exposure - overall brightness (Thumper default: 1.3)
@export var base_exposure: float = 4.96
## Peak exposure on beats - brightest point
@export var pulse_exposure: float = 9.055
## Base white point - where colors clip to white
@export var base_white: float = 8.995
## Peak white point on beats - more aggressive clipping
@export var pulse_white: float = 12.0

@export_group("Adjustments")
## Base brightness adjustment (1.0 = normal)
@export var base_brightness: float = 12.53
## Peak brightness on beats
@export var pulse_brightness: float = 13.49
## Base contrast - separation between dark and light (1.0 = normal, higher = more contrast)
@export var base_contrast: float = 1.415
## Peak contrast on beats - maximum separation
@export var pulse_contrast: float = 1.415
## Base saturation - color intensity (1.0 = normal, higher = more vivid)
@export var base_saturation: float = 1.425
## Peak saturation on beats - hyper-vivid colors
@export var pulse_saturation: float = 2.2

@export_group("Color Flash")
## Enable/disable all color flash effects
@export var enable_color_flash: bool = true
## Intensity of color flashes (0.0-1.0, higher = more visible)
@export var color_flash_intensity: float = 0.1

@export_subgroup("MIDI Channel Mode")
## Use predefined colors per MIDI channel (disables Color Rotator if true)
@export var react_to_midi_channel: bool = false
## Array of 16 colors - one for each MIDI channel (0-15)
@export var channel_colors: Array[Color] = [
	Color(1.0, 0.0, 1.0),  # Channel 0 - Hot Magenta
	Color(0.0, 1.0, 1.0),  # Channel 1 - Cyan
	Color(1.0, 0.2, 0.0),  # Channel 2 - Hot Orange
	Color(1.0, 0.0, 0.5),  # Channel 3 - Hot Pink
	Color(0.5, 0.0, 1.0),  # Channel 4 - Purple
	Color(0.0, 1.0, 0.5),  # Channel 5 - Neon Green
	Color(1.0, 1.0, 0.0),  # Channel 6 - Electric Yellow
	Color(1.0, 0.0, 0.0),  # Channel 7 - Pure Red
	Color(1.0, 1.0, 1.0),  # Channel 8 - Blinding White
	Color(1.0, 0.1, 0.8),  # Channel 9 - Hot Pink (Drums)
	Color(0.0, 0.8, 1.0),  # Channel 10 - Bright Cyan
	Color(1.0, 0.5, 0.0),  # Channel 11 - Orange
	Color(0.8, 0.0, 1.0),  # Channel 12 - Violet
	Color(0.5, 1.0, 0.0),  # Channel 13 - Lime
	Color(0.0, 0.5, 1.0),  # Channel 14 - Sky Blue
	Color(1.0, 0.8, 0.0),  # Channel 15 - Gold
]

@export_subgroup("Color Rotator Mode")
## Enable automatic color cycling (Red→Purple→Blue ping-pong). Overrides MIDI channel colors when enabled.
@export var enable_color_rotator: bool = true
## Speed of color cycling (lower = slower, recommended: 0.05-0.2)
@export var rotation_speed: float = 0.1
## Starting hue - Red (0.0 in HSV color space)
@export var hue_min: float = 0.0
## Ending hue - Blue (0.66 in HSV color space). Color cycles between min and max.
@export var hue_max: float = 0.66
## Color saturation (0.0 = grayscale, 1.0 = fully saturated)
@export var color_saturation: float = 1.0
## Color brightness/value (0.0 = black, 1.0 = full brightness)
@export var color_value: float = 1.0

@export_subgroup("Note Pitch Mode")
## Map note pitch to color (low notes = red, high notes = blue). Only works if Color Rotator and MIDI Channel modes are disabled.
@export var note_pitch_affects_color: bool = false

@export_group("Fog Pulse")
## Enable fog density pulsing on beats
@export var enable_fog_pulse: bool = true
## Base fog density (lower = less fog, 0.005 = subtle)
@export var base_fog_density: float = 0.05
## Peak fog density on beats
@export var pulse_fog_density: float = 0.001
## Base fog light energy (brightness of fog lighting)
@export var base_fog_light_energy: float = 0.5
## Peak fog light energy on beats
@export var pulse_fog_light_energy: float = 2.0

@export_group("Ambient Light Pulse")
## Enable ambient light pulsing on beats
@export var enable_ambient_pulse: bool = true
## Base ambient light energy (very low for dark atmosphere)
@export var base_ambient_energy: float = 0.05
## Peak ambient light energy on beats
@export var pulse_ambient_energy: float = 0.4

@export_group("Background")
## Enable background color flashing on beats
@export var enable_background_pulse: bool = false
## Base background color (usually pure black for Thumper style)
@export var base_background_color: Color = Color(0.0, 0.0, 0.0)
## Duration of background flash in seconds (lower = quicker flash)
@export var background_flash_duration: float = 0.15

@export_group("Timing")
## Attack time - how fast visual hits peak (lower = more instant, Thumper: 0.02)
@export var pulse_attack: float = 0.02
## Release time - how long before returning to base values (higher = longer sustain)
@export var pulse_release: float = 0.8
## MIDI velocity sensitivity multiplier (higher = more responsive to note velocity)
@export var velocity_sensitivity: float = 1.5

@export_group("Advanced")
## Enable different pulse intensities per MIDI channel
@export var per_channel_intensity: bool = true
## Intensity multiplier for drum channel (MIDI channel 9/10). Only works if per_channel_intensity is enabled.
@export var drum_channel_boost: float = 2.0
## Print color selection mode and debug info to console
@export var debug_mode: bool = false

@export_group("Skybox Override")
## Disable all lighting effects on skybox materials (allows video skyboxes to remain visible)
@export var disable_skybox_override: bool = true
## Tag to identify skybox nodes (add this tag to your skybox in Node → Groups)
@export var skybox_group_name: String = "skybox"

# Internal state
var environment: Environment
var pulse_progress: float = 0.0
var target_pulse_progress: float = 0.0
var current_channel_color: Color = Color.WHITE
var target_channel_color: Color = Color.WHITE
var background_flash_progress: float = 0.0
var target_background_flash: float = 0.0

# Color rotator state
var hue_progress: float = 0.0
var hue_direction: int = 1  # 1 = forward, -1 = backward

func _ready():
	print("=== Lighting Controller Initializing ===")
	
	if not world_environment:
		push_error("WorldEnvironment not assigned to LightingController!")
		return
	
	environment = world_environment.environment
	if not environment:
		push_error("WorldEnvironment has no Environment resource!")
		return
	
	print("✓ Environment found and assigned")
	
	# Print color mode priority
	_print_color_mode_status()
	
	# Apply initial base settings
	_apply_base_settings()
	
	# Connect to MIDI player
	if midi_player:
		midi_player.midi_event.connect(_on_midi_event)
		print("✓ LightingController connected to MIDI player")
	else:
		push_warning("No MIDI player assigned to LightingController")
	
	# Disable environment effects on skybox if enabled
	if disable_skybox_override:
		_setup_skybox_override()
	
	print("=== Lighting Controller Ready ===")

func _setup_skybox_override():
	"""Prevent lighting from affecting skybox visibility"""
	var skybox_nodes = get_tree().get_nodes_in_group(skybox_group_name)
	
	if skybox_nodes.size() > 0:
		print("✓ Found ", skybox_nodes.size(), " skybox node(s) - will preserve visibility")
	else:
		print("⚠ No skybox nodes found in group '", skybox_group_name, "'")
		print("  Add your skybox to group '", skybox_group_name, "' in Node → Groups")

func _print_color_mode_status():
	"""Print which color mode is active based on priority"""
	print("\n--- COLOR MODE PRIORITY ---")
	if not enable_color_flash:
		print("⚠ Color Flash DISABLED - No color changes will occur")
	elif enable_color_rotator:
		print("✓ ACTIVE MODE: Color Rotator (Red→Blue ping-pong)")
		print("  - Overrides MIDI channel colors and note pitch colors")
		print("  - To use channel colors: set enable_color_rotator = false")
	elif react_to_midi_channel:
		print("✓ ACTIVE MODE: MIDI Channel Colors")
		print("  - Each MIDI channel uses predefined color from array")
		print("  - To use rotator: set enable_color_rotator = true")
	elif note_pitch_affects_color:
		print("✓ ACTIVE MODE: Note Pitch Colors")
		print("  - Color based on note pitch (low=red, high=blue)")
	else:
		print("⚠ ACTIVE MODE: Fallback White")
		print("  - Enable one of the above modes for color variation")
	print("---------------------------\n")

func _apply_base_settings():
	if not environment:
		return
	
	environment.glow_intensity = base_glow_intensity
	environment.glow_bloom = base_glow_bloom
	environment.glow_strength = base_glow_strength
	environment.glow_hdr_threshold = base_glow_hdr_threshold
	environment.glow_hdr_scale = base_glow_hdr_scale
	
	environment.tonemap_exposure = base_exposure
	environment.tonemap_white = base_white
	
	environment.adjustment_brightness = base_brightness
	environment.adjustment_contrast = base_contrast
	environment.adjustment_saturation = base_saturation
	
	if enable_fog_pulse and environment.fog_enabled:
		environment.fog_density = base_fog_density
		environment.fog_light_energy = base_fog_light_energy
	
	if enable_ambient_pulse:
		environment.ambient_light_energy = base_ambient_energy

func _on_midi_event(channel, event):
	# React to Note On events
	if event is SMF.MIDIEventNoteOn and event.velocity > 0:
		var channel_number = channel.number
		var velocity = event.velocity
		var note = event.note
		
		trigger_pulse(channel_number, velocity, note)

func trigger_pulse(channel_number: int = 0, velocity: int = 127, note: int = 60):
	# Calculate intensity based on velocity
	var base_intensity = float(velocity) / 127.0 * velocity_sensitivity
	var intensity = base_intensity
	
	# Boost drum channel if enabled
	if per_channel_intensity and channel_number == 9:  # MIDI channel 10 (drums) = index 9
		intensity *= drum_channel_boost
	
	# Clamp intensity
	intensity = clamp(intensity, 0.0, 1.5)  # Allow over 1.0 for extra punch
	
	# Set target for lerping (not instant)
	target_pulse_progress = intensity
	
	# Handle color flash with PRIORITY SYSTEM
	if enable_color_flash:
		# PRIORITY 1: Color Rotator (highest priority)
		if enable_color_rotator:
			target_channel_color = _get_rotator_color()
			if debug_mode:
				print("Using Color Rotator: ", target_channel_color)
		
		# PRIORITY 2: MIDI Channel Colors
		elif react_to_midi_channel and channel_number < channel_colors.size():
			target_channel_color = channel_colors[channel_number]
			if debug_mode:
				print("Using MIDI Channel ", channel_number, " Color: ", target_channel_color)
		
		# PRIORITY 3: Note Pitch Colors
		elif note_pitch_affects_color:
			var hue = remap(float(note), 0.0, 127.0, 0.0, 0.7)
			target_channel_color = Color.from_hsv(hue, 1.0, 1.0)
			if debug_mode:
				print("Using Note Pitch Color (note ", note, "): ", target_channel_color)
		
		# PRIORITY 4: Fallback to White
		else:
			target_channel_color = Color.WHITE
			if debug_mode:
				print("Using Fallback White")
		
		# Flash background if enabled
		if enable_background_pulse:
			target_background_flash = intensity

func _get_rotator_color() -> Color:
	"""Get the current color from the rotator based on hue progress"""
	var current_hue: float
	
	if hue_direction == 1:
		# Going forward: red -> purple -> blue
		current_hue = hue_min + (hue_max - hue_min) * hue_progress
	else:
		# Going backward: blue -> purple -> red
		current_hue = hue_max - (hue_max - hue_min) * (1.0 - hue_progress)
	
	return Color.from_hsv(current_hue, color_saturation, color_value)

func _update_color_rotator(delta: float):
	"""Update the color rotator - ping pong between min and max hue"""
	if not enable_color_rotator:
		return
	
	# Move the hue progress
	hue_progress += rotation_speed * delta
	
	# Check bounds and reverse direction (ping pong)
	if hue_progress >= 1.0:
		hue_progress = 1.0
		hue_direction = -1  # Reverse to go back
	elif hue_progress <= 0.0:
		hue_progress = 0.0
		hue_direction = 1  # Reverse to go forward

func _process(delta):
	if not environment:
		return
	
	# Update color rotator (only if enabled)
	_update_color_rotator(delta)
	
	# LERP pulse progress towards target
	if pulse_progress < target_pulse_progress:
		# Fading in - use attack time
		pulse_progress = lerp(pulse_progress, target_pulse_progress, delta / max(pulse_attack, 0.001))
	else:
		# Fading out - use release time
		pulse_progress = lerp(pulse_progress, 0.0, delta / max(pulse_release, 0.001))
		target_pulse_progress = lerp(target_pulse_progress, 0.0, delta / max(pulse_release, 0.001))
	
	# Smoothly interpolate to target color
	var color_speed = delta / max(pulse_attack, 0.001)
	current_channel_color = current_channel_color.lerp(target_channel_color, color_speed)
	
	# LERP background flash progress
	if background_flash_progress < target_background_flash:
		# Fading in - use attack time
		background_flash_progress = lerp(background_flash_progress, target_background_flash, delta / max(pulse_attack, 0.001))
	else:
		# Fading out - use release time for consistency
		background_flash_progress = lerp(background_flash_progress, 0.0, delta / max(pulse_release, 0.001))
		target_background_flash = lerp(target_background_flash, 0.0, delta / max(pulse_release, 0.001))
	
	# Apply all settings based on pulse progress
	var t = pulse_progress
	
	# Glow settings - ALWAYS ACTIVE
	environment.glow_intensity = lerp(base_glow_intensity, pulse_glow_intensity, t)
	environment.glow_bloom = lerp(base_glow_bloom, pulse_glow_bloom, t)
	environment.glow_strength = lerp(base_glow_strength, pulse_glow_strength, t)
	environment.glow_hdr_threshold = lerp(base_glow_hdr_threshold, pulse_glow_hdr_threshold, t)
	environment.glow_hdr_scale = lerp(base_glow_hdr_scale, pulse_glow_hdr_scale, t)
	
	# Tonemap settings - ALWAYS ACTIVE
	environment.tonemap_exposure = lerp(base_exposure, pulse_exposure, t)
	environment.tonemap_white = lerp(base_white, pulse_white, t)
	
	# Adjustment settings - ALWAYS ACTIVE
	environment.adjustment_brightness = lerp(base_brightness, pulse_brightness, t)
	environment.adjustment_contrast = lerp(base_contrast, pulse_contrast, t)
	environment.adjustment_saturation = lerp(base_saturation, pulse_saturation, t)
	
	# Fog settings - Only if enabled
	if enable_fog_pulse and environment.fog_enabled:
		environment.fog_density = lerp(base_fog_density, pulse_fog_density, t)
		environment.fog_light_energy = lerp(base_fog_light_energy, pulse_fog_light_energy, t)
	
	# Ambient light settings - Only if enabled
	if enable_ambient_pulse:
		environment.ambient_light_energy = lerp(base_ambient_energy, pulse_ambient_energy, t)
	
	# Background flash - only if enabled
	if enable_background_pulse and background_flash_progress > 0.01:
		var flash_color = current_channel_color * color_flash_intensity * background_flash_progress
		environment.background_color = base_background_color + flash_color
	else:
		environment.background_color = base_background_color

## Manually trigger a pulse with specific intensity (0.0 to 1.5)
func pulse_on_beat(intensity: float = 1.0):
	target_pulse_progress = clamp(intensity, 0.0, 1.5)

## Dynamically adjust base values during runtime. Set to -1.0 to skip that parameter.
func set_base_values(glow: float = -1.0, exposure: float = -1.0, contrast: float = -1.0, saturation: float = -1.0):
	if glow >= 0.0:
		base_glow_intensity = glow
	if exposure >= 0.0:
		base_exposure = exposure
	if contrast >= 0.0:
		base_contrast = contrast
	if saturation >= 0.0:
		base_saturation = saturation

## Dynamically adjust pulse peak values during runtime. Set to -1.0 to skip that parameter.
func set_pulse_values(glow: float = -1.0, exposure: float = -1.0, contrast: float = -1.0, saturation: float = -1.0):
	if glow >= 0.0:
		pulse_glow_intensity = glow
	if exposure >= 0.0:
		pulse_exposure = exposure
	if contrast >= 0.0:
		pulse_contrast = contrast
	if saturation >= 0.0:
		pulse_saturation = saturation

## Force a specific color flash, temporarily overriding the current color mode
func force_color(color: Color, duration: float = 0.5):
	target_channel_color = color
	target_background_flash = 1.0
	background_flash_duration = duration
