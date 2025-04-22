shader_type canvas_item;

uniform bool vertical;
uniform sampler2D screen: hint_screen_texture;

const vec2 pixel_size = vec2(1.0 / 640.0, 1.0 / 360.0);

void fragment() {
	vec2 pixel_offset = vertical ? vec2(pixel_size.x, 0) : vec2(0, pixel_size.y);
	vec2 uv1 = SCREEN_UV;
	vec2 uv0 = SCREEN_UV + pixel_offset * 1.33333;
	vec2 uv2 = SCREEN_UV - pixel_offset * 1.33333;
	vec3 col0 = texture(screen, uv0).rgb * 0.35294117647058826;
	vec3 col1 = texture(screen, uv1).rgb * 0.29411764705882354;
	vec3 col2 = texture(screen, uv2).rgb * 0.35294117647058826;
	COLOR = vec4(col0 + col1 + col2, 1.0);
	// Called for every pixel the material is visible on.
}
