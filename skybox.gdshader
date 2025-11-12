shader_type spatial;
render_mode unshaded, cull_front;

uniform sampler2D video_texture : source_color;
uniform float base_brightness = 0.05;
uniform float glow_intensity = 1.0;
uniform vec3 glow_color = vec3(0.3, 0.7, 1.0);

void fragment() {
	vec2 uv = UV;
	uv.y = 1.0 - uv.y;
	vec3 color = texture(video_texture, uv).rgb;
	
	// Start very dark so environment can boost it
	color *= base_brightness;
	
	// Detect blue/cyan for glow
	float blue_amount = max(color.b - color.r * 0.5, 0.0);
	float cyan_amount = max((color.b + color.g) * 0.5 - color.r, 0.0);
	float glow_mask = max(blue_amount, cyan_amount);
	
	// Intense glow on blue areas
	vec3 glow = glow_color * glow_mask * glow_intensity;
	
	// High contrast
	color = pow(color, vec3(1.5));
	
	ALBEDO = color;
	EMISSION = glow;
}