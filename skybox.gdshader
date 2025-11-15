shader_type spatial;
render_mode unshaded, cull_front;

uniform sampler2D video_texture : source_color;
uniform float base_brightness = 5;
uniform float glow_intensity = 0;
uniform vec3 glow_color = vec3(0.3, 0.7, 1.0);
uniform float max_brightness = 0;  // NEW - cap brightness

void fragment() {
	vec2 uv = UV;
	uv.y = 1.0 - uv.y;
	vec3 color = texture(video_texture, uv).rgb;

	// Apply base brightness
	color *= base_brightness;

	// Clamp to prevent bloom from going crazy
	color = clamp(color, vec3(0.0), vec3(max_brightness));

	// Detect blue/cyan for glow
	float blue_amount = max(color.b - color.r * 0.5, 0.0);
	float cyan_amount = max((color.b + color.g) * 0.5 - color.r, 0.0);
	float glow_mask = max(blue_amount, cyan_amount);

	// Reduced glow on blue areas
	vec3 glow = glow_color * glow_mask * glow_intensity;
	glow = clamp(glow, vec3(0.0), vec3(0.3));  // Cap emission

	// High contrast
	color = pow(color, vec3(1.5));

	ALBEDO = color;
	EMISSION = glow;  // Capped emission won't bloom as much
}